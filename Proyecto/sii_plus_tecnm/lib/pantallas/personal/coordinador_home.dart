import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sii_navbar.dart';

class CoordinadorHome extends StatefulWidget {
  const CoordinadorHome({super.key});

  @override
  State<CoordinadorHome> createState() => _CoordinadorHomeState();
}

class _CoordinadorHomeState extends State<CoordinadorHome> {
  int _tabActiva = 0;
  bool _cargando = true;
  String _departamento = '';
  
  // Datos para el resumen y las tablas
  int _total = 0, _pendientes = 0, _aceptados = 0;
  List<dynamic> _aspirantesPendientes = [];
  List<dynamic> _estudiantesInscritos = []; 

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _cargando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Obtener info del coordinador
      final coord = await Supabase.instance.client
          .from('coordinadores')
          .select('departamento_coordina')
          .eq('id_auth', user.id)
          .single();
      
      _departamento = coord['departamento_coordina'];

      // 2. Obtener aspirantes
      final aspirantesData = await Supabase.instance.client
          .from('aspirantes')
          .select()
          .eq('carrera_solicitada', _departamento);

      // 3. Obtener estudiantes ya inscritos en esta carrera
      final estudiantesData = await Supabase.instance.client
          .from('estudiantes')
          .select()
          .eq('carrera_plan_estudios', _departamento)
          .order('apellido_paterno', ascending: true);

      setState(() {
        _total = aspirantesData.length;
        _pendientes = aspirantesData.where((a) => a['estatus_admision'] == 'En proceso').length;
        _aceptados = estudiantesData.length; // Ahora leemos el total real de estudiantes
        
        _aspirantesPendientes = aspirantesData.where((a) => a['estatus_admision'] == 'En proceso').toList();
        _estudiantesInscritos = estudiantesData;
        
        _cargando = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _cargando = false);
    }
  }

  // Función para aprobar o rechazar
  Future<void> _procesarAdmision(Map<String, dynamic> aspirante, bool aprobado) async {
    setState(() => _cargando = true);
    try {
      if (aprobado) {
        final matricula = '2026${DateTime.now().millisecond.toString().padLeft(4, '0')}';

        // Pasa a la tabla oficial de estudiantes
        await Supabase.instance.client.from('estudiantes').insert({
          'matricula': matricula,
          'nombres': aspirante['nombres'],
          'apellido_paterno': aspirante['apellido_paterno'],
          'apellido_materno': aspirante['apellido_materno'],
          'curp': aspirante['curp'],
          'correo_personal': aspirante['correo_personal'],
          'carrera_plan_estudios': aspirante['carrera_solicitada'],
          'promedio_total': aspirante['promedio_preparatoria'],
          'id_auth': aspirante['id_auth'], 
          'semestre_curso': 1,
        });

        await Supabase.instance.client
            .from('aspirantes')
            .update({'estatus_admision': 'Aceptado'})
            .eq('folio_aspirante', aspirante['folio_aspirante']);

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inscripción exitosa. Matrícula: $matricula'), backgroundColor: Colors.green));
      } else {
        await Supabase.instance.client
            .from('aspirantes')
            .update({'estatus_admision': 'Rechazado'})
            .eq('folio_aspirante', aspirante['folio_aspirante']);
            
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud rechazada'), backgroundColor: Colors.red));
      }
      _fetchData(); // Recarga las listas para actualizar las tablas visualmente
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _cargando = false);
    }
  }

  void _mostrarDetalles(Map<String, dynamic> aspirante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revisar Folio: ${aspirante['folio_aspirante']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${aspirante['nombres']} ${aspirante['apellido_paterno']}'),
            Text('Promedio: ${aspirante['promedio_preparatoria']}'),
            Text('CURP: ${aspirante['curp']}'),
            const SizedBox(height: 20),
            const Text('¿Desea formalizar la inscripción de este aspirante?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () { Navigator.pop(context); _procesarAdmision(aspirante, false); },
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
            onPressed: () { Navigator.pop(context); _procesarAdmision(aspirante, true); },
            child: const Text('Aprobar e Inscribir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<SiiNavTab> misTabs = [
      const SiiNavTab(label: 'Inicio', icon: Icons.dashboard),
      const SiiNavTab(label: 'Solicitudes', icon: Icons.people),
      const SiiNavTab(label: 'Estudiantes', icon: Icons.school),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SiiNavbar(
        titulo: 'SII - $_departamento',
        tabs: misTabs,
        indexSeleccionado: _tabActiva,
        onTabSelected: (idx) => setState(() => _tabActiva = idx),
        onLogout: _cerrarSesion,
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : _tabActiva == 0 
            ? _buildInicio() 
            : _tabActiva == 1 
                ? _buildSolicitudes() 
                : _buildEstudiantes(), // Llamamos a la nueva pestaña
    );
  }

  // --- SECCIÓN 0: INICIO (RESUMEN VISUAL) ---
  Widget _buildInicio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado del Ciclo Escolar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 30),
          Row(
            children: [
              _resumenCard('Aspirantes Totales', _total.toString(), Colors.blue, Icons.description),
              const SizedBox(width: 20),
              _resumenCard('Pendientes de Revisión', _pendientes.toString(), Colors.orange, Icons.pending),
              const SizedBox(width: 20),
              _resumenCard('Alumnos Inscritos', _aceptados.toString(), Colors.green, Icons.verified),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN 1: SOLICITUDES (TABLA DE ASPIRANTES) ---
  Widget _buildSolicitudes() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestión de Aspirantes Pendientes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: _aspirantesPendientes.isEmpty 
                ? const Center(child: Text('No hay solicitudes pendientes por el momento.'))
                : ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Folio')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Promedio')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: _aspirantesPendientes.map((a) => DataRow(cells: [
                          DataCell(Text(a['folio_aspirante'])),
                          DataCell(Text('${a['nombres']} ${a['apellido_paterno']}')),
                          DataCell(Text(a['promedio_preparatoria'].toString())),
                          DataCell(
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_turned_in, size: 16),
                              label: const Text('Evaluar'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
                              onPressed: () => _mostrarDetalles(a),
                            )
                          ),
                        ])).toList(),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN 2: ESTUDIANTES INSCRITOS (NUEVA TABLA) ---
  Widget _buildEstudiantes() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Directorio de Estudiantes Oficiales', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 8),
          const Text('Alumnos que han completado su proceso de admisión y cuentan con matrícula.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: _estudiantesInscritos.isEmpty 
                ? const Center(child: Text('Aún no hay estudiantes inscritos en este departamento.'))
                : ListView(
                    children: [
                      DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
                        columns: const [
                          DataColumn(label: Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Nombre Completo', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Semestre', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _estudiantesInscritos.map((e) => DataRow(cells: [
                          DataCell(Text(e['matricula'], style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text('${e['apellido_paterno']} ${e['apellido_materno'] ?? ''} ${e['nombres']}')),
                          DataCell(Text(e['semestre_curso'].toString())),
                          DataCell(Chip(
                            label: const Text('Activo', style: TextStyle(color: Colors.green, fontSize: 12)),
                            backgroundColor: Colors.green.shade100,
                            side: BorderSide.none,
                          )),
                        ])).toList(),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenCard(String tit, String val, Color col, IconData ic) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          border: Border(left: BorderSide(color: col, width: 6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ic, color: col, size: 30),
            const SizedBox(height: 15),
            Text(tit, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          ],
        ),
      ),
    );
  }
}