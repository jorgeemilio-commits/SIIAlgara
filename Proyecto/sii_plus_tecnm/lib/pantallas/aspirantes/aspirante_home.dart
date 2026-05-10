import 'package:flutter/material.dart';
import 'aspirante_formulario.dart'; // Importamos la pantalla del formulario

class AspiranteHome extends StatefulWidget {
  const AspiranteHome({super.key});

  @override
  State<AspiranteHome> createState() => _AspiranteHomeState();
}

class _AspiranteHomeState extends State<AspiranteHome> {
  bool _esRegistro = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso de Aspirantes'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500), // Diseño web centrado
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.person_outline, size: 80, color: Color(0xFF003366)),
                      const SizedBox(height: 20),
                      Text(
                        _esRegistro ? 'Crear Cuenta' : 'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                      ),
                      const SizedBox(height: 30),
                      if (_esRegistro) ...[
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 15),
                      ],
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: () {
                          /*Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AspiranteFormulario()),
                          );*/
                        },
                        child: Text(_esRegistro ? 'CREAR CUENTA Y CONTINUAR' : 'INGRESAR', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _esRegistro = !_esRegistro);
                        },
                        child: Text(_esRegistro ? '¿Ya tienes cuenta? Inicia Sesión' : '¿No tienes cuenta? Crea una'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}