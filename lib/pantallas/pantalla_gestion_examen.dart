import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';

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

  final List<String> _tubos = ['Lila', 'Celeste', 'Verde', 'Rojo'];
  final List<String> _anticoagulantes = [
    'EDTA K2',
    'Citrato de sodio 3.2%',
    'Heparina',
    'Sin Aditivo',
  ];
  final List<String> _areas = [
    'Hematología',
    'Coagulación',
    'Química',
    'Inmunología',
    'Microbiología',
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
        // Regresar a la pantalla anterior (o principal)
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el examen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examenId == null ? 'Nuevo Examen' : 'Editar Examen'),
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
                  children: [
                    // Campo Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Examen',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Ingrese el nombre del examen.'
                          : null,
                    ),

                    // Campo Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Método',
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese la descripción.' : null,
                    ),

                    const SizedBox(height: 20),

                    // Dropdown Tubo Requerido
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tubo Requerido',
                      ),
                      initialValue: _nombreTuboSeleccionado,
                      items: _tubos
                          .map(
                            (tubo) => DropdownMenuItem(
                              value: tubo,
                              child: Text(tubo),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _nombreTuboSeleccionado = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleccione un tubo.' : null,
                    ),

                    // Dropdown Anticoagulante
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Anticoagulante',
                      ),
                      initialValue: _anticoagulanteSeleccionado,
                      items: _anticoagulantes
                          .map(
                            (anticoagulante) => DropdownMenuItem(
                              value: anticoagulante,
                              child: Text(anticoagulante),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _anticoagulanteSeleccionado = value;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Seleccione un anticoagulante.'
                          : null,
                    ),

                    // Dropdown Área
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Área del Laboratorio',
                      ),
                      initialValue: _areaSeleccionada,
                      items: _areas
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _areaSeleccionada = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleccione un área.' : null,
                    ),

                    // Campo Volumen
                    TextFormField(
                      controller: _volumenController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Volumen mínimo (ml)',
                      ),
                      validator: (value) =>
                          value!.isEmpty || double.tryParse(value) == null
                          ? 'Ingrese un volumen válido.'
                          : null,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarExamen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          widget.examenId == null
                              ? 'Guardar Nuevo Examen'
                              : 'Actualizar Examen',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
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
