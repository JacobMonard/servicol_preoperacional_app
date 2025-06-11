// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:servicolpreoperacionalapp/models/conductor.dart';
import 'package:servicolpreoperacionalapp/models/vehiculo.dart';
import 'package:servicolpreoperacionalapp/utils/app_data.dart';
import 'package:servicolpreoperacionalapp/screens/preoperacional_form_screen.dart';
import 'package:servicolpreoperacionalapp/screens/preoperacional_list_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Conductor? _selectedConductor;
  Vehiculo? _selectedVehiculo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Preoperacional Servicol'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de Conductor
            DropdownButtonFormField<Conductor>(
              decoration: const InputDecoration(
                labelText: 'Selecciona un Conductor',
                border: OutlineInputBorder(),
              ),
              value: _selectedConductor,
              items: AppData.conductores.map((conductor) {
                return DropdownMenuItem<Conductor>(
                  value: conductor,
                  child: Text(conductor.nombreCompleto),
                );
              }).toList(),
              onChanged: (Conductor? newValue) {
                setState(() {
                  _selectedConductor = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, selecciona un conductor.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Selector de Vehículo
            DropdownButtonFormField<Vehiculo>(
              decoration: const InputDecoration(
                labelText: 'Selecciona un Vehículo',
                border: OutlineInputBorder(),
              ),
              value: _selectedVehiculo,
              items: AppData.vehiculos.map((vehiculo) {
                return DropdownMenuItem<Vehiculo>(
                  value: vehiculo,
                  child: Text('${vehiculo.placa} (${vehiculo.tipoVehiculo})'),
                );
              }).toList(),
              onChanged: (Vehiculo? newValue) {
                setState(() {
                  _selectedVehiculo = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, selecciona un vehículo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Botón para iniciar el Formulario Preoperacional
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedConductor != null && _selectedVehiculo != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreoperacionalFormScreen(
                        conductor: _selectedConductor!,
                        vehiculo: _selectedVehiculo!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, selecciona conductor y vehículo.')),
                  );
                }
              },
              icon: const Icon(Icons.note_add),
              label: const Text('Iniciar Preoperacional Diario'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Botón para ver la lista de Preoperacionales (historial)
            ElevatedButton.icon(
              onPressed: () {
                 if (_selectedConductor != null && _selectedVehiculo != null) {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => PreoperacionalListScreen(
                         conductorId: _selectedConductor!.id,
                         vehiculoId: _selectedVehiculo!.id,
                       ),
                     ),
                   );
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Por favor, selecciona conductor y vehículo para ver el historial.')),
                   );
                 }
              },
              icon: const Icon(Icons.history),
              label: const Text('Ver Historial de Preoperacionales'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.teal, // Otro color para diferenciar
              ),
            ),
          ],
        ),
      ),
    );
  }
}