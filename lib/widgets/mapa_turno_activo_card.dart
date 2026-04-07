import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mapa compacto del turno activo: check-in del profesional y domicilio.
/// Colores de marcadores cercanos a Vitta (#1A3E6F / #2E7D32) vía hue del pin nativo.
class MapaTurnoActivoCard extends StatefulWidget {
  const MapaTurnoActivoCard({
    super.key,
    this.checkinGps,
    this.domicilioGps,
  });

  final GeoPoint? checkinGps;
  final GeoPoint? domicilioGps;

  @override
  State<MapaTurnoActivoCard> createState() => _MapaTurnoActivoCardState();
}

class _MapaTurnoActivoCardState extends State<MapaTurnoActivoCard> {
  static const double _hueAzulVitta = 225;
  static const double _hueVerdeVitta = 105;

  Future<void> _onMapCreated(GoogleMapController c) async {
    final check = widget.checkinGps;
    final dom = widget.domicilioGps;
    if (check != null && dom != null) {
      final cLat = check.latitude;
      final cLng = check.longitude;
      final dLat = dom.latitude;
      final dLng = dom.longitude;
      final sw = LatLng(
        math.min(cLat, dLat),
        math.min(cLng, dLng),
      );
      final ne = LatLng(
        math.max(cLat, dLat),
        math.max(cLng, dLng),
      );
      try {
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(southwest: sw, northeast: ne),
            56,
          ),
        );
      } catch (_) {
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(cLat, cLng), 15),
        );
      }
    } else if (check != null) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(check.latitude, check.longitude), 15),
      );
    } else if (dom != null) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(dom.latitude, dom.longitude), 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final check = widget.checkinGps;
    final dom = widget.domicilioGps;

    final markers = <Marker>{};
    LatLng center = const LatLng(-26.8241, -65.2226);

    if (dom != null) {
      final p = LatLng(dom.latitude, dom.longitude);
      center = p;
      markers.add(
        Marker(
          markerId: const MarkerId('domicilio'),
          position: p,
          icon: BitmapDescriptor.defaultMarkerWithHue(_hueVerdeVitta),
          infoWindow: const InfoWindow(title: 'Domicilio'),
        ),
      );
    }
    if (check != null) {
      final p = LatLng(check.latitude, check.longitude);
      if (dom == null) center = p;
      markers.add(
        Marker(
          markerId: const MarkerId('checkin'),
          position: p,
          icon: BitmapDescriptor.defaultMarkerWithHue(_hueAzulVitta),
          infoWindow: const InfoWindow(title: 'Check-in'),
        ),
      );
    }

    if (markers.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A3E6F), width: 1.5),
        ),
        child: Text(
          'Ubicación no disponible',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 14,
          ),
          markers: markers,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }
}
