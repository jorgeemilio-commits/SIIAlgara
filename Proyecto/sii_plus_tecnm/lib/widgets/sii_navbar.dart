import 'package:flutter/material.dart';

class SiiNavTab {
  final String label;
  final IconData icon;
  const SiiNavTab({required this.label, required this.icon});
}

class SiiNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final List<SiiNavTab> tabs;
  final int indexSeleccionado;
  final Function(int) onTabSelected;
  final VoidCallback onLogout;

  const SiiNavbar({
    super.key,
    required this.titulo,
    required this.tabs,
    required this.indexSeleccionado,
    required this.onTabSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF003366),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      elevation: 4,
      title: Row(
        children: [
          const Icon(Icons.account_balance, size: 28),
          const SizedBox(width: 12),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        // Generamos los botones dinámicamente según las pestañas recibidas
        ...tabs.asMap().entries.map((entry) {
          int idx = entry.key;
          SiiNavTab tab = entry.value;
          bool esActivo = indexSeleccionado == idx;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: esActivo ? Colors.orangeAccent : Colors.white70,
              ),
              icon: Icon(tab.icon, size: 20),
              label: Text(tab.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => onTabSelected(idx),
            ),
          );
        }),
        const VerticalDivider(color: Colors.white24, width: 32, indent: 15, endIndent: 15),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          tooltip: 'Cerrar Sesión',
          onPressed: onLogout,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}