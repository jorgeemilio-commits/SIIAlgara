import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_home.dart';
import 'coordinador_home.dart';
import 'profesor_home.dart';

class PersonalLogin extends StatefulWidget {
  const PersonalLogin({super.key});

  @override
  State<PersonalLogin> createState() => _PersonalLoginState();
}

class _PersonalLoginState extends State<PersonalLogin> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _verificarSesionActiva();
  }

  // Verifica si ya hay una sesión guardada para saltar el login
  Future<void> _verificarSesionActiva() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _buscarRolYRedirigir(session.user.id);
    }
  }

  Future<void> _acceder() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _error('Por favor, completa todos los campos.');
      return;
    }

    setState(() => _cargando = true);
    try {
      // 1. Autenticación en Supabase Auth
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (authRes.user != null) {
        await _buscarRolYRedirigir(authRes.user!.id);
      }
    } catch (e) {
      _error('Credenciales incorrectas o error de conexión.');
      setState(() => _cargando = false);
    }
  }

  // Lógica central de redirección por tablas 
  Future<void> _buscarRolYRedirigir(String userId) async {
    try {
      // 1. ¿Es Administrador?
      final admin = await Supabase.instance.client
          .from('administradores')
          .select('id_admin')
          .eq('id_auth', userId)
          .maybeSingle();

      if (admin != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHome()));
        return;
      }

      // 2. ¿Es Coordinador? 
      final coord = await Supabase.instance.client
          .from('coordinadores')
          .select('numero_nomina')
          .eq('id_auth', userId)
          .maybeSingle();

      if (coord != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CoordinadorHome()));
        return;
      }

      // 3. ¿Es Profesor? 
      final prof = await Supabase.instance.client
          .from('profesores')
          .select('numero_nomina')
          .eq('id_auth', userId)
          .maybeSingle();

      if (prof != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfesorHome()));
        return;
      }

      // Si no está en ninguna tabla, cerramos sesión por seguridad
      await Supabase.instance.client.auth.signOut();
      _error('Acceso denegado: El usuario no está registrado en el personal autorizado.');
      
    } catch (e) {
      _error('Error al verificar permisos.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _error(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Portal de Personal Institucional'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF003366),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 80, color: Color(0xFF003366)),
                    const SizedBox(height: 20),
                    const Text(
                      'Bienvenido al SII',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                    ),
                    const SizedBox(height: 10),
                    const Text('Ingresa tus credenciales institucionales', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _acceder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _cargando 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('INICIAR SESIÓN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}