import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient _client;

  final String broker = '192.168.0.106';
  final int port = 1883;
  final String clientId = 'flutter_mqtt_client';
  final String topic = 'sensor/data';
  final String? username = 'mymqtt';
  final String? password = 'paddy';

  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client.port = port;
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;

    _client.onConnected = onConnected;
    _client.onDisconnected = onDisconnected;
    _client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .keepAliveFor(20)
        .authenticateAs(username, password);
    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
    } on Exception catch (e) {
      print('Connection exception: $e');
      _client.disconnect();
    }
  }

  void onConnected() {
    print('Connected to MQTT broker');
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void publishData(String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print('Published data: $payload');
  }

  void listenToMessages(Function(String) onMessageReceived) {
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> messages) {
      final MqttPublishMessage recMessage =
          messages[0].payload as MqttPublishMessage;
      final String message =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('Received message: $message from topic: ${messages[0].topic}');

      onMessageReceived(message);
    });
  }

  void disconnect() {
    _client.disconnect();
  }
}
