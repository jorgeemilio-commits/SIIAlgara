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

  // --- Campos de formulario ---
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
  final _extensionCtrl = TextEditingController();
  final _correoInstCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

// Configuración de Supabase Admin
  final String _supabaseUrl = 'https://slrcguaqmlftohfmzzkt.supabase.co';
  final String _serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNscmNndWFxbWxmdG9oZm16emt0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzQ4Mzk2MSwiZXhwIjoyMDkzMDU5OTYxfQ.9rvVIhhiVv73Osiv5cdC5UGrydRhM5q5XsvusyuU32A';

  Future<void> _guardarCoordinador() async {
    if (_nominaCtrl.text.isEmpty || _correoInstCtrl.text.isEmpty || _passCtrl.text.isEmpty || _deptoSeleccionado == null) {
      _mensaje('Nómina, Correo Institucional, Contraseña y Departamento son obligatorios.', Colors.red);
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

// Insertamos el nuevo coordinador en la tabla 'coordinadores' con el ID de autenticación
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

// Limpia todos los campos del formulario y resetea las selecciones
  void _limpiarFormulario() {
    _nominaCtrl.clear(); _nombresCtrl.clear(); _apellidosCtrl.clear();
    _curpCtrl.clear(); _rfcCtrl.clear(); _fechaNacCtrl.clear();
    _domicilioCtrl.clear(); _telefonoCtrl.clear(); _correoPersonalCtrl.clear();
    _correoInstCtrl.clear(); _passCtrl.clear();
    setState(() {
      _sexoSeleccionado = null;
      _deptoSeleccionado = null;
    });
  }

  void _mensaje(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    final List<SiiNavTab> adminTabs = [
      const SiiNavTab(label: 'Inicio', icon: Icons.admin_panel_settings),
      const SiiNavTab(label: 'Alta Coordinadores', icon: Icons.person_add),
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
      body: _cargando 
          ? const Center(child: CircularProgressIndicator()) 
          : _tabActiva == 1 ? _buildFormularioAlta() : const Center(child: Text('Sección Administrativa')),
    );
  }

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
                  const Text('Ficha de Registro: Coordinador', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                  const Divider(height: 40),

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
                      Expanded(child: _campo('Número de Nómina', _nominaCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Nombres', _nombresCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Apellidos', _apellidosCtrl)),
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
                  _campo('Domicilio Completo', _domicilioCtrl),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _campo('Teléfono', _telefonoCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Correo Personal', _correoPersonalCtrl)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _seccionTitulo('4. Datos Laborales'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _deptoSeleccionado,
                          isExpanded: true, // Asegura que el texto largo no se corte
                          decoration: const InputDecoration(labelText: 'Departamento que Coordina', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                          items: _departamentos.map((String depto) {
                            return DropdownMenuItem<String>(
                              value: depto,
                              child: Text(depto, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _deptoSeleccionado = val),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _guardarCoordinador,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), shape: const StadiumBorder()),
                      child: const Text('REGISTRAR COORDINADOR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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