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
  final _condicionController = TextEditingController();
  final _muestraController = TextEditingController();
  final _recipienteController = TextEditingController();
  final _conservacionController = TextEditingController();
  final _plazoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _horarioController = TextEditingController();

  String? _areaSeleccionada;
  String? _seccionSeleccionada;
  bool _esDeriivado = false;
  bool _disponibleUrgencia = false;
  bool _isLoading = true;

  static const String _horarioRutina =
      'Lunes a jueves 8:00–17:00, viernes 8:00–16:00';
  static const String _horarioUrgencia = '24 horas, 7 días';

  static const List<String> _areasInternas = [
    'Química Clínica', 'Hematología', 'Microbiología', 'Hormonas',
    'Virología', 'Inmunología', 'Líquidos Biológicos', 'Parasitología',
    'Tuberculosis', 'Andrología', 'Biología Molecular', 'Urgencia',
  ];

  static const List<String> _seccionesDerivadas = [
    'Laboratorio Barnafi-Krause', 'UC Christus', 'INTA', 'ISP',
    'Genometrics', 'Hosp. Calvo Mackenna', 'Hosp. El Salvador',
    'Hosp. Lucio Córdova', 'Derivado sin convenio',
  ];

  @override
  void initState() {
    super.initState();
    _horarioController.text = _horarioRutina;
    if (widget.examenId != null) {
      _cargarExamenExistente();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _cargarExamenExistente() async {
    final examen = await _firestoreService.getExamen(widget.examenId!);
    if (examen != null && mounted) {
      _nombreController.text = examen.nombre;
      _condicionController.text = examen.condicion_paciente;
      _muestraController.text = examen.muestra;
      _recipienteController.text = examen.recipiente;
      _conservacionController.text = examen.conservacion_transporte;
      _plazoController.text = examen.plazo_entrega;
      _observacionesController.text = examen.observaciones;
      _horarioController.text = examen.horario_disponibilidad;
      _esDeriivado = examen.es_derivado;
      _disponibleUrgencia = examen.disponible_urgencia;
      _areaSeleccionada = examen.area;
      _seccionSeleccionada = examen.seccion;
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onUrgenciaChanged(bool value) {
    setState(() {
      _disponibleUrgencia = value;
      // Actualizar horario automáticamente solo si coincide con el default
      if (value && _horarioController.text == _horarioRutina) {
        _horarioController.text = _horarioUrgencia;
      } else if (!value && _horarioController.text == _horarioUrgencia) {
        _horarioController.text = _horarioRutina;
      }
    });
  }

  Future<void> _guardarExamen() async {
    if (!_formKey.currentState!.validate()) return;

    final seccionFinal = _esDeriivado ? _seccionSeleccionada : _areaSeleccionada;
    if (seccionFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona el área o centro de destino.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final newExamen = Examen(
      id: widget.examenId ?? '',
      nombre: _nombreController.text.trim(),
      nombre_normalizado:
          _firestoreService.normalizar(_nombreController.text.trim()),
      condicion_paciente: _condicionController.text.trim(),
      muestra: _muestraController.text.trim(),
      recipiente: _recipienteController.text.trim(),
      conservacion_transporte: _conservacionController.text.trim(),
      seccion: _esDeriivado ? _seccionSeleccionada! : _areaSeleccionada!,
      plazo_entrega: _plazoController.text.trim(),
      observaciones: _observacionesController.text.trim(),
      area: _esDeriivado ? null : _areaSeleccionada,
      es_derivado: _esDeriivado,
      disponible_urgencia: _disponibleUrgencia,
      horario_disponibilidad: _horarioController.text.trim(),
    );

    try {
      await _firestoreService.saveExamen(newExamen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.examenId == null
              ? 'Examen creado exitosamente.'
              : 'Examen actualizado exitosamente.'),
          backgroundColor: AppStyles.primaryDark,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool required = true,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo obligatorio.' : null
          : null,
    );
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
                    // ── Datos básicos ──────────────────────────────
                    _buildTextField(_nombreController, 'Nombre del Examen',
                        Icons.science_outlined),
                    const SizedBox(height: 14),
                    _buildTextField(_condicionController,
                        'Condición del Paciente', Icons.person_outline,
                        hint: 'Ej: Ayuno, No requiere...'),
                    const SizedBox(height: 14),
                    _buildTextField(_muestraController, 'Muestra requerida',
                        Icons.colorize_outlined,
                        hint: 'Ej: Sangre total 4 ml, Orina 50 ml...'),
                    const SizedBox(height: 14),
                    _buildTextField(_recipienteController, 'Recipiente',
                        Icons.inventory_2_outlined,
                        hint: 'Ej: Tubo Tapa roja, Frasco limpio...'),
                    const SizedBox(height: 14),
                    _buildTextField(_conservacionController,
                        'Conservación y Transporte', Icons.thermostat_outlined,
                        hint: 'Ej: Tº ambiente, 4°C (transporte en hielo)...'),
                    const SizedBox(height: 14),
                    _buildTextField(_plazoController,
                        'Plazo de entrega de resultados',
                        Icons.access_time_outlined,
                        hint: 'Ej: 24 horas, 15 días...'),
                    const SizedBox(height: 14),
                    _buildTextField(_observacionesController, 'Observaciones',
                        Icons.info_outline,
                        maxLines: 3, required: false),
                    const SizedBox(height: 20),

                    // ── Switch derivado/interno ────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _esDeriivado
                                ? Icons.local_shipping_outlined
                                : Icons.business_outlined,
                            color: _esDeriivado
                                ? Colors.orange
                                : AppStyles.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _esDeriivado
                                  ? 'Examen Derivado (otro centro)'
                                  : 'Examen Interno (laboratorio)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _esDeriivado,
                            activeThumbColor: Colors.orange,
                            onChanged: (v) => setState(() {
                              _esDeriivado = v;
                              _areaSeleccionada = null;
                              _seccionSeleccionada = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selector área o sección derivada
                    if (!_esDeriivado)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Área del Laboratorio',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _areaSeleccionada,
                        items: _areasInternas
                            .map((a) =>
                                DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _areaSeleccionada = v;
                          _seccionSeleccionada = v;
                        }),
                        validator: (v) =>
                            v == null ? 'Selecciona el área.' : null,
                      )
                    else
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Centro de Destino',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _seccionSeleccionada,
                        items: _seccionesDerivadas
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _seccionSeleccionada = v),
                        validator: (v) =>
                            v == null ? 'Selecciona el centro.' : null,
                      ),

                    const SizedBox(height: 20),

                    // ── Disponibilidad / Horario ───────────────────
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Disponibilidad horaria',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppStyles.primaryDark)),
                    ),

                    // Switch urgencia
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _disponibleUrgencia
                            ? Colors.red.shade50
                            : Colors.grey.shade50,
                        border: Border.all(
                            color: _disponibleUrgencia
                                ? Colors.red.shade300
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emergency_outlined,
                              color: _disponibleUrgencia
                                  ? Colors.red.shade700
                                  : Colors.grey,
                              size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _disponibleUrgencia
                                      ? 'Disponible en Urgencia (24/7)'
                                      : 'Solo Rutina',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _disponibleUrgencia
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  _disponibleUrgencia
                                      ? 'Este examen se puede realizar las 24 hrs'
                                      : 'Solo disponible en horario de rutina',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _disponibleUrgencia,
                            activeThumbColor: Colors.red.shade600,
                            onChanged: _onUrgenciaChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo horario editable (siempre visible para casos especiales)
                    TextFormField(
                      controller: _horarioController,
                      decoration: InputDecoration(
                        labelText: 'Horario de disponibilidad',
                        hintText: 'Ej: Lunes a jueves 8:00–17:00...',
                        prefixIcon: const Icon(Icons.schedule),
                        border: const OutlineInputBorder(),
                        helperText:
                            'Puedes personalizar este texto para casos especiales '
                            '(ej: exámenes derivados que no se aceptan todos los días)',
                        helperMaxLines: 2,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obligatorio.'
                          : null,
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardarExamen,
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                      label: Text(
                        widget.examenId == null
                            ? 'Guardar Examen'
                            : 'Actualizar Examen',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
    _condicionController.dispose();
    _muestraController.dispose();
    _recipienteController.dispose();
    _conservacionController.dispose();
    _plazoController.dispose();
    _observacionesController.dispose();
    _horarioController.dispose();
    super.dispose();
  }
}
