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
  
  // URLs de los documentos remotos guardados en Supabase
  String? _urlCertificado; 
  String? _urlActa;
  String? _urlCurp;
  String? _urlNss;

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

  // --- VARIABLES TEMPORALES PARA ARCHIVOS LOCALES ---
  PlatformFile? _certificadoFile;
  PlatformFile? _actaFile;
  PlatformFile? _curpFile;
  PlatformFile? _nssFile;

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
          _folioAsignado = data['folio_aspirante'];
          _carreraSeleccionada = data['carrera_solicitada'];
          
          // Recuperación de URLs de documentos desde la BD
          _urlCertificado = data['url_certificado'];
          _urlActa = data['url_acta_nacimiento'];
          _urlCurp = data['url_curp'];
          _urlNss = data['url_nss'];
          
          // Mapeo en modo lectura de los campos del formulario
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

  // --- SECCIÓN: SELECCIÓN LOCAL DE ARCHIVOS (Solo antes del envío) ---
  Future<PlatformFile?> _seleccionarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      return result.files.first;
    }
    return null;
  }

  // --- SECCIÓN: AUXILIAR DE SUBIDA DE ARCHIVOS A BUCKET ---
  Future<String?> _subirDocumentoBucket(String nombreArchivo, PlatformFile? file) async {
    if (file == null) return null;
    final path = 'certificados/$nombreArchivo.pdf';
    final storage = Supabase.instance.client.storage.from('documentos_aspirantes');
    
    if (kIsWeb) {
      await storage.uploadBinary(path, file.bytes!, fileOptions: const FileOptions(upsert: true));
    } else {
      await storage.upload(path, File(file.path!), fileOptions: const FileOptions(upsert: true));
    }
    return storage.getPublicUrl(path);
  }

  // --- LÓGICA: ENVIAR FORMULARIO E INYECTAR ARCHIVOS ---
  Future<void> _enviarSolicitud() async {
    setState(() => _enviando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final tempFolio = 'ASP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Proceso ordenado de subida de archivos individuales
      String? resCertificado = await _subirDocumentoBucket('${tempFolio}_certificado', _certificadoFile);
      String? resActa = await _subirDocumentoBucket('${tempFolio}_acta', _actaFile);
      String? resCurp = await _subirDocumentoBucket('${tempFolio}_curp', _curpFile);
      String? resNss = await _subirDocumentoBucket('${tempFolio}_nss', _nssFile);

      // Inserción masiva de los datos recabados en la tabla pública de aspirantes
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
        
        // Mapeo de URLs públicas generadas desde el bucket
        'url_certificado': resCertificado,
        'url_acta_nacimiento': resActa,
        'url_curp': resCurp,
        'url_nss': resNss,
        'id_auth': user?.id,
      });

      setState(() {
        _folioAsignado = tempFolio;
        _urlCertificado = resCertificado;
        _urlActa = resActa;
        _urlCurp = resCurp;
        _urlNss = resNss;
        _tieneRegistro = true; 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar la solicitud: $e'), backgroundColor: Colors.red));
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

  // ==========================================================
  // WIDGET AUXILIAR: Selector de Archivos (Para el formulario de edición)
  // ==========================================================
  Widget _constructorCajaArchivo({
    required String tituloBoton,
    required PlatformFile? archivoLocal,
    required VoidCallback alSeleccionar,
    required VoidCallback alEliminar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          if (archivoLocal == null) ...[
            ElevatedButton.icon(
              onPressed: alSeleccionar,
              icon: const Icon(Icons.upload_file),
              label: Text(tituloBoton),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
            ),
            const SizedBox(width: 15),
            const Expanded(child: Text('Ningún documento seleccionado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
          ] else ...[
            const Icon(Icons.picture_as_pdf, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text('Listo: ${archivoLocal.name}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            TextButton.icon(
              onPressed: alEliminar,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Quitar', style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
  }

  // ==========================================================
  // WIDGET AUXILIAR: Visor de Archivos (Para la pantalla de estatus congelada)
  // ==========================================================
  Widget _constructorVisorArchivo(String descriptorDocumento, String? urlRemota) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      child: urlRemota != null && urlRemota.isNotEmpty
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  Text(descriptorDocumento, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  if (kIsWeb) {
                    web.window.open(urlRemota, '_blank');
                  } else {
                    debugPrint('Visualizando: $urlRemota');
                  }
                },
                icon: const Icon(Icons.visibility, color: Color(0xFF003366)),
                label: const Text('Ver Documento', style: TextStyle(color: Color(0xFF003366))),
              )
            ],
          )
        : Text('No se adjuntó el archivo de: $descriptorDocumento', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

                  // -- ACADÉMICO Y DOCUMENTACIÓN --
                  const Divider(height: 40),
                  const Text('Datos Académicos y Documentación Requerida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _carreraSeleccionada,
                        decoration: const InputDecoration(labelText: 'Carrera a Solicitar', border: OutlineInputBorder()),
                        items: _carreras.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _carreraSeleccionada = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Promedio General', _promedioCtrl)),
                  ]),
                  const SizedBox(height: 25),
                  
                  // Componentes dinámicos de selección de archivos en fase de llenado
                  _constructorCajaArchivo(
                    tituloBoton: 'Certificado de Preparatoria (PDF)',
                    archivoLocal: _certificadoFile,
                    alSeleccionar: () async { final f = await _seleccionarArchivo(); if (f != null) setState(() => _certificadoFile = f); },
                    alEliminar: () => setState(() => _certificadoFile = null),
                  ),
                  _constructorCajaArchivo(
                    tituloBoton: 'Acta de Nacimiento (PDF)',
                    archivoLocal: _actaFile,
                    alSeleccionar: () async { final f = await _seleccionarArchivo(); if (f != null) setState(() => _actaFile = f); },
                    alEliminar: () => setState(() => _actaFile = null),
                  ),
                  _constructorCajaArchivo(
                    tituloBoton: 'Constancia de CURP (PDF)',
                    archivoLocal: _curpFile,
                    alSeleccionar: () async { final f = await _seleccionarArchivo(); if (f != null) setState(() => _curpFile = f); },
                    alEliminar: () => setState(() => _curpFile = null),
                  ),
                  _constructorCajaArchivo(
                    tituloBoton: 'Número de Seguridad Social (PDF)',
                    archivoLocal: _nssFile,
                    alSeleccionar: () async { final f = await _seleccionarArchivo(); if (f != null) setState(() => _nssFile = f); },
                    alEliminar: () => setState(() => _nssFile = null),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviarSolicitud,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                      child: _enviando ? const CircularProgressIndicator(color: Colors.white) : const Text('ENVIAR DATOS DE ADMISIÓN', style: TextStyle(color: Colors.white, fontSize: 16)),
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
  // VISTA 2: ESTATUS DE SOLICITUD (SOLO LECTURA COMPLETA)
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
                  
                  // PANEL DE RESUMEN EN MODO LECTURA
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
                  const Text('Expediente Digital Cargado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                  const SizedBox(height: 15),
                  
                  // Despliegue de visores limpios de documentos remotos (sin botones de alterar o eliminar)
                  _constructorVisorArchivo('Certificado de Preparatoria', _urlCertificado),
                  _constructorVisorArchivo('Acta de Nacimiento', _urlActa),
                  _constructorVisorArchivo('Constancia de CURP', _urlCurp),
                  _constructorVisorArchivo('Número de Seguridad Social (NSS)', _urlNss),

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

  Widget _campo(String label, TextEditingController ctrl) => TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));

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