import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulated Environmental Sensor',
      theme: ThemeData(
        fontFamily: 'SansSerif',
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[600],
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 18, color: Colors.grey[800]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: MQTTExample(),
    );
  }
}

class MQTTExample extends StatefulWidget {
  @override
  _MQTTExampleState createState() => _MQTTExampleState();
}

class _MQTTExampleState extends State<MQTTExample> {
  final client = MqttServerClient('test.mosquitto.org', '');
  List<String> messages = [];
  Timer? _timer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _connectMQTT();
  }

  Future<void> _connectMQTT() async {
    client.logging(on: true);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.onUnsubscribed = _onUnsubscribed;
    client.onSubscribeFail = _onSubscribeFail;
    client.pongCallback = _pong;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${_random.nextInt(10000)}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.updates!.listen(_onMessage);
    } catch (e) {
      print('Error: $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker!');
    client.subscribe('test/flutter/topic', MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  void _onUnsubscribed(String? topic) {
    print('Unsubscribed from $topic');
  }

  void _pong() {
    print('Ping response client received');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final MqttPublishMessage recMessage = event[0].payload as MqttPublishMessage;
    final String message =
    MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

    setState(() {
      messages.add(message);
    });

    print('Received message: $message from topic: ${event[0].topic}>');
  }

  double _getRandomValue(double base, double variation) {
    return base + (_random.nextDouble() * variation * 2) - variation;
  }

  void _publishSensorData() {
    final humidity = _getRandomValue(40.0, 60.0); // Range 40-60%
    final temperature = _getRandomValue(17.0, 25.0); // Range 17-27°C
    final pressure = _getRandomValue(1010.25, 1020.0); // Range around standard atmospheric pressure

    final messageJson = jsonEncode({
      'type': 'sensor_reading',
      'id': 1,
      'humidity': humidity,
      'temperature': temperature,
      'pressure': pressure,
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(messageJson);
    client.publishMessage('test/flutter/topic', MqttQos.atLeastOnce, builder.payload!);
  }

  void _startSimulation() {
    _stopTimer();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _publishSensorData();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    print('Stopped sending messages');
  }

  void _clearMessages() {
    setState(() {
      messages.clear();
    });
    print('Cleared all messages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulated Sensor 1'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startSimulation,
                icon: const Icon(Icons.play_arrow, color: Colors.lightGreen),
                label: const Text('Start Simulation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[900],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _stopTimer,
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[900],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearMessages,
                icon: const Icon(Icons.cleaning_services, color: Colors.blueAccent),
                label: const Text('Clean'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.message, color: Colors.green[400]),
                        title: Text(
                          messages[index],
                          style: TextStyle(color: Colors.green[900]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    client.disconnect();
    super.dispose();
  }
}
