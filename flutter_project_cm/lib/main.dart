import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_project_cm/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      User user = boxUsers.getAt(i)!;
      if (user.username == username && user.password == password) {
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.home),
                text: 'Home',
              ),
              Tab(
                icon: Icon(Icons.map),
                text: 'Map',
              ),
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.thermostat),
                  title: Text('Temperature'),
                  subtitle: Text('25°C'),
                ),
                ListTile(
                  leading: Icon(Icons.water_drop),
                  title: Text('Humidity'),
                  subtitle: Text('60%'),
                ),
                ListTile(
                  leading: Icon(Icons.science),
                  title: Text('pH'),
                  subtitle: Text('7.0'),
                ),
                ListTile(
                  leading: Icon(Icons.electrical_services),
                  title: Text('Dielectric'),
                  subtitle: Text('10.5'),
                ),
              ],
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
  final PopupController _popupController = PopupController();

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
      User user = boxUsers.getAt(i)!;
      if (user.username == loggedInUser) {
        markers.add(
          Marker(
            key: ValueKey('marker$i'),
            width: user.width,
            height: user.height,
            point: LatLng(user.latitude, user.longitude),
            child: Icon(
              Icons.location_on,
              size: 50.0,
              color: randomColor(),
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
        initialCenter: const LatLng(40.6405, -8.6538), // Coordinates for Aveiro
        initialZoom: 17.0,
        onTap: (_, __) => _popupController.hideAllPopups(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: _markers),
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            markers: _markers,
            popupController: _popupController,
            markerTapBehavior: MarkerTapBehavior.togglePopup(),
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
                String markerName = 'Marker ${_markers.indexOf(marker) + 1}';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(markerName),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}