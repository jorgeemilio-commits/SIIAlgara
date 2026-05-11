import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoordinadorHome extends StatefulWidget {
  const CoordinadorHome({super.key});

  @override
  State<CoordinadorHome> createState() => _CoordinadorHomeState();
}

class _CoordinadorHomeState extends State<CoordinadorHome> {
  bool _cargando = true;
  String _departamento = '';
  List<dynamic> _listaAspirantes = [];

  @override
  void initState() {
    super.initState();
    _cargarAspirantes();
  }

  Future<void> _cargarAspirantes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Obtenemos el departamento que coordina el usuario actual
      final coordData = await Supabase.instance.client
          .from('coordinadores')
          .select('departamento_coordina')
          .eq('id_auth', userId)
          .single();

      _departamento = coordData['departamento_coordina'] ?? 'Sin asignar';

      // 2. Traemos a los aspirantes de esa carrera específica
      final aspirantesData = await Supabase.instance.client
          .from('aspirantes')
          .select()
          .eq('carrera_solicitada', _departamento)
          .order('fecha_registro', ascending: false); // Los más recientes primero

      if (mounted) {
        setState(() {
          _listaAspirantes = aspirantesData;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar la lista de aspirantes: $e')),
        );
        setState(() => _cargando = false);
      }
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
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings),
            SizedBox(width: 12),
            Text('PANEL DE COORDINACIÓN'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Salir', style: TextStyle(color: Colors.red)),
            onPressed: _cerrarSesion,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aspirantes - $_departamento',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total de solicitudes encontradas: ${_listaAspirantes.length}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Divider(height: 40),
                  
                  // Tabla de Datos
                  Expanded(
                    child: _listaAspirantes.isEmpty
                        ? const Center(child: Text('No hay aspirantes registrados para esta carrera aún.'))
                        : Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal, // Por si la pantalla es pequeña
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                                  columns: const [
                                    DataColumn(label: Text('Folio', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nombre Completo', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('CURP', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Promedio', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _listaAspirantes.map((aspirante) {
                                    // Concatenamos el nombre usando la estructura de tu BD
                                    final nombreCompleto = '${aspirante['nombres']} ${aspirante['apellido_paterno']} ${aspirante['apellido_materno'] ?? ''}';
                                    
                                    return DataRow(cells: [
                                      DataCell(Text(aspirante['folio_aspirante'].toString())),
                                      DataCell(Text(nombreCompleto)),
                                      DataCell(Text(aspirante['curp'].toString())),
                                      DataCell(Text(aspirante['promedio_preparatoria'].toString())),
                                      DataCell(
                                        Chip(
                                          label: Text(aspirante['estatus_admision'].toString(), style: const TextStyle(fontSize: 12)),
                                          backgroundColor: aspirante['estatus_admision'] == 'En proceso' ? Colors.orange.shade100 : Colors.green.shade100,
                                        ),
                                      ),
                                      DataCell(
                                        TextButton.icon(
                                          icon: const Icon(Icons.manage_search, size: 18),
                                          label: const Text('Revisar'),
                                          onPressed: () {
                                            // TODO: Aquí pondremos la lógica para abrir el detalle y aprobar/rechazar
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Próximamente: Evaluar folio ${aspirante['folio_aspirante']}')),
                                            );
                                          },
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}