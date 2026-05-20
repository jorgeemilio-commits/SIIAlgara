import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'aspirante_formulario.dart';

class AspiranteHome extends StatefulWidget {
  const AspiranteHome({super.key});

  @override
  State<AspiranteHome> createState() => _AspiranteHomeState();
}

class _AspiranteHomeState extends State<AspiranteHome> {
  // Iniciamos en false para que la vista por defecto sea "Iniciar Sesión"
  bool _esRegistro = false; 
  bool _cargando = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController(); // Controlador para confirmar contraseña

  @override
  void initState() {
    super.initState();
    _verificarSesionActiva();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // Verificamos si ya hay una sesión activa guardada en el navegador
  Future<void> _verificarSesionActiva() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
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

  // --- Verificar si la cuenta pertenece a un empleado o a un estudiante ---
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
    // Validaciones básicas de campos vacíos
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos.');
      return;
    }

    if (_esRegistro && _confirmPassCtrl.text.isEmpty) {
      _mostrarMensaje('Por favor, confirma tu contraseña.');
      return;
    }

    // Validación de coincidencia de contraseñas en registro
    if (_esRegistro && _passCtrl.text.trim() != _confirmPassCtrl.text.trim()) {
      _mostrarMensaje('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _cargando = true);
    try {
      if (_esRegistro) {
        // Lógica de registro para nuevos aspirantes
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
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
            // Bloqueamos el acceso y cerramos la sesión
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
          backgroundColor: msg.contains('denegado') || msg.contains('error') || msg.contains('incorrectas') || msg.contains('coinciden') || msg.contains('completa') ? Colors.red : Colors.green
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso de Aspirantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Botón de retroceso en el AppBar
        ),
      ),
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
                        _esRegistro ? 'Nueva Solicitud' : 'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _esRegistro 
                            ? 'Crea tu cuenta para generar una nueva ficha de admisión.' 
                            : 'Ingresa con tu correo para continuar tu proceso.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      
                      // --- CAMPOS DE TEXTO ---
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico', 
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder()
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña', 
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder()
                        ),
                      ),
                      
                      // Solo mostramos el campo de confirmar contraseña en modo Registro (Nueva Solicitud)
                      if (_esRegistro) ...[
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Contraseña', 
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                            border: OutlineInputBorder()
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),

                      // --- BOTONES DINÁMICOS SEGÚN EL ESTADO ---
                      if (!_esRegistro) ...[
                        // Botones Modo Iniciar Sesión (Ingresar, Nueva Solicitud, Salir)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onPressed: _cargando ? null : _autenticar,
                          child: _cargando 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('INGRESAR', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(height: 15),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(color: Color(0xFF003366)),
                          ),
                          onPressed: _cargando ? null : () => setState(() => _esRegistro = true),
                          child: const Text('NUEVA SOLICITUD', style: TextStyle(color: Color(0xFF003366), fontSize: 16)),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _cargando ? null : () => Navigator.pop(context),
                          child: const Text('SALIR', style: TextStyle(color: Colors.red, fontSize: 16)),
                        ),
                      ] else ...[
                        // Botones Modo Nueva Solicitud (Crear Cuenta, Cancelar y Volver)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onPressed: _cargando ? null : _autenticar,
                          child: _cargando 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('CREAR CUENTA', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _cargando ? null : () => setState(() => _esRegistro = false),
                          child: const Text('CANCELAR Y VOLVER', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                      ],
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