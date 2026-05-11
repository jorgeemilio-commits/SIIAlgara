import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'coordinador_home.dart';
import 'profesor_home.dart';

class PersonalLogin extends StatefulWidget {
  const PersonalLogin({super.key});

  @override
  State<PersonalLogin> createState() => _PersonalLoginState();
}

class _PersonalLoginState extends State<PersonalLogin> {
  bool _cargando = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _iniciarSesion() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _mostrarMensaje('Por favor, ingresa correo y contraseña.');
      return;
    }

    setState(() => _cargando = true);
    try {
      // 1. Iniciamos sesión en Supabase Auth
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final user = res.user;
      if (user != null) {
        
        // 2. Buscamos primero en la tabla de coordinadores
        final dataCoordinador = await Supabase.instance.client
            .from('coordinadores')
            .select('numero_nomina') // Solo traemos un dato ligero para verificar existencia
            .eq('id_auth', user.id)
            .maybeSingle();

        if (dataCoordinador != null) {
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CoordinadorHome()));
          return; // Terminamos la ejecución aquí
        }

        // 3. Si no es coordinador, buscamos en la tabla de profesores
        final dataProfesor = await Supabase.instance.client
            .from('profesores')
            .select('numero_nomina')
            .eq('id_auth', user.id)
            .maybeSingle();

        if (dataProfesor != null) {
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfesorHome()));
          return; // Terminamos la ejecución aquí
        }

        // 4. Si no está en ninguna de las dos tablas
        _mostrarMensaje('Acceso denegado. Su cuenta no está asignada como personal activo.');
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      _mostrarMensaje('Credenciales incorrectas o error de conexión.');
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
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.manage_accounts),
            SizedBox(width: 12),
            Text('ACCESO DE PERSONAL'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), 
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.badge, size: 80, color: Color(0xFF003366)),
                      const SizedBox(height: 20),
                      const Text(
                        'Portal Institucional',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ingresa con tu correo y contraseña asignada por el instituto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo Institucional', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        onFieldSubmitted: (_) => _iniciarSesion(), 
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: _cargando ? null : _iniciarSesion,
                        child: _cargando 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('INICIAR SESIÓN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
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