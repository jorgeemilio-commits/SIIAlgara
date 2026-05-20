import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AspiranteFormulario extends StatefulWidget {
  const AspiranteFormulario({super.key});

  @override
  State<AspiranteFormulario> createState() => _AspiranteFormularioState();
}

class _AspiranteFormularioState extends State<AspiranteFormulario> {
  bool _cargandoInicial = true; 
  bool _tieneRegistro = false;
  bool _enviando = false;
  
  String _folioAsignado = '';

  // --- CONTROLADORES ORIGINALES ---
  final _nombresCtrl = TextEditingController(text: 'Jorge Emilio');
  final _paternoCtrl = TextEditingController(text: 'Chávez');
  final _maternoCtrl = TextEditingController(text: 'Lizárraga');
  final _curpCtrl = TextEditingController(text: 'CHLJ010203HSRL01');
  final _fechaNacCtrl = TextEditingController(text: '2001-02-03');
  final _correoPersonalCtrl = TextEditingController(text: 'test@email.com');
  final _telefonoCtrl = TextEditingController(text: '6681234567');
  final _promedioCtrl = TextEditingController(text: '92.50');

  // --- NUEVOS CONTROLADORES (Dirección) ---
  final _calleCtrl = TextEditingController(text: 'Conocido #123');
  final _coloniaCtrl = TextEditingController(text: 'Centro');
  final _cpCtrl = TextEditingController(text: '81200');
  final _localidadCtrl = TextEditingController(text: 'Los Mochis');
  String? _entidadSeleccionada = 'Sinaloa';

  // --- VARIABLE PARA EL DOCUMENTO ---
  PlatformFile? _certificadoFile;

  final List<String> _carreras = [
    'Arquitectura', 'Contador Público', 'Ingeniería Bioquímica', 'Ingeniería Electromecánica',
    'Ingeniería Informática', 'Ingeniería Industrial', 'Ingeniería Mecatrónica',
  ];
  String? _carreraSeleccionada = 'Ingeniería Informática';

  final List<String> _entidades = ['Sinaloa', 'Sonora', 'Nayarit', 'Otro'];

  @override
  void initState() {
    super.initState();
    _verificarRegistroPrevio();
  }

  @override
  void dispose() {
    _nombresCtrl.dispose(); _paternoCtrl.dispose(); _maternoCtrl.dispose();
    _curpCtrl.dispose(); _fechaNacCtrl.dispose(); _correoPersonalCtrl.dispose();
    _telefonoCtrl.dispose(); _promedioCtrl.dispose();
    _calleCtrl.dispose(); _coloniaCtrl.dispose(); _cpCtrl.dispose(); _localidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarRegistroPrevio() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client.from('aspirantes').select().eq('id_auth', user.id).maybeSingle();
        if (data != null) {
          _folioAsignado = data['folio_aspirante'];
          _carreraSeleccionada = data['carrera_solicitada'];
          _tieneRegistro = true; 
        }
      } catch (e) {
        debugPrint('Error al consultar: $e');
      }
    }
    if (mounted) setState(() => _cargandoInicial = false);
  }

  // --- MÉTODO PARA SELECCIONAR EL ARCHIVO PDF ---
  Future<void> _seleccionarCertificado() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _certificadoFile = result.files.first);
    }
  }

  // --- MÉTODO PARA ENVIAR SOLICITUD (Con subida de archivo) ---
  Future<void> _enviarSolicitud() async {
    setState(() => _enviando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final tempFolio = 'ASP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      String? urlCertificado;

      // 1. Subir el archivo si fue seleccionado
      if (_certificadoFile != null) {
        final path = 'certificados/${tempFolio}_certificado.pdf';
        final storage = Supabase.instance.client.storage.from('documentos_aspirantes'); // Asegúrate de crear este bucket en Supabase
        
        if (kIsWeb) {
          await storage.uploadBinary(path, _certificadoFile!.bytes!, fileOptions: const FileOptions(upsert: true));
        } else {
          await storage.upload(path, File(_certificadoFile!.path!), fileOptions: const FileOptions(upsert: true));
        }
        urlCertificado = storage.getPublicUrl(path);
      }

      // 2. Insertar todos los datos en la tabla aspirantes
      await Supabase.instance.client.from('aspirantes').insert({
        'folio_aspirante': tempFolio,
        'nombres': _nombresCtrl.text,
        'apellido_paterno': _paternoCtrl.text,
        'apellido_materno': _maternoCtrl.text,
        'curp': _curpCtrl.text,
        'fecha_nacimiento': _fechaNacCtrl.text,
        'correo_personal': _correoPersonalCtrl.text,
        'telefono': _telefonoCtrl.text,
        
        // Nuevos campos de contacto
        'domicilio_actual': _calleCtrl.text,
        'colonia': _coloniaCtrl.text,
        'codigo_postal': _cpCtrl.text,
        'localidad': _localidadCtrl.text,
        'entidad_federativa': _entidadSeleccionada,

        // Datos académicos y documento
        'carrera_solicitada': _carreraSeleccionada,
        'promedio_preparatoria': double.tryParse(_promedioCtrl.text),
        'url_certificado': urlCertificado,
        'id_auth': user?.id,
      });

      setState(() {
        _folioAsignado = tempFolio;
        _tieneRegistro = true; 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Aspirante'),
        automaticallyImplyLeading: false, 
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion, tooltip: 'Cerrar Sesión')],
      ),
      body: Center(
        child: _cargandoInicial 
          ? const CircularProgressIndicator() 
          : _tieneRegistro ? _vistaEstatus() : _vistaFormulario(),
      ),
    );
  }

  Widget _vistaFormulario() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ficha de Registro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                  
                  // --- SECCIÓN 1: DATOS PERSONALES ---
                  const Divider(height: 40),
                  const Text('Datos Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _campo('Nombres', _nombresCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('A. Paterno', _paternoCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('A. Materno', _maternoCtrl)),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _campo('CURP', _curpCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Fecha Nac. (YYYY-MM-DD)', _fechaNacCtrl)),
                  ]),
                  
                  // --- SECCIÓN 2: DATOS DE CONTACTO ---
                  const Divider(height: 40),
                  const Text('Datos de Contacto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(flex: 2, child: _campo('Calle y Número', _calleCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Colonia', _coloniaCtrl)),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _campo('Código Postal', _cpCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Localidad/Ciudad', _localidadCtrl)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _entidadSeleccionada,
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                        items: _entidades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _entidadSeleccionada = val),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _campo('Teléfono', _telefonoCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Correo', _correoPersonalCtrl)),
                  ]),

                  // --- SECCIÓN 3: ACADÉMICO Y DOCUMENTOS (MODIFICADA) ---
                  const Divider(height: 40),
                  const Text('Datos Académicos y Documentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _carreraSeleccionada,
                        decoration: const InputDecoration(labelText: 'Carrera', border: OutlineInputBorder()),
                        items: _carreras.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _carreraSeleccionada = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Promedio', _promedioCtrl)),
                  ]),
                  const SizedBox(height: 20),
                  
                  // Botón para subir certificado
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _seleccionarCertificado,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Certificado de Preparatoria (PDF)'),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            _certificadoFile != null ? 'Seleccionado: ${_certificadoFile!.name}' : 'Ningún archivo seleccionado',
                            style: TextStyle(color: _certificadoFile != null ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- BOTÓN FINAL ---
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviarSolicitud,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                      child: _enviando ? const CircularProgressIndicator() : const Text('ENVIAR DATOS DE ADMISIÓN', style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _vistaEstatus() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text('¡Solicitud Confirmada!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  const Text('Tus datos ya están registrados en el sistema.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      children: [
                        Text('Folio asignado: $_folioAsignado', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                        const SizedBox(height: 10),
                        Text('Carrera solicitada: $_carreraSeleccionada', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        const Chip(label: Text('ESTATUS: EN PROCESO'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    height: 45,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Cerrar Sesión'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade700)),
                      onPressed: _cerrarSesion,
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

  Widget _campo(String label, TextEditingController ctrl) => TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
}