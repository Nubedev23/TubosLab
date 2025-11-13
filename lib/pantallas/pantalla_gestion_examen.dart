import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';

class PantallaGestionExamen extends StatefulWidget {
  final String? examenId;

  const PantallaGestionExamen({this.examenId, Key? key}) : super(key: key);
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
  ];

  @override
  void initState() {
    super.initState();
    if (widget.examenId != null) {
      _cargarDatosExamen(widget.examenId!);
    } else {
      _isLoading = false;
    }
  }

  void _cargarDatosExamen(String id) async {
    try {
      final examen = await _firestoreService.getExamenById(id);
      _nombreController.text = examen.nombre;
      _descripcionController.text = examen.descripcion;
      _volumenController.text = examen.volumen_ml.toString();

      setState(() {
        _nombreTuboSeleccionado = examen.tubo;
        _anticoagulanteSeleccionado = examen.anticoagulante;
        _areaSeleccionada = examen.area;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _guardarExamen() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final examenAGuardar = Examen(
      id: widget.examenId ?? '',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      tubo: _nombreTuboSeleccionado!,
      anticoagulante: _anticoagulanteSeleccionado!,
      volumen_ml: double.parse(_volumenController.text.trim()),
      area: _areaSeleccionada,
    );

    try {
      await _firestoreService.saveExamen(examenAGuardar);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.examenId == null ? 'Crear nuevo examen' : 'Editar examen',
        ),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.padding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del examen',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción breve',
                ),
                maxLines: 2,
              ),

              const Divider(height: 30),
              const Text(
                'Requisitos de muestra',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Área / Sección'),
                value: _areaSeleccionada,
                items: _areas
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _areaSeleccionada = value);
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tubo (Color)'),
                value: _nombreTuboSeleccionado,
                items: _tubos
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _nombreTuboSeleccionado = value);
                },
                validator: (value) =>
                    value == null ? 'Seleccione el color del tubo.' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Anticoagulante'),
                value: _anticoagulanteSeleccionado,
                items: _anticoagulantes
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _anticoagulanteSeleccionado = value);
                },
                validator: (value) =>
                    value == null ? 'Seleccione el anticoagulante.' : null,
              ),
              TextFormField(
                controller: _volumenController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Volumen requerido (ml)',
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
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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
