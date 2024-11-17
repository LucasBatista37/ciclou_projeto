import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RequestorMapScreen extends StatefulWidget {
  const RequestorMapScreen({super.key});

  @override
  _RequestorMapScreenState createState() => _RequestorMapScreenState();
}

class _RequestorMapScreenState extends State<RequestorMapScreen> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(-24.0924, -46.6213);
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadCollectionPointMarker();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _loadCollectionPointMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('collectionPoint'),
          position: const LatLng(-24.0924, -46.6213),
          infoWindow: const InfoWindow(
            title: 'Ponto de Coleta',
            snippet: 'Rua Exemplo, 123',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Local da Coleta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 15,
        ),
        markers: Set<Marker>.of(_markers),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _verColetoresDisponiveis,
        child: const Icon(Icons.person_search, color: Colors.white),
      ),
    );
  }

  void _verColetoresDisponiveis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exibindo coletores disponíveis...')),
    );
  }
}
