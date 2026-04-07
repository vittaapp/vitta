import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> _tienePacienteRegistrado(String uid) async {
    final snap = await _db
        .collection('pacientes')
        .where('familiarId', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Registro con email y password
  Future<Usuario?> registrar({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final usuario = Usuario(
        id: credencial.user!.uid,
        nombre: nombre,
        email: email,
        rol: rol,
      );
      await _db
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set(usuario.toMap());
      return usuario;
    } catch (e) {
      return null;
    }
  }

  // Login con email y password
  Future<Usuario?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _db
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .get();
      if (doc.exists) {
        final u = Usuario.fromMap(doc.data()!, doc.id);
        final tiene = await _tienePacienteRegistrado(credencial.user!.uid);
        return u.copyWith(tienePacienteRegistrado: tiene);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Login con Google
  Future<Usuario?> loginConGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await googleSignIn.initialize();
        _googleInitialized = true;
      }
      final GoogleSignInAccount cuenta = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = cuenta.authentication;

      final credencial = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final resultado = await _auth.signInWithCredential(credencial);
      await resultado.user?.reload();
      final user = _auth.currentUser!;

      final profile = resultado.additionalUserInfo?.profile;
      Map<String, dynamic>? profileMap;
      if (profile != null) {
        profileMap = Map<String, dynamic>.from(profile as Map);
      }

      String nombre =
          user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : '';
      if (nombre.isEmpty) {
        final name = profileMap?['name'];
        if (name is String && name.trim().isNotEmpty) {
          nombre = name.trim();
        }
      }
      if (nombre.isEmpty) nombre = 'Usuario';

      String fotoUrl = user.photoURL?.trim().isNotEmpty == true ? user.photoURL!.trim() : '';
      if (fotoUrl.isEmpty) {
        final picture = profileMap?['picture'];
        if (picture is String && picture.trim().isNotEmpty) {
          fotoUrl = picture.trim();
        }
      }

      final doc = await _db.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        final u = Usuario.fromMap(doc.data()!, doc.id);
        final tiene = await _tienePacienteRegistrado(user.uid);
        return u.copyWith(tienePacienteRegistrado: tiene);
      } else {
        final nuevoUsuario = Usuario(
          id: user.uid,
          nombre: nombre,
          email: user.email ?? '',
          rol: 'familiar',
          fotoUrl: fotoUrl,
          tienePacienteRegistrado: false,
        );
        await _db
            .collection('usuarios')
            .doc(user.uid)
            .set(nuevoUsuario.toMap());
        return nuevoUsuario;
      }
    } catch (e) {
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}