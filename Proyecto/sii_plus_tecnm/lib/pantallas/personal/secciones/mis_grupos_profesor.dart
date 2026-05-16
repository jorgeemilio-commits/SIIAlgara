import 'package:flutter/material.dart';
import 'captura_calificaciones.dart';

class MisGruposProfesor extends StatefulWidget {
  final List<dynamic> misGrupos; // Recibe la lista de grupos desde la pantalla principal

  const MisGruposProfesor({super.key, required this.misGrupos});

  @override
  State<MisGruposProfesor> createState() => _MisGruposProfesorState();
}

class _MisGruposProfesorState extends State<MisGruposProfesor> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Carga Académica Actual', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 8),
          const Text('Selecciona un grupo para gestionar la lista de asistencia y capturar calificaciones.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          Expanded(
            child: widget.misGrupos.isEmpty
              ? const Center(child: Text('No tienes grupos asignados en este periodo escolar.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: widget.misGrupos.length,
                  itemBuilder: (context, index) {
                    final grupo = widget.misGrupos[index];
                    final asignatura = grupo['asignaturas'] != null ? grupo['asignaturas']['nombre_materia'] : 'Materia Desconocida';
                    
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          // Navegación implementada hacia la pantalla de captura pasando el grupo seleccionado
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CapturaCalificaciones(grupo: grupo),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(grupo['clave_materia'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: const Color(0xFF003366),
                                  ),
                                  Text('Grupo: ${grupo['nombre_grupo']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const Spacer(),
                              Text(asignatura, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(grupo['horario'] ?? 'Sin horario', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(grupo['aula'] ?? 'Sin aula', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}