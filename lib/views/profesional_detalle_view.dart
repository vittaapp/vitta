import 'package:flutter/material.dart';

import '../models/bandeja_perfil_profesional.dart';
import '../models/perfil_paciente_registro.dart';
import '../models/profesional_lista_item.dart';
import '../utils/geo_tucuman.dart';

/// Ficha del profesional: contacto solo vía app (sin teléfono).
class ProfesionalDetalleView extends StatelessWidget {
  const ProfesionalDetalleView({
    super.key,
    required this.item,
    required this.pacienteAltaComplejidad,
  });

  final ProfesionalListaItem item;
  final bool pacienteAltaComplejidad;

  static const Color _azul = Color(0xFF0D47A1);
  static const Color _doradoBrillante = Color(0xFFFFA000);
  static const Color _doradoClaro = Color(0xFFFFE082);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      body: FutureBuilder<PerfilPacienteRegistro?>(
        future: PerfilPacienteRegistro.cargarGuardado(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final ref = referenciaFamiliarTucuman(snapshot.data);
          final km = distanciaKmHaversine(
            ref.lat,
            ref.lon,
            item.latitud,
            item.longitud,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    item.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE3F2FD),
                          alignment: Alignment.center,
                          child: Text(
                            item.nombre.isNotEmpty ? item.nombre[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: _azul,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.nombre,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _azul,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _filaValoracionDetalle(),
                      if (item.esNuevoTalento) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _chipNuevoTalento(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _filaUbicacion(km),
                      const SizedBox(height: 14),
                      Text(
                        item.fuerte,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _bloqueBandejaYConfianza(),
                      const SizedBox(height: 18),
                      _seccionDisponibilidadHabitual(),
                      const SizedBox(height: 22),
                      Text(
                        'Biografía',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.biografia,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Especialidades y habilidades',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.etiquetas.map((e) {
                          return Chip(
                            label: Text(e),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.blue.shade100),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 22, color: _azul),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Por seguridad, el teléfono no se muestra todavía. '
                                'Todo contacto con este profesional se coordina solo desde Vitta.',
                                style: TextStyle(fontSize: 13, height: 1.35, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: pacienteAltaComplejidad
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _azul,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Solicitud de entrevista enviada a ${item.nombre} (demo).'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Solicitar Entrevista',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _azul,
                    side: const BorderSide(color: _azul, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calendario de ${item.nombre} (demo).'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Ver Calendario de Disponibilidad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _filaValoracionDetalle() {
    if (item.cantidadResenas == 0) {
      return Text(
        'Sin reseñas aún',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      );
    }
    final textoResenas =
        item.cantidadResenas == 1 ? '1 reseña' : '${item.cantidadResenas} reseñas';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              size: 22,
              color: _doradoClaro.withValues(alpha: 0.85),
            ),
            Icon(
              Icons.star_rounded,
              size: 16,
              color: _doradoBrillante,
              shadows: const [
                Shadow(color: Color(0xFFFFF9C4), blurRadius: 6),
                Shadow(color: Color(0xFFFFD54F), blurRadius: 3),
              ],
            ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          item.calificacionPromedio.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '($textoResenas)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filaUbicacion(double km) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${item.zona} • a ${km.toStringAsFixed(1)} km',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipNuevoTalento() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5C6BC0).withValues(alpha: 0.4)),
      ),
      child: Text(
        'Nuevo Talento',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.indigo.shade800,
        ),
      ),
    );
  }

  Widget _bloqueBandejaYConfianza() {
    final b = item.bandeja;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: b.colorAcento.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: b.colorAcento,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: b.colorAcento.withValues(alpha: 0.45), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.tituloNivelDetalle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: b.colorAcento,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.tituloCategoria,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: b.colorAcento.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.etiquetaContexto,
                      style: TextStyle(fontSize: 13, height: 1.35, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.semaforoConfianzaVerde) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.green.shade800, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semáforo verde de confianza',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Matrícula verificada en Vitta. Identidad y credenciales validadas.',
                          style: TextStyle(fontSize: 12, height: 1.3, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Perfil sin matrícula verificada al máximo nivel. Evaluá biografía y habilidades según tu necesidad.',
              style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seccionDisponibilidadHabitual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 22, color: _azul),
              const SizedBox(width: 8),
              const Text(
                'Disponibilidad habitual',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _azul,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _franjaHoraria(
                  emoji: '☀️',
                  etiqueta: 'Mañana',
                  activa: item.disponibilidadManana,
                ),
              ),
              Expanded(
                child: _franjaHoraria(
                  emoji: '⛅',
                  etiqueta: 'Tarde',
                  activa: item.disponibilidadTarde,
                ),
              ),
              Expanded(
                child: _franjaHoraria(
                  emoji: '🌙',
                  etiqueta: 'Noche',
                  activa: item.disponibilidadNoche,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _franjaHoraria({
    required String emoji,
    required String etiqueta,
    required bool activa,
  }) {
    final child = Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activa ? Colors.grey.shade900 : Colors.grey.shade400,
          ),
        ),
      ],
    );
    return Opacity(
      opacity: activa ? 1 : 0.38,
      child: child,
    );
  }
}
