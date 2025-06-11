// lib/models/vehiculo.dart
class Vehiculo {
  final String id;
  final String placa;
  final String tipoVehiculo; // Ej: Furgón, Camioneta, Coche

  Vehiculo({required this.id, required this.placa, required this.tipoVehiculo});
}