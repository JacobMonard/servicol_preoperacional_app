// lib/screens/preoperacional_list_screen.dart
import 'package:flutter/material.dart';
import 'package:servicolpreoperacionalapp/models/conductor.dart';
import 'package:servicolpreoperacionalapp/models/vehiculo.dart';
import 'package:servicolpreoperacionalapp/utils/app_data.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // ¡ELIMINADA!
// Si en el futuro quieres historial LOCAL, necesitarías importar una librería de persistencia aquí (ej. sqflite, hive)


class PreoperacionalListScreen extends StatefulWidget {
  final String conductorId;
  final String vehiculoId;

  const PreoperacionalListScreen({
    super.key,
    required this.conductorId,
    required this.vehiculoId,
  });

  @override
  State<PreoperacionalListScreen> createState() => _PreoperacionalListScreenState();
}

class _PreoperacionalListScreenState extends State<PreoperacionalListScreen> {
  // No hay necesidad de StreamController ni suscripciones a Firestore aquí.

  @override
  Widget build(BuildContext context) {
    // Obtener información del conductor y vehículo para el título
    final conductor = AppData.conductores.firstWhere((c) => c.id == widget.conductorId);
    final vehiculo = AppData.vehiculos.firstWhere((v) => v.id == widget.vehiculoId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Preoperacionales'), // Título más general
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                Text('Conductor: ${conductor.nombreCompleto}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text('Vehículo: ${vehiculo.placa}', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'El historial de preoperacionales en la nube ha sido deshabilitado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Los preoperacionales se generan como PDF y se comparten localmente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            // El botón de "Generar Reporte Mensual PDF" que existía antes
            // ha sido eliminado ya que no tiene datos de historial de la nube.
            // Si se desea un historial local, se deberá implementar persistencia local.
          ],
        ),
      ),
    );
  }
}