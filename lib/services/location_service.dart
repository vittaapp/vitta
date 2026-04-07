// lib/services/location_service.dart

class LocationService {
  // Función para simular la validación de llegada
  // En el futuro usaremos el paquete 'geolocator' de Flutter
  Future<bool> validarLlegada(double latCasa, double lngCasa) async {
    print("Verificando ubicación del profesional...");
    await Future.delayed(const Duration(seconds: 2));

    // Aquí simulamos que el GPS dice que está a menos de 50 metros
    bool estaCerca = true;
    return estaCerca;
  }
}