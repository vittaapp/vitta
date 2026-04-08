import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/registro_historial_clinico.dart';
import '../../providers/bitacora_provider.dart';
import '../../views/historial_completo_view.dart';

const Color _kAzulVitta = Color(0xFF0066CC);

class RecentBitacoraWidget extends ConsumerWidget {
  const RecentBitacoraWidget({
    Key? key,
    required this.pacienteId,
  }) : super(key: key);

  final String pacienteId;

  static const Color _azul = Color(0xFF0D47A1);

  static String _fmtHora(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _textoRegistro(RegistroHistorialClinico r) {
    final d = r.descripcion?.trim();
    if (d != null && d.isNotEmpty) return d;
    switch (r.tipoRegistro) {
      case TipoRegistroHistorial.turno:
        return 'Registro de turno';
      case TipoRegistroHistorial.observacion:
        return 'Observación';
      case TipoRegistroHistorial.medicacion:
        return 'Medicación';
      case TipoRegistroHistorial.emergencia:
        return 'Emergencia';
    }
  }

  static (IconData, Color) _icono(RegistroHistorialClinico r) {
    if (r.tipoRegistro == TipoRegistroHistorial.observacion) {
      return (Icons.note_rounded, const Color(0xFF1565C0));
    }
    if (r.signosVitales?.tieneAlguno == true) {
      return (Icons.favorite_rounded, Colors.red.shade700);
    }
    if (r.tipoRegistro == TipoRegistroHistorial.turno) {
      return (Icons.favorite_rounded, Colors.red.shade700);
    }
    if (r.tipoRegistro == TipoRegistroHistorial.medicacion) {
      return (Icons.medication_rounded, Colors.orange.shade800);
    }
    if (r.tipoRegistro == TipoRegistroHistorial.emergencia) {
      return (Icons.warning_amber_rounded, Colors.deepOrange);
    }
    return (Icons.article_rounded, Colors.grey.shade700);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pacienteId.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBDEFB)),
          boxShadow: [
            BoxShadow(
              color: _azul.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bitácora reciente',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _azul,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Registrá un paciente para ver la bitácora en tiempo real.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    final async = ref.watch(bitacoraProvider(pacienteId));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: _azul.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bitácora reciente',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _azul,
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: _kAzulVitta),
              ),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se pudo cargar la bitácora. Probá de nuevo más tarde.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$e',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            data: (lista) {
              if (lista.isEmpty) {
                return Text(
                  'Sin registros aún — los registros del cuidador aparecerán aquí.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                );
              }

              final visibles = lista.take(5).toList();
              final hayMas = lista.length > 5;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...visibles.map((r) {
                    final (iconData, colorData) = _icono(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 8),
                            child: Icon(iconData, size: 20, color: colorData),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              _fmtHora(r.fecha),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: _azul.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _textoRegistro(r),
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (hayMas) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                HistorialCompletoView(pacienteId: pacienteId),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver historial completo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _kAzulVitta,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
