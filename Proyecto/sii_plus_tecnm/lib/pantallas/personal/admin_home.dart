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

  // --- CONTROLADORES PARA TODOS LOS CAMPOS SQL ---
  final _nominaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _curpCtrl = TextEditingController();
  final _rfcCtrl = TextEditingController();
  final _fechaNacCtrl = TextEditingController(); // Formato YYYY-MM-DD
  String? _sexoSeleccionado;
  final _domicilioCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoPersonalCtrl = TextEditingController();
  final _deptoCoordCtrl = TextEditingController();
  final _oficinaCtrl = TextEditingController();
  final _extensionCtrl = TextEditingController();
  
  // Credenciales Auth
  final _correoInstCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // ATENCIÓN: Reemplaza esto con tus credenciales de Supabase
  final String _supabaseUrl = 'https://TU-URL-DE-SUPABASE.supabase.co';
  final String _serviceRoleKey = 'TU-SERVICE-ROLE-KEY';

  Future<void> _guardarCoordinador() async {
    if (_nominaCtrl.text.isEmpty || _correoInstCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _mensaje('Nómina, Correo Institucional y Contraseña son obligatorios.', Colors.red);
      return;
    }

    setState(() => _cargando = true);
    
    // 1. Cliente temporal con privilegios de Administrador para Auth
    final adminClient = SupabaseClient(_supabaseUrl, _serviceRoleKey);

    try {
      // 2. Crear usuario en Authentication
      final authRes = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: _correoInstCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          emailConfirm: true,
        ),
      );

      final nuevoIdAuth = authRes.user!.id;

      // 3. Insertar TODOS los campos en la tabla de coordinadores
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
        'departamento_coordina': _deptoCoordCtrl.text.trim(),
        'oficina_atencion': _oficinaCtrl.text.trim(),
        'extension_telefonica': _extensionCtrl.text.trim(),
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

  void _limpiarFormulario() {
    _nominaCtrl.clear(); _nombresCtrl.clear(); _apellidosCtrl.clear();
    _curpCtrl.clear(); _rfcCtrl.clear(); _fechaNacCtrl.clear();
    _domicilioCtrl.clear(); _telefonoCtrl.clear(); _correoPersonalCtrl.clear();
    _deptoCoordCtrl.clear(); _oficinaCtrl.clear(); _extensionCtrl.clear();
    _correoInstCtrl.clear(); _passCtrl.clear();
    setState(() => _sexoSeleccionado = null);
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
                  const Text('Ficha de Registro Completa: Coordinador', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
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

                  _seccionTitulo('2. Datos Personales Básicos'),
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
                            DropdownMenuItem(value: 'Otro', child: Text('Otro')),
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
                      Expanded(child: _campo('Correo Electrónico Personal', _correoPersonalCtrl)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _seccionTitulo('4. Datos Laborales'),
                  Row(
                    children: [
                      Expanded(child: _campo('Departamento que Coordina', _deptoCoordCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Oficina de Atención', _oficinaCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _campo('Extensión Telefónica', _extensionCtrl)),
                    ],
                  ),

                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _guardarCoordinador,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), shape: const StadiumBorder()),
                      child: const Text('CREAR ACCESO Y GUARDAR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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