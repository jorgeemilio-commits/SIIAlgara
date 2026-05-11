import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoordinadorHome extends StatelessWidget {
  const CoordinadorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Coordinación'),
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
        child: Text('Bienvenido, Coordinador\nAcceso a solicitudes de aspirantes confirmado.', 
          textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}