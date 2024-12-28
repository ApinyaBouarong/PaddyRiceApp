import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final Map<String, WebSocketChannel> _channels = {};

  void connectToDevice(String deviceId, Function(dynamic) onData) {
    if (!_channels.containsKey(deviceId)) {
      final wsUrl = Uri.parse('ws://10.0.2.2:3000/ws');
      final channel = WebSocketChannel.connect(wsUrl);

      channel.stream.listen(
        (data) {
          onData(data);
        },
        onError: (error) {
          print('WebSocket Error: $error');
          reconnectToDevice(deviceId, onData);
        },
        onDone: () {
          print('WebSocket connection closed');
          reconnectToDevice(deviceId, onData);
        },
      );

      _channels[deviceId] = channel;
    }
  }

  void reconnectToDevice(String deviceId, Function(dynamic) onData) {
    _channels.remove(deviceId);
    Future.delayed(Duration(seconds: 1), () {
      connectToDevice(deviceId, onData);
    });
  }

  void disconnectFromDevice(String deviceId) {
    if (_channels.containsKey(deviceId)) {
      _channels[deviceId]!.sink.close(status.goingAway);
      _channels.remove(deviceId);
    }
  }

  void dispose() {
    for (var channel in _channels.values) {
      channel.sink.close();
    }
    _channels.clear();
  }
}
