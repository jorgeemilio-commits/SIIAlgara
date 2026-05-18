import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

class PlanAcademicoSeccion extends StatefulWidget {
  final List<dynamic> misGrupos;

  const PlanAcademicoSeccion({super.key, required this.misGrupos});

  @override
  State<PlanAcademicoSeccion> createState() => _PlanAcademicoSeccionState();
}

class _PlanAcademicoSeccionState extends State<PlanAcademicoSeccion> {
  bool _procesando = false;

  // --- MÉTODO AUXILIAR PARA VALIDACIÓN ---
  bool _tienePlan(Map<String, dynamic> grupo) {
    final url = grupo['url_plan'];
    return url != null && url.toString().isNotEmpty;
  }

  // --- SECCIÓN LÓGICA: SUBIR Y REEMPLAZAR ARCHIVO ---
  Future<void> _seleccionarYSubirPlan(Map<String, dynamic> grupo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => _procesando = true);

    try {
      // Usamos el id_grupo para garantizar un identificador único y persistente
      final fileName = '${grupo['id_grupo']}.pdf';
      final path = 'pdf_planes/$fileName';

      final storage = Supabase.instance.client.storage.from('planes_academicos');

      // Subida al Storage (upsert: true permite reemplazar el archivo existente)
      if (kIsWeb) {
        await storage.uploadBinary(path, result.files.first.bytes!,
            fileOptions: const FileOptions(upsert: true));
      } else {
        await storage.upload(path, File(result.files.first.path!),
            fileOptions: const FileOptions(upsert: true));
      }

      final String rawUrl = storage.getPublicUrl(path);
      // Cache buster para forzar al navegador a recargar el archivo actualizado
      final String publicUrl = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Vinculamos la URL generada al registro exacto en la tabla 'grupos'
      await Supabase.instance.client
          .from('grupos')
          .update({'url_plan': publicUrl})
          .eq('id_grupo', grupo['id_grupo']);

      setState(() {
        grupo['url_plan'] = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Plan guardado y vinculado correctamente.'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Error al subir: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al subir: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // --- SECCIÓN LÓGICA: ELIMINAR PLAN ACADÉMICO ---
  Future<void> _eliminarPlan(Map<String, dynamic> grupo) async {
    setState(() => _procesando = true);

    try {
      final fileName = '${grupo['id_grupo']}.pdf';
      final path = 'pdf_planes/$fileName';

      // 1. Borrar archivo físico del Storage
      await Supabase.instance.client.storage.from('planes_academicos').remove([path]);

      // 2. Limpiar la columna 'url_plan' en la base de datos
      await Supabase.instance.client
          .from('grupos')
          .update({'url_plan': null})
          .eq('id_grupo', grupo['id_grupo']);

      setState(() {
        grupo['url_plan'] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Plan eliminado correctamente.'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      debugPrint('Error al eliminar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // --- SECCIÓN LÓGICA: VISUALIZACIÓN ---
  void _verPlan(String url) {
    if (kIsWeb) {
      web.window.open(url, '_blank');
    } else {
      debugPrint('Abriendo URL fuera del entorno Web: $url');
    }
  }

  // --- SECCIÓN: DISEÑO DE INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestión de Planes Académicos',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366))),
          const SizedBox(height: 10),
          const Text(
              'Sube, consulta o actualiza el programa de estudios oficial (PDF) de tus asignaturas.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          if (_procesando == true) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 15),
          ],
          Expanded(
            child: widget.misGrupos.isEmpty
                ? const Center(child: Text('No hay grupos cargados.'))
                : ListView.builder(
                    itemCount: widget.misGrupos.length,
                    itemBuilder: (context, index) {
                      final grupo = widget.misGrupos[index];
                      final bool tienePlan = _tienePlan(grupo);
                      
                      final String nombreMateria = grupo['asignaturas'] != null
                          ? (grupo['asignaturas']['nombre_materia'] ?? 'Materia sin nombre')
                          : 'Materia Desconocida';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf,
                              color: tienePlan ? Colors.green : Colors.red,
                              size: 40),
                          title: Text(nombreMateria,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Grupo: ${grupo['nombre_grupo'] ?? 'N/A'} | Estatus: ${tienePlan ? 'Cargado' : 'Pendiente'}'),
                          trailing: tienePlan
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _procesando == true
                                          ? null
                                          : () => _verPlan(grupo['url_plan']),
                                      icon: const Icon(Icons.visibility,
                                          color: Color(0xFF003366)),
                                      label: const Text('Ver',
                                          style: TextStyle(color: Color(0xFF003366))),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton.icon(
                                      onPressed: _procesando == true
                                          ? null
                                          : () => _seleccionarYSubirPlan(grupo),
                                      icon: const Icon(Icons.refresh,
                                          color: Colors.blueGrey),
                                      label: const Text('Reemplazar',
                                          style: TextStyle(color: Colors.blueGrey)),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton.icon(
                                      onPressed: _procesando == true
                                          ? null
                                          : () => _eliminarPlan(grupo),
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      label: const Text('Eliminar',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                )
                              : ElevatedButton.icon(
                                  onPressed: _procesando == true
                                      ? null
                                      : () => _seleccionarYSubirPlan(grupo),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Subir Plan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003366),
                                    foregroundColor: Colors.white,
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