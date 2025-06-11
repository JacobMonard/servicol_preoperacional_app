// lib/utils/app_data.dart
import 'package:servicolpreoperacionalapp/models/conductor.dart';
import 'package:servicolpreoperacionalapp/models/vehiculo.dart';
import 'package:servicolpreoperacionalapp/models/item_revision.dart';

// Esta clase contendrá datos estáticos de la aplicación, como conductores y vehículos
class AppData {
  // Lista de Conductores
  static final List<Conductor> conductores = [
    Conductor(id: 'c1', nombreCompleto: 'Juan Pérez', cedula: '123456789'),
    Conductor(id: 'c2', nombreCompleto: 'María Gómez', cedula: '987654321'),
    Conductor(id: 'c3', nombreCompleto: 'Carlos Ruiz', cedula: '456789123'),
  ];

  // Lista de Vehículos
  static final List<Vehiculo> vehiculos = [
    Vehiculo(id: 'v1', placa: 'ABC-123', tipoVehiculo: 'Furgón'),
    Vehiculo(id: 'v2', placa: 'DEF-456', tipoVehiculo: 'Camioneta'),
    Vehiculo(id: 'v3', placa: 'GHI-789', tipoVehiculo: 'Coche'),
  ];

  // Lista de Ítems de Revisión (basados en tu PDF)
  static final List<ItemRevision> itemsRevision = [
    // Iluminación
    ItemRevision(id: 'ir001', categoria: 'Iluminación', concepto: 'Exteriores (Altas y bajas)'),
    ItemRevision(id: 'ir002', categoria: 'Iluminación', concepto: 'Direccionales delanteras'),
    ItemRevision(id: 'ir003', categoria: 'Iluminación', concepto: 'Direccionales traseras'),
    ItemRevision(id: 'ir004', categoria: 'Iluminación', concepto: 'Luces de estacionamiento'),
    ItemRevision(id: 'ir005', categoria: 'Iluminación', concepto: 'Luces de Stop'),

    // Cabina y Visibilidad
    ItemRevision(id: 'ir006', categoria: 'Cabina y Visibilidad', concepto: 'Espejo central convexo'),
    ItemRevision(id: 'ir007', categoria: 'Cabina y Visibilidad', concepto: 'Espejos laterales'),
    ItemRevision(id: 'ir008', categoria: 'Cabina y Visibilidad', concepto: 'Cinturones de seguridad'),
    ItemRevision(id: 'ir009', categoria: 'Cabina y Visibilidad', concepto: 'Vidrio frontal/Limpiaparabrisas'),
    ItemRevision(id: 'ir010', categoria: 'Cabina y Visibilidad', concepto: 'Asientos y tapicería'),
    ItemRevision(id: 'ir011', categoria: 'Cabina y Visibilidad', concepto: 'Indicadores Tablero: (Km/H, Batería, temperatura)'),
    ItemRevision(id: 'ir012', categoria: 'Cabina y Visibilidad', concepto: 'Bocina y pito'),

    // Seguridad y Prevención
    ItemRevision(id: 'ir013', categoria: 'Seguridad y Prevención', concepto: 'Equipo de prevención y seguridad (botiquín, equipo de carretera)'),
    ItemRevision(id: 'ir014', categoria: 'Seguridad y Prevención', concepto: 'Kit ambiental'),
    ItemRevision(id: 'ir015', categoria: 'Seguridad y Prevención', concepto: 'Extintor de incendios'),

    // Frenos y Suspensión
    ItemRevision(id: 'ir016', categoria: 'Frenos y Suspensión', concepto: 'Freno de servicio'),
    ItemRevision(id: 'ir017', categoria: 'Frenos y Suspensión', concepto: 'Freno de emergencia'),
    ItemRevision(id: 'ir018', categoria: 'Frenos y Suspensión', concepto: 'Suspensión/Dirección'),

    // Llantas
    ItemRevision(id: 'ir019', categoria: 'Llantas', concepto: 'Estado general de las llantas'),
    ItemRevision(id: 'ir020', categoria: 'Llantas', concepto: 'Presión del aire'),
    ItemRevision(id: 'ir021', categoria: 'Llantas', concepto: 'Llanta de repuesto'),

    // Mecánico y Fluidos
    ItemRevision(id: 'ir022', categoria: 'Mecánico y Fluidos', concepto: 'Nivel agua, aceite, combustible y fluidos'),
    ItemRevision(id: 'ir023', categoria: 'Mecánico y Fluidos', concepto: 'Fugas del motor'),
    ItemRevision(id: 'ir024', categoria: 'Mecánico y Fluidos', concepto: 'Tensión de correas'),
    ItemRevision(id: 'ir025', categoria: 'Mecánico y Fluidos', concepto: 'Conexiones eléctricas'),
    ItemRevision(id: 'ir026', categoria: 'Mecánico y Fluidos', concepto: 'Caja de cambios/Transmisión'),
    ItemRevision(id: 'ir027', categoria: 'Mecánico y Fluidos', concepto: 'Batería, Bornes, cables, niveles de electrolito y sulfatación'),
    ItemRevision(id: 'ir028', categoria: 'Mecánico y Fluidos', concepto: 'Estribos'),

    // Documentación
    ItemRevision(id: 'ir029', categoria: 'Documentación', concepto: 'VEHICULO (Licencia de tránsito, SOAT, Seguro Responsabilidad civil contractual y extracontractual, Tarjeta de Operación, Revisión Técnico Mecánica)')
  ];
}