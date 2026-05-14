import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sii_navbar.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tabActiva = 0;
  bool _cargando = false;

  // --- VARIABLES PARA EL DIRECTORIO Y FILTROS ---
  bool _cargandoDirectorio = true;
  List<Map<String, dynamic>> _directorioCompleto = [];
  List<Map<String, dynamic>> _directorioFiltrado = [];
  int _totCoord = 0;
  int _totProf = 0;
  String _filtroTexto = '';
  String _filtroRol = 'Todos'; // 'Todos', 'Coordinador', 'Profesor'

  // Variable para alternar entre perfiles en el formulario
  String _tipoPersonal = 'coordinador';

  // --- Campos de formulario (Comunes y Coordinador) ---
  final _nominaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _curpCtrl = TextEditingController();
  final _rfcCtrl = TextEditingController();
  final _fechaNacCtrl = TextEditingController();
  String? _sexoSeleccionado;
  
  String? _deptoSeleccionado;
  final List<String> _departamentos = [
    'Arquitectura', 'Contador Público', 'Ingeniería Bioquímica', 'Ingeniería Electromecánica',
    'Ingeniería Electrónica', 'Ingeniería en Gestión Empresarial', 'Ingeniería en Industrias Alimentarias',
    'Ingeniería Industrial', 'Ingeniería en Innovación Agrícola Sustentable', 'Ingeniería Mecatrónica',
    'Ingeniería Informática', 'Licenciatura en Administración', 'Licenciatura en Biología', 'Ingeniería Química'
  ];

  final _domicilioCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoPersonalCtrl = TextEditingController();
  final _correoInstCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // --- Nuevos campos de formulario (Específicos para Profesores) ---
  final _paternoCtrl = TextEditingController();
  final _maternoCtrl = TextEditingController();
  final _lugarNacCtrl = TextEditingController();
  String? _estadoCivilSeleccionado;
  final _domicilioActualCtrl = TextEditingController();
  final _coloniaCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _localidadCtrl = TextEditingController();
  final _entidadCtrl = TextEditingController();

  // Configuración de Supabase Admin
  final String _supabaseUrl = 'https://slrcguaqmlftohfmzzkt.supabase.co';
  final String _serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNscmNndWFxbWxmdG9oZm16emt0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzQ4Mzk2MSwiZXhwIjoyMDkzMDU5OTYxfQ.9rvVIhhiVv73Osiv5cdC5UGrydRhM5q5XsvusyuU32A';

  @override
  void initState() {
    super.initState();
    _cargarDirectorio(); // Cargar la tabla al iniciar
  }

  // --- FUNCIONES DEL DIRECTORIO (CARGA, FILTRADO Y ELIMINACIÓN) ---
  Future<void> _cargarDirectorio() async {
    setState(() => _cargandoDirectorio = true);
    try {
      final responseCoord = await Supabase.instance.client.from('coordinadores').select('numero_nomina, id_auth, nombres, apellidos, telefono, correo_institucional');
      final responseProf = await Supabase.instance.client.from('profesores').select('numero_nomina, id_auth, nombres, apellido_paterno, apellido_materno, telefono, correo_institucional');

      List<Map<String, dynamic>> personal = [];
      
      for(var c in responseCoord) {
        personal.add({
          'id_auth': c['id_auth'],
          'nomina': c['numero_nomina'],
          'tipo': 'Coordinador',
          'nombre': '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim(),
          'telefono': c['telefono'] ?? 'Sin registro',
          'correo': c['correo_institucional'] ?? 'Sin registro',
        });
      }

      for(var p in responseProf) {
        personal.add({
          'id_auth': p['id_auth'],
          'nomina': p['numero_nomina'],
          'tipo': 'Profesor',
          'nombre': '${p['nombres'] ?? ''} ${p['apellido_paterno'] ?? ''} ${p['apellido_materno'] ?? ''}'.trim(),
          'telefono': p['telefono'] ?? 'Sin registro',
          'correo': p['correo_institucional'] ?? 'Sin registro',
        });
      }

      setState(() {
        _totCoord = responseCoord.length;
        _totProf = responseProf.length;
        _directorioCompleto = personal;
      });
      _aplicarFiltros();
    } catch (e) {
      _mensaje('Error al cargar directorio: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _cargandoDirectorio = false);
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _directorioFiltrado = _directorioCompleto.where((p) {
        final coincideRol = _filtroRol == 'Todos' || p['tipo'] == _filtroRol;
        final coincideTexto = p['nombre'].toLowerCase().contains(_filtroTexto.toLowerCase()) || 
                              p['correo'].toLowerCase().contains(_filtroTexto.toLowerCase()) ||
                              p['nomina'].toLowerCase().contains(_filtroTexto.toLowerCase());
        return coincideRol && coincideTexto;
      }).toList();
    });
  }

  Future<void> _confirmarEliminacion(Map<String, dynamic> usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text('Confirmar Eliminación')]),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente a:\n\n${usuario['nombre']} (${usuario['tipo']})?\n\nSe borrará su registro y su acceso al sistema de forma irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, Eliminar Definitivamente', style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );

    if (confirmar == true) {
      _ejecutarEliminacion(usuario);
    }
  }

  Future<void> _ejecutarEliminacion(Map<String, dynamic> usuario) async {
    setState(() => _cargandoDirectorio = true);
    final adminClient = SupabaseClient(_supabaseUrl, _serviceRoleKey);
    
    try {
      // 1. Borrar de la tabla pública
      final tabla = usuario['tipo'] == 'Coordinador' ? 'coordinadores' : 'profesores';
      await Supabase.instance.client.from(tabla).delete().eq('numero_nomina', usuario['nomina']);
      
      // 2. Borrar del sistema de Auth
      if (usuario['id_auth'] != null) {
        await adminClient.auth.admin.deleteUser(usuario['id_auth']);
      }
      
      _mensaje('${usuario['tipo']} eliminado exitosamente.', Colors.green);
      await _cargarDirectorio(); // Recargar la tabla completa
    } catch (e) {
      _mensaje('Error al eliminar: $e', Colors.red);
      setState(() => _cargandoDirectorio = false);
    } finally {
      adminClient.dispose();
    }
  }

  // --- FUNCIÓN DE GUARDADO (ALTA) ---
  Future<void> _guardarPersonal() async {
    if (_nominaCtrl.text.isEmpty || _correoInstCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _mensaje('Nómina, Correo Institucional y Contraseña son obligatorios.', Colors.red);
      return;
    }
    if (_tipoPersonal == 'coordinador' && _deptoSeleccionado == null) {
      _mensaje('El Departamento que Coordina es obligatorio.', Colors.red);
      return;
    }

    setState(() => _cargando = true);
    final adminClient = SupabaseClient(_supabaseUrl, _serviceRoleKey);

    try {
      final authRes = await adminClient.auth.admin.createUser(
        AdminUserAttributes(email: _correoInstCtrl.text.trim(), password: _passCtrl.text.trim(), emailConfirm: true),
      );

      final nuevoIdAuth = authRes.user!.id;

      if (_tipoPersonal == 'coordinador') {
        await Supabase.instance.client.from('coordinadores').insert({
          'numero_nomina': _nominaCtrl.text.trim(),
          'nombres': _nombresCtrl.text.trim(),
          'apellidos': _apellidosCtrl.text.trim(),
          'curp': _curpCtrl.text.trim(),
          'rfc': _rfcCtrl.text.trim(),
          'fecha_nacimiento': _fechaNacCtrl.text.isEmpty ? null : _fechaNacCtrl.text.trim(),
          'sexo': _sexoSeleccionado,
          'domicilio_completo': _domicilioCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'correo_personal': _correoPersonalCtrl.text.trim(),
          'departamento_coordina': _deptoSeleccionado,
          'correo_institucional': _correoInstCtrl.text.trim(),
          'id_auth': nuevoIdAuth,
        });
        _mensaje('Coordinador creado y vinculado exitosamente.', Colors.green);
      } else {
        await Supabase.instance.client.from('profesores').insert({
          'numero_nomina': _nominaCtrl.text.trim(),
          'nombres': _nombresCtrl.text.trim(),
          'apellido_paterno': _paternoCtrl.text.trim(),
          'apellido_materno': _maternoCtrl.text.trim(),
          'curp': _curpCtrl.text.trim(),
          'rfc': _rfcCtrl.text.trim(),
          'lugar_nacimiento': _lugarNacCtrl.text.trim(),
          'fecha_nacimiento': _fechaNacCtrl.text.isEmpty ? null : _fechaNacCtrl.text.trim(),
          'sexo': _sexoSeleccionado,
          'estado_civil': _estadoCivilSeleccionado,
          'domicilio_actual': _domicilioActualCtrl.text.trim(),
          'colonia': _coloniaCtrl.text.trim(),
          'codigo_postal': _cpCtrl.text.trim(),
          'localidad': _localidadCtrl.text.trim(),
          'entidad_federativa': _entidadCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'correo_personal': _correoPersonalCtrl.text.trim(),
          'correo_institucional': _correoInstCtrl.text.trim(),
          'id_auth': nuevoIdAuth,
        });
        _mensaje('Profesor creado y vinculado exitosamente.', Colors.green);
      }

      _limpiarFormulario();
      _cargarDirectorio(); // Actualizamos la lista silenciosamente
    } on AuthException catch (ae) {
      _mensaje('Error de Autenticación: ${ae.message}', Colors.red);
    } catch (e) {
      _mensaje('Error al guardar en BD: $e', Colors.red);
    } finally {
      adminClient.dispose();
      setState(() => _cargando = false);
    }
  }

  void _limpiarFormulario() {
    _nominaCtrl.clear(); _nombresCtrl.clear(); _apellidosCtrl.clear();
    _curpCtrl.clear(); _rfcCtrl.clear(); _fechaNacCtrl.clear();
    _domicilioCtrl.clear(); _telefonoCtrl.clear(); _correoPersonalCtrl.clear();
    _correoInstCtrl.clear(); _passCtrl.clear();
    _paternoCtrl.clear(); _maternoCtrl.clear(); _lugarNacCtrl.clear();
    _domicilioActualCtrl.clear(); _coloniaCtrl.clear(); _cpCtrl.clear();
    _localidadCtrl.clear(); _entidadCtrl.clear();
    setState(() {
      _sexoSeleccionado = null;
      _deptoSeleccionado = null;
      _estadoCivilSeleccionado = null;
    });
  }

  void _mensaje(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    final List<SiiNavTab> adminTabs = [
      const SiiNavTab(label: 'Inicio', icon: Icons.admin_panel_settings),
      const SiiNavTab(label: 'Alta de Personal', icon: Icons.person_add),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SiiNavbar(
        titulo: 'SII - ADMINISTRACIÓN CENTRAL',
        tabs: adminTabs,
        indexSeleccionado: _tabActiva,
        onTabSelected: (idx) {
          setState(() => _tabActiva = idx);
          if (idx == 0 || idx == 2) _cargarDirectorio(); // Recarga los datos al volver al inicio
        },
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) Navigator.pop(context);
        },
      ),
      body: _cargando 
          ? const Center(child: CircularProgressIndicator()) 
          : _tabActiva == 1 
              ? _buildFormularioAlta() 
              : _buildInicio(),
    );
  }

  // --- PANTALLA PRINCIPAL CON FILTROS ---
  Widget _buildInicio() {
    if (_cargandoDirectorio) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Panel de Administración Central', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 30),
          
          Row(
            children: [
              _resumenCard('Coordinadores', _totCoord.toString(), Colors.orange, Icons.manage_accounts),
              const SizedBox(width: 20),
              _resumenCard('Profesores', _totProf.toString(), Colors.green, Icons.school),
              const SizedBox(width: 20),
              _resumenCard('Total de Personal', (_totCoord + _totProf).toString(), Colors.blue, Icons.groups),
            ],
          ),
          const SizedBox(height: 40),

          // --- BARRA DE FILTROS ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Buscar por Nombre, Correo o Nómina...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                    onChanged: (val) {
                      _filtroTexto = val;
                      _aplicarFiltros();
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _filtroRol,
                    decoration: const InputDecoration(labelText: 'Filtrar por Rol', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Coordinador', child: Text('Coordinadores')),
                      DropdownMenuItem(value: 'Profesor', child: Text('Profesores')),
                    ],
                    onChanged: (val) {
                      setState(() => _filtroRol = val!);
                      _aplicarFiltros();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // --- TABLA DE DATOS ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: _directorioFiltrado.isEmpty 
                ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No se encontraron resultados.')))
                : DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nómina', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre Completo', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Correo Institucional', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _directorioFiltrado.map((p) => DataRow(cells: [
                      DataCell(Chip(
                        label: Text(p['tipo'], style: TextStyle(color: p['tipo'] == 'Coordinador' ? Colors.orange.shade800 : Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: p['tipo'] == 'Coordinador' ? Colors.orange.shade100 : Colors.green.shade100,
                        side: BorderSide.none,
                      )),
                      DataCell(Text(p['nomina'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                      DataCell(Text(p['nombre'])),
                      DataCell(Text(p['correo'])),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar Usuario',
                        onPressed: () => _confirmarEliminacion(p),
                      )),
                    ])).toList(),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN: ALTA DE PERSONAL ---
  Widget _buildFormularioAlta() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ficha de Registro de Personal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                  const Divider(height: 30),

                  Row(
                    children: [
                      const Text('Tipo de personal a registrar: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: _tipoPersonal,
                        items: const [
                          DropdownMenuItem(value: 'coordinador', child: Text('Coordinador Institucional')),
                          DropdownMenuItem(value: 'profesor', child: Text('Profesor Docente')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _tipoPersonal = val!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _seccionTitulo('1. Credenciales de Acceso'),
                  Row(
                    children: [
                      Expanded(child: _campo('Correo Institucional', _correoInstCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Contraseña', _passCtrl, oculto: true)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _seccionTitulo('2. Datos Personales'),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _campo('Número de Nómina', _nominaCtrl)),
                      const SizedBox(width: 15),
                      Expanded(flex: 3, child: _campo('Nombres', _nombresCtrl)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  if (_tipoPersonal == 'coordinador')
                    _campo('Apellidos Completos', _apellidosCtrl)
                  else
                    Row(
                      children: [
                        Expanded(child: _campo('Apellido Paterno', _paternoCtrl)),
                        const SizedBox(width: 15),
                        Expanded(child: _campo('Apellido Materno', _maternoCtrl)),
                      ],
                    ),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(child: _campo('Fecha de Nacimiento (YYYY-MM-DD)', _fechaNacCtrl, hint: 'Ej: 1980-05-24')),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sexoSeleccionado,
                          decoration: const InputDecoration(labelText: 'Sexo', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                            DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                          ],
                          onChanged: (val) => setState(() => _sexoSeleccionado = val),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_tipoPersonal == 'profesor') ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _campo('Lugar de Nacimiento', _lugarNacCtrl)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _estadoCivilSeleccionado,
                            decoration: const InputDecoration(labelText: 'Estado Civil', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'Soltero(a)', child: Text('Soltero(a)')),
                              DropdownMenuItem(value: 'Casado(a)', child: Text('Casado(a)')),
                              DropdownMenuItem(value: 'Divorciado(a)', child: Text('Divorciado(a)')),
                              DropdownMenuItem(value: 'Viudo(a)', child: Text('Viudo(a)')),
                            ],
                            onChanged: (val) => setState(() => _estadoCivilSeleccionado = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 30),

                  _seccionTitulo('3. Identificación y Contacto'),
                  Row(
                    children: [
                      Expanded(child: _campo('CURP', _curpCtrl, maxLength: 18)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('RFC', _rfcCtrl, maxLength: 13)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  if (_tipoPersonal == 'coordinador')
                    _campo('Domicilio Completo', _domicilioCtrl)
                  else ...[
                    Row(
                      children: [
                        Expanded(flex: 2, child: _campo('Domicilio Actual (Calle y Número)', _domicilioActualCtrl)),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: _campo('Colonia', _coloniaCtrl)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _campo('Código Postal', _cpCtrl, maxLength: 5)),
                        const SizedBox(width: 15),
                        Expanded(child: _campo('Localidad/Ciudad', _localidadCtrl)),
                        const SizedBox(width: 15),
                        Expanded(child: _campo('Entidad Federativa', _entidadCtrl)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(child: _campo('Teléfono', _telefonoCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Correo Personal', _correoPersonalCtrl)),
                    ],
                  ),

                  if (_tipoPersonal == 'coordinador') ...[
                    const SizedBox(height: 30),
                    _seccionTitulo('4. Datos Laborales'),
                    DropdownButtonFormField<String>(
                      value: _deptoSeleccionado,
                      isExpanded: true, 
                      decoration: const InputDecoration(
                        labelText: 'Departamento que Coordina', 
                        border: OutlineInputBorder(), 
                        filled: true, 
                        fillColor: Colors.white
                      ),
                      items: _departamentos.map((String depto) {
                        return DropdownMenuItem<String>(
                          value: depto,
                          child: Text(depto, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _deptoSeleccionado = val),
                    ),
                  ],

                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _guardarPersonal,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), shape: const StadiumBorder()),
                      child: Text(
                        _tipoPersonal == 'coordinador' ? 'REGISTRAR COORDINADOR' : 'REGISTRAR PROFESOR', 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES VISUALES ---
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

  Widget _seccionTitulo(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _campo(String label, TextEditingController ctrl, {bool oculto = false, String? hint, int? maxLength}) => TextFormField(
    controller: ctrl,
    obscureText: oculto,
    maxLength: maxLength,
    decoration: InputDecoration(
      labelText: label, 
      hintText: hint,
      counterText: "", 
      border: const OutlineInputBorder(), 
      filled: true, 
      fillColor: Colors.white
    ),
  );
}