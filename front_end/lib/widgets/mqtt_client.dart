import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  // Singleton pattern
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;

  final String broker = '192.168.33.87';
  final int port = 1883;
  final String clientId = 'flutter_mqtt_client';
  final String tempDataTopic = 'sensor/data';
  final String humidityDataTopic = 'sensor/ai';
  final String? username = 'mymqtt';
  final String? password = 'paddy';

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect() async {
    if (isConnected) {
      print('Already connected to MQTT broker');
      return true;
    }

    String uniqueId = '$clientId-${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(broker, uniqueId);
    _client!.port = port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;

    _client!.onConnected = onConnected;
    _client!.onDisconnected = onDisconnected;
    _client!.onSubscribed = onSubscribed;
    _client!.onAutoReconnect = () {
      print('Auto reconnecting to MQTT broker...');
    };
    _client!.onAutoReconnected = () {
      print('Auto reconnected to MQTT broker');
      _client!.subscribe(tempDataTopic, MqttQos.atLeastOnce);
      _client!.subscribe(humidityDataTopic, MqttQos.atLeastOnce);
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(uniqueId)
        .startClean()
        .keepAliveFor(20)
        .withWillQos(MqttQos.atLeastOnce)
        .withWillTopic('client/status')
        .withWillMessage('offline')
        .authenticateAs(username, password);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      return isConnected;
    } on Exception catch (e) {
      print('Connection exception: $e');
      _client!.disconnect();
      return false;
    }
  }

  void onConnected() {
    print('Connected to MQTT broker');
    _client!.subscribe(tempDataTopic, MqttQos.atLeastOnce);
    _client!.subscribe(humidityDataTopic, MqttQos.atLeastOnce);

    final builder = MqttClientPayloadBuilder();
    builder.addString('online');
    _client!
        .publishMessage('client/status', MqttQos.atLeastOnce, builder.payload!);
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
    Future.delayed(Duration(seconds: 5), () {
      if (!isConnected) {
        print('Attempting to reconnect after disconnect...');
        connect();
      }
    });
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void publishData(String payload, String topic) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Published data: $payload to topic: $topic');
    } else {
      print('Cannot publish: not connected to broker');
      connect().then((connected) {
        if (connected) {
          publishData(payload, topic);
        }
      });
    }
  }

  void listenToMessages(Function(String) onMessageReceived) {
    if (_client != null) {
      _client!.updates
          ?.listen((List<MqttReceivedMessage<MqttMessage?>> messages) {
        if (messages.isNotEmpty && messages[0].payload != null) {
          final MqttPublishMessage recMessage =
              messages[0].payload as MqttPublishMessage;
          final String message = MqttPublishPayload.bytesToStringAsString(
              recMessage.payload.message);

          print('Received message: $message from topic: ${messages[0].topic}');

          onMessageReceived(message);
        }
      });
    }
  }

  void disconnect() {
    if (_client != null && isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('offline');
      _client!.publishMessage(
          'client/status', MqttQos.atLeastOnce, builder.payload!);

      _client!.disconnect();
    }
  }

  Future<bool> ensureConnected() async {
    return isConnected ? true : await connect();
  }
}
