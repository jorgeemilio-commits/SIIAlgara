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

  // Variable para alternar entre perfiles
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

  // --- FUNCIÓN PARA EXTRAER LA LISTA DEL PERSONAL ---
  Future<Map<String, dynamic>> _fetchResumen() async {
    final responseCoord = await Supabase.instance.client.from('coordinadores').select('nombres, apellidos, telefono, correo_institucional');
    final responseProf = await Supabase.instance.client.from('profesores').select('nombres, apellido_paterno, apellido_materno, telefono, correo_institucional');

    List<Map<String, dynamic>> personal = [];
    
    // Agregamos coordinadores a la lista combinada
    for(var c in responseCoord) {
      personal.add({
        'tipo': 'Coordinador',
        'nombre': '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim(),
        'telefono': c['telefono'] ?? 'Sin registro',
        'correo': c['correo_institucional'] ?? 'Sin registro',
      });
    }

    // Agregamos profesores a la lista combinada
    for(var p in responseProf) {
      personal.add({
        'tipo': 'Profesor',
        'nombre': '${p['nombres'] ?? ''} ${p['apellido_paterno'] ?? ''} ${p['apellido_materno'] ?? ''}'.trim(),
        'telefono': p['telefono'] ?? 'Sin registro',
        'correo': p['correo_institucional'] ?? 'Sin registro',
      });
    }

    return {
      'total_coordinadores': responseCoord.length,
      'total_profesores': responseProf.length,
      'lista': personal,
    };
  }

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
        AdminUserAttributes(
          email: _correoInstCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          emailConfirm: true,
        ),
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
      const SiiNavTab(label: 'Directorio', icon: Icons.badge),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SiiNavbar(
        titulo: 'SII - ADMINISTRACIÓN CENTRAL',
        tabs: adminTabs,
        indexSeleccionado: _tabActiva,
        onTabSelected: (idx) => setState(() => _tabActiva = idx),
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) Navigator.pop(context);
        },
      ),
      // --- LÓGICA DE NAVEGACIÓN ---
      body: _cargando 
          ? const Center(child: CircularProgressIndicator()) 
          : _tabActiva == 1 
              ? _buildFormularioAlta() 
              : _buildInicio(), // Se muestra en 'Inicio' y en 'Directorio'
    );
  }

  // --- SECCIÓN: PANTALLA PRINCIPAL / DIRECTORIO ---
  Widget _buildInicio() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchResumen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final int totCoord = data['total_coordinadores'];
        final int totProf = data['total_profesores'];
        final List<Map<String, dynamic>> lista = data['lista'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Panel de Administración Central', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
              const SizedBox(height: 30),
              
              // Tarjetas de Resumen
              Row(
                children: [
                  _resumenCard('Coordinadores', totCoord.toString(), Colors.orange, Icons.manage_accounts),
                  const SizedBox(width: 20),
                  _resumenCard('Profesores', totProf.toString(), Colors.green, Icons.school),
                  const SizedBox(width: 20),
                  _resumenCard('Total de Personal', (totCoord + totProf).toString(), Colors.blue, Icons.groups),
                ],
              ),
              const SizedBox(height: 40),

              const Text('Directorio Institucional', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
              const SizedBox(height: 20),
              
              // Tabla del Personal
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: lista.isEmpty 
                    ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No hay personal registrado aún.')))
                    : DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Nombre Completo', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Correo Institucional', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: lista.map((p) => DataRow(cells: [
                          DataCell(Chip(
                            label: Text(p['tipo'], style: TextStyle(color: p['tipo'] == 'Coordinador' ? Colors.orange.shade800 : Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                            backgroundColor: p['tipo'] == 'Coordinador' ? Colors.orange.shade100 : Colors.green.shade100,
                            side: BorderSide.none,
                          )),
                          DataCell(Text(p['nombre'])),
                          DataCell(Text(p['telefono'])),
                          DataCell(Text(p['correo'])),
                        ])).toList(),
                      ),
                ),
              ),
            ],
          ),
        );
      }
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