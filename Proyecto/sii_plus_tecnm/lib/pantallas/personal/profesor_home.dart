import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sii_navbar.dart';
import 'secciones/mis_grupos_profesor.dart'; 

class ProfesorHome extends StatefulWidget {
  const ProfesorHome({super.key});

  @override
  State<ProfesorHome> createState() => _ProfesorHomeState();
}

class _ProfesorHomeState extends State<ProfesorHome> {
  int _tabActiva = 0;
  bool _cargando = true;
  
  String _nombreCompleto = '';
  String _nomina = '';
  String _departamento = '';
  List<dynamic> _misGrupos = [];
  String _mensajeError = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosProfesor();
  }

  Future<void> _cargarDatosProfesor() async {
    setState(() {
      _cargando = true;
      _mensajeError = '';
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() { _mensajeError = 'No hay sesión de usuario activa.'; _cargando = false; });
        return;
      }

      final dataProf = await Supabase.instance.client
          .from('profesores')
          .select('numero_nomina, nombres, apellido_paterno, apellido_materno, departamento_academico')
          .eq('id_auth', user.id)
          .maybeSingle();

      if (dataProf == null) {
        setState(() { 
          _mensajeError = 'ERROR: No se encontró un perfil de profesor en la base de datos vinculado a tu ID de sesión (${user.id}).'; 
          _cargando = false; 
        });
        return;
      }

      _nomina = dataProf['numero_nomina'] ?? '';
      _nombreCompleto = '${dataProf['nombres']} ${dataProf['apellido_paterno']} ${dataProf['apellido_materno'] ?? ''}'.trim();
      _departamento = dataProf['departamento_academico'] ?? 'Sin asignar';

      try {
        final dataGrupos = await Supabase.instance.client
            .from('grupos')
            .select('*, asignaturas(nombre_materia)')
            .eq('numero_nomina_profesor', _nomina);

        setState(() {
          _misGrupos = dataGrupos;
          _cargando = false;
        });
      } catch (errGrupos) {
        setState(() { _mensajeError = 'ERROR AL CARGAR GRUPOS: $errGrupos'; _cargando = false; });
      }

    } catch (e) {
      setState(() { _mensajeError = 'ERROR CRÍTICO GENERAL: $e'; _cargando = false; });
    }
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
        : _mensajeError.isNotEmpty 
            ? _buildPantallaError()
            : IndexedStack(
                index: _tabActiva,
                children: [
                  _buildDashboard(),
                  MisGruposProfesor(misGrupos: _misGrupos), // <-- INVOCAMOS EL WIDGET DESDE EL OTRO ARCHIVO
                  _buildPlanAcademicoPlaceholder(),
                ],
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
            const Text('Algo salió mal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 10),
            Text(_mensajeError, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _cargarDatosProfesor, child: const Text('Reintentar'))
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenido(a), $_nombreCompleto', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF003366))),
          const SizedBox(height: 8),
          Text('Nómina: $_nomina | Departamento: $_departamento', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 40),
          
          const Text('Resumen del Semestre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _resumenCard('Grupos Asignados', _misGrupos.length.toString(), Colors.blue, Icons.class_),
              const SizedBox(width: 20),
              _resumenCard('Alumnos Totales', '--', Colors.green, Icons.people),
              const SizedBox(width: 20),
              _resumenCard('Actas Pendientes', _misGrupos.length.toString(), Colors.orange, Icons.warning_amber_rounded),
            ],
          ),
        ],
      ),
    );
  }

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
            Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF003366))),
          ],
        ),
      ),
    );
  }
}