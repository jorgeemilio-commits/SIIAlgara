import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/sii_navbar.dart';

class CapturaCalificaciones extends StatefulWidget {
  final Map<String, dynamic> grupo;

  const CapturaCalificaciones({super.key, required this.grupo});

  @override
  State<CapturaCalificaciones> createState() => _CapturaCalificacionesState();
}

class _CapturaCalificacionesState extends State<CapturaCalificaciones> {
  // --- VARIABLES DE ESTADO GENERAL ---
  int _subTabActiva = 0; 
  bool _cargando = true; 
  bool _guardando = false; 
  String _mensajeError = ''; // Almacena el texto del error si algo falla
  
  List<Map<String, dynamic>> _listaAlumnos = []; 
  List<Map<String, dynamic>> _originalAlumnos = []; 
  
  // --- VARIABLES DE CALIFICACIONES Y ASISTENCIA ---
  final Map<String, TextEditingController> _controllers = {}; 
  int _cantidadParciales = 3; 
  DateTime _fechaSeleccionada = DateTime.now(); 
  Map<String, bool> _registroAsistencia = {}; 

  @override
  void initState() {
    super.initState();
    if (widget.grupo['asignaturas'] != null && widget.grupo['asignaturas']['cantidad_parciales'] != null) {
      _cantidadParciales = widget.grupo['asignaturas']['cantidad_parciales'] as int;
    }
    _inicializarDatos();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _inicializarDatos() async {
    await _cargarListaAlumnos();
    if (_mensajeError.isEmpty) {
      await _cargarAsistenciaFecha();
    }
  }

  // --- SECCIÓN: CARGA Y ORDENAMIENTO ALFABÉTICO DE ALUMNO ---
  Future<void> _cargarListaAlumnos({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _mensajeError = '';
      });
    }
    try {
      final response = await Supabase.instance.client
          .from('calificaciones')
          .select('*, estudiantes(nombres, apellido_paterno, apellido_materno), solicitudes_correccion(estatus, motivo)')
          .eq('clave_materia', widget.grupo['clave_materia'])
          .eq('periodo_escolar', widget.grupo['periodo_escolar']);

      _listaAlumnos = List<Map<String, dynamic>>.from(response.map((e) => Map<String, dynamic>.from(e)));

      // Ordenado alfabético estricto de la A a la Z
      _listaAlumnos.sort((a, b) {
        final estA = a['estudiantes'] ?? {};
        final estB = b['estudiantes'] ?? {};
        final nombreA = '${estA['apellido_paterno'] ?? ''} ${estA['apellido_materno'] ?? ''} ${estA['nombres'] ?? ''}'.trim().toLowerCase();
        final nombreB = '${estB['apellido_paterno'] ?? ''} ${estB['apellido_materno'] ?? ''} ${estB['nombres'] ?? ''}'.trim().toLowerCase();
        return nombreA.compareTo(nombreB);
      });

      _originalAlumnos = List<Map<String, dynamic>>.from(_listaAlumnos.map((e) => Map<String, dynamic>.from(e)));

      for (var alumno in _listaAlumnos) {
        final id = alumno['id_calificacion'].toString();
        for (int i = 1; i <= _cantidadParciales; i++) {
          _actualizarControlador('${id}_p$i', alumno['calificacion_parcial_$i']);
        }
      }
      if (mounted) setState(() => _cargando = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensajeError = 'Error al cargar estudiantes: $e';
          _cargando = false;
        });
      }
    }
  }

  void _actualizarControlador(String key, dynamic valorDB) {
    final valorTexto = valorDB?.toString() ?? '';
    if (_controllers.containsKey(key)) {
      if (_controllers[key]!.text != valorTexto) _controllers[key]!.text = valorTexto;
    } else {
      _controllers[key] = TextEditingController(text: valorTexto);
    }
  }

  // --- SECCIÓN: ENVIAR CALIFICACIONES A SUPABASE ---
  Future<void> _guardarCalificaciones() async {
    setState(() => _guardando = true);
    int exitosos = 0;
    try {
      for (var orig in _originalAlumnos) {
        final id = orig['id_calificacion'].toString();
        bool tieneCorreccionAprobada = false;
        if (orig['solicitudes_correccion'] != null) {
          final solicitudes = orig['solicitudes_correccion'] as List;
          tieneCorreccionAprobada = solicitudes.any((s) => s['estatus'] == 'Aprobada');
        }

        final Map<String, dynamic> updateData = {};
        for (int i = 1; i <= _cantidadParciales; i++) {
          final pText = _controllers['${id}_p$i']!.text.trim();
          if ((orig['calificacion_parcial_$i'] == null || tieneCorreccionAprobada) && pText.isNotEmpty) {
            updateData['calificacion_parcial_$i'] = double.tryParse(pText);
          }
        }

        if (updateData.isNotEmpty) {
          final actualizacion = await Supabase.instance.client
              .from('calificaciones')
              .update(updateData)
              .eq('id_calificacion', orig['id_calificacion'])
              .select();
          if (actualizacion.isNotEmpty) exitosos++;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(exitosos > 0 ? 'Se guardaron $exitosos alumnos con éxito.' : 'No hay cambios nuevos guardables.'), 
          backgroundColor: exitosos > 0 ? Colors.green : Colors.orange
        ));
      }
      await _cargarListaAlumnos(silencioso: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // --- SECCIÓN: CONTROL Y PASE DE ASISTENCIAS ---
  Future<void> _cargarAsistenciaFecha() async {
    try {
      final fechaString = "${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}";
      
      final response = await Supabase.instance.client
          .from('asistencias')
          .select('matricula_estudiante, asistio')
          .eq('clave_materia', widget.grupo['clave_materia'])
          .eq('periodo_escolar', widget.grupo['periodo_escolar'])
          .eq('fecha', fechaString);

      final Map<String, bool> mapaAsistencias = {};
      for (var row in response) {
        mapaAsistencias[row['matricula_estudiante']] = row['asistio'] as bool;
      }

      setState(() {
        _registroAsistencia = mapaAsistencias;
        for (var alumno in _listaAlumnos) {
          final mat = alumno['matricula_estudiante'];
          _registroAsistencia.putIfAbsent(mat, () => true);
        }
      });
    } catch (e) {
      debugPrint("Error cargando asistencias: $e");
    }
  }

  Future<void> _guardarAsistencia() async {
    setState(() => _guardando = true);
    try {
      final fechaString = "${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}";

      for (var entry in _registroAsistencia.entries) {
        await Supabase.instance.client.from('asistencias').upsert({
          'matricula_estudiante': entry.key,
          'clave_materia': widget.grupo['clave_materia'],
          'periodo_escolar': widget.grupo['periodo_escolar'],
          'fecha': fechaString,
          'asistio': entry.value
        }, onConflict: 'matricula_estudiante, clave_materia, periodo_escolar, fecha');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista de asistencia guardada correctamente.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar asistencia: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // --- SECCIÓN: INTERFAZ GRÁFICA (VISTAS REUTILIZABLES) ---
  @override
  Widget build(BuildContext context) {
    final asignatura = widget.grupo['asignaturas'] != null ? widget.grupo['asignaturas']['nombre_materia'] : 'Materia';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SiiNavbar(
        titulo: 'SII - Portal Docente',
        tabs: const [
          SiiNavTab(label: 'Captura de Calificaciones', icon: Icons.assignment_turned_in),
          SiiNavTab(label: 'Asistencia de Grupo', icon: Icons.calendar_month),
        ],
        indexSeleccionado: _subTabActiva,
        onTabSelected: (idx) => setState(() => _subTabActiva = idx),
        onLogout: () => Navigator.pop(context), 
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : _mensajeError.isNotEmpty
            ? _buildPantallaError() // Si hay error, rompe aquí y te lo muestra explícitamente
            : SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF003366)),
                      label: const Text('VOLVER AL LISTADO DE GRUPOS', style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 25),
                    _subTabActiva == 0 
                        ? _buildSeccionCalificaciones(asignatura) 
                        : _buildSeccionAsistencia(asignatura),
                  ],
                ),
              ),
    );
  }

  Widget _buildPantallaError() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text('Error en la Consulta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 10),
            Text(_mensajeError, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _inicializarDatos, child: const Text('Reintentar'))
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionCalificaciones(String asignatura) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asignatura: $asignatura (Grupo ${widget.grupo['nombre_grupo']})', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                const SizedBox(height: 8),
                Text('Periodo: ${widget.grupo['periodo_escolar']} | Horario: ${widget.grupo['horario']}', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarCalificaciones,
              icon: _guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('GUARDAR CALIFICACIONES', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
            )
          ],
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                dataRowMaxHeight: 70,
                columns: [
                  const DataColumn(label: Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Nombre del Alumno', style: TextStyle(fontWeight: FontWeight.bold))),
                  for (int i = 1; i <= _cantidadParciales; i++)
                    DataColumn(label: Text('Parcial $i', style: const TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Promedio Final', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)))),
                  const DataColumn(label: Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: List<DataRow>.generate(_listaAlumnos.length, (index) {
                  final alumno = _listaAlumnos[index];
                  final orig = _originalAlumnos[index];
                  final nombreCompleto = '${alumno['estudiantes']['apellido_paterno']} ${alumno['estudiantes']['apellido_materno'] ?? ''} ${alumno['estudiantes']['nombres']}';
                  final finalCalc = alumno['calificacion_final']?.toString() ?? '--';
                  final id = alumno['id_calificacion'].toString();

                  bool tieneCorreccionAprobada = false;
                  bool tieneCorreccionPendiente = false;
                  if (orig['solicitudes_correccion'] != null) {
                    final solicitudes = orig['solicitudes_correccion'] as List;
                    tieneCorreccionAprobada = solicitudes.any((s) => s['estatus'] == 'Aprobada');
                    tieneCorreccionPendiente = solicitudes.any((s) => s['estatus'] == 'Pendiente');
                  }

                  bool algunParcialLleno = false;
                  for (int i = 1; i <= _cantidadParciales; i++) {
                    if (orig['calificacion_parcial_$i'] != null) algunParcialLleno = true;
                  }

                  return DataRow(cells: [
                    DataCell(Text(alumno['matricula_estudiante'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(nombreCompleto)),
                    for (int i = 1; i <= _cantidadParciales; i++)
                      DataCell(_casillaCalificacion(_controllers['${id}_p$i']!, orig['calificacion_parcial_$i'], tieneCorreccionAprobada)),
                    DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(finalCalc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366))))),
                    DataCell(tieneCorreccionPendiente
                      ? const Chip(label: Text('Pendiente', style: TextStyle(color: Colors.orange, fontSize: 11)), backgroundColor: Color(0xFFFFF3E0), side: BorderSide.none)
                      : algunParcialLleno && !tieneCorreccionAprobada
                        ? TextButton.icon(
                            icon: const Icon(Icons.lock_open, size: 16, color: Colors.orange), 
                            label: const Text('Desbloquear', style: TextStyle(fontSize: 12, color: Colors.orange)), 
                            onPressed: () {
                              final motivoCtrl = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(children: [Icon(Icons.lock_open, color: Colors.orange), SizedBox(width: 10), Text('Solicitar Desbloqueo')]),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Alumno: $nombreCompleto', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 15),
                                      const Text('Motivo para solicitar la corrección al Coordinador:'),
                                      const SizedBox(height: 10),
                                      TextField(controller: motivoCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej: Error de captura...')),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                                      onPressed: () async {
                                        if (motivoCtrl.text.trim().isEmpty) return;
                                        Navigator.pop(context);
                                        try {
                                          await Supabase.instance.client.from('solicitudes_correccion').insert({'id_calificacion': id, 'motivo': motivoCtrl.text.trim(), 'estatus': 'Pendiente'});
                                          _cargarListaAlumnos(silencioso: true);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Petición enviada.'), backgroundColor: Colors.orange));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                        }
                                      }, 
                                      child: const Text('Enviar', style: TextStyle(color: Colors.white))
                                    )
                                  ],
                                ),
                              );
                            })
                        : const Chip(label: Text('Abierto', style: TextStyle(color: Colors.green, fontSize: 11)), backgroundColor: Color(0xFFE8F5E9), side: BorderSide.none)),
                  ]);
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionAsistencia(String asignatura) {
    final fechaFormateada = "${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pase de Lista: $asignatura', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text('Día: $fechaFormateada', style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaSeleccionada,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2027),
                        );
                        if (picked != null && picked != _fechaSeleccionada) {
                          setState(() => _fechaSeleccionada = picked);
                          _cargarAsistenciaFecha(); 
                        }
                      },
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Cambiar Fecha', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade100, foregroundColor: Colors.blueGrey.shade800, elevation: 0),
                    )
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarAsistencia,
              icon: _guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.done_all),
              label: const Text('GUARDAR ASISTENCIAS', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
            )
          ],
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              dataRowMaxHeight: 65,
              columns: const [
                DataColumn(label: Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nombre del Alumno', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Estatus de Asistencia', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _listaAlumnos.map((alumno) {
                final mat = alumno['matricula_estudiante'];
                final nombreCompleto = '${alumno['estudiantes']['apellido_paterno']} ${alumno['estudiantes']['apellido_materno'] ?? ''} ${alumno['estudiantes']['nombres']}';
                final asistio = _registroAsistencia[mat] ?? true;

                return DataRow(cells: [
                  DataCell(Text(mat ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(nombreCompleto)),
                  DataCell(
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Asistencia', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: asistio == true,
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: asistio ? Colors.green.shade900 : Colors.grey),
                          onSelected: (val) { if (val) setState(() => _registroAsistencia[mat!] = true); },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Falta', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: asistio == false,
                          selectedColor: Colors.red.shade100,
                          labelStyle: TextStyle(color: !asistio ? Colors.red.shade900 : Colors.grey),
                          onSelected: (val) { if (val) setState(() => _registroAsistencia[mat!] = false); },
                        ),
                      ],
                    )
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _casillaCalificacion(TextEditingController controller, dynamic valorOriginal, bool tieneCorreccionAprobada) {
    final bool yaCalificado = valorOriginal != null;
    final bool esSoloLectura = yaCalificado && !tieneCorreccionAprobada;
    return SizedBox(
      width: 75,
      child: TextFormField(
        controller: controller,
        enabled: !esSoloLectura, 
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(color: esSoloLectura ? Colors.grey.shade600 : Colors.black, fontWeight: esSoloLectura ? FontWeight.normal : FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: esSoloLectura ? Colors.grey.shade200 : Colors.white,
          suffixIcon: esSoloLectura ? const Icon(Icons.lock, size: 14, color: Colors.grey) : null,
        ),
      ),
    );
  }
}