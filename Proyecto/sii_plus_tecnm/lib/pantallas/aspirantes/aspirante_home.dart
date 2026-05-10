import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'aspirante_formulario.dart';

class AspiranteHome extends StatefulWidget {
  const AspiranteHome({super.key});

  @override
  State<AspiranteHome> createState() => _AspiranteHomeState();
}

class _AspiranteHomeState extends State<AspiranteHome> {
  bool _esRegistro = true;
  bool _cargando = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController(); 

  // Autenticación con Supabase
  Future<void> _autenticar() async {
    setState(() => _cargando = true);
    try {
      if (_esRegistro) {
        // Crear cuenta en Supabase Auth
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          data: {'nombre': _nombreCtrl.text.trim()},
        );
        _mostrarMensaje('Cuenta creada exitosamente.');
      } else {
        // Iniciar sesión
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }

      // Si tiene éxito, pasamos al formulario
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AspiranteFormulario()),
        );
      }
    } catch (e) {
      _mostrarMensaje('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso de Aspirantes')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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
                        onPressed: _cargando ? null : _autenticar,
                        child: _cargando 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_esRegistro ? 'REGISTRARME' : 'INGRESAR', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _esRegistro = !_esRegistro),
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