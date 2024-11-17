import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CollectorMapScreen extends StatefulWidget {
  const CollectorMapScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CollectorMapScreenState createState() => _CollectorMapScreenState();
}

class _CollectorMapScreenState extends State<CollectorMapScreen> {
  final LatLng _initialPosition = const LatLng(-24.0924, -46.6213);
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadSolicitationMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
  }

  void _loadSolicitationMarkers() {
    setState(() {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('restauranteX'),
          position: const LatLng(-24.0914, -46.6223),
          infoWindow: const InfoWindow(
            title: 'Restaurante X',
            snippet: '10 Litros - Aguardando Propostas',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('condominioY'),
          position: const LatLng(-24.0930, -46.6200),
          infoWindow: const InfoWindow(
            title: 'Condomínio Y',
            snippet: '5 Litros - Proposta Aceita',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Solicitações Próximas',
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
        onPressed: _calcularRota,
        child: const Icon(Icons.directions, color: Colors.white),
      ),
    );
  }

  void _calcularRota() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cálculo de rota em desenvolvimento')),
    );
  }
}
