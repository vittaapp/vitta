import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'views/login_view.dart';
import 'services/notificacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificacionService().inicializar();
  runApp(const ProviderScope(child: VittaApp()));
}

class VittaApp extends StatelessWidget {
  const VittaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitta Salud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3E6F),
        ),
        useMaterial3: true,
      ),
      scaffoldMessengerKey: NotificacionService.scaffoldMessengerKey,
      home: const LoginView(),
    );
  }
}