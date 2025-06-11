// lib/models/item_revision.dart
class ItemRevision {
  final String id;
  final String categoria; // Ej: Iluminación, Frenos, Neumáticos
  final String concepto;  // Ej: Luces Altas, Freno de Servicio, Presión del Aire

  ItemRevision({required this.id, required this.categoria, required this.concepto});
}