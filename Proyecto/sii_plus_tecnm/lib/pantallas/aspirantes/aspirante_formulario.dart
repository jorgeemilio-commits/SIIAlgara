import 'package:flutter/material.dart';

class AspiranteFormulario extends StatefulWidget {
  const AspiranteFormulario({super.key});

  @override
  State<AspiranteFormulario> createState() => _AspiranteFormularioState();
}

class _AspiranteFormularioState extends State<AspiranteFormulario> {
  bool _solicitudEnviada = false; // Controla si mostramos el formulario o el estatus

  // Datos precargados para testeo rápido
  final _nombresCtrl = TextEditingController(text: 'Jorge Emilio');
  final _paternoCtrl = TextEditingController(text: 'Chávez');
  final _maternoCtrl = TextEditingController(text: 'Lizárraga');
  final _curpCtrl = TextEditingController(text: 'CHLJ010203HSRL01');
  final _fechaNacCtrl = TextEditingController(text: '2001-02-03');
  final _correoPersonalCtrl = TextEditingController(text: 'test@email.com');
  final _telefonoCtrl = TextEditingController(text: '6681234567');
  final _promedioCtrl = TextEditingController(text: '92.50');

  // Lista oficial de carreras
  final List<String> _carrerasOficiales = [
    'Arquitectura', 'Contador Público', 'Ingeniería Bioquímica',
    'Ingeniería Electromecánica', 'Ingeniería Electrónica',
    'Ingeniería en Gestión Empresarial', 'Ingeniería en Industrias Alimentarias',
    'Ingeniería Industrial', 'Ingeniería en Innovación Agrícola Sustentable',
    'Ingeniería Mecatrónica', 'Ingeniería Informática',
    'Licenciatura en Administración', 'Licenciatura en Biología', 'Ingeniería Química'
  ];
  String? _carreraSeleccionada;

  @override
  void initState() {
    super.initState();
    _carreraSeleccionada = 'Ingeniería Informática';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Aspirantes - Registro'),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context), // Regresa al menú principal del SII
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Diseño ancho para el formulario
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
        const Text(
          'Ficha de Registro',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
        ),
        const Text('Por favor, valida tu información. Algunos campos se han pre-llenado para agilizar tus pruebas.'),
        const Divider(height: 40),
        
        Row(
          children: [
            Expanded(child: _crearCampo('Nombres', _nombresCtrl)),
            const SizedBox(width: 15),
            Expanded(child: _crearCampo('Apellido Paterno', _paternoCtrl)),
            const SizedBox(width: 15),
            Expanded(child: _crearCampo('Apellido Materno', _maternoCtrl)),
          ],
        ),
        const SizedBox(height: 15),
        
        Row(
          children: [
            Expanded(child: _crearCampo('CURP', _curpCtrl)),
            const SizedBox(width: 15),
            Expanded(child: _crearCampo('Fecha Nacimiento (YYYY-MM-DD)', _fechaNacCtrl)),
          ],
        ),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(child: _crearCampo('Correo Personal', _correoPersonalCtrl)),
            const SizedBox(width: 15),
            Expanded(child: _crearCampo('Teléfono', _telefonoCtrl)),
          ],
        ),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Carrera Solicitada', border: OutlineInputBorder()),
                value: _carreraSeleccionada,
                isExpanded: true,
                items: _carrerasOficiales.map((String carrera) {
                  return DropdownMenuItem<String>(value: carrera, child: Text(carrera, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() => _carreraSeleccionada = nuevoValor);
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: _crearCampo('Promedio Prepa', _promedioCtrl)),
          ],
        ),
        
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: () {
              // Simulamos que la solicitud se envió y cambiamos la vista
              setState(() => _solicitudEnviada = true);
            },
            child: const Text('ENVIAR SOLICITUD DE INGRESO', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _vistaEstatus() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 100, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          '¡Solicitud Registrada!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              const Text('Estatus de Admisión:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                child: const Text('EN PROCESO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 20),
              Text('Folio asignado: ASP-2026-0001\nCarrera: $_carreraSeleccionada', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar sesión y volver al menú principal', style: TextStyle(fontSize: 16)),
        )
      ],
    );
  }

  Widget _crearCampo(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}