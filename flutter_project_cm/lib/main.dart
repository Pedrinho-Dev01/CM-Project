import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'sensor_graph.dart'; // Importação do arquivo do gráfico
import 'package:flutter_project_cm/user.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'boxes.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  boxUsers = await Hive.openBox<User>('userBox');
  await addDefaultUser();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LandingPage(),
      routes: {
        '/hello': (context) => const HelloWorldPage(),
      },
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    bool isValid = await _verifyCredentials(username, password);

    if (isValid) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUser', username);
      Navigator.pushNamed(context, '/hello');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  Future<bool> _verifyCredentials(String username, String password) async {
    for (var i = 0; i < boxUsers.length; i++) {
      User? user = boxUsers.getAt(i);
      if (user != null && user.username == username && user.password == password) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
            ),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HelloWorldPage extends StatelessWidget {
  const HelloWorldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.map), text: 'Map'),
            ],
          ),
          title: const Text('Hello World Page'),
        ),
        body: const TabBarView(
          children: [
            HomeTab(),
            MapTab(),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  double temperature = 25.0;
  double humidity = 60.0;
  double ph = 7.0;
  double dielectric = 10.5;

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Temperature: $temperature°C', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('Humidity: $humidity%', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('pH: $ph', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('Dielectric: $dielectric', style: pw.TextStyle(fontSize: 18)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.thermostat),
                  title: const Text('Temperature'),
                  subtitle: Text('$temperature°C'),
                ),
                ListTile(
                  leading: const Icon(Icons.water_drop),
                  title: const Text('Humidity'),
                  subtitle: Text('$humidity%'),
                ),
                ListTile(
                  leading: const Icon(Icons.science),
                  title: const Text('pH'),
                  subtitle: Text('$ph'),
                ),
                ListTile(
                  leading: const Icon(Icons.electrical_services),
                  title: const Text('Dielectric'),
                  subtitle: Text('$dielectric'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _printPdf,
              child: const Text('Print PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  List<Marker> _markers = [];

  Color randomColor() {
    Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  Future<List<Marker>> loadUserMarkers() async {
    List<Marker> markers = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String loggedInUser = prefs.getString('loggedInUser') ?? '';

    for (var i = 0; i < boxUsers.length; i++) {
      User? user = boxUsers.getAt(i);
      if (user != null && user.username == loggedInUser) {
        markers.add(
          Marker(
            key: ValueKey('marker$i'),
            width: user.width,
            height: user.height,
            point: LatLng(user.latitude, user.longitude),
            child: GestureDetector(
              onTap: () {
                String lastValue = user.lastValue ?? 'N/A';
                int sensorId = int.tryParse(lastValue) ?? 0;

                if (sensorId == 1 || sensorId == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SensorGraph(id: sensorId),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        insetPadding: EdgeInsets.zero,
                        child: Scaffold(
                          appBar: AppBar(
                            title: Text('Detalhes do Marcador ${i + 1}'),
                            backgroundColor: Colors.blue,
                          ),
                          body: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Último Valor: $lastValue',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
              child: Icon(
                Icons.location_on,
                size: 50.0,
                color: randomColor(),
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  @override
  void initState() {
    super.initState();
    loadUserMarkers().then((markers) {
      setState(() {
        _markers = markers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(40.6405, -8.6538),
        initialZoom: 17.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }
}
