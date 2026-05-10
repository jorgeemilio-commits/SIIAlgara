import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AspiranteFormulario extends StatefulWidget {
  const AspiranteFormulario({super.key});

  @override
  State<AspiranteFormulario> createState() => _AspiranteFormularioState();
}

class _AspiranteFormularioState extends State<AspiranteFormulario> {
  bool _solicitudEnviada = false;
  bool _enviando = false;
  String _folioAsignado = '';

  // Controladores con datos de prueba
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

  // Función para guardar datos en la tabla pública.aspirantes
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
        'id_auth': user?.id, // Vincula con la cuenta de Supabase Auth
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Aspirante'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context))],
      ),
      body: Center(
        child: SingleChildScrollView(
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

  Widget _vistaEstatus() {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text('Solicitud Enviada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Folio: $_folioAsignado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        const Chip(label: Text('EN PROCESO'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white)),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Salir'))
      ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl) => TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
}