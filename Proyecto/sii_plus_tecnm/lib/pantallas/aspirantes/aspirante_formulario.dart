import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AspiranteFormulario extends StatefulWidget {
  const AspiranteFormulario({super.key});

  @override
  State<AspiranteFormulario> createState() => _AspiranteFormularioState();
}

class _AspiranteFormularioState extends State<AspiranteFormulario> {
  bool _cargandoInicial = true;
  bool _solicitudEnviada = false;
  bool _enviando = false;
  String _folioAsignado = '';

  final _nombresCtrl = TextEditingController(text: 'Jorge Emilio');
  final _paternoCtrl = TextEditingController(text: 'Chávez');
  final _maternoCtrl = TextEditingController(text: 'Lizárraga');
  final _curpCtrl = TextEditingController(text: 'CHLJ010203HSRL01');
  final _fechaNacCtrl = TextEditingController(text: '2001-02-03');
  final _correoPersonalCtrl = TextEditingController(text: 'test@email.com');
  final _telefonoCtrl = TextEditingController(text: '6681234567');
  final _promedioCtrl = TextEditingController(text: '92.50');

  final List<String> _carreras = [
    'Arquitectura', 'Contador Público', 'Ingeniería Bioquímica', 'Ingeniería Electromecánica',
    'Ingeniería Electrónica', 'Ingeniería en Gestión Empresarial', 'Ingeniería en Industrias Alimentarias',
    'Ingeniería Industrial', 'Ingeniería en Innovación Agrícola Sustentable', 'Ingeniería Mecatrónica',
    'Ingeniería Informática', 'Licenciatura en Administración', 'Licenciatura en Biología', 'Ingeniería Química'
  ];
  String? _carreraSeleccionada = 'Ingeniería Informática';

  @override
  void initState() {
    super.initState();
    _verificarSiYaTieneRegistro();
  }

  // Busca en la BD si este usuario ya mandó sus datos
  Future<void> _verificarSiYaTieneRegistro() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('aspirantes')
          .select()
          .eq('id_auth', user.id)
          .maybeSingle();

      if (data != null) {
        // Ya tiene registro, recuperamos el folio y la carrera
        setState(() {
          _folioAsignado = data['folio_aspirante'];
          _carreraSeleccionada = data['carrera_solicitada'];
          _solicitudEnviada = true;
        });
      }
    } catch (e) {
      debugPrint('No se encontraron registros previos o hubo error: $e');
    } finally {
      setState(() => _cargandoInicial = false);
    }
  }

  Future<void> _enviarSolicitud() async {
    setState(() => _enviando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final tempFolio = 'ASP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      await Supabase.instance.client.from('aspirantes').insert({
        'folio_aspirante': tempFolio,
        'nombres': _nombresCtrl.text,
        'apellido_paterno': _paternoCtrl.text,
        'apellido_materno': _maternoCtrl.text,
        'curp': _curpCtrl.text,
        'fecha_nacimiento': _fechaNacCtrl.text,
        'correo_personal': _correoPersonalCtrl.text,
        'telefono': _telefonoCtrl.text,
        'carrera_solicitada': _carreraSeleccionada,
        'promedio_preparatoria': double.tryParse(_promedioCtrl.text),
        'id_auth': user?.id,
      });

      setState(() {
        _folioAsignado = tempFolio;
        _solicitudEnviada = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // Función para cerrar sesión y borrar caché
  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      // Regresa al menú principal (RoleSelectionScreen)
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Aspirante'),
        automaticallyImplyLeading: false, // Quita la flecha de regreso
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: Center(
        child: _cargandoInicial 
          ? const CircularProgressIndicator() // Si está revisando la BD, muestra rueda
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: _solicitudEnviada ? _vistaEstatus() : _vistaFormulario(),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _vistaFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ficha de Registro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
        const Divider(height: 40),
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
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _enviando ? null : _enviarSolicitud,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
            child: _enviando ? const CircularProgressIndicator() : const Text('ENVIAR DATOS', style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    );
  }

  // Vista actualizada con confirmación de guardado y botón grande de cerrar sesión
  Widget _vistaEstatus() {
    return Column(
      children: [
        const Icon(Icons.verified_user, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text('¡Datos Guardados Exitosamente!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 10),
        const Text(
          'Tu solicitud fue enviada y vinculada a tu cuenta de manera correcta. Puedes iniciar sesión en cualquier momento para revisar tu estatus.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
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
        
        // Botón grande y claro para Cerrar Sesión
        SizedBox(
          width: 250,
          height: 45,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Cerrar Sesión Segura'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade700),
            ),
            onPressed: _cerrarSesion,
          ),
        )
      ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl) => TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
}