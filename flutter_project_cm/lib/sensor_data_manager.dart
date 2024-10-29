import 'dart:async';
import 'dart:convert';

class SensorDataManager {
  final StreamController<Map<String, dynamic>> _sensorDataController =
  StreamController.broadcast();

  // Stream to listen to sensor data updates
  Stream<Map<String, dynamic>> get sensorDataStream => _sensorDataController.stream;

  // Latest sensor readings
  double? humidity;
  double? temperature;
  double? pressure;
  double? lux;

  // Method to process incoming JSON data
  void processSensorData(String jsonString) {
    final decodedData = jsonDecode(jsonString);

    if (decodedData['type'] == 'sensor_reading') {
      final int id = decodedData['id'];

      if (id == 1) {
        humidity = decodedData['humidity'];
        temperature = decodedData['temperature'];
        pressure = decodedData['pressure'];
      } else if (id == 2) {
        lux = decodedData['lux'];
      }

      // Push the updated data to the stream
      _sensorDataController.add({
        'humidity': humidity,
        'temperature': temperature,
        'pressure': pressure,
        'lux': lux,
      });
    }
  }

  void dispose() {
    _sensorDataController.close();
  }
}
