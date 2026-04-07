import 'package:flutter/material.dart';

import '../models/bandeja_perfil_profesional.dart';
import '../models/perfil_paciente_registro.dart';
import '../models/profesional_lista_item.dart';
import '../utils/geo_tucuman.dart';
import 'profesional_detalle_view.dart';

/// Lista de profesionales con orden según la necesidad del paciente y bandeja de perfil.
class ListaCuidadoresView extends StatefulWidget {
  const ListaCuidadoresView({super.key});

  @override
  State<ListaCuidadoresView> createState() => _ListaCuidadoresViewState();
}

class _ListaCuidadoresViewState extends State<ListaCuidadoresView> {
  bool _ordenMejorCalificados = false;

  static const Color _azul = Color(0xFF0D47A1);

  static bool _esNecesidadAltaComplejidad(String? necesidad) {
    if (necesidad == null || necesidad.isEmpty) return false;
    const altas = {'Post-operatorio', 'Discapacidad', 'Pediatría'};
    return altas.contains(necesidad);
  }

  static List<ProfesionalListaItem> _datosDemo() {
    return [
      ProfesionalListaItem(
        id: '1',
        nombre: 'Dra. Ana Pérez',
        especialidad: 'Lic. en Enfermería · Matrícula verificada',
        fotoUrl: 'https://i.pravatar.cc/300?img=5',
        bandeja: BandejaPerfilProfesional.verde,
        semaforoConfianzaVerde: true,
        fuerte: 'Especialista en movilidad y recuperación post-quirúrgica',
        biografia:
            'Enfermera universitaria con más de 12 años en cuidado domiciliario y hospitalario. '
            'Me enfoco en adultos mayores y post-operatorio, con comunicación clara con la familia.',
        etiquetas: const ['Inyectables', 'RCP', 'Geriatría', 'Heridas', 'Oxigenoterapia'],
        calificacionPromedio: 4.8,
        cantidadResenas: 24,
        zona: 'Barrio Norte',
        latitud: -26.805,
        longitud: -65.21,
        esNuevoTalento: false,
        disponibilidadManana: true,
        disponibilidadTarde: true,
        disponibilidadNoche: false,
      ),
      ProfesionalListaItem(
        id: '2',
        nombre: 'Lic. Roberto Sanz',
        especialidad: 'Enfermería · Post-operatorio y cuidados críticos',
        fotoUrl: 'https://i.pravatar.cc/300?img=12',
        bandeja: BandejaPerfilProfesional.verde,
        semaforoConfianzaVerde: true,
        fuerte: 'Puntualidad 100% en controles y visitas',
        biografia:
            'Acompaño procesos de alta complejidad en el hogar: controles frecuentes, coordinación con médico tratante '
            'y registro claro para la familia.',
        etiquetas: const ['Post-operatorio', 'RCP', 'Inyectables', 'SV y PICC', 'Oxigenoterapia'],
        calificacionPromedio: 4.9,
        cantidadResenas: 18,
        zona: 'Yerba Buena',
        latitud: -26.8167,
        longitud: -65.3167,
        esNuevoTalento: false,
        disponibilidadManana: true,
        disponibilidadTarde: true,
        disponibilidadNoche: true,
      ),
      ProfesionalListaItem(
        id: '3',
        nombre: 'Lucía Torres',
        especialidad: 'Estudiante avanzada de Enfermería (UNT)',
        fotoUrl: 'https://i.pravatar.cc/300?img=9',
        bandeja: BandejaPerfilProfesional.amarillo,
        semaforoConfianzaVerde: false,
        fuerte: 'Gran predisposición y calma en el día a día',
        biografia:
            'Estudiante de últimos años con práctica en geriatría. Busco acompañar con paciencia y buenos hábitos de hidratación y movilidad.',
        etiquetas: const ['Movilización', 'Acompañamiento', 'Pediatría básica', 'Primeros auxilios'],
        calificacionPromedio: 0.0,
        cantidadResenas: 0,
        zona: 'Tafí Viejo',
        latitud: -26.7333,
        longitud: -65.2667,
        esNuevoTalento: true,
        disponibilidadManana: true,
        disponibilidadTarde: true,
        disponibilidadNoche: false,
      ),
      ProfesionalListaItem(
        id: '4',
        nombre: 'Carlos Gómez',
        especialidad: 'Cuidador geriátrico · Acompañamiento terapéutico',
        fotoUrl: 'https://i.pravatar.cc/300?img=14',
        bandeja: BandejaPerfilProfesional.celeste,
        semaforoConfianzaVerde: false,
        fuerte: 'Gran predisposición · paseos y farmacia sin apuro',
        biografia:
            'Más de 8 años con adultos mayores. Trabajo en estimulación cognitiva simple, contención emocional y rutinas seguras en el hogar.',
        etiquetas: const ['Geriatría', 'Demencias leves', 'Paseos', 'Higiene asistida'],
        calificacionPromedio: 4.5,
        cantidadResenas: 8,
        zona: 'Yerba Buena',
        latitud: -26.818,
        longitud: -65.308,
        esNuevoTalento: false,
        disponibilidadManana: true,
        disponibilidadTarde: false,
        disponibilidadNoche: false,
      ),
      ProfesionalListaItem(
        id: '5',
        nombre: 'Marta López',
        especialidad: 'Auxiliar de enfermería',
        fotoUrl: 'https://i.pravatar.cc/300?img=16',
        bandeja: BandejaPerfilProfesional.amarillo,
        semaforoConfianzaVerde: false,
        fuerte: 'Puntualidad 100% en medicación y curaciones',
        biografia:
            'Auxiliar matriculada con experiencia en clínica y domicilio. Me gusta ordenar medicación y dejar indicaciones por escrito a la familia.',
        etiquetas: const ['Inyectables', 'Curaciones', 'Signos vitales', 'Geriatría'],
        calificacionPromedio: 4.6,
        cantidadResenas: 31,
        zona: 'San Miguel de Tucumán',
        latitud: -26.83,
        longitud: -65.23,
        esNuevoTalento: false,
        disponibilidadManana: false,
        disponibilidadTarde: true,
        disponibilidadNoche: true,
      ),
      ProfesionalListaItem(
        id: '6',
        nombre: 'Lic. Marcos Paz',
        especialidad: 'Lic. en Enfermería · SIPROSA',
        fotoUrl: 'https://i.pravatar.cc/300?img=3',
        bandeja: BandejaPerfilProfesional.verde,
        semaforoConfianzaVerde: true,
        fuerte: 'Especialista en movilidad y educación en patologías crónicas',
        biografia:
            'Enfermero con fuerte foco en Tucumán: seguimiento de patologías crónicas, educación al paciente y vínculo con obra social cuando hace falta.',
        etiquetas: const ['Geriatría', 'Diabetes', 'Hipertensión', 'Inyectables', 'RCP'],
        calificacionPromedio: 4.7,
        cantidadResenas: 15,
        zona: 'Barrio Norte',
        latitud: -26.806,
        longitud: -65.212,
        esNuevoTalento: false,
        disponibilidadManana: true,
        disponibilidadTarde: true,
        disponibilidadNoche: true,
      ),
    ];
  }

  static List<ProfesionalListaItem> _ordenarPorMejorCalificacion(List<ProfesionalListaItem> lista) {
    final copia = List<ProfesionalListaItem>.from(lista);
    copia.sort((a, b) {
      final cmp = b.calificacionPromedio.compareTo(a.calificacionPromedio);
      if (cmp != 0) return cmp;
      final r = b.cantidadResenas.compareTo(a.cantidadResenas);
      if (r != 0) return r;
      return a.nombre.compareTo(b.nombre);
    });
    return copia;
  }

  static List<ProfesionalListaItem> _ordenarLista(
    List<ProfesionalListaItem> lista,
    String? necesidadPaciente,
    bool altaComplejidad,
  ) {
    final copia = List<ProfesionalListaItem>.from(lista);
    copia.sort((a, b) {
      final pa = prioridadBandejaParaNecesidad(a.bandeja, necesidadPaciente);
      final pb = prioridadBandejaParaNecesidad(b.bandeja, necesidadPaciente);
      if (pa != pb) return pa.compareTo(pb);
      if (altaComplejidad) {
        if (a.semaforoConfianzaVerde != b.semaforoConfianzaVerde) {
          return a.semaforoConfianzaVerde ? -1 : 1;
        }
      }
      return a.nombre.compareTo(b.nombre);
    });
    return copia;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      appBar: AppBar(
        title: const Text('Profesionales recomendados'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<PerfilPacienteRegistro?>(
        future: PerfilPacienteRegistro.cargarGuardado(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final perfil = snapshot.data;
          final necesidad = perfil?.necesidadPrincipal;
          final altaComplejidad = _esNecesidadAltaComplejidad(necesidad);
          final datos = _datosDemo();
          final lista = _ordenMejorCalificados
              ? _ordenarPorMejorCalificacion(datos)
              : _ordenarLista(datos, necesidad, altaComplejidad);
          final refFamiliar = referenciaFamiliarTucuman(perfil);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (altaComplejidad) ...[
                const _BannerAltaComplejidad(),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  necesidad != null
                      ? 'Necesidad registrada: $necesidad'
                      : 'Profesionales verificados por Vitta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                _TextoFiltroInteligente(necesidad: necesidad),
                const SizedBox(height: 12),
              ],
              _SeleccionOrdenLista(
                ordenMejorCalificados: _ordenMejorCalificados,
                onChanged: (v) => setState(() => _ordenMejorCalificados = v),
              ),
              const SizedBox(height: 12),
              ...lista.map((p) {
                final km = distanciaKmHaversine(
                  refFamiliar.lat,
                  refFamiliar.lon,
                  p.latitud,
                  p.longitud,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TarjetaProfesional(
                    item: p,
                    distanciaKm: km,
                    destacado: altaComplejidad && p.semaforoConfianzaVerde,
                    pacienteAltaComplejidad: altaComplejidad,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SeleccionOrdenLista extends StatelessWidget {
  const _SeleccionOrdenLista({
    required this.ordenMejorCalificados,
    required this.onChanged,
  });

  final bool ordenMejorCalificados;
  final ValueChanged<bool> onChanged;

  static const Color _azul = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ordenar lista',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('Recomendado'),
              icon: Icon(Icons.tune_rounded, size: 18),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Mejor calificados'),
              icon: Icon(Icons.star_rounded, size: 18),
            ),
          ],
          selected: {ordenMejorCalificados},
          onSelectionChanged: (Set<bool> next) {
            if (next.isEmpty) return;
            onChanged(next.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return _azul;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return _azul;
              return Colors.white;
            }),
            side: WidgetStateProperty.all(BorderSide(color: _azul.withValues(alpha: 0.35))),
          ),
        ),
      ],
    );
  }
}

class _FilaValoracionEstrellas extends StatelessWidget {
  const _FilaValoracionEstrellas({
    required this.calificacion,
    required this.cantidadResenas,
  });

  final double calificacion;
  final int cantidadResenas;

  static const Color _doradoBrillante = Color(0xFFFFA000);
  static const Color _doradoClaro = Color(0xFFFFE082);

  @override
  Widget build(BuildContext context) {
    if (cantidadResenas == 0) {
      return Text(
        'Sin reseñas aún',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
          height: 1.2,
        ),
      );
    }
    final textoResenas = cantidadResenas == 1 ? '1 reseña' : '$cantidadResenas reseñas';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              size: 19,
              color: _doradoClaro.withValues(alpha: 0.85),
            ),
            Icon(
              Icons.star_rounded,
              size: 14,
              color: _doradoBrillante,
              shadows: const [
                Shadow(color: Color(0xFFFFF9C4), blurRadius: 6),
                Shadow(color: Color(0xFFFFD54F), blurRadius: 3),
              ],
            ),
          ],
        ),
        const SizedBox(width: 5),
        Text(
          calificacion.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '($textoResenas)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipNuevoTalento extends StatelessWidget {
  const _ChipNuevoTalento();

  @override
  Widget build(BuildContext context) {
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
}

class _FilaUbicacionDiscreta extends StatelessWidget {
  const _FilaUbicacionDiscreta({
    required this.zona,
    required this.distanciaKm,
  });

  final String zona;
  final double distanciaKm;

  @override
  Widget build(BuildContext context) {
    return Text(
      '📍 $zona · a ${distanciaKm.toStringAsFixed(1)} km',
      style: TextStyle(
        fontSize: 11.5,
        height: 1.25,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _TextoFiltroInteligente extends StatelessWidget {
  const _TextoFiltroInteligente({required this.necesidad});

  final String? necesidad;

  @override
  Widget build(BuildContext context) {
    String texto;
    switch (necesidad) {
      case 'Acompañamiento':
        texto =
            'Conectamos tu necesidad con el alcance adecuado: primero quienes se enfocan en cuidado y compañía (celeste).';
        break;
      case 'Adulto Mayor':
        texto =
            'Orden por afinidad: primero perfiles de cuidado y acompañamiento, según tu registro.';
        break;
      case 'Post-operatorio':
        texto =
            'Orden por afinidad: primero atención clínica (verde), alineada a post-operatorio y seguimiento.';
        break;
      case 'Pediatría':
      case 'Discapacidad':
        texto = 'Orden por afinidad: primero alcance clínico y asistencia sanitaria avanzada.';
        break;
      default:
        texto = 'Indicá la necesidad en tu registro para ordenar por alcance y especialidad.';
    }
    return Text(
      texto,
      style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey.shade700),
    );
  }
}

class _BannerAltaComplejidad extends StatelessWidget {
  const _BannerAltaComplejidad();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF9A9A)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.health_and_safety_outlined, color: Colors.red.shade800, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alta complejidad (nivel rojo)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Según el caso, destacamos primero el alcance clínico y, dentro de ese grupo, credenciales verificadas en Vitta.',
                  style: TextStyle(fontSize: 13, height: 1.35, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({
    required this.item,
    required this.distanciaKm,
    required this.destacado,
    required this.pacienteAltaComplejidad,
  });

  final ProfesionalListaItem item;
  final double distanciaKm;
  final bool destacado;
  final bool pacienteAltaComplejidad;

  static const Color _azul = Color(0xFF0D47A1);

  void _abrirDetalle(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProfesionalDetalleView(
          item: item,
          pacienteAltaComplejidad: pacienteAltaComplejidad,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = item.bandeja;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: destacado ? const Color(0xFFA5D6A7) : const Color(0xFFE0E0E0),
          width: destacado ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FotoPerfil(url: item.fotoUrl, nombre: item.nombre),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: b.colorAcento,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: b.colorAcento.withValues(alpha: 0.5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.nombre,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _azul,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _FilaValoracionEstrellas(
                        calificacion: item.calificacionPromedio,
                        cantidadResenas: item.cantidadResenas,
                      ),
                      if (item.esNuevoTalento) ...[
                        const SizedBox(height: 8),
                        const _ChipNuevoTalento(),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        b.tituloCategoria,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: b.colorAcento,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.etiquetaContexto,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (item.semaforoConfianzaVerde) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.verified, size: 15, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Confianza VITTA (matrícula verificada)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        item.especialidad,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _FilaUbicacionDiscreta(zona: item.zona, distanciaKm: distanciaKm),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fuerte: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.fuerte,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade900,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => _abrirDetalle(context),
              style: FilledButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ver Perfil y Disponibilidad',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FotoPerfil extends StatelessWidget {
  const _FotoPerfil({required this.url, required this.nombre});

  final String url;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 76,
            height: 76,
            color: Colors.blue.shade50,
            child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 76,
          height: 76,
          color: const Color(0xFFE3F2FD),
          alignment: Alignment.center,
          child: Text(
            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
        ),
      ),
    );
  }
}
