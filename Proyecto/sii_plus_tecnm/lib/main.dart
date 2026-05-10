import 'package:flutter/material.dart';

// Imports de tus pantallas (mantenemos las rutas correctas)
import 'pantallas/aspirantes/aspirante_home.dart';
import 'pantallas/personal/personal_login.dart';

void main() {
  runApp(const SIIAlgaraApp());
}

class SIIAlgaraApp extends StatelessWidget {
  const SIIAlgaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SII Algara - Portal Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colores institucionales
        primaryColor: const Color(0xFF003366),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Fondo Gris claro web
        
        // Estilo web para el AppBar (Blanco y limpio)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF003366),
          elevation: 1, // Sombra sutil para separar del contenido
          titleTextStyle: TextStyle(
            color: Color(0xFF003366),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Configuración de textos globales para web (más grandes y legibles)
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
          bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF374151)),
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
    // Obtenemos el ancho de la pantalla para hacerlo responsivo sutilmente
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance, color: Color(0xFF003366)),
            const SizedBox(width: 10),
            const Text('SII ALGARA - INSTITUTO INTEGRAL'),
          ],
        ),
        // Espacio para links típicos de web (opcional)
        actions: [
          TextButton(onPressed: () {}, child: const Text('Contacto')),
          TextButton(onPressed: () {}, child: const Text('Ayuda')),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sección de Bienvenida (Aprovecha el ancho)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido al Sistema de Información Integral',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Seleccione el portal de acceso correspondiente a su perfil para continuar.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            
            // 2. Sección de Tarjetas de Acceso (Layout Web horizontal)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Wrap(
                  spacing: 30, // Espacio horizontal entre tarjetas
                  runSpacing: 30, // Espacio vertical si se amontonan
                  alignment: WrapAlignment.center,
                  children: [
                    // Tarjeta Aspirantes
                    _buildWebActionTile(
                      context,
                      title: 'Portal de Aspirantes',
                      description: 'Si eres de nuevo ingreso, inicia tu proceso de admisión, consulta tu folio y resultados.',
                      icon: Icons.person_add_alt_1,
                      buttonText: 'Iniciar Registro',
                      onTap: () {
                       // Navigator.push(context, MaterialPageRoute(builder: (_) => const AspiranteHome()));
                      },
                    ),
                    
                    // Tarjeta Alumnos (Diseño "Desactivado")
                    _buildWebActionTile(
                      context,
                      title: 'Portal de Alumnos',
                      description: 'Accede a tu kárdex, horarios, reinscripciones y servicios escolares en línea.',
                      icon: Icons.school,
                      buttonText: 'Sección en Mantenimiento',
                      isActive: false, // Desactivado
                      onTap: () {},
                    ),
                    
                    // Tarjeta Personal
                    _buildWebActionTile(
                      context,
                      title: 'Portal del Personal',
                      description: 'Acceso exclusivo para docentes, coordinadores y personal administrativo del instituto.',
                      icon: Icons.manage_accounts,
                      buttonText: 'Ingresar al Portal',
                      onTap: () {
                       // Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalLogin()));
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Pie de página web sutil
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

  // Widget para crear tarjetas web grandes y detalladas
  Widget _buildWebActionTile(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    // Definimos un ancho fijo para las tarjetas estilo web
    const double tileWidth = 350;

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Container(
        width: tileWidth,
        height: 400, // Altura fija para que todas se vean iguales
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono grande y centrado
            Icon(icon, size: 70, color: const Color(0xFF003366)),
            const SizedBox(height: 25),
            
            // Título de la sección
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 15),
            
            // Descripción detallada
            Expanded(
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Botón de acción web
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isActive ? onTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366), // Azul
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey.shade400, // Color si está desactivado
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}