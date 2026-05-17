import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PlanAcademicoSeccion extends StatefulWidget {
  final List<dynamic> misGrupos;

  const PlanAcademicoSeccion({super.key, required this.misGrupos});

  @override
  State<PlanAcademicoSeccion> createState() => _PlanAcademicoSeccionState();
}

class _PlanAcademicoSeccionState extends State<PlanAcademicoSeccion> {
  bool _subiendo = false;

  Future<void> _seleccionarYSubirPlan(Map<String, dynamic> grupo) async {
    // 1. Seleccionar el archivo PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return; // El usuario canceló

    setState(() => _subiendo = true);

    try {
      final file = result.files.first;
      final fileExtension = file.extension;
      // Nombre único: nomina_materia_grupo.pdf
      final fileName = '${grupo['numero_nomina_profesor']}_${grupo['clave_materia']}_${grupo['nombre_grupo']}.$fileExtension';
      final path = 'pdf_planes/$fileName';

      // 2. Subir a Supabase Storage
      final storage = Supabase.instance.client.storage.from('planes_academicos');
      
      if (kIsWeb) {
        await storage.uploadBinary(path, file.bytes!, fileOptions: const FileOptions(upsert: true));
      } else {
        await storage.upload(path, File(file.path!), fileOptions: const FileOptions(upsert: true));
      }

      // 3. Obtener la URL pública y actualizar la tabla 'grupos'
      final String publicUrl = storage.getPublicUrl(path);

      await Supabase.instance.client
          .from('grupos')
          .update({'url_plan': publicUrl})
          .eq('id_grupo', grupo['id_grupo']); // Asegúrate de tener 'id_grupo' en tu tabla

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan Académico subido con éxito.'), backgroundColor: Colors.green));
      }
      
      // Aquí podrías recargar la lista si fuera necesario
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestión de Planes Académicos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 10),
          const Text('Sube el programa de estudios oficial (PDF) para cada una de tus materias asignadas.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          if (_subiendo) const LinearProgressIndicator(),

          Expanded(
            child: widget.misGrupos.isEmpty
              ? const Center(child: Text('No hay grupos cargados.'))
              : ListView.builder(
                  itemCount: widget.misGrupos.length,
                  itemBuilder: (context, index) {
                    final grupo = widget.misGrupos[index];
                    final tienePlan = grupo['url_plan'] != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: tienePlan ? Colors.green : Colors.red, size: 40),
                        title: Text(grupo['asignaturas']['nombre_materia'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Grupo: ${grupo['nombre_grupo']} | Estatus: ${tienePlan ? 'Cargado' : 'Pendiente'}'),
                        trailing: ElevatedButton.icon(
                          onPressed: _subiendo ? null : () => _seleccionarYSubirPlan(grupo),
                          icon: const Icon(Icons.upload_file),
                          label: Text(tienePlan ? 'Reemplazar' : 'Subir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tienePlan ? Colors.grey : const Color(0xFF003366),
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