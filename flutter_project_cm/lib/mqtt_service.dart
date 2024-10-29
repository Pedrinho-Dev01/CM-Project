import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final client = MqttServerClient('test.mosquitto.org', '');
  final StreamController<Map<String, dynamic>> _streamController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get sensorStream => _streamController.stream;

  MqttService() {
    _connectMQTT();
  }

  Future<void> _connectMQTT() async {
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.subscribe('test/flutter/topic', MqttQos.atLeastOnce);
      client.updates!.listen(_onMessage);
    } catch (e) {
      print('Error connecting to MQTT broker: $e');
      client.disconnect();
    }
  }

  void _onConnected() => print('Connected to MQTT broker');
  void _onDisconnected() => print('Disconnected from MQTT broker');

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final MqttPublishMessage recMessage = event[0].payload as MqttPublishMessage;
    final message = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

    try {
      final data = jsonDecode(message);
      if (data['type'] == 'sensor_reading') {
        _streamController.add(data);
      }
    } catch (e) {
      print('Error parsing MQTT message: $e');
    }
  }

  void dispose() {
    _streamController.close();
    client.disconnect();
  }
}

final mqttService = MqttService();
