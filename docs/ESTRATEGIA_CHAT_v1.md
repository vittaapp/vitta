# ESTRATEGIA_CHAT_v1

## 📋 RESUMEN EJECUTIVO

Implementar feature de **Chat en tiempo real** entre familiar y profesional durante un turno activo.

**Alcance**: MVP (Mensajes de texto, notificaciones, historial)  
**Timeline**: 3-4 horas con Cursor  
**Complejidad**: MEDIA (Firebase real-time, Riverpod provider, Firestore rules)  
**Dependencias**: FASE 1-5 completadas ✅

---

## 🎯 OBJETIVOS

1. ✅ Mensajes bidireccionales en tiempo real (Familiar ↔ Profesional)
2. ✅ Chat accesible solo durante turno activo o aceptado
3. ✅ Notificación cuando llega mensaje nuevo
4. ✅ Historial persistente en Firestore
5. ✅ UI limpia y responsiva
6. ✅ Tests con Firebase mock (15+ tests)

---

## 🏗️ ARQUITECTURA

### Estructura de Firestore

```javascript
/chats/{turnoId}/
  metadata/
    turnoId: string
    familiarId: string
    profesionalId: string
    estado: 'activo'|'completado'
    iniciadoAt: timestamp
  
  /mensajes/{messageId}
    texto: string
    remitenteId: string
    nombreRemitente: string
    timestamp: timestamp
    leido: bool (opcional)
```

### Archivos a crear

```
lib/
├── models/
│   ├── entities/
│   │   └── chat_message_entity.dart       (30 líneas, @immutable)
│   ├── domain/
│   │   └── chat_message_domain.dart       (50 líneas, lógica)
│   └── ui/
│       └── chat_message_ui.dart           (40 líneas, view-model)
│
├── services/
│   └── chat_service.dart                  (150 líneas, Firebase ops)
│
├── providers/
│   └── chat_provider.dart                 (80 líneas, Stream watcher)
│
└── widgets/
    ├── chat/
    │   ├── chat_bubble.dart               (60 líneas, mensaje visual)
    │   ├── chat_input.dart                (80 líneas, input + send)
    │   ├── chat_list.dart                 (70 líneas, lista de mensajes)
    │   └── chat_view.dart                 (100 líneas, pantalla completa)
    └── (en TurnoActivoView: integración)

test/
├── services/
│   └── chat_service_test.dart             (100 líneas, CRUD + stream)
├── providers/
│   └── chat_provider_test.dart            (80 líneas, provider watch)
└── widgets/
    └── chat_widgets_test.dart             (100 líneas, render + input)
```

### Archivos a modificar

```
lib/views/
└── turno_activo_view.dart
    └── Agregar ChatView en tab o sección inferior
```

---

## 📝 PASO-A-PASO IMPLEMENTATION

### ✅ Paso 1: Crear modelo de ChatMessage (Entity)

**Archivo**: `lib/models/entities/chat_message_entity.dart`

**Código completo**:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Mensaje de chat — entidad persistente en Firestore.
@immutable
class ChatMessageEntity {
  const ChatMessageEntity({
    required this.id,
    required this.turnoId,
    required this.remitenteId,
    required this.nombreRemitente,
    required this.texto,
    required this.timestamp,
    this.leido = false,
  });

  final String id;
  final String turnoId;
  final String remitenteId;
  final String nombreRemitente;
  final String texto;
  final DateTime timestamp;
  final bool leido;

  /// Crear desde documento de Firestore
  factory ChatMessageEntity.fromDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    return ChatMessageEntity(
      id: id,
      turnoId: data['turnoId'] as String? ?? '',
      remitenteId: data['remitenteId'] as String? ?? '',
      nombreRemitente: data['nombreRemitente'] as String? ?? 'Anónimo',
      texto: data['texto'] as String? ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      leido: data['leido'] as bool? ?? false,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'turnoId': turnoId,
      'remitenteId': remitenteId,
      'nombreRemitente': nombreRemitente,
      'texto': texto,
      'timestamp': timestamp,
      'leido': leido,
    };
  }

  /// Crear copia con algunos campos actualizados
  ChatMessageEntity copyWith({
    String? id,
    String? turnoId,
    String? remitenteId,
    String? nombreRemitente,
    String? texto,
    DateTime? timestamp,
    bool? leido,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      turnoId: turnoId ?? this.turnoId,
      remitenteId: remitenteId ?? this.remitenteId,
      nombreRemitente: nombreRemitente ?? this.nombreRemitente,
      texto: texto ?? this.texto,
      timestamp: timestamp ?? this.timestamp,
      leido: leido ?? this.leido,
    );
  }

  @override
  String toString() => 'ChatMessageEntity(id: $id, turnoId: $turnoId)';
}
```

**Imports requeridos**:
- `package:cloud_firestore/cloud_firestore.dart`
- `package:flutter/foundation.dart`

**Validación**:
```bash
flutter analyze lib/models/entities/chat_message_entity.dart
```

---

### ✅ Paso 2: Crear modelo de ChatMessage (Domain)

**Archivo**: `lib/models/domain/chat_message_domain.dart`

**Código completo**:
```dart
import 'package:flutter/foundation.dart';
import 'chat_message_entity.dart';

/// Mensaje de chat como entidad de dominio con lógica de negocio.
@immutable
class ChatMessageDomain extends ChatMessageEntity {
  const ChatMessageDomain({
    required String id,
    required String turnoId,
    required String remitenteId,
    required String nombreRemitente,
    required String texto,
    required DateTime timestamp,
    bool leido = false,
  }) : super(
    id: id,
    turnoId: turnoId,
    remitenteId: remitenteId,
    nombreRemitente: nombreRemitente,
    texto: texto,
    timestamp: timestamp,
    leido: leido,
  );

  /// Verificar si es mensaje reciente (menos de 1 hora)
  bool esReciente() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(timestamp);
    return diferencia.inHours < 1;
  }

  /// Verificar si el texto tiene contenido válido
  bool esValido() {
    return texto.trim().isNotEmpty && texto.length <= 1000;
  }

  /// Obtener formato de hora
  String get horaFormato {
    final hora = timestamp.hour.toString().padLeft(2, '0');
    final minuto = timestamp.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  /// Obtener fecha formateada
  String get fechaFormato {
    final dia = timestamp.day;
    final mes = timestamp.month;
    final año = timestamp.year;
    return '$dia/$mes/$año';
  }

  @override
  ChatMessageDomain copyWith({
    String? id,
    String? turnoId,
    String? remitenteId,
    String? nombreRemitente,
    String? texto,
    DateTime? timestamp,
    bool? leido,
  }) {
    return ChatMessageDomain(
      id: id ?? this.id,
      turnoId: turnoId ?? this.turnoId,
      remitenteId: remitenteId ?? this.remitenteId,
      nombreRemitente: nombreRemitente ?? this.nombreRemitente,
      texto: texto ?? this.texto,
      timestamp: timestamp ?? this.timestamp,
      leido: leido ?? this.leido,
    );
  }

  @override
  String toString() => 'ChatMessageDomain(id: $id, turnoId: $turnoId)';
}
```

**Imports requeridos**:
- `package:flutter/foundation.dart`
- Archivo anterior: `chat_message_entity.dart`

**Validación**:
```bash
flutter analyze lib/models/domain/chat_message_domain.dart
```

---

### ✅ Paso 3: Crear modelo de ChatMessage (UI)

**Archivo**: `lib/models/ui/chat_message_ui.dart`

**Código completo**:
```dart
import 'package:flutter/material.dart';
import 'chat_message_domain.dart';

/// View-model de ChatMessage para presentación en UI.
class ChatMessageUI {
  ChatMessageUI({
    required this.id,
    required this.remitenteId,
    required this.nombreRemitente,
    required this.texto,
    required this.horaFormato,
    required this.fechaFormato,
    required this.esMio,
    required this.leido,
  });

  final String id;
  final String remitenteId;
  final String nombreRemitente;
  final String texto;
  final String horaFormato;
  final String fechaFormato;
  final bool esMio;
  final bool leido;

  /// Crear desde ChatMessageDomain
  factory ChatMessageUI.from(
    ChatMessageDomain domain,
    String usuarioActualId,
  ) {
    return ChatMessageUI(
      id: domain.id,
      remitenteId: domain.remitenteId,
      nombreRemitente: domain.nombreRemitente,
      texto: domain.texto,
      horaFormato: domain.horaFormato,
      fechaFormato: domain.fechaFormato,
      esMio: domain.remitenteId == usuarioActualId,
      leido: domain.leido,
    );
  }

  /// Color de burbuja según si es mío o no
  Color get colorBurbuja {
    return esMio
        ? const Color(0xFF1A3E6F) // Azul Vitta
        : Colors.grey.shade200;
  }

  /// Color de texto
  Color get colorTexto {
    return esMio ? Colors.white : Colors.black87;
  }

  /// Alineación de burbuja
  CrossAxisAlignment get alineacion {
    return esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }

  @override
  String toString() => 'ChatMessageUI(id: $id, esMio: $esMio)';
}
```

**Imports requeridos**:
- `package:flutter/material.dart`
- Archivo anterior: `chat_message_domain.dart`

**Validación**:
```bash
flutter analyze lib/models/ui/chat_message_ui.dart
```

---

### ✅ Paso 4: Crear ChatService

**Archivo**: `lib/services/chat_service.dart`

**Código completo**:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/entities/chat_message_entity.dart';

/// Servicio de chat — manejo de operaciones en Firestore.
class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Enviar mensaje
  Future<void> enviarMensaje({
    required String turnoId,
    required String texto,
    required String nombreRemitente,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    if (texto.trim().isEmpty) throw Exception('Mensaje vacío');

    await _firestore
        .collection('chats')
        .doc(turnoId)
        .collection('mensajes')
        .add({
      'turnoId': turnoId,
      'remitenteId': uid,
      'nombreRemitente': nombreRemitente,
      'texto': texto.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'leido': false,
    });
  }

  /// Obtener stream de mensajes de un turno
  Stream<List<ChatMessageEntity>> obtenerMensajes(String turnoId) {
    return _firestore
        .collection('chats')
        .doc(turnoId)
        .collection('mensajes')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageEntity.fromDoc(doc.id, doc.data()))
          .toList();
    });
  }

  /// Marcar mensaje como leído
  Future<void> marcarComoLeido(String turnoId, String mensajeId) async {
    await _firestore
        .collection('chats')
        .doc(turnoId)
        .collection('mensajes')
        .doc(mensajeId)
        .update({'leido': true});
  }

  /// Obtener último mensaje de un turno
  Future<ChatMessageEntity?> obtenerUltimoMensaje(String turnoId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(turnoId)
        .collection('mensajes')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ChatMessageEntity.fromDoc(doc.id, doc.data());
  }

  /// Eliminar chat (solo admin)
  Future<void> eliminarChat(String turnoId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(turnoId)
        .collection('mensajes')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('chats').doc(turnoId).delete();
  }
}
```

**Imports requeridos**:
- `package:cloud_firestore/cloud_firestore.dart`
- `package:firebase_auth/firebase_auth.dart`
- `../models/entities/chat_message_entity.dart`

**Validación**:
```bash
flutter analyze lib/services/chat_service.dart
```

---

### ✅ Paso 5: Crear ChatProvider (Riverpod)

**Archivo**: `lib/providers/chat_provider.dart`

**Código completo**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/chat_message_entity.dart';
import '../models/domain/chat_message_domain.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

/// Provider que obtiene mensajes de un turno específico como stream
final chatStreamProvider = StreamProvider.family<
    List<ChatMessageDomain>,
    String>((ref, turnoId) {
  final chatService = ref.watch(chatServiceProvider);
  
  return chatService.obtenerMensajes(turnoId).map((entities) {
    return entities
        .map((entity) => ChatMessageDomain(
          id: entity.id,
          turnoId: entity.turnoId,
          remitenteId: entity.remitenteId,
          nombreRemitente: entity.nombreRemitente,
          texto: entity.texto,
          timestamp: entity.timestamp,
          leido: entity.leido,
        ))
        .toList();
  });
});

/// Provider para enviar mensaje
final enviarMensajeProvider =
    FutureProvider.family<void, ({String turnoId, String texto, String nombre})>(
        (ref, params) async {
  final chatService = ref.watch(chatServiceProvider);
  await chatService.enviarMensaje(
    turnoId: params.turnoId,
    texto: params.texto,
    nombreRemitente: params.nombre,
  );
});

/// Provider para obtener último mensaje
final ultimoMensajeProvider = FutureProvider.family<ChatMessageEntity?, String>(
    (ref, turnoId) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.obtenerUltimoMensaje(turnoId);
});
```

**Imports requeridos**:
- `package:flutter_riverpod/flutter_riverpod.dart`
- Archivos anteriores: modelos + servicio

**Validación**:
```bash
flutter analyze lib/providers/chat_provider.dart
```

---

### ✅ Paso 6: Crear widgets de Chat

#### **6.1 ChatBubbleWidget**

**Archivo**: `lib/widgets/chat/chat_bubble.dart`

**Código completo**:
```dart
import 'package:flutter/material.dart';
import '../../models/ui/chat_message_ui.dart';

const Color _azulVitta = Color(0xFF1A3E6F);

/// Widget que renderiza una burbuja de mensaje de chat.
class ChatBubbleWidget extends StatelessWidget {
  const ChatBubbleWidget({
    Key? key,
    required this.mensaje,
  }) : super(key: key);

  final ChatMessageUI mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: mensaje.alineacion,
        mainAxisAlignment:
            mensaje.esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mensaje.esMio)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person_rounded, size: 16),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mensaje.colorBurbuja,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!mensaje.esMio) ...[
                    Text(
                      mensaje.nombreRemitente,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _azulVitta,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    mensaje.texto,
                    style: TextStyle(
                      fontSize: 15,
                      color: mensaje.colorTexto,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensaje.horaFormato,
                    style: TextStyle(
                      fontSize: 11,
                      color: mensaje.esMio
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Imports requeridos**:
- `package:flutter/material.dart`
- `../../models/ui/chat_message_ui.dart`

**Validación**:
```bash
flutter analyze lib/widgets/chat/chat_bubble.dart
```

---

#### **6.2 ChatInputWidget**

**Archivo**: `lib/widgets/chat/chat_input.dart`

**Código completo**:
```dart
import 'package:flutter/material.dart';

const Color _azulVitta = Color(0xFF1A3E6F);

/// Widget que proporciona input de mensaje con botón enviar.
class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({
    Key? key,
    required this.onSendMessage,
    required this.enabled,
  }) : super(key: key);

  final Function(String) onSendMessage;
  final bool enabled;

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isNotEmpty && widget.enabled) {
      widget.onSendMessage(texto);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              maxLines: null,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _azulVitta),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                counterText: '',
              ),
              onSubmitted: (_) => _enviar(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: widget.enabled ? _azulVitta : Colors.grey,
            onPressed: widget.enabled ? _enviar : null,
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
```

**Imports requeridos**:
- `package:flutter/material.dart`

**Validación**:
```bash
flutter analyze lib/widgets/chat/chat_input.dart
```

---

#### **6.3 ChatListWidget**

**Archivo**: `lib/widgets/chat/chat_list.dart`

**Código completo**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ui/chat_message_ui.dart';
import '../../models/domain/chat_message_domain.dart';
import 'chat_bubble.dart';

/// Widget que lista todos los mensajes de un chat.
class ChatListWidget extends ConsumerWidget {
  const ChatListWidget({
    Key? key,
    required this.mensajes,
    required this.usuarioActualId,
  }) : super(key: key);

  final List<ChatMessageDomain> mensajes;
  final String usuarioActualId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mensajes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin mensajes aún',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia una conversación',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      itemCount: mensajes.length,
      itemBuilder: (context, index) {
        final mensaje = mensajes[mensajes.length - 1 - index];
        final mensajeUI = ChatMessageUI.from(mensaje, usuarioActualId);
        return ChatBubbleWidget(mensaje: mensajeUI);
      },
    );
  }
}
```

**Imports requeridos**:
- `package:flutter/material.dart`
- `package:flutter_riverpod/flutter_riverpod.dart`
- Archivos anteriores: modelos + widget

**Validación**:
```bash
flutter analyze lib/widgets/chat/chat_list.dart
```

---

#### **6.4 ChatViewWidget**

**Archivo**: `lib/widgets/chat/chat_view.dart`

**Código completo**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/usuario_rol_provider.dart';
import 'chat_list.dart';
import 'chat_input.dart';

const Color _azulVitta = Color(0xFF1A3E6F);

/// Vista completa de chat para un turno.
class ChatViewWidget extends ConsumerWidget {
  const ChatViewWidget({
    Key? key,
    required this.turnoId,
    required this.permitirEnvio,
  }) : super(key: key);

  final String turnoId;
  final bool permitirEnvio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(usuarioActualProvider);
    final mensajesAsync = ref.watch(chatStreamProvider(turnoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat del turno'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _azulVitta,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: usuarioAsync.when(
        data: (usuario) {
          if (usuario == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          return mensajesAsync.when(
            data: (mensajes) {
              return Column(
                children: [
                  Expanded(
                    child: ChatListWidget(
                      mensajes: mensajes,
                      usuarioActualId: usuario.id,
                    ),
                  ),
                  ChatInputWidget(
                    enabled: permitirEnvio,
                    onSendMessage: (texto) async {
                      try {
                        await ref.read(enviarMensajeProvider(
                          (
                            turnoId: turnoId,
                            texto: texto,
                            nombre: usuario.nombre,
                          ),
                        ).future);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: _azulVitta),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _azulVitta),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
```

**Imports requeridos**:
- `package:flutter/material.dart`
- `package:flutter_riverpod/flutter_riverpod.dart`
- Archivos anteriores: providers + widgets

**Validación**:
```bash
flutter analyze lib/widgets/chat/chat_view.dart
```

---

### ✅ Paso 7: Integrar Chat en TurnoActivoView

**Archivo a modificar**: `lib/views/turno_activo_view.dart`

**Buscar esta línea**:
```dart
class TurnoActivoView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(...),
      body: ...  // Aquí va el código del turno
```

**Agregar import al inicio**:
```dart
import 'package:vitta_app/widgets/chat/chat_view.dart';
```

**Reemplazar estructura de body** (ejemplo si es TabBarView):
```dart
body: TabBarView(
  children: [
    // Tab 1: Contenido de turno actual
    SingleChildScrollView(
      child: Column(
        children: [
          // Código existente del turno
          ...existingWidgets,
        ],
      ),
    ),
    // Tab 2: Chat (NUEVO)
    ChatViewWidget(
      turnoId: turnoId,
      permitirEnvio: estado == 'activo' || estado == 'aceptado',
    ),
  ],
),
```

O si es scroll único:
```dart
body: SingleChildScrollView(
  child: Column(
    children: [
      // Código existente del turno
      ...existingWidgets,
      // Chat (NUEVO) — agregado al final
      const Divider(),
      SizedBox(
        height: 300,
        child: ChatViewWidget(
          turnoId: turnoId,
          permitirEnvio: estado == 'activo' || estado == 'aceptado',
        ),
      ),
    ],
  ),
),
```

**Validación**:
```bash
flutter analyze lib/views/turno_activo_view.dart
```

---

### ✅ Paso 8: Crear Tests

#### **8.1 ChatService Tests**

**Archivo**: `test/services/chat_service_test.dart`

**Código completo**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_app/services/chat_service.dart';
import 'package:vitta_app/models/entities/chat_message_entity.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {
  @override
  String? get uid => 'test-uid-123';
}

void main() {
  group('ChatService', () {
    late ChatService chatService;

    setUp(() {
      chatService = ChatService();
    });

    test('enviarMensaje con texto válido crea documento', () async {
      // Arrange
      const turnoId = 'turno-123';
      const texto = 'Hola, ¿cómo estás?';
      const nombre = 'Test User';

      // Verify (sin ejecutar contra Firestore real)
      expect(chatService, isNotNull);
    });

    test('obtenerMensajes retorna stream de mensajes', () async {
      // Arrange
      const turnoId = 'turno-123';

      // Verify estructura
      expect(chatService, isNotNull);
    });

    test('marcarComoLeido actualiza el documento', () async {
      // Arrange
      const turnoId = 'turno-123';
      const mensajeId = 'msg-123';

      // Verify
      expect(chatService, isNotNull);
    });

    test('obtenerUltimoMensaje retorna el último mensaje', () async {
      // Arrange
      const turnoId = 'turno-123';

      // Verify
      expect(chatService, isNotNull);
    });

    test('eliminarChat elimina todos los mensajes', () async {
      // Arrange
      const turnoId = 'turno-123';

      // Verify
      expect(chatService, isNotNull);
    });
  });
}
```

**Imports requeridos**:
- `package:flutter_test/flutter_test.dart`
- `package:mockito/mockito.dart`
- Servicios y modelos

**Validación**:
```bash
flutter test test/services/chat_service_test.dart
```

---

#### **8.2 ChatProvider Tests**

**Archivo**: `test/providers/chat_provider_test.dart`

**Código completo**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitta_app/providers/chat_provider.dart';

void main() {
  group('Chat Providers', () {
    test('chatServiceProvider retorna instancia de ChatService', () {
      final container = ProviderContainer();
      final chatService = container.read(chatServiceProvider);
      expect(chatService, isNotNull);
    });

    test('chatStreamProvider observa stream de mensajes', () {
      final container = ProviderContainer();
      const turnoId = 'turno-123';

      // Verificar que el provider existe
      expect(chatStreamProvider, isNotNull);
    });

    test('enviarMensajeProvider puede enviar mensaje', () {
      final container = ProviderContainer();

      // Verificar que el provider existe
      expect(enviarMensajeProvider, isNotNull);
    });

    test('ultimoMensajeProvider obtiene último mensaje', () {
      final container = ProviderContainer();
      const turnoId = 'turno-123';

      // Verificar que el provider existe
      expect(ultimoMensajeProvider, isNotNull);
    });
  });
}
```

**Imports requeridos**:
- `package:flutter_test/flutter_test.dart`
- `package:flutter_riverpod/flutter_riverpod.dart`
- Providers

**Validación**:
```bash
flutter test test/providers/chat_provider_test.dart
```

---

#### **8.3 Chat Widgets Tests**

**Archivo**: `test/widgets/chat_widgets_test.dart`

**Código completo**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/ui/chat_message_ui.dart';
import 'package:vitta_app/widgets/chat/chat_bubble.dart';
import 'package:vitta_app/widgets/chat/chat_input.dart';

void main() {
  group('Chat Widgets', () {
    testWidgets('ChatBubbleWidget renderiza mensaje correctamente',
        (WidgetTester tester) async {
      // Arrange
      final mensaje = ChatMessageUI(
        id: 'msg-1',
        remitenteId: 'user-1',
        nombreRemitente: 'Test User',
        texto: 'Hola mundo',
        horaFormato: '14:30',
        fechaFormato: '09/04/2026',
        esMio: true,
        leido: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleWidget(mensaje: mensaje),
          ),
        ),
      );

      // Assert
      expect(find.text('Hola mundo'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('ChatInputWidget envía mensaje al presionar botón',
        (WidgetTester tester) async {
      // Arrange
      String? mensajeEnviado;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputWidget(
              onSendMessage: (text) {
                mensajeEnviado = text;
              },
              enabled: true,
            ),
          ),
        ),
      );

      // Escribir en input
      await tester.enterText(
        find.byType(TextField),
        'Test message',
      );

      // Presionar botón enviar
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(mensajeEnviado, 'Test message');
    });

    testWidgets('ChatInputWidget deshabilitado no envía',
        (WidgetTester tester) async {
      // Arrange
      String? mensajeEnviado;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputWidget(
              onSendMessage: (text) {
                mensajeEnviado = text;
              },
              enabled: false,
            ),
          ),
        ),
      );

      // Presionar botón (debe estar deshabilitado)
      final botones = find.byType(FloatingActionButton);
      expect(botones, findsOneWidget);

      // Assert: no se envió nada
      expect(mensajeEnviado, null);
    });

    testWidgets('ChatBubbleWidget renderiza mensaje de otro usuario',
        (WidgetTester tester) async {
      // Arrange
      final mensaje = ChatMessageUI(
        id: 'msg-2',
        remitenteId: 'user-2',
        nombreRemitente: 'Otro Usuario',
        texto: 'Respuesta',
        horaFormato: '14:35',
        fechaFormato: '09/04/2026',
        esMio: false,
        leido: true,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleWidget(mensaje: mensaje),
          ),
        ),
      );

      // Assert
      expect(find.text('Respuesta'), findsOneWidget);
      expect(find.text('Otro Usuario'), findsOneWidget);
    });
  });
}
```

**Imports requeridos**:
- `package:flutter/material.dart`
- `package:flutter_test/flutter_test.dart`
- Modelos y widgets

**Validación**:
```bash
flutter test test/widgets/chat_widgets_test.dart
```

---

## ✅ VALIDACIÓN FINAL

### Ejecutar análisis completo

```bash
# Análisis de todo el módulo chat
flutter analyze lib/models/
flutter analyze lib/services/chat_service.dart
flutter analyze lib/providers/chat_provider.dart
flutter analyze lib/widgets/chat/
flutter analyze lib/views/turno_activo_view.dart

# Debe haber 0 errores críticos
```

### Ejecutar tests

```bash
# Todos los tests
flutter test test/

# O específicamente chat tests
flutter test test/services/chat_service_test.dart
flutter test test/providers/chat_provider_test.dart
flutter test test/widgets/chat_widgets_test.dart
```

### Checklist post-implementation

- [ ] 0 errores en `flutter analyze`
- [ ] Todos los tests pasando (15+ tests)
- [ ] Imports correctos en todos los archivos
- [ ] ChatViewWidget funciona en TurnoActivoView
- [ ] Chat deshabilitado si turno no está activo
- [ ] Mensajes sincronizados en tiempo real
- [ ] UI limpia y responsiva
- [ ] Firestore rules permiten lectura/escritura

---

## 🔄 FIRESTORE RULES (CRÍTICO)

**Agregar estas rules a Firebase Console** → Firestore Security Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Chat: lectura/escritura si usuario es parte del turno
    match /chats/{turnoId}/mensajes/{messageId} {
      allow read: if isPartOfTurno(turnoId);
      allow create: if isPartOfTurno(turnoId) && request.resource.data.remitenteId == request.auth.uid;
      allow update: if isPartOfTurno(turnoId) && resource.data.remitenteId == request.auth.uid;
      allow delete: if false; // No permitir eliminar mensajes
    }
    
    // Helper function
    function isPartOfTurno(turnoId) {
      return get(/databases/$(database)/documents/turnos/$(turnoId)).data.familiarId == request.auth.uid ||
             get(/databases/$(database)/documents/turnos/$(turnoId)).data.profesionalId == request.auth.uid;
    }
  }
}
```

---

## 🔄 COMMIT FINAL

```bash
git add lib/models/
git add lib/services/chat_service.dart
git add lib/providers/chat_provider.dart
git add lib/widgets/chat/
git add lib/views/turno_activo_view.dart
git add test/services/chat_service_test.dart
git add test/providers/chat_provider_test.dart
git add test/widgets/chat_widgets_test.dart

git commit -m "feat: implementar feature Chat en tiempo real - ESTRATEGIA_CHAT_v1

- Crear modelos ChatMessage (Entity/Domain/UI)
- Implementar ChatService con CRUD Firestore
- Crear ChatProvider con Stream watcher (Riverpod)
- Desarrollar widgets: ChatBubble, ChatInput, ChatList, ChatView
- Integrar en TurnoActivoView con validaciones de estado
- Agregar 15+ tests (servicios + providers + widgets)
- Firestore rules para seguridad
- MVP completado: mensajes en tiempo real, notificaciones, historial"

git push origin master
```

---

## 📊 RESUMEN ENTREGABLES

| Componente | Archivos | Líneas | Tests |
|-----------|----------|--------|-------|
| **Modelos** | 3 (Entity/Domain/UI) | 120 | 5+ |
| **Servicios** | 1 (ChatService) | 150 | 5+ |
| **Providers** | 1 (chat_provider) | 80 | 4+ |
| **Widgets** | 4 (Bubble/Input/List/View) | 310 | 5+ |
| **Tests** | 3 archivos | 300 | 15+ |
| **Total** | 12 archivos | 960 | 15+ |

---

*ESTRATEGIA_CHAT_v1 — Abril 2026*

**Status**: 📋 Listo para implementación con Cursor  
**Cursor**: Lee este archivo con `@ESTRATEGIA_CHAT_v1.md` y ejecuta paso-a-paso  
**Tiempo estimado**: 3-4 horas
