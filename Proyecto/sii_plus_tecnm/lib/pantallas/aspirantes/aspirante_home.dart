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

  @override
  void initState() {
    super.initState();
    _verificarSesionActiva();
  }

  // Verificamos si ya hay una sesión activa guardada en el navegador
  Future<void> _verificarSesionActiva() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Validamos que la sesión recordada NO sea de un alumno ni del personal
      final tieneOtroRol = await _tieneOtroRol(session.user.id);
      
      if (tieneOtroRol) {
        // Si es un maestro o estudiante que había dejado la sesión abierta, la cerramos
        await Supabase.instance.client.auth.signOut();
      } else if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AspiranteFormulario()),
        );
      }
    }
  }

  // --- Validar si la cuenta pertenece a un empleado o a un estudiante ---
  Future<bool> _tieneOtroRol(String userId) async {
    try {
      // 1. ¿Es Administrador?
      final admin = await Supabase.instance.client
          .from('administradores')
          .select('id_admin')
          .eq('id_auth', userId)
          .maybeSingle();
      if (admin != null) return true;

      // 2. ¿Es Coordinador?
      final coord = await Supabase.instance.client
          .from('coordinadores')
          .select('numero_nomina')
          .eq('id_auth', userId)
          .maybeSingle();
      if (coord != null) return true;

      // 3. ¿Es Profesor?
      final prof = await Supabase.instance.client
          .from('profesores')
          .select('numero_nomina')
          .eq('id_auth', userId)
          .maybeSingle();
      if (prof != null) return true;

      // 4. ¿Es Estudiante?
      final est = await Supabase.instance.client
          .from('estudiantes')
          .select('matricula')
          .eq('id_auth', userId)
          .maybeSingle();
      if (est != null) return true;

      return false; // Si no está en NINGUNA de las 4 tablas, entonces sí es un aspirante
    } catch (e) {
      debugPrint('Error al verificar rol: $e');
      return false; 
    }
  }

  Future<void> _autenticar() async {
    setState(() => _cargando = true);
    try {
      if (_esRegistro) {
        // Lógica de registro para nuevos aspirantes
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          data: {'nombre': _nombreCtrl.text.trim()},
        );
        _mostrarMensaje('Cuenta creada exitosamente.');
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AspiranteFormulario()),
          );
        }
      } else {
        // Lógica de Inicio de Sesión
        final authRes = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        if (authRes.user != null) {
          // Filtro de seguridad: Evitar que personal o estudiantes entren aquí
          final tieneOtroRol = await _tieneOtroRol(authRes.user!.id);
          
          if (tieneOtroRol) {
            // Bloqueamos el acceso y cerramos la sesión que Auth acaba de autorizar
            await Supabase.instance.client.auth.signOut();
            _mostrarMensaje('Acceso denegado: Esta cuenta pertenece a un Alumno o al Personal. Utilice el portal correspondiente.');
            return;
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AspiranteFormulario()),
            );
          }
        }
      }
    } catch (e) {
      _mostrarMensaje('Credenciales incorrectas o error de conexión.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg), 
          backgroundColor: msg.contains('denegado') || msg.contains('error') || msg.contains('incorrectas') ? Colors.red : Colors.green
        )
      );
    }
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
                      const SizedBox(height: 10),
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