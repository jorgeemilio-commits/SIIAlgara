import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CapturaCalificaciones extends StatefulWidget {
  final Map<String, dynamic> grupo;

  const CapturaCalificaciones({super.key, required this.grupo});

  @override
  State<CapturaCalificaciones> createState() => _CapturaCalificacionesState();
}

class _CapturaCalificacionesState extends State<CapturaCalificaciones> {
  bool _cargando = true;
  bool _guardando = false;
  List<Map<String, dynamic>> _listaAlumnos = [];
  List<Map<String, dynamic>> _originalAlumnos = []; 
  
  // Mapa de controladores estables
  final Map<String, TextEditingController> _controllers = {};
  
  // Variable dinámica para saber cuántos parciales tiene esta materia en específico
  int _cantidadParciales = 3;

  @override
  void initState() {
    super.initState();
    // Leemos la cantidad de parciales desde el JOIN de asignaturas (si es nulo, usamos 3 por defecto)
    if (widget.grupo['asignaturas'] != null && widget.grupo['asignaturas']['cantidad_parciales'] != null) {
      _cantidadParciales = widget.grupo['asignaturas']['cantidad_parciales'] as int;
    }
    _cargarListaAlumnos();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarListaAlumnos({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    
    try {
      final response = await Supabase.instance.client
          .from('calificaciones')
          .select('*, estudiantes(nombres, apellido_paterno, apellido_materno), solicitudes_correccion(estatus, motivo)')
          .eq('clave_materia', widget.grupo['clave_materia'])
          .eq('periodo_escolar', widget.grupo['periodo_escolar'])
          .order('matricula_estudiante', ascending: true);

      _listaAlumnos = List<Map<String, dynamic>>.from(response.map((e) => Map<String, dynamic>.from(e)));
      _originalAlumnos = List<Map<String, dynamic>>.from(response.map((e) => Map<String, dynamic>.from(e)));

      // Bucle DINÁMICO: Creamos/actualizamos solo los controladores necesarios (de 1 hasta _cantidadParciales)
      for (var alumno in _listaAlumnos) {
        final id = alumno['id_calificacion'].toString();
        for (int i = 1; i <= _cantidadParciales; i++) {
          _actualizarControlador('${id}_p$i', alumno['calificacion_parcial_$i']);
        }
      }

      if (mounted) {
        setState(() {
          if (!silencioso) _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _actualizarControlador(String key, dynamic valorDB) {
    final valorTexto = valorDB?.toString() ?? '';
    if (_controllers.containsKey(key)) {
      if (_controllers[key]!.text != valorTexto) {
        _controllers[key]!.text = valorTexto;
      }
    } else {
      _controllers[key] = TextEditingController(text: valorTexto);
    }
  }

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

        // Armamos el mapa de actualización de forma DINÁMICA
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
          content: Text(exitosos > 0 ? 'Se guardaron $exitosos alumnos y sus campos han sido bloqueados.' : 'No se detectaron calificaciones nuevas o editables.'), 
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

  void _abrirDialogoSolicitud(int idCalificacion, String alumnoNombre) {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.lock_open, color: Colors.orange), const SizedBox(width: 10), const Text('Solicitar Desbloqueo')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alumno: $alumnoNombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text('Especifique el motivo para que Coordinación autorice la corrección de calificación:'),
            const SizedBox(height: 10),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej: Captura incorrecta del primer parcial...'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
            onPressed: () async {
              if (motivoCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              _enviarSolicitudCorreccion(idCalificacion, motivoCtrl.text.trim());
            }, 
            child: const Text('Enviar Solicitud', style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  Future<void> _enviarSolicitudCorreccion(int idCalificacion, String motivo) async {
    try {
      await Supabase.instance.client.from('solicitudes_correccion').insert({
        'id_calificacion': idCalificacion,
        'motivo': motivo,
        'estatus': 'Pendiente'
      });
      _cargarListaAlumnos(silencioso: true); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Petición de apertura enviada.'), backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al solicitar: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asignatura = widget.grupo['asignaturas'] != null ? widget.grupo['asignaturas']['nombre_materia'] : 'Materia';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Evaluación: $asignatura (Grupo ${widget.grupo['nombre_grupo']})'),
        elevation: 1,
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lista de Asistencia y Calificaciones', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                        const SizedBox(height: 8),
                        Text('Periodo: ${widget.grupo['periodo_escolar']} | Horario: ${widget.grupo['horario']}', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardarCalificaciones,
                      icon: _guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('GUARDAR CALIFICACIONES', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
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
                    child: _listaAlumnos.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No hay alumnos inscritos.')))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal, // Permite scroll horizontal si hay muchos parciales
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                            dataRowMaxHeight: 70,
                            columns: [
                              const DataColumn(label: Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Nombre del Alumno', style: TextStyle(fontWeight: FontWeight.bold))),
                              
                              // COLUMNAS GENERADAS DINÁMICAMENTE BASADAS EN _cantidadParciales
                              for (int i = 1; i <= _cantidadParciales; i++)
                                DataColumn(label: Text('Parcial $i', style: const TextStyle(fontWeight: FontWeight.bold))),
                              
                              const DataColumn(label: Text('Promedio Final', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)))),
                              const DataColumn(label: Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: List<DataRow>.generate(_listaAlumnos.length, (index) {
                              final alumno = _listaAlumnos[index];
                              final orig = _originalAlumnos[index];
                              
                              final estudiante = alumno['estudiantes'] ?? {};
                              final nombreCompleto = '${estudiante['apellido_paterno'] ?? ''} ${estudiante['apellido_materno'] ?? ''} ${estudiante['nombres'] ?? 'Sin datos'}'.trim();
                              final finalCalc = alumno['calificacion_final']?.toString() ?? '--';
                              final id = alumno['id_calificacion'].toString();

                              bool tieneCorreccionAprobada = false;
                              bool tieneCorreccionPendiente = false;
                              if (orig['solicitudes_correccion'] != null) {
                                final solicitudes = orig['solicitudes_correccion'] as List;
                                tieneCorreccionAprobada = solicitudes.any((s) => s['estatus'] == 'Aprobada');
                                tieneCorreccionPendiente = solicitudes.any((s) => s['estatus'] == 'Pendiente');
                              }

                              // Verificamos si AL MENOS UN parcial está lleno para mostrar el botón de desbloqueo
                              bool algunParcialLleno = false;
                              for (int i = 1; i <= _cantidadParciales; i++) {
                                if (orig['calificacion_parcial_$i'] != null) algunParcialLleno = true;
                              }

                              return DataRow(cells: [
                                DataCell(Text(alumno['matricula_estudiante'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(nombreCompleto)),
                                
                                // CELDAS DE CALIFICACIÓN GENERADAS DINÁMICAMENTE
                                for (int i = 1; i <= _cantidadParciales; i++)
                                  DataCell(_casillaCalificacion(_controllers['${id}_p$i']!, orig['calificacion_parcial_$i'], tieneCorreccionAprobada)),
                                
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text(finalCalc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF003366))),
                                  )
                                ),
                                
                                DataCell(
                                  tieneCorreccionPendiente
                                  ? const Chip(label: Text('Pendiente', style: TextStyle(color: Colors.orange, fontSize: 11)), backgroundColor: Color(0xFFFFF3E0), side: BorderSide.none)
                                  : algunParcialLleno && !tieneCorreccionAprobada
                                    ? TextButton.icon(
                                        icon: const Icon(Icons.lock_open, size: 16, color: Colors.orange),
                                        label: const Text('Desbloquear', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                        onPressed: () => _abrirDialogoSolicitud(orig['id_calificacion'], nombreCompleto),
                                      )
                                    : const Chip(label: Text('Abierto', style: TextStyle(color: Colors.green, fontSize: 11)), backgroundColor: Color(0xFFE8F5E9), side: BorderSide.none)
                                ),
                              ]);
                            }),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
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
        style: TextStyle(
          color: esSoloLectura ? Colors.grey.shade600 : Colors.black,
          fontWeight: esSoloLectura ? FontWeight.normal : FontWeight.bold,
        ),
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