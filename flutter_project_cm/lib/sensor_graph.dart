// sensor_graph.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorGraph extends StatefulWidget {
  @override
  _SensorGraphState createState() => _SensorGraphState();
}

class _SensorGraphState extends State<SensorGraph> {
  final client = MqttServerClient('test.mosquitto.org', '');
  List<FlSpot> luxReadings = [];
  int xAxisCounter = 0;
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
      print('Erro: $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('Conectado ao broker MQTT!');
    client.subscribe('test/flutter/topic', MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Desconectado do broker MQTT');
  }

  void _onSubscribed(String topic) {
    print('Inscrito no tópico $topic');
  }

  void _onSubscribeFail(String topic) {
    print('Falha ao se inscrever no tópico $topic');
  }

  void _pong() {
    print('Resposta ping recebida');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final MqttPublishMessage recMessage = event[0].payload as MqttPublishMessage;
    final String message =
    MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

    try {
      final decodedMessage = jsonDecode(message);
      if (decodedMessage['type'] == 'sensor_reading' && decodedMessage['id'] == 2) {
        final luxValue = decodedMessage['lux'] as double;

        setState(() {
          luxReadings.add(FlSpot(xAxisCounter.toDouble(), luxValue));
          xAxisCounter++;
        });
        print('Valor de lux adicionado ao gráfico: $luxValue');
      } else {
        print('Mensagem recebida, mas não corresponde ao formato esperado.');
      }
    } catch (e) {
      print('Erro ao analisar mensagem: $e');
    }
  }

  void _clearMessages() {
    setState(() {
      luxReadings.clear();
      xAxisCounter = 0;
    });
    print('Mensagens limpas');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leituras do Sensor de Luz'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            onPressed: _clearMessages,
            tooltip: 'Limpar Dados',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: luxReadings,
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 3,
                      belowBarData:
                      BarAreaData(show: true, color: Colors.indigo.withOpacity(0.3)),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              luxReadings.isNotEmpty
                  ? 'Última leitura de Lux: ${luxReadings.last.y.toStringAsFixed(2)}'
                  : 'Aguardando dados...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
