import 'package:flutter/material.dart';

class AdminAprobacionesView extends StatelessWidget {
  const AdminAprobacionesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel de Aprobaciones")),
      body: const Center(child: Text("Lista de profesionales pendientes")),
    );
  }
}