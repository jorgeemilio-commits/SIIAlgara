import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sii_navbar.dart';

class ProfesorHome extends StatefulWidget {
  const ProfesorHome({super.key});

  @override
  State<ProfesorHome> createState() => _ProfesorHomeState();
}

class _ProfesorHomeState extends State<ProfesorHome> {
  int _tabActiva = 0;
  bool _cargando = true;
  
  // Datos del profesor logueado
  String _nombreCompleto = '';
  String _nomina = '';
  String _departamento = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosProfesor();
  }

  Future<void> _cargarDatosProfesor() async {
    setState(() => _cargando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profesores')
          .select('numero_nomina, nombres, apellido_paterno, apellido_materno, departamento_academico')
          .eq('id_auth', user.id)
          .single();

      setState(() {
        _nomina = data['numero_nomina'] ?? '';
        _nombreCompleto = '${data['nombres']} ${data['apellido_paterno']} ${data['apellido_materno'] ?? ''}'.trim();
        _departamento = data['departamento_academico'] ?? 'Sin asignar';
        _cargando = false;
      });
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
      setState(() => _cargando = false);
    }
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Pestañas basadas en la planeación de la Semana 4
    final List<SiiNavTab> profeTabs = [
      const SiiNavTab(label: 'Inicio', icon: Icons.dashboard),
      const SiiNavTab(label: 'Mis Grupos y Calificaciones', icon: Icons.assignment),
      const SiiNavTab(label: 'Plan Académico', icon: Icons.folder_shared),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SiiNavbar(
        titulo: 'SII - Portal Docente',
        tabs: profeTabs,
        indexSeleccionado: _tabActiva,
        onTabSelected: (idx) => setState(() => _tabActiva = idx),
        onLogout: _cerrarSesion,
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _tabActiva,
            children: [
              _buildDashboard(),
              _buildMisGruposPlaceholder(),
              _buildPlanAcademicoPlaceholder(),
            ],
          ),
    );
  }

  // --- 1. SECCIÓN: DASHBOARD (INICIO) ---
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenido(a), $_nombreCompleto', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 8),
          Text('Nómina: $_nomina | Departamento: $_departamento', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 40),
          
          const Text('Resumen del Semestre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _resumenCard('Grupos Asignados', '0', Colors.blue, Icons.class_),
              const SizedBox(width: 20),
              _resumenCard('Alumnos Totales', '0', Colors.green, Icons.people),
              const SizedBox(width: 20),
              _resumenCard('Actas Pendientes', '0', Colors.orange, Icons.warning_amber_rounded),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. SECCIÓN: GRUPOS Y CALIFICACIONES (PLACEHOLDER) ---
  Widget _buildMisGruposPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('Módulo de Captura de Calificaciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Aquí el profesor verá sus listas y podrá calificar.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- 3. SECCIÓN: PLAN ACADÉMICO (PLACEHOLDER) ---
  Widget _buildPlanAcademicoPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('Gestión de Plan Académico', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Aquí se subirá el documento del plan de la materia.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- WIDGET REUTILIZABLE ---
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