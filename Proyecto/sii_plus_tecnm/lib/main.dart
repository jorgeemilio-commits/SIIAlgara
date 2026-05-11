import 'package:flutter/material.dart';
import 'pantallas/aspirantes/aspirante_home.dart';
import 'pantallas/personal/personal_login.dart';
import 'widgets/web_action_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización con tus credenciales de Supabase
  await Supabase.initialize(
    url: 'https://slrcguaqmlftohfmzzkt.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNscmNndWFxbWxmdG9oZm16emt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0ODM5NjEsImV4cCI6MjA5MzA1OTk2MX0.IYAxKVIyVGvXI1E60mBz8RY1bRrlGMkwHrU9_z32KTg',                     
  );

  runApp(const SIIAlgaraApp());
}

class SIIAlgaraApp extends StatelessWidget {
  const SIIAlgaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SII+ - Portal Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF003366),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF003366),
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Color(0xFF003366),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const WebRoleSelectionPage(),
    );
  }
}

class WebRoleSelectionPage extends StatelessWidget {
  const WebRoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Color(0xFF003366)),
            SizedBox(width: 10),
            Text('SII+  INSTITUTO TECNOLÓGICO DE LOS MOCHIS'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Bienvenida
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido al Sistema de Información Integral del Instituto Tecnológico de Los Mochis',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Seleccione el portal de acceso correspondiente a su perfil para continuar.',
                    style: TextStyle(fontSize: 18, color: Color(0xFF374151)),
                  ),
                ],
              ),
            ),
            
            // Grid de Tarjetas
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Wrap(
                  spacing: 30,
                  runSpacing: 30,
                  alignment: WrapAlignment.center,
                  children: [
                    WebActionTile(
                      title: 'Portal de Aspirantes',
                      description: 'Si eres de nuevo ingreso, inicia tu proceso de admisión, consulta tu folio y resultados.',
                      icon: Icons.person_add_alt_1,
                      buttonText: 'Iniciar Registro',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AspiranteHome()));
                      },
                    ),
                    
                    WebActionTile(
                      title: 'Portal de Alumnos',
                      description: 'Accede a tu kárdex, horarios, reinscripciones y servicios escolares en línea.',
                      icon: Icons.school,
                      buttonText: 'Próximamente',
                      isActive: false, 
                      onTap: () {},
                    ),
                    
                    WebActionTile(
                      title: 'Portal del Personal',
                      description: 'Acceso exclusivo para docentes, coordinadores y personal administrativo del instituto.',
                      icon: Icons.manage_accounts,
                      buttonText: 'Ingresar al Portal',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalLogin()));
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade300,
              child: const Center(
                child: Text('© 2026 Instituto Tecnologico de Los Mochis - Todos los derechos reservados.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}