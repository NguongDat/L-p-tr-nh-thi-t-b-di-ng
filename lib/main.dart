import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF4A44BC), useMaterial3: true),
        home: const MyLocationPage(),
      );
}

class MyLocationPage extends StatefulWidget {
  const MyLocationPage({super.key});
  @override
  State<MyLocationPage> createState() => _MyLocationPageState();
}

class _MyLocationPageState extends State<MyLocationPage> {
  final MapController _map = MapController();
  bool _mapReady = false;
  LatLng? _me;
  double? _accuracy;
  String _status = 'Đang lấy vị trí...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _getMyLocation();
    });
  }

  Future<void> _getMyLocation() async {
    if (!mounted) return;
    setState(() => _status = 'Đang lấy vị trí...');

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() => _status = 'GPS đang tắt. Hãy bật dịch vụ vị trí.');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _status = 'Bạn chưa cấp quyền vị trí.');
        return;
      }

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() {
        _me = here;
        _accuracy = p.accuracy;
        _status = 'Đã tìm thấy vị trí của bạn';
      });

      if (_mapReady) _map.move(here, 17);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Không thể truy cập vị trí trên môi trường hiện tại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vị trí của tôi'),
        backgroundColor: const Color(0xFF4A44BC),
        foregroundColor: Colors.white,
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: const LatLng(10.7769, 106.7009),
            initialZoom: 12,
            onMapReady: () {
              _mapReady = true;
              if (_me != null) _map.move(_me!, 17);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.geolocator_demo',
            ),
            if (_me != null)
              MarkerLayer(markers: [
                Marker(
                  point: _me!,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                ),
              ]),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_me != null) ...[
                  const SizedBox(height: 6),
                  Text('Vĩ độ: ${_me!.latitude.toStringAsFixed(6)}'),
                  Text('Kinh độ: ${_me!.longitude.toStringAsFixed(6)}'),
                  Text('Độ chính xác: ${_accuracy?.toStringAsFixed(0)} m'),
                ],
              ]),
            ),
          ),
        ),
      ]),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 130),
        child: FloatingActionButton(
          onPressed: _getMyLocation,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}