// lib/models/preoperacional.dart
import 'package:uuid/uuid.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // ¡ELIMINADA!

class Preoperacional {
  final String id;
  final DateTime fechaHora;
  final String conductorId;
  final String vehiculoId;
  final double odometro;
  final String? observacionesGenerales;
  final String? firmaDigitalUrl; // Ahora puede ser un path local temporal o null
  final List<DetalleItemPreoperacional> detalles;

  Preoperacional({
    required this.id,
    required this.fechaHora,
    required this.conductorId,
    required this.vehiculoId,
    required this.odometro,
    this.observacionesGenerales,
    this.firmaDigitalUrl,
    required this.detalles,
  });

  factory Preoperacional.fromJson(Map<String, dynamic> json) {
    var detallesList = json['detalles'] as List;
    List<DetalleItemPreoperacional> detalles = detallesList.map((i) => DetalleItemPreoperacional.fromJson(i)).toList();

    return Preoperacional(
      id: json['id'],
      fechaHora: DateTime.parse(json['fechaHora']), // De Timestamp a DateTime.parse de String
      conductorId: json['conductorId'],
      vehiculoId: json['vehiculoId'],
      odometro: (json['odometro'] as num).toDouble(), // Asegura que sea double
      observacionesGenerales: json['observacionesGenerales'],
      firmaDigitalUrl: json['firmaDigitalUrl'],
      detalles: detalles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fechaHora': fechaHora.toIso8601String(), // De Timestamp a String ISO 8601
      'conductorId': conductorId,
      'vehiculoId': vehiculoId,
      'odometro': odometro,
      'observacionesGenerales': observacionesGenerales,
      'firmaDigitalUrl': firmaDigitalUrl,
      'detalles': detalles.map((d) => d.toJson()).toList(), // Mapea cada detalle a su JSON
    };
  }
}

enum EstadoItem { ok, nok }

class DetalleItemPreoperacional {
  final String itemId;
  EstadoItem estado;
  String? observaciones;
  String? fotoUrl; // Ahora puede ser un path local temporal (o URL de blob para web)

  DetalleItemPreoperacional({
    required this.itemId,
    this.estado = EstadoItem.ok,
    this.observaciones,
    this.fotoUrl,
  });

  factory DetalleItemPreoperacional.fromJson(Map<String, dynamic> json) {
    return DetalleItemPreoperacional(
      itemId: json['itemId'],
      estado: EstadoItem.values.firstWhere((e) => e.toString().split('.').last == json['estado']),
      observaciones: json['observaciones'],
      fotoUrl: json['fotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'estado': estado.toString().split('.').last, // Guarda 'ok' o 'nok'
      'observaciones': observaciones,
      'fotoUrl': fotoUrl,
    };
  }
}