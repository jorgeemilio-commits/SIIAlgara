import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

class AspiranteFormulario extends StatefulWidget {
  const AspiranteFormulario({super.key});

  @override
  State<AspiranteFormulario> createState() => _AspiranteFormularioState();
}

class _AspiranteFormularioState extends State<AspiranteFormulario> {
  // --- VARIABLES DE CONTROL ---
  bool _cargandoInicial = true; 
  bool _tieneRegistro = false;
  bool _enviando = false;
  
  String _folioAsignado = '';
  String? _urlCertificado; // Guarda la URL para poder VER el documento después

  // Controladores de Datos Personales
  final _nombresCtrl = TextEditingController(text: 'Jorge Emilio');
  final _paternoCtrl = TextEditingController(text: 'Chávez');
  final _maternoCtrl = TextEditingController(text: 'Lizárraga');
  final _curpCtrl = TextEditingController(text: 'CHLJ010203HSRL01');
  final _fechaNacCtrl = TextEditingController(text: '2001-02-03');
  final _correoPersonalCtrl = TextEditingController(text: 'test@email.com');
  final _telefonoCtrl = TextEditingController(text: '6681234567');
  final _promedioCtrl = TextEditingController(text: '92.50');

  // Controladores de Dirección
  final _calleCtrl = TextEditingController(text: 'Conocido #123');
  final _coloniaCtrl = TextEditingController(text: 'Centro');
  final _cpCtrl = TextEditingController(text: '81200');
  final _localidadCtrl = TextEditingController(text: 'Los Mochis');
  String? _entidadSeleccionada = 'Sinaloa';

  // Variable para guardar el archivo temporalmente antes de enviar
  PlatformFile? _certificadoFile;

  final List<String> _carreras = [
    'Arquitectura', 'Contador Público', 'Ingeniería Bioquímica', 'Ingeniería Electromecánica',
    'Ingeniería Electrónica', 'Ingeniería en Gestión Empresarial', 'Ingeniería en Industrias Alimentarias',
    'Ingeniería Industrial', 'Ingeniería en Innovación Agrícola Sustentable', 'Ingeniería Mecatrónica',
    'Ingeniería Informática', 'Licenciatura en Administración', 'Licenciatura en Biología', 'Ingeniería Química'
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

  // --- LÓGICA: VERIFICAR SI YA SE ENVIÓ LA SOLICITUD ---
  Future<void> _verificarRegistroPrevio() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client.from('aspirantes').select().eq('id_auth', user.id).maybeSingle();
        
        if (data != null) {
          // Si ya hay datos, los cargamos para mostrarlos en el resumen (modo lectura)
          _folioAsignado = data['folio_aspirante'];
          _carreraSeleccionada = data['carrera_solicitada'];
          _urlCertificado = data['url_certificado'];
          
          _nombresCtrl.text = data['nombres'] ?? '';
          _paternoCtrl.text = data['apellido_paterno'] ?? '';
          _maternoCtrl.text = data['apellido_materno'] ?? '';
          _curpCtrl.text = data['curp'] ?? '';
          _calleCtrl.text = data['domicilio_actual'] ?? '';
          _coloniaCtrl.text = data['colonia'] ?? '';
          _telefonoCtrl.text = data['telefono'] ?? '';
          _correoPersonalCtrl.text = data['correo_personal'] ?? '';
          
          _tieneRegistro = true; 
        }
      } catch (e) {
        debugPrint('Error al consultar: $e');
      }
    }
    if (mounted) setState(() => _cargandoInicial = false);
  }

  // --- SECCIÓN: SELECCIÓN LOCAL DEL ARCHIVO (Solo al crear la solicitud) ---
  Future<void> _seleccionarCertificado() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _certificadoFile = result.files.first);
    }
  }

  // --- SECCIÓN: VER EL DOCUMENTO YA SUBIDO (Solo lectura) ---
  void _verCertificado() {
    if (_urlCertificado != null && _urlCertificado!.isNotEmpty) {
      if (kIsWeb) {
        web.window.open(_urlCertificado!, '_blank');
      } else {
        debugPrint('Abriendo URL: $_urlCertificado');
      }
    }
  }

  // --- LÓGICA: ENVIAR FORMULARIO A LA BASE DE DATOS ---
  Future<void> _enviarSolicitud() async {
    setState(() => _enviando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final tempFolio = 'ASP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      String? urlGenerada;

      // 1. Subimos el archivo si se adjuntó uno
      if (_certificadoFile != null) {
        final path = 'certificados/${tempFolio}_certificado.pdf';
        final storage = Supabase.instance.client.storage.from('documentos_aspirantes');
        
        if (kIsWeb) {
          await storage.uploadBinary(path, _certificadoFile!.bytes!, fileOptions: const FileOptions(upsert: true));
        } else {
          await storage.upload(path, File(_certificadoFile!.path!), fileOptions: const FileOptions(upsert: true));
        }
        urlGenerada = storage.getPublicUrl(path);
      }

      // 2. Guardamos toda la información en la tabla aspirantes
      await Supabase.instance.client.from('aspirantes').insert({
        'folio_aspirante': tempFolio,
        'nombres': _nombresCtrl.text,
        'apellido_paterno': _paternoCtrl.text,
        'apellido_materno': _maternoCtrl.text,
        'curp': _curpCtrl.text,
        'fecha_nacimiento': _fechaNacCtrl.text,
        'correo_personal': _correoPersonalCtrl.text,
        'telefono': _telefonoCtrl.text,
        'domicilio_actual': _calleCtrl.text,
        'colonia': _coloniaCtrl.text,
        'codigo_postal': _cpCtrl.text,
        'localidad': _localidadCtrl.text,
        'entidad_federativa': _entidadSeleccionada,
        'carrera_solicitada': _carreraSeleccionada,
        'promedio_preparatoria': double.tryParse(_promedioCtrl.text),
        'url_certificado': urlGenerada, // Guardamos la URL para poder verla después
        'id_auth': user?.id,
      });

      setState(() {
        _folioAsignado = tempFolio;
        _urlCertificado = urlGenerada;
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
          // Control de vista: Si ya tiene registro muestra resumen, sino, el formulario
          : _tieneRegistro ? _vistaEstatus() : _vistaFormulario(),
      ),
    );
  }

  // ==========================================================
  // VISTA 1: CREAR SOLICITUD (FORMULARIO EDITABLE)
  // ==========================================================
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
                  
                  // -- DATOS PERSONALES --
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
                  
                  // -- DATOS DE CONTACTO --
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

                  // -- ACADÉMICO Y DOCUMENTO --
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
                  
                  // CAJA DE SELECCIÓN DE DOCUMENTO (Solo permite Seleccionar o Eliminar)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                    child: Row(
                      children: [
                        if (_certificadoFile == null) ...[
                          ElevatedButton.icon(
                            onPressed: _seleccionarCertificado,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Adjuntar Certificado (PDF)'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(child: Text('Ningún archivo seleccionado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                        ] else ...[
                          const Icon(Icons.picture_as_pdf, color: Colors.green, size: 30),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Seleccionado: ${_certificadoFile!.name}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          TextButton.icon(
                            // BOTÓN DE ELIMINAR PARA PERMITIR CAMBIAR DE ARCHIVO ANTES DE ENVIAR
                            onPressed: () => setState(() => _certificadoFile = null),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ]
                      ],
                    ),
                  ),

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

  // ==========================================================
  // VISTA 2: ESTATUS DE SOLICITUD (SOLO LECTURA)
  // ==========================================================
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: Icon(Icons.verified_user, size: 80, color: Colors.green)),
                  const SizedBox(height: 20),
                  const Center(child: Text('¡Solicitud Confirmada!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green))),
                  const SizedBox(height: 10),
                  const Center(child: Text('Tus datos están registrados y en proceso de revisión. Ya no es posible modificarlos.', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center)),
                  const SizedBox(height: 30),
                  
                  // PANEL DE RESUMEN DE DATOS
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Folio: $_folioAsignado', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                            const Chip(label: Text('EN PROCESO'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 30),
                        _filaResumen('Aspirante:', '${_nombresCtrl.text} ${_paternoCtrl.text} ${_maternoCtrl.text}'),
                        _filaResumen('CURP:', _curpCtrl.text),
                        _filaResumen('Carrera Solicitada:', _carreraSeleccionada ?? 'N/A'),
                        _filaResumen('Contacto:', '${_telefonoCtrl.text} | ${_correoPersonalCtrl.text}'),
                        _filaResumen('Domicilio:', '${_calleCtrl.text}, ${_coloniaCtrl.text}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  const Text('Documentación Oficial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                  const SizedBox(height: 15),
                  
                  // CAJA DE DOCUMENTO REMOTO (SOLO VER, SIN REEMPLAZAR NI ELIMINAR)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: _urlCertificado != null && _urlCertificado!.isNotEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.green, size: 30),
                                SizedBox(width: 10),
                                Text('Certificado_Preparatoria.pdf', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _verCertificado,
                              icon: const Icon(Icons.visibility, color: Color(0xFF003366)),
                              label: const Text('Ver Documento', style: TextStyle(color: Color(0xFF003366))),
                            )
                          ],
                        )
                      : const Text('No adjuntaste ningún certificado durante tu registro.', style: TextStyle(color: Colors.red)),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 45,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Cerrar Sesión'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade700)),
                        onPressed: _cerrarSesion,
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

  // Widget auxiliar para los campos editables
  Widget _campo(String label, TextEditingController ctrl) => TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));

  // Widget auxiliar para mostrar los datos en modo lectura
  Widget _filaResumen(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
          Expanded(child: Text(valor, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}