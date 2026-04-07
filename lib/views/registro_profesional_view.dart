import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Imagen (cámara/galería) o archivo desde selector (imagen/PDF).
class _AdjuntoDni {
  _AdjuntoDni._({this.xfile, this.platformFile})
      : assert(xfile != null || platformFile != null);

  factory _AdjuntoDni.desdeXFile(XFile f) => _AdjuntoDni._(xfile: f);

  factory _AdjuntoDni.desdePlatform(PlatformFile f) => _AdjuntoDni._(platformFile: f);

  final XFile? xfile;
  final PlatformFile? platformFile;

  bool get esPdf {
    final ext = platformFile?.extension?.toLowerCase();
    if (ext == 'pdf') return true;
    final n = platformFile?.name.toLowerCase() ?? '';
    return n.endsWith('.pdf');
  }

  String get etiquetaCorta {
    if (platformFile != null) {
      final n = platformFile!.name;
      return n.length > 22 ? '${n.substring(0, 19)}…' : n;
    }
    return 'Imagen';
  }

  Future<Uint8List?> bytesParaVista() async {
    if (xfile != null) return xfile!.readAsBytes();
    final p = platformFile;
    if (p == null) return null;
    if (p.bytes != null) return p.bytes;
    return null;
  }
}

class RegistroProfesionalView extends StatefulWidget {
  const RegistroProfesionalView({super.key});

  @override
  State<RegistroProfesionalView> createState() => _RegistroProfesionalViewState();
}

class _RegistroProfesionalViewState extends State<RegistroProfesionalView> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _institucionController = TextEditingController();
  final TextEditingController _anioCursadoController = TextEditingController();
  final TextEditingController _experienciaController = TextEditingController();

  _AdjuntoDni? _frenteDni;
  _AdjuntoDni? _dorsoDni;
  XFile? _selfieSeguridad;

  String? _categoriaSeleccionada;
  bool _tieneSeguro = false;

  final List<String> _categorias = [
    'Enfermero Matriculado',
    'Estudiante de Enfermería',
    'Cuidador / Acompañante',
  ];

  static const Color _azulMedico = Color(0xFF0D47A1);
  static const Color _azulMedicoClaro = Color(0xFF1565C0);

  @override
  void dispose() {
    _scrollController.dispose();
    _nombreController.dispose();
    _especialidadController.dispose();
    _matriculaController.dispose();
    _institucionController.dispose();
    _anioCursadoController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  List<String> _recolectarErroresValidacion() {
    final errores = <String>[];

    if (_frenteDni == null) {
      errores.add('Cargá el frente del DNI (foto, imagen o PDF).');
    }
    if (_dorsoDni == null) {
      errores.add('Cargá el dorso del DNI (foto, imagen o PDF).');
    }
    if (_selfieSeguridad == null) {
      errores.add('Tomate la selfie de seguridad para validar tu identidad.');
    }
    if (_nombreController.text.trim().isEmpty) {
      errores.add('Escribí tu nombre y apellido como figura en el DNI.');
    }
    if (_especialidadController.text.trim().isEmpty) {
      errores.add('Indicá tu especialidad o área de trabajo.');
    }
    if (_categoriaSeleccionada == null) {
      errores.add('Elegí cuál es tu formación en el menú desplegable.');
    }

    switch (_categoriaSeleccionada) {
      case 'Enfermero Matriculado':
        if (_matriculaController.text.trim().isEmpty) {
          errores.add('Escribí tu número de matrícula (Tucumán).');
        }
        break;
      case 'Estudiante de Enfermería':
        if (_institucionController.text.trim().isEmpty) {
          errores.add('Indicá en qué institución estudiás.');
        }
        if (_anioCursadoController.text.trim().isEmpty) {
          errores.add('Indicá el año de cursado actual.');
        }
        break;
      case 'Cuidador / Acompañante':
        if (_experienciaController.text.trim().isEmpty) {
          errores.add('Completá el resumen de experiencia o referencias.');
        }
        break;
      default:
        break;
    }

    return errores;
  }

  void _mostrarErrores(List<String> errores) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.shield_outlined, color: _azulMedicoClaro, size: 40),
        title: const Text('Revisá la documentación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Corregí lo siguiente y volvé a intentar:',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              ...errores.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: _azulMedicoClaro, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(e, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _finalizarRegistro() {
    final errores = _recolectarErroresValidacion();
    if (errores.isNotEmpty) {
      if (_frenteDni == null || _dorsoDni == null || _selfieSeguridad == null) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
      _mostrarErrores(errores);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '¡Listo! Recibimos tu solicitud. Te avisamos cuando validemos tu perfil.',
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _mostrarOpcionesDni({required bool esFrente}) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    esFrente ? 'Frente del DNI' : 'Dorso del DNI',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: _azulMedico),
                  title: const Text('Usar cámara'),
                  subtitle: const Text('Sacá una foto al documento'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _capturarDniCamara(esFrente: esFrente);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.folder_open_outlined, color: _azulMedico),
                  title: const Text('Subir archivo o PDF'),
                  subtitle: const Text('Imagen o PDF desde archivos o galería'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _subirArchivoDni(esFrente: esFrente);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _capturarDniCamara({required bool esFrente}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null || !mounted) return;
      setState(() {
        final adj = _AdjuntoDni.desdeXFile(picked);
        if (esFrente) {
          _frenteDni = adj;
        } else {
          _dorsoDni = adj;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _snackError('No pudimos usar la cámara. Revisá permisos o probá subir un archivo.');
    }
  }

  Future<void> _subirArchivoDni({required bool esFrente}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final f = result.files.single;
      if (f.size == 0 && (f.bytes == null || f.bytes!.isEmpty)) {
        _snackError('No se pudo leer el archivo. Probá con otro.');
        return;
      }
      setState(() {
        final adj = _AdjuntoDni.desdePlatform(f);
        if (esFrente) {
          _frenteDni = adj;
        } else {
          _dorsoDni = adj;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _snackError('Error al elegir el archivo.');
    }
  }

  /// Solo cámara frontal en vivo: no se permite galería para la selfie de validación.
  Future<void> _tomarSelfieValidacionEnVivo() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null || !mounted) return;
      setState(() => _selfieSeguridad = picked);
    } catch (e) {
      if (!mounted) return;
      _snackError('No pudimos abrir la cámara frontal. Revisá los permisos.');
    }
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azulTitulo = _azulMedico;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sumate al equipo VITTA'),
        backgroundColor: _azulMedico,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE8EEF5),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completá tu perfil profesional',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _azulMedicoClaro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Validamos tu identidad de forma segura. Los datos están protegidos.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.35),
            ),
            const SizedBox(height: 22),

            // --- DNI flexible ---
            _tarjetaSeguridad(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tituloSeccion(
                    icon: Icons.badge_outlined,
                    titulo: 'Documento nacional (DNI)',
                    subtitulo:
                        'Usá la cámara o subí una imagen o PDF desde tus archivos.',
                  ),
                  const SizedBox(height: 18),
                  _bloqueDniLado(
                    etiqueta: 'Frente del DNI',
                    adjunto: _frenteDni,
                    onElegir: () => _mostrarOpcionesDni(esFrente: true),
                  ),
                  const SizedBox(height: 20),
                  _bloqueDniLado(
                    etiqueta: 'Dorso del DNI',
                    adjunto: _dorsoDni,
                    onElegir: () => _mostrarOpcionesDni(esFrente: false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // --- Selfie en vivo (solo cámara frontal; sin galería) ---
            _tarjetaSeguridad(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tituloSeccion(
                    icon: Icons.verified_user_outlined,
                    titulo: 'Validación de Identidad',
                    subtitulo:
                        'Selfie en vivo obligatoria: solo cámara frontal, sin elegir fotos guardadas.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _azulMedicoClaro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _tomarSelfieValidacionEnVivo,
                      icon: const Icon(Icons.camera_front_outlined, size: 22),
                      label: const Text(
                        'Tomar Selfie de Validación',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      'Sacate una foto de frente, con buena luz y sin lentes. '
                      'Esta foto se validará contra tu DNI.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: _vistaPreviaSelfieCircular(_selfieSeguridad)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Tus datos',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: azulTitulo,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: _decorationCampo(
                label: 'Nombre y apellido',
                hint: 'Como figura en tu DNI',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _especialidadController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decorationCampo(
                label: 'Especialidad',
                hint: 'Ej: adulto mayor, cuidados paliativos…',
                icon: Icons.medical_information_outlined,
              ),
            ),

            const SizedBox(height: 22),

            DropdownMenu<String>(
              width: MediaQuery.sizeOf(context).width - 40,
              label: const Text('¿Cuál es tu formación?'),
              leadingIcon: Icon(Icons.school_outlined, color: _azulMedico),
              hintText: 'Elegí una opción',
              initialSelection: _categoriaSeleccionada,
              dropdownMenuEntries: [
                for (final cat in _categorias)
                  DropdownMenuEntry<String>(value: cat, label: cat),
              ],
              onSelected: (value) {
                setState(() => _categoriaSeleccionada = value);
              },
            ),

            const SizedBox(height: 20),

            if (_categoriaSeleccionada == 'Enfermero Matriculado') ...[
              TextField(
                controller: _matriculaController,
                keyboardType: TextInputType.text,
                decoration: _decorationCampo(
                  label: 'Número de Matrícula (Tucumán)',
                  hint: '',
                  icon: Icons.numbers_rounded,
                  helperText: 'Será validada con el SIPROSA',
                ),
              ),
              const SizedBox(height: 15),
              SwitchListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                activeThumbColor: _azulMedicoClaro,
                activeTrackColor: _azulMedicoClaro.withValues(alpha: 0.35),
                title: const Text('¿Tenés Seguro de Mala Praxis vigente?'),
                value: _tieneSeguro,
                onChanged: (val) => setState(() => _tieneSeguro = val),
              ),
            ],

            if (_categoriaSeleccionada == 'Estudiante de Enfermería') ...[
              TextField(
                controller: _institucionController,
                textCapitalization: TextCapitalization.words,
                decoration: _decorationCampo(
                  label: 'Institución (UNT, Cruz Roja, etc.)',
                  hint: '',
                  icon: Icons.apartment_outlined,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _anioCursadoController,
                decoration: _decorationCampo(
                  label: 'Año de cursado actual',
                  hint: '',
                  icon: Icons.calendar_today_outlined,
                ),
                keyboardType: TextInputType.number,
              ),
            ],

            if (_categoriaSeleccionada == 'Cuidador / Acompañante') ...[
              TextField(
                controller: _experienciaController,
                maxLines: 3,
                decoration: _decorationCampo(
                  label: 'Resumen de experiencia y referencias',
                  hint: 'Ej: 5 años cuidando adultos mayores…',
                  icon: Icons.description_outlined,
                ),
              ),
            ],

            const SizedBox(height: 28),

            _tarjetaSeguridad(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fact_check_outlined, color: _azulMedico, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Revisá antes de enviar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _azulMedico,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Miniaturas de lo que vamos a validar:',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _miniaturaDni('Frente', _frenteDni)),
                      const SizedBox(width: 10),
                      Expanded(child: _miniaturaDni('Dorso', _dorsoDni)),
                      const SizedBox(width: 10),
                      Expanded(child: _miniaturaSelfie('Selfie', _selfieSeguridad)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _azulMedico,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _finalizarRegistro,
                child: const Text('FINALIZAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decorationCampo({
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      prefixIcon: Icon(icon, color: _azulMedico),
    );
  }

  Widget _tarjetaSeguridad({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: _azulMedico.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _tituloSeccion({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _azulMedico, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _azulMedico,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.35),
        ),
      ],
    );
  }

  Widget _bloqueDniLado({
    required String etiqueta,
    required _AdjuntoDni? adjunto,
    required VoidCallback onElegir,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _azulMedicoClaro,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onElegir,
          icon: const Icon(Icons.add_a_photo_outlined, size: 22),
          label: Text(
            adjunto == null ? 'Cargar archivo o foto' : 'Cambiar archivo o foto',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _azulMedico,
            side: BorderSide(color: _azulMedicoClaro, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        _vistaPreviaGrandeDni(adjunto),
      ],
    );
  }

  Widget _vistaPreviaGrandeDni(_AdjuntoDni? adj) {
    return AspectRatio(
      aspectRatio: 1.58,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: adj == null
            ? _placeholderCarnet()
            : adj.esPdf
                ? _placeholderPdf(adj.etiquetaCorta)
                : FutureBuilder<Uint8List?>(
                    key: ValueKey('${adj.xfile?.path ?? adj.platformFile?.name}'),
                    future: adj.bytesParaVista(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final data = snapshot.data;
                      if (data != null && data.isNotEmpty) {
                        return Image.memory(data, fit: BoxFit.cover);
                      }
                      return _placeholderCarnet();
                    },
                  ),
      ),
    );
  }

  /// Vista previa de la selfie en círculo (confirmación visual).
  Widget _vistaPreviaSelfieCircular(XFile? file) {
    const double tamano = 220;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _azulMedicoClaro, width: 3),
        boxShadow: [
          BoxShadow(
            color: _azulMedico.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: file == null
          ? _placeholderSelfieCircular()
          : FutureBuilder<Uint8List>(
              key: ValueKey(file.path),
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: tamano,
                  height: tamano,
                );
              },
            ),
    );
  }

  Widget _placeholderCarnet() {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_outlined, size: 52, color: Colors.blue.shade300),
          const SizedBox(height: 8),
          Text(
            'Sin archivo',
            style: TextStyle(fontSize: 14, color: Colors.blue.shade400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _placeholderPdf(String nombre) {
    return Container(
      color: const Color(0xFFFFEBEE),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.red.shade700),
          const SizedBox(height: 8),
          Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _placeholderSelfieCircular() {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.face_retouching_natural_outlined, size: 48, color: Colors.blue.shade300),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Vista previa',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.blue.shade400, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniaturaDni(String titulo, _AdjuntoDni? adj) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _azulMedico),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _thumbDni(adj),
          ),
        ),
      ],
    );
  }

  Widget _miniaturaSelfie(String titulo, XFile? f) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _azulMedico),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _thumbSelfie(f),
          ),
        ),
      ],
    );
  }

  Widget _thumbDni(_AdjuntoDni? adj) {
    if (adj == null) {
      return Icon(Icons.image_not_supported_outlined, color: Colors.blue.shade200, size: 32);
    }
    if (adj.esPdf) {
      return Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 36);
    }
    return FutureBuilder<Uint8List?>(
      key: ValueKey('thumb_${adj.xfile?.path ?? adj.platformFile?.name}'),
      future: adj.bytesParaVista(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null || snap.data!.isEmpty) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }

  Widget _thumbSelfie(XFile? f) {
    if (f == null) {
      return Icon(Icons.face_outlined, color: Colors.blue.shade200, size: 32);
    }
    return FutureBuilder<Uint8List>(
      key: ValueKey('thumb_${f.path}'),
      future: f.readAsBytes(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }
}
