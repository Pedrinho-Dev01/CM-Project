import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorGraph extends StatefulWidget {
  final int id;

  const SensorGraph({Key? key, required this.id}) : super(key: key);

  @override
  _SensorGraphState createState() => _SensorGraphState();
}

class _SensorGraphState extends State<SensorGraph> {
  final client = MqttServerClient('test.mosquitto.org', '');
  bool isConnected = false;
  final _random = Random();

  // Data lists for ID 1 sensors (humidity, temperature, pressure)
  List<FlSpot> humidityReadings = [];
  List<FlSpot> temperatureReadings = [];
  List<FlSpot> pressureReadings = [];
  int xAxisCounter = 0;

  // Data list for ID 2 sensors (lux)
  List<FlSpot> luxReadings = [];

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
      _showConnectionError();
      client.disconnect();
    }
  }

  void _showConnectionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text('Failed to connect to the MQTT broker. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onConnected() {
    setState(() {
      isConnected = true;
    });
    print('Connected to the MQTT broker!');
    client.subscribe('test/flutter/topic', MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    setState(() {
      isConnected = false;
    });
    print('Disconnected from the MQTT broker');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic $topic');
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe to topic $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final MqttPublishMessage recMessage = event[0].payload as MqttPublishMessage;
    final String message =
    MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

    try {
      final decodedMessage = jsonDecode(message);

      // Handle ID = 1 messages with humidity, temperature, and pressure
      if (decodedMessage['type'] == 'sensor_reading' && decodedMessage['id'] == 1) {
        final double humidity = decodedMessage['humidity'];
        final double temperature = decodedMessage['temperature'];
        final double pressure = decodedMessage['pressure'];

        setState(() {
          humidityReadings.add(FlSpot(xAxisCounter.toDouble(), humidity));
          temperatureReadings.add(FlSpot(xAxisCounter.toDouble(), temperature));
          pressureReadings.add(FlSpot(xAxisCounter.toDouble(), pressure));
          xAxisCounter++;
        });

        print('ID 1 data added: Humidity=$humidity, Temperature=$temperature, Pressure=$pressure');

        // Handle ID = 2 messages with lux
      } else if (decodedMessage['type'] == 'sensor_reading' && decodedMessage['id'] == 2) {
        final double luxValue = decodedMessage['lux'];

        setState(() {
          luxReadings.add(FlSpot(xAxisCounter.toDouble(), luxValue));
          xAxisCounter++;
        });

        print('Lux value added to graph: $luxValue');
      } else {
        print('Unknown message format or ID.');
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _clearMessages() {
    setState(() {
      humidityReadings.clear();
      temperatureReadings.clear();
      pressureReadings.clear();
      luxReadings.clear();
      xAxisCounter = 0;
    });
    print('Messages cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Readings for ID ${widget.id}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: Colors.white,
            ),
            onPressed: () {},
            tooltip: isConnected ? 'Connected' : 'Disconnected',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            onPressed: _clearMessages,
            tooltip: 'Clear Data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.id == 1 ? _buildId1Display() : _buildLuxDisplay(),
      ),
    );
  }

  // Display for ID = 1 (humidity, temperature, pressure)
  Widget _buildId1Display() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _buildParameterChart('Humidity', humidityReadings),
              _buildParameterChart('Temperature', temperatureReadings),
              _buildParameterChart('Pressure', pressureReadings),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Latest Readings - Humidity: ${humidityReadings.isNotEmpty ? humidityReadings.last.y.toStringAsFixed(2) : 'N/A'}%, '
              'Temperature: ${temperatureReadings.isNotEmpty ? temperatureReadings.last.y.toStringAsFixed(2) : 'N/A'}°C, '
              'Pressure: ${pressureReadings.isNotEmpty ? pressureReadings.last.y.toStringAsFixed(2) : 'N/A'} hPa',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Display for ID = 2 (lux)
  Widget _buildLuxDisplay() {
    return Column(
      children: [
        Expanded(
          child: _buildParameterChart('Lux', luxReadings),
        ),
        const SizedBox(height: 20),
        Text(
          luxReadings.isNotEmpty
              ? 'Last Lux Reading: ${luxReadings.last.y.toStringAsFixed(2)}'
              : 'Waiting for data...',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper function to build charts for each parameter
  Widget _buildParameterChart(String title, List<FlSpot> readings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 5),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.black, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: readings,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
