import 'package:flutter/material.dart';

Future<void> showHomeQuickGuide(BuildContext context) {
  final es = Localizations.localeOf(context).languageCode == 'es';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(es ? 'Tu espacio en Hexora' : 'Your Hexora workspace'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: Text(es ? 'Selecciona un negocio' : 'Select a business'),
              subtitle: Text(es
                  ? 'Abre una tarjeta para acceder a sus facturas, documentos, equipo y calendario.'
                  : 'Open a card to access its invoices, documents, team and calendar.'),
            ),
            ListTile(
              leading: const Icon(Icons.star_border_rounded),
              title: Text(
                  es ? 'Organiza tus negocios' : 'Organize your businesses'),
              subtitle: Text(es
                  ? 'Busca por nombre y marca tus favoritos para encontrarlos rápidamente.'
                  : 'Search by name and mark favourites to find them quickly.'),
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(es ? 'Personaliza tu espacio' : 'Make it yours'),
              subtitle: Text(es
                  ? 'En Configuración puedes cambiar el idioma, la apariencia y tus preferencias de navegación.'
                  : 'Open Settings to change your language, appearance and navigation preferences.'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(es ? 'Entendido' : 'Got it'))
      ],
    ),
  );
}
