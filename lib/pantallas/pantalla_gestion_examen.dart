import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';
import 'dart:developer';

class PantallaGestionExamen extends StatefulWidget {
  final String? examenId;

  const PantallaGestionExamen({this.examenId, super.key});
  static const routeName = '/gestion-examen';

  @override
  State<PantallaGestionExamen> createState() => _PantallaGestionExamenState();
}

class _PantallaGestionExamenState extends State<PantallaGestionExamen> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _volumenController = TextEditingController();

  String? _nombreTuboSeleccionado;
  String? _anticoagulanteSeleccionado;
  String? _areaSeleccionada;

  bool _isLoading = true;
  Examen? _examenActual;

  final List<String> _tubos = ['Lila', 'Celeste', 'Verde', 'Rojo'];
  final List<String> _anticoagulantes = [
    'EDTA K2',
    'Citrato de sodio 3.2%',
    'Heparina de sodio',
    'Heparina de litio',
    'Sin Aditivo',
  ];
  final List<String> _areas = [
    'Hematología',
    'Coagulación',
    'Química',
    'Inmunología',
    'Microbiología',
    'Hormonas',
    'Virología',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.examenId != null) {
      _cargarExamenExistente();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _cargarExamenExistente() async {
    final examen = await _firestoreService.getExamen(widget.examenId!);
    if (examen != null) {
      _nombreController.text = examen.nombre;
      _descripcionController.text = examen.descripcion;
      _volumenController.text = examen.volumen_ml.toString();
      _nombreTuboSeleccionado = examen.tubo;
      _anticoagulanteSeleccionado = examen.anticoagulante;
      _areaSeleccionada = examen.area;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _guardarExamen() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newExamen = Examen(
        id: widget.examenId ?? '', // Si es null, es un nuevo examen
        nombre: _nombreController.text.trim(),
        nombre_normalizado: _firestoreService.normalizar(
          _nombreController.text.trim(),
        ),
        descripcion: _descripcionController.text.trim(),
        tubo: _nombreTuboSeleccionado!,
        anticoagulante: _anticoagulanteSeleccionado!,
        volumen_ml: double.parse(_volumenController.text),
        area: _areaSeleccionada,
      );

      try {
        await _firestoreService.saveExamen(newExamen);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.examenId == null
                  ? 'Examen guardado exitosamente.'
                  : 'Examen actualizado exitosamente.',
            ),
            backgroundColor: AppStyles.primaryDark,
          ),
        );
        if (mounted) {
          // Regresar a la pantalla anterior (o principal)
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar el examen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget para construir los campos de Dropdown
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      value: value,
      hint: Text('Selecciona el $label'),
      isExpanded: true,
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Debe seleccionar una opción.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el ID pasado como argumento si existe
    final passedExamenId =
        ModalRoute.of(context)?.settings.arguments as String?;
    // Si el widget se creó sin ID, pero se pasó por argumento, usar el argumento
    if (widget.examenId == null && passedExamenId != null) {
      // Nota: En una app real, esto podría requerir un manejo más complejo si el
      // initState ya corrió sin el ID. Aquí asumimos que el widget se usa correctamente
      // como ruta.
    }

    final String title = widget.examenId == null
        ? 'Crear Nuevo Examen'
        : 'Editar Examen ID: ${widget.examenId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppStyles.padding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // --- Campo: Nombre del Examen ---
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Examen',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? 'El nombre no puede estar vacío.'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // --- Campo: Descripción ---
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Instrucciones',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? 'La descripción no puede estar vacía.'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // --- Campo: Área de Laboratorio (Dropdown) ---
                    _buildDropdownField(
                      label: 'Área del Laboratorio',
                      items: _areas,
                      value: _areaSeleccionada,
                      onChanged: (String? newValue) {
                        setState(() {
                          _areaSeleccionada = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- Campo: Tubo (Dropdown) ---
                    _buildDropdownField(
                      label: 'Tubo Requerido',
                      items: _tubos,
                      value: _nombreTuboSeleccionado,
                      onChanged: (String? newValue) {
                        setState(() {
                          _nombreTuboSeleccionado = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- Campo: Anticoagulante (Dropdown) ---
                    _buildDropdownField(
                      label: 'Anticoagulante',
                      items: _anticoagulantes,
                      value: _anticoagulanteSeleccionado,
                      onChanged: (String? newValue) {
                        setState(() {
                          _anticoagulanteSeleccionado = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- Campo: Volumen (Numérico) ---
                    TextFormField(
                      controller: _volumenController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Volumen Mínimo (ml)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Ingrese un volumen.';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingrese un número válido.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // --- Botón de Guardar/Actualizar ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarExamen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                widget.examenId == null
                                    ? 'Guardar Nuevo Examen'
                                    : 'Actualizar Examen',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _volumenController.dispose();
    super.dispose();
  }
}
