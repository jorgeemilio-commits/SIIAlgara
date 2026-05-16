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

  @override
  void initState() {
    super.initState();
    _cargarListaAlumnos();
  }

  Future<void> _cargarListaAlumnos() async {
    setState(() => _cargando = true);
    try {
      // Buscamos a los alumnos inscritos en esta materia y periodo específico
      // Hacemos JOIN con la tabla de estudiantes para traernos sus nombres reales
      final response = await Supabase.instance.client
          .from('calificaciones')
          .select('*, estudiantes(nombres, apellido_paterno, apellido_materno)')
          .eq('clave_materia', widget.grupo['clave_materia'])
          .eq('periodo_escolar', widget.grupo['periodo_escolar'])
          .order('matricula_estudiante', ascending: true);

      setState(() {
        // Hacemos una copia profunda (Map) para poder editar los valores en los TextFields
        _listaAlumnos = List<Map<String, dynamic>>.from(response.map((e) => Map<String, dynamic>.from(e)));
        _cargando = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCalificaciones() async {
    setState(() => _guardando = true);
    try {
      // Recorremos la lista y actualizamos la base de datos alumno por alumno
      for (var alumno in _listaAlumnos) {
        await Supabase.instance.client.from('calificaciones').update({
          'calificacion_parcial_1': double.tryParse(alumno['calificacion_parcial_1']?.toString() ?? ''),
          'calificacion_parcial_2': double.tryParse(alumno['calificacion_parcial_2']?.toString() ?? ''),
          'calificacion_parcial_3': double.tryParse(alumno['calificacion_parcial_3']?.toString() ?? ''),
        }).eq('id_calificacion', alumno['id_calificacion']);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calificaciones guardadas con éxito.'), backgroundColor: Colors.green));
      }
      
      // Recargamos la lista para ver el Promedio Final que calculó tu Trigger en SQL automáticamente
      await _cargarListaAlumnos();
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _guardando = false);
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
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No hay alumnos inscritos en este grupo.')))
                      : DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                          dataRowMaxHeight: 70,
                          columns: const [
                            DataColumn(label: Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nombre del Alumno', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Parcial 1', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Parcial 2', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Parcial 3', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Promedio Final', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)))),
                          ],
                          rows: _listaAlumnos.map((alumno) {
                            final nombreCompleto = '${alumno['estudiantes']['apellido_paterno']} ${alumno['estudiantes']['apellido_materno'] ?? ''} ${alumno['estudiantes']['nombres']}';
                            final finalCalc = alumno['calificacion_final']?.toString() ?? '--';
                            
                            return DataRow(cells: [
                              DataCell(Text(alumno['matricula_estudiante'], style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(nombreCompleto)),
                              DataCell(_casillaCalificacion(alumno, 'calificacion_parcial_1')),
                              DataCell(_casillaCalificacion(alumno, 'calificacion_parcial_2')),
                              DataCell(_casillaCalificacion(alumno, 'calificacion_parcial_3')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(finalCalc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366))),
                                )
                              ),
                            ]);
                          }).toList(),
                        ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Widget para crear el TextField cuadradito para las calificaciones
  Widget _casillaCalificacion(Map<String, dynamic> alumno, String clave) {
    return SizedBox(
      width: 70,
      child: TextFormField(
        initialValue: alumno[clave]?.toString() ?? '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: (valor) => alumno[clave] = valor, // Actualiza el mapa temporal en memoria
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}