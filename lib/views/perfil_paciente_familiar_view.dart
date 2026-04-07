import 'package:flutter/material.dart';

import '../models/perfil_paciente_registro.dart';
import 'registro_familiar_view.dart';

/// Resumen del perfil de salud y emergencias del paciente (datos guardados al registrar).
class PerfilPacienteFamiliarView extends StatefulWidget {
  const PerfilPacienteFamiliarView({super.key});

  @override
  State<PerfilPacienteFamiliarView> createState() => _PerfilPacienteFamiliarViewState();
}

class _PerfilPacienteFamiliarViewState extends State<PerfilPacienteFamiliarView> {
  static const Color _azul = Color(0xFF0D47A1);

  Future<PerfilPacienteRegistro?>? _carga;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  void _refrescar() {
    setState(() {
      _carga = PerfilPacienteRegistro.cargarGuardado();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        title: const Text('Mi familiar / Perfil del paciente'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<PerfilPacienteRegistro?>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final perfil = snapshot.data;
          if (perfil == null || _perfilVacio(perfil)) {
            return _vacio(context);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos de salud y contactos que el cuidador verá durante la guardia.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.35),
                ),
                const SizedBox(height: 18),
                _tarjeta(
                  titulo: 'Paciente',
                  icono: Icons.person_outline_rounded,
                  children: [
                    _fila('Nombre', perfil.nombrePaciente),
                    _fila('Edad', perfil.edadPaciente),
                    if (perfil.necesidadPrincipal != null && perfil.necesidadPrincipal!.isNotEmpty)
                      _fila('Necesidad principal', perfil.necesidadPrincipal!),
                    if (perfil.descripcionNecesidad.isNotEmpty)
                      _fila('Descripción', perfil.descripcionNecesidad),
                    if (perfil.ubicacionServicio.isNotEmpty)
                      _fila('Ubicación del servicio', perfil.ubicacionServicio),
                  ],
                ),
                const SizedBox(height: 14),
                _tarjeta(
                  titulo: 'Cobertura y emergencias',
                  icono: Icons.health_and_safety_outlined,
                  children: [
                    _fila('Obra Social / Prepaga', perfil.obraSocialPrepaga.isEmpty ? '—' : perfil.obraSocialPrepaga),
                    _fila('Teléfono de emergencia', perfil.telefonoEmergencia.isEmpty ? '—' : perfil.telefonoEmergencia),
                    _fila(
                      'Contacto emergencias desde la app',
                      perfil.autorizaContactoEmergenciaDesdeApp ? 'Autorizado' : 'No autorizado',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _azul,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(builder: (context) => const RegistroFamiliarView()),
                    );
                    _refrescar();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar datos (mismo formulario de registro)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _perfilVacio(PerfilPacienteRegistro p) {
    return p.nombrePaciente.isEmpty &&
        p.edadPaciente.isEmpty &&
        p.descripcionNecesidad.isEmpty &&
        p.ubicacionServicio.isEmpty &&
        p.obraSocialPrepaga.isEmpty &&
        p.telefonoEmergencia.isEmpty;
  }

  Widget _vacio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.heart_broken_outlined, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'Todavía no cargaste el perfil del paciente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),
            Text(
              'Completá el registro familiar para guardar salud, cobertura y emergencias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (context) => const RegistroFamiliarView()),
                );
                _refrescar();
              },
              child: const Text('Ir al registro familiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: _azul, size: 26),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _azul,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(valor, style: TextStyle(fontSize: 15, color: Colors.grey.shade900, height: 1.35)),
        ],
      ),
    );
  }
}
