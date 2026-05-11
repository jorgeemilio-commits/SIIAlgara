import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfesorHome extends StatelessWidget {
  const ProfesorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Docente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Bienvenido, Profesor\nAcceso a listas y grupos confirmado.', 
          textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}