import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

void main() {
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

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('LandingPage'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/hello');
              },
              child: const Text('Enter'),
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

  final List<Marker> _markers = [
    const Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(40.6405, -8.6538),
      child: Icon(
        Icons.location_pin,
        color: Colors.red,
        size: 40.0,
      ),
      key: ValueKey('marker1'),
    ),
    const Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(40.6415, -8.6548),
      child: Icon(
        Icons.location_pin,
        color: Colors.blue,
        size: 40.0,
      ),
      key: ValueKey('marker2'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(40.6405, -8.6538), // Coordinates for Aveiro
        initialZoom: 13.0,
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
                String markerName;
                if (marker.key == const ValueKey('marker1')) {
                  markerName = 'Marker 1';
                } else if (marker.key == const ValueKey('marker2')) {
                  markerName = 'Marker 2';
                } else {
                  markerName = 'Unknown Marker';
                }
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