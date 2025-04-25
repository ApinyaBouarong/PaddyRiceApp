import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  // Singleton pattern
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;

  final String broker = '192.168.186.94';
  final int port = 1883;
  final String clientId = 'flutter_mqtt_client';
  final String topic = 'sensor/data';
  final String? username = 'mymqtt';
  final String? password = 'paddy';

  // เพิ่มตัวแปรเก็บสถานะการเชื่อมต่อ
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect() async {
    // ถ้าเชื่อมต่ออยู่แล้ว ไม่ต้องเชื่อมต่อใหม่
    if (isConnected) {
      print('Already connected to MQTT broker');
      return true;
    }

    // สร้าง unique client ID เพื่อป้องกันการชนกันของ client IDs
    String uniqueId = '$clientId-${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(broker, uniqueId);
    _client!.port = port;
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true; // เพิ่ม auto reconnect

    _client!.onConnected = onConnected;
    _client!.onDisconnected = onDisconnected;
    _client!.onSubscribed = onSubscribed;
    _client!.onAutoReconnect = () {
      print('Auto reconnecting to MQTT broker...');
    };
    _client!.onAutoReconnected = () {
      print('Auto reconnected to MQTT broker');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(uniqueId)
        .startClean()
        .keepAliveFor(20)
        .withWillQos(MqttQos.atLeastOnce) // เพิ่ม will message
        // .withWillRetain(false)
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
    // ทำการ subscribe เมื่อเชื่อมต่อได้
    _client!.subscribe(topic, MqttQos.atLeastOnce);

    // ส่งข้อความว่า online เมื่อเชื่อมต่อได้
    final builder = MqttClientPayloadBuilder();
    builder.addString('online');
    _client!
        .publishMessage('client/status', MqttQos.atLeastOnce, builder.payload!);
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
    // พยายามเชื่อมต่อใหม่หลังจาก 5 วินาที
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

  void publishData(String payload) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Published data: $payload');
    } else {
      print('Cannot publish: not connected to broker');
      // ลองเชื่อมต่อใหม่ก่อน publish
      connect().then((connected) {
        if (connected) {
          publishData(payload);
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
      // ส่งข้อความว่า offline ก่อนตัดการเชื่อมต่อ
      final builder = MqttClientPayloadBuilder();
      builder.addString('offline');
      _client!.publishMessage(
          'client/status', MqttQos.atLeastOnce, builder.payload!);

      _client!.disconnect();
    }
  }

  // เพิ่มฟังก์ชันเพื่อตรวจสอบและรักษาการเชื่อมต่อ
  Future<bool> ensureConnected() async {
    return isConnected ? true : await connect();
  }
}
