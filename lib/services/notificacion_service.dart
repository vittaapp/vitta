import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Servicio básico de notificaciones push con FCM.
///
/// Nota: el envío real de FCM requiere backend/Cloud Functions. En esta app
/// guardamos la notificación como "pendiente" en Firestore (Fase 2).
class NotificacionService {
  NotificacionService({FirebaseFirestore? firestore, FirebaseMessaging? fcm})
      : _db = firestore ?? FirebaseFirestore.instance,
        _fcm = fcm ?? FirebaseMessaging.instance;

  final FirebaseFirestore _db;
  final FirebaseMessaging _fcm;

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<User?>? _onAuthSub;

  Future<void> inicializar() async {
    // Handlers en foreground (mientras la app está abierta).
    configurarHandlers();

    // Guardar token para el usuario actual (si ya hay sesión).
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      unawaited(guardarToken(currentUser.uid));
    }

    // Guardar token cuando el usuario inicia sesión por primera vez.
    _onAuthSub?.cancel();
    _onAuthSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (u == null) return;
      try {
        await guardarToken(u.uid);
      } catch (_) {
        // Silencioso: no interrumpir el flujo principal.
      }
    });

    // Pedir permisos (Android + iOS). En Android puede requerir autorización en Android 13+.
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Silencioso.
    }
  }

  void configurarHandlers() {
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      try {
        final body = message.notification?.body ??
            message.data['body'] as String? ??
            message.data['mensaje'] as String? ??
            'Notificación recibida';

        final messenger = scaffoldMessengerKey.currentState;
        messenger?.showSnackBar(
          SnackBar(
            content: Text(body),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (_) {
        // Silencioso.
      }
    });
  }

  Future<void> guardarToken(String uid) async {
    final token = await _fcm.getToken();
    if (token == null || token.trim().isEmpty) return;

    try {
      await _db.collection('usuarios').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (_) {
      // Silencioso.
    }
  }
}

