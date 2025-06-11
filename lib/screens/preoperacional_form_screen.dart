// lib/screens/preoperacional_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for rootBundle
import 'package:servicolpreoperacionalapp/models/conductor.dart';
import 'package:servicolpreoperacionalapp/models/vehiculo.dart';
import 'package:servicolpreoperacionalapp/models/item_revision.dart';
import 'package:servicolpreoperacionalapp/models/preoperacional.dart';
import 'package:servicolpreoperacionalapp/utils/app_data.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart'; // Import PdfColors
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;


class PreoperacionalFormScreen extends StatefulWidget {
  final Conductor conductor;
  final Vehiculo vehiculo;

  const PreoperacionalFormScreen({
    super.key,
    required this.conductor,
    required this.vehiculo,
  });

  @override
  State<PreoperacionalFormScreen> createState() => _PreoperacionalFormScreenState();
}

class _PreoperacionalFormScreenState extends State<PreoperacionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  double _odometro = 0.0;
  final TextEditingController _odometroController = TextEditingController();
  final TextEditingController _observacionesGeneralesController = TextEditingController();

  Map<String, DetalleItemPreoperacional> _itemsState = {};
  Map<String, XFile?> _tempPhotoFiles = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeItemsState();
  }

  void _initializeItemsState() {
    for (var item in AppData.itemsRevision) {
      _itemsState[item.id] = DetalleItemPreoperacional(itemId: item.id);
    }
  }

  @override
  void dispose() {
    _odometroController.dispose();
    _observacionesGeneralesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  // --- Funciones de Manejo de Fotos ---
  Future<void> _takePhoto(String itemId) async {
    try {
      final result = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto con cámara'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de galería'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (result != null) {
        final XFile? image = await _picker.pickImage(source: result);
        if (image != null) {
          setState(() {
            _tempPhotoFiles[itemId] = image;

            if (kIsWeb) {
              image.readAsBytes().then((imageBytes) {
                setState(() {
                  _itemsState[itemId]!.fotoUrl = html.Url.createObjectUrlFromBlob(html.Blob([imageBytes]));
                });
              });
            } else {
              _itemsState[itemId]!.fotoUrl = image.path;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto seleccionada/tomada.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al tomar/seleccionar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al manejar la imagen: ${e.toString()}')),
      );
    }
  }


  // --- Funciones de Guardado y Generación de PDF ---
  Future<void> _savePreoperacional() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_odometro <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el odómetro.')),
      );
      return;
    }
    if (_signatureController.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, firma para completar el preoperacional.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Uint8List? firmaImageBytesForPdf;

      if (!_signatureController.isEmpty) {
        firmaImageBytesForPdf = await _signatureController.toPngBytes();
        if (firmaImageBytesForPdf == null) {
          throw Exception('No se pudo generar la imagen de la firma.');
        }
      }

      final preoperacional = Preoperacional(
        id: const Uuid().v4(),
        fechaHora: DateTime.now(),
        conductorId: widget.conductor.id,
        vehiculoId: widget.vehiculo.id,
        odometro: _odometro,
        observacionesGenerales: _observacionesGeneralesController.text,
        firmaDigitalUrl: null, // Not used directly here for PDF, image is passed by bytes
        detalles: _itemsState.values.toList(),
      );

      // --- DEBUG PRINTS START ---
      debugPrint('--- Datos Preoperacional Antes de PDF ---');
      debugPrint('Fecha Hora: ${preoperacional.fechaHora}');
      debugPrint('Conductor ID: ${preoperacional.conductorId}');
      debugPrint('Vehiculo ID: ${preoperacional.vehiculoId}');
      debugPrint('Odometro: ${preoperacional.odometro}');
      debugPrint('Observaciones Generales: ${preoperacional.observacionesGenerales?.trim().isNotEmpty == true ? preoperacional.observacionesGenerales! : 'Ninguna'}');
      debugPrint('Total de Detalles de Items: ${preoperacional.detalles.length}');
      for (var detalle in preoperacional.detalles) {
        final itemNombre = AppData.itemsRevision.firstWhere((i) => i.id == detalle.itemId).concepto;
        debugPrint('  - Item: $itemNombre (ID: ${detalle.itemId}), Estado: ${detalle.estado}, Obs: ${detalle.observaciones ?? 'N/A'}, Foto URL: ${detalle.fotoUrl ?? 'N/A'}');
      }
      debugPrint('Número de fotos temporales (${_tempPhotoFiles.length}):');
      _tempPhotoFiles.forEach((key, value) {
        debugPrint('  - Item ID: $key, Path: ${value?.path ?? 'N/A'}');
      });
      debugPrint('Firma Bytes para PDF es nula? ${firmaImageBytesForPdf == null}');
      debugPrint('--- Fin Datos Preoperacional Antes de PDF ---');
      // --- DEBUG PRINTS END ---


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preoperacional listo para generar PDF.')),
      );

      await _generateAndSharePdf(preoperacional, firmaImageBytesForPdf, _tempPhotoFiles);

      _odometroController.clear();
      _observacionesGeneralesController.clear();
      _signatureController.clear();
      setState(() {
        _tempPhotoFiles.clear();
        _initializeItemsState();
      });

    } catch (e) {
      debugPrint('Error al procesar preoperacional: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar preoperacional: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // --- Función para cargar imágenes (firma y novedades) para el PDF ---
  Future<void> _generateAndSharePdf(
    Preoperacional preoperacional,
    Uint8List? firmaImageBytes,
    Map<String, XFile?> tempPhotoFiles,
  ) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      // --- Load Roboto Font ---
      // Make sure Roboto-Regular.ttf and Roboto-Bold.ttf files are in assets/fonts/
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      final ttfBold = pw.Font.ttf(fontBoldData);
      // --- End Font Loading ---

      pw.MemoryImage? loadedSignature;
      if (firmaImageBytes != null) {
        loadedSignature = pw.MemoryImage(firmaImageBytes);
      }

      // --- SECCIÓN PARA CARGAR LAS IMÁGENES DE NOVEDADES (DESCOMENTADA) ---
      final Map<String, pw.MemoryImage> loadedImagesForPdf = {};
      await Future.wait(tempPhotoFiles.entries.map((entry) async {
        if (entry.value != null) {
          try {
            final imageBytes = await entry.value!.readAsBytes();
            loadedImagesForPdf[entry.key] = pw.MemoryImage(imageBytes);
            debugPrint('DEBUG: Image for item ${entry.key} loaded successfully for PDF.');
          } catch (e) {
            debugPrint('ERROR: Error loading image bytes for PDF for itemId ${entry.key}: $e');
          }
        } else {
           debugPrint('DEBUG: No XFile found for itemId ${entry.key} in tempPhotoFiles.');
        }
      }));
      // --- FIN DE LA SECCIÓN DESCOMENTADA ---


      pdf.addPage(
        pw.MultiPage( // Mantenemos MultiPage para manejar múltiples páginas
          pageFormat: PdfPageFormat.letter.copyWith(
            // --- CORREGIDO: USO DE PROPIEDADES DIRECTAS DE MARGEN CON copyWith ---
            marginLeft: PdfPageFormat.mm * 10,
            marginTop: PdfPageFormat.mm * 10,
            marginRight: PdfPageFormat.mm * 10,
            marginBottom: PdfPageFormat.mm * 10,
            // --- FIN DE CORRECCIÓN ---
          ),
          build: (pw.Context context) {
            return [ // Los widgets de nivel superior dentro de MultiPage deben ser una lista.
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'REVISIÓN DIARIA PREOPERACIONAL - SERVICOL',
                      style: pw.TextStyle(fontSize: 18, font: ttfBold),
                    ),
                  ),
                  pw.SizedBox(height: 10), // Espaciado fijo
                  pw.Text('Fecha: ${dateFormat.format(preoperacional.fechaHora)}', style: pw.TextStyle(font: ttf)),
                  pw.Text('Conductor: ${AppData.conductores.firstWhere((c) => c.id == preoperacional.conductorId).nombreCompleto}', style: pw.TextStyle(font: ttf)),
                  pw.Text('Placa: ${AppData.vehiculos.firstWhere((v) => v.id == preoperacional.vehiculoId).placa}', style: pw.TextStyle(font: ttf)),
                  pw.Text('Odómetro: ${preoperacional.odometro} Km', style: pw.TextStyle(font: ttf)),
                  pw.SizedBox(height: 10), // Espaciado fijo
                  pw.Text('Ítems de Revisión:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold)),
                  pw.SizedBox(height: 5), // Espaciado fijo
                  // TABLA DE ITEMS DE REVISIÓN
                  _buildItemsTable(preoperacional, ttf, ttfBold),
                  pw.SizedBox(height: 10), // Espaciado fijo
                  pw.Text(
                      'Observaciones Generales: ${preoperacional.observacionesGenerales?.trim().isNotEmpty == true ? preoperacional.observacionesGenerales! : 'Ninguna'}',
                      style: pw.TextStyle(font: ttf)
                  ),
                  pw.SizedBox(height: 10), // Espaciado fijo
                  pw.Text('Firma del Conductor:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold)),
                  pw.SizedBox(height: 5), // Espaciado fijo
                  loadedSignature != null
                      ? pw.Container(
                          alignment: pw.Alignment.centerLeft, // Alinea a la izquierda si lo deseas
                          child: pw.Image(loadedSignature, height: 60), // Altura un poco más pequeña
                        )
                      : pw.Text('Firma no disponible.', style: pw.TextStyle(font: ttf)),
                  pw.SizedBox(height: 10), // Espaciado fijo

                  // SECCIÓN DE FOTOS DE NOVEDADES
                  pw.NewPage(), // <-- AÑADIDO: Fuerza un salto de página aquí
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Fotos de Novedades:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold)),
                      pw.SizedBox(height: 5), // Espaciado fijo
                      ..._buildPhotoNovedadesWidgets(preoperacional, loadedImagesForPdf, ttf),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final String conductorName = AppData.conductores.firstWhere((c) => c.id == preoperacional.conductorId).nombreCompleto;
      final String fileName = 'Preoperacional_${preoperacional.vehiculoId}_${conductorName}_${DateFormat('yyyyMMdd_HHmm').format(preoperacional.fechaHora)}.pdf';

      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generado y listo para descargar en el navegador.')),
        );
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/$fileName');
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generado: ${file.path}')),
        );

        OpenFilex.open(file.path);
        await Share.shareXFiles([XFile(file.path)], text: 'Preoperacional Diario - ${preoperacional.vehiculoId}');
      }
    } catch (e) {
      debugPrint('Error al generar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: ${e.toString()}')),
      );
    }
  }

  // --- _buildItemsTable con datos dinámicos ---
  pw.Widget _buildItemsTable(Preoperacional preoperacional, pw.Font normalFont, pw.Font boldFont) {
    debugPrint('DEBUG: Intentando construir la tabla de ítems con datos DINÁMICOS...');
    try {
      return pw.Table.fromTextArray(
        headers: ['Categoría', 'Concepto', 'Estado', 'Observaciones'],
        data: preoperacional.detalles.map((detalle) {
          final item = AppData.itemsRevision.firstWhere((i) => i.id == detalle.itemId);
          final String estadoTexto = detalle.estado == EstadoItem.ok ? 'OK' : 'NOK';
          final String observacionesTexto = detalle.observaciones != null && detalle.observaciones!.trim().isNotEmpty
              ? detalle.observaciones!
              : (detalle.estado == EstadoItem.nok ? 'Sin observación registrada' : 'N/A');
          
          debugPrint('  - Fila de tabla para: ${item.concepto}, Estado: $estadoTexto, Obs: $observacionesTexto');
          return [
            item.categoria,
            item.concepto,
            estadoTexto,
            observacionesTexto,
          ];
        }).toList(),
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont, fontSize: 9), // <-- CAMBIADO AQUÍ
        cellStyle: pw.TextStyle(font: normalFont, fontSize: 8), // <-- CAMBIADO AQUÍ
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        // --- AÑADIDO: ANCHOS DE COLUMNA PARA LA TABLA ---
        columnWidths: {
          0: const pw.FlexColumnWidth(2), // Categoría
          1: const pw.FlexColumnWidth(3), // Concepto
          2: const pw.FlexColumnWidth(1), // Estado
          3: const pw.FlexColumnWidth(3), // Observaciones
        },
        // --- FIN DE AÑADIDO ---
      );
    } catch (e) {
      debugPrint('ERROR: Fallo al construir la tabla de ítems con datos DINÁMICOS: $e');
      return pw.Text(
        'Error al cargar la tabla de ítems con datos dinámicos: $e',
        style: pw.TextStyle(font: normalFont, color: PdfColors.red),
      );
    }
  }


  // --- _buildPhotoNovedadesWidgets con carga de imágenes ---
  List<pw.Widget> _buildPhotoNovedadesWidgets(
    Preoperacional preoperacional,
    Map<String, pw.MemoryImage> loadedImagesForPdf,
    pw.Font normalFont,
  ) {
    final List<pw.Widget> photoWidgets = [];

    // Filter details that are NOK (Novedad) and have an attached photo or attempted to attach.
    for (var detalle in preoperacional.detalles.where((d) => d.estado == EstadoItem.nok)) {
      final item = AppData.itemsRevision.firstWhere((element) => element.id == detalle.itemId);
      final loadedImage = loadedImagesForPdf[detalle.itemId]; // This is the image loaded in memory for the PDF

      // Add text for the novelty
      photoWidgets.add(
        pw.Text(
          'Novedad en: ${item.concepto} - Observación: ${detalle.observaciones != null && detalle.observaciones!.isNotEmpty ? detalle.observaciones! : 'Sin observación'}',
          style: pw.TextStyle(font: normalFont),
        ),
      );

      // If the image was successfully loaded (is in loadedImagesForPdf), display it.
      if (loadedImage != null) {
        photoWidgets.add(
          pw.Image(
            loadedImage,
            height: 100, // CAMBIADO DE 150 A 100
            fit: pw.BoxFit.contain, // MUY IMPORTANTE: ajusta la imagen para que quepa en el espacio, manteniendo relación de aspecto
          ),
        );
        debugPrint('DEBUG: Photo added to PDF for item: ${item.concepto}');
      } else {
        // If no image loaded, indicate it.
        photoWidgets.add(pw.Text('No hay imagen adjunta para ${item.concepto} o no pudo cargarse.', style: pw.TextStyle(font: normalFont)));
        debugPrint('DEBUG: No photo or failed to load for item: ${item.concepto}');
      }
      photoWidgets.add(pw.SizedBox(height: 10)); // Spacing between photos
    }
    return photoWidgets;
  }


  Widget _buildRevisionItem(ItemRevision item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.concepto,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<EstadoItem>(
                    title: const Text('OK'),
                    value: EstadoItem.ok,
                    groupValue: _itemsState[item.id]!.estado,
                    onChanged: (EstadoItem? value) {
                      setState(() {
                        _itemsState[item.id]!.estado = value!;
                        _itemsState[item.id]!.observaciones = null;
                        _itemsState[item.id]!.fotoUrl = null;
                        _tempPhotoFiles.remove(item.id); // Remove temporary photo
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<EstadoItem>(
                    title: const Text('NOK'),
                    value: EstadoItem.nok,
                    groupValue: _itemsState[item.id]!.estado,
                    onChanged: (EstadoItem? value) {
                      setState(() {
                        _itemsState[item.id]!.estado = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_itemsState[item.id]!.estado == EstadoItem.nok)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Observaciones de la novedad',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      _itemsState[item.id]!.observaciones = value;
                    },
                    initialValue: _itemsState[item.id]!.observaciones,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _takePhoto(item.id),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_itemsState[item.id]!.fotoUrl == null ? 'Adjuntar Foto' : 'Foto Adjunta'),
                  ),
                  if (_itemsState[item.id]!.fotoUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: kIsWeb
                          ? Image.network(
                              _itemsState[item.id]!.fotoUrl!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                            )
                          : Image.file(
                              File(_itemsState[item.id]!.fotoUrl!),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                            ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<ItemRevision>> groupedItems = {};
    for (var item in AppData.itemsRevision) {
      groupedItems.putIfAbsent(item.categoria, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Preoperacional - ${widget.vehiculo.placa}'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Conductor: ${widget.conductor.nombreCompleto}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Vehículo: ${widget.vehiculo.placa} (${widget.vehiculo.tipoVehiculo})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _odometroController,
                    decoration: const InputDecoration(
                      labelText: 'Odómetro (Km)',
                      border: OutlineInputBorder(),
                      suffixText: 'Km',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa el odómetro.';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Ingresa un valor numérico válido para el odómetro.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _odometro = double.parse(value!);
                    },
                  ),
                  const SizedBox(height: 30),
                  ...groupedItems.keys.map((categoria) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 30, thickness: 2),
                        Text(
                          categoria,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        ...groupedItems[categoria]!.map((item) => _buildRevisionItem(item)).toList(),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _observacionesGeneralesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones Generales',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Firma del Conductor:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Signature(
                      controller: _signatureController,
                      height: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      _signatureController.clear();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Borrar Firma'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePreoperacional,
                    icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Generando PDF...' : 'Generar Preoperacional y Compartir PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}