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
import 'mqtt_service.dart';

double temperature = 0.0;
double humidity = 0.0;
double pressure = 0.0;
double lux = 0.0;
void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  boxUsers = await Hive.openBox<User>('userBox');
  await addDefaultUser();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _loggedInUser = '';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLoggedInUser();
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeMode = prefs.getString('themeMode');
    setState(() {
      if (themeMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  Future<void> _loadLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUser = prefs.getString('loggedInUser') ?? '';
      print('Logged in user: $_loggedInUser'); // Debugging statement
    });
  }

  Future<void> _toggleThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        prefs.setString('themeMode', 'dark');
      } else {
        _themeMode = ThemeMode.light;
        prefs.setString('themeMode', 'light');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: LandingPage(
        toggleThemeMode: _toggleThemeMode,
        themeMode: _themeMode,
      ),
      routes: {
        '/hello': (context) => HelloWorldPage(
          toggleThemeMode: _toggleThemeMode,
          themeMode: _themeMode,
          user: _loggedInUser,
        ),
      },
    );
  }
}

class LandingPage extends StatefulWidget {
  final VoidCallback toggleThemeMode;
  final ThemeMode themeMode;

  const LandingPage({super.key, required this.toggleThemeMode, required this.themeMode});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Farm Sensor App',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Card(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                            ),
                            const SizedBox(height: 16.0),
                            OutlinedButton(
                              onPressed: _login,
                              child: const Text('Login'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 32.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(widget.themeMode == ThemeMode.light
                  ? Icons.wb_sunny
                  : Icons.nights_stay),
              onPressed: widget.toggleThemeMode,
            ),
          ),
        ],
      ),
    );
  }
}


class HelloWorldPage extends StatelessWidget {
  final VoidCallback toggleThemeMode;
  final ThemeMode themeMode;
  final String user;

  const HelloWorldPage({super.key, required this.toggleThemeMode, required this.themeMode, required this.user});

  @override
  Widget build(BuildContext context) {
    print('HelloWorldPage user: $user'); // Debugging statement
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
          title: Text('Welcome $user'),
          actions: [
            IconButton(
              icon: Icon(themeMode == ThemeMode.light ? Icons.wb_sunny : Icons.nights_stay),
              onPressed: toggleThemeMode,
            ),
          ],
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
              pw.Text('Pressure: $pressure', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('Lux: $lux', style: pw.TextStyle(fontSize: 18)),
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
  void initState() {
    super.initState();
    mqttService.sensorStream.listen((data) {
      if (mounted) {
        setState(() {
          if (data['id'] == 1) {
            temperature = data['temperature'] ?? temperature;
            humidity = data['humidity'] ?? humidity;
            pressure = data['pressure'] ?? pressure;
          } else if (data['id'] == 2) {
            lux = data['lux'] ?? lux;
          }
        });
      }
    });
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
                  leading: const Icon(Icons.compress),
                  title: const Text('Pressure'),
                  subtitle: Text('$pressure hPa'),
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Lux'),
                  subtitle: Text('$lux lx'),
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
                  ).then((result) {
                    if (result != null) {
                      temperature = result['temperature'];
                      humidity = result['humidity'];
                      pressure = result['pressure'];
                      lux = result['lux'];
                    }
                  });
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