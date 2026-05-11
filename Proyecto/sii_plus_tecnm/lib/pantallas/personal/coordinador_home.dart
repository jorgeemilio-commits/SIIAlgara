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
  
  // Datos para el resumen
  int _total = 0, _pendientes = 0, _aceptados = 0;
  List<dynamic> _aspirantesPendientes = [];

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

      // Obtener info del coordinador
      final coord = await Supabase.instance.client
          .from('coordinadores')
          .select('departamento_coordina')
          .eq('id_auth', user.id)
          .single();
      
      _departamento = coord['departamento_coordina'];

      // Obtener aspirantes para estadísticas y tabla
      final data = await Supabase.instance.client
          .from('aspirantes')
          .select()
          .eq('carrera_solicitada', _departamento);

      setState(() {
        _total = data.length;
        _pendientes = data.where((a) => a['estatus_admision'] == 'En proceso').length;
        _aceptados = data.where((a) => a['estatus_admision'] == 'Aceptado').length;
        _aspirantesPendientes = data.where((a) => a['estatus_admision'] == 'En proceso').toList();
        _cargando = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _cargando = false);
    }
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Definimos las pestañas específicas para este rol
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
        : _tabActiva == 0 ? _buildInicio() : _tabActiva == 1 ? _buildSolicitudes() : _buildPlaceholder(),
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
          const SizedBox(height: 40),
          // Aquí podrías agregar gráficas o avisos parroquiales en el futuro
        ],
      ),
    );
  }

  // --- SECCIÓN 1: SOLICITUDES (TABLA FUNCIONAL) ---
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
                          DataCell(ElevatedButton(onPressed: () {}, child: const Text('Revisar'))),
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

  Widget _buildPlaceholder() => const Center(child: Text('Sección en desarrollo comercial.', style: TextStyle(fontSize: 18, color: Colors.grey)));

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