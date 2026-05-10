import 'package:flutter/material.dart';
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
      title: 'SII Algara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF003366), // Azul Institucional
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Gris claro
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 90,
                  color: Color(0xFF003366),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SII ALGARA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 50),
                
                // Sección Aspirantes
                _buildRoleCard(
                  context,
                  title: 'Aspirantes',
                  description: 'Registro de nuevo ingreso y seguimiento',
                  icon: Icons.person_add_alt_1,
                  isActive: true,
                  onTap: () {
                    //Navigator.push(context, MaterialPageRoute(builder: (_) => const AspiranteHome()));
                  },
                ),
                const SizedBox(height: 20),

                // Sección Alumnos
                _buildRoleCard(
                  context,
                  title: 'Alumnos',
                  description: 'Sección en mantenimiento',
                  icon: Icons.school,
                  isActive: false,
                  onTap: () {},
                ),
                const SizedBox(height: 20),

                // Sección Personal
                _buildRoleCard(
                  context,
                  title: 'Personal',
                  description: 'Portal para Profesores y Coordinadores',
                  icon: Icons.manage_accounts,
                  isActive: true,
                  onTap: () {
                   //Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalLogin()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {
    required String title, 
    required String description, 
    required IconData icon, 
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: isActive ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ] : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF003366).withOpacity(0.08)
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 38, color: isActive ? const Color(0xFF003366) : Colors.white),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFF003366) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive) Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}