import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConstants.googleWebClientId : null,
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user exists in Firestore
  Future<bool> _userExistsInFirestore(String uid) async {
    try {
      final docSnapshot =
          await _firestore.collection('usuarios').doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      log('Error checking if user exists: $e');
      return false;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      log('Iniciando proceso de Google Sign-In');
      User? user;

      // Handle authentication differently based on platform
      if (kIsWeb) {
        log('Detectada plataforma Web - usando flujo de autenticación web');
        // Configure GoogleAuthProvider with additional scopes if needed
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider
            .addScope('https://www.googleapis.com/auth/contacts.readonly');
        authProvider.setCustomParameters(
            {'login_hint': 'user@example.com', 'prompt': 'select_account'});

        // Sign in using popup for web
        final UserCredential userCredential =
            await _auth.signInWithPopup(authProvider);
        user = userCredential.user;
      } else {
        // For mobile platforms
        log('Detectada plataforma Móvil - usando flujo de autenticación móvil');
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          log('El usuario canceló el inicio de sesión con Google');
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        user = userCredential.user;
      }

      // Save user data to Firestore only if user doesn't exist already
      if (user != null) {
        final bool userExists = await _userExistsInFirestore(user.uid);

        if (!userExists) {
          log('Usuario nuevo, guardando datos en Firestore');
          await _firestore.collection('usuarios').doc(user.uid).set({
            'uid': user.uid,
            'nombre': user.displayName,
            'email': user.email,
            'foto': user.photoURL,
            'rol': 'paciente', // Default role is patient
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        } else {
          log('Usuario existente, no se sobreescriben datos');
        }
      }

      return user;
    } catch (e, stackTrace) {
      log('Error en signInWithGoogle: $e');
      log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      log('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log('Error during sign out: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _createUserInFirestore(userCredential.user!, name, 'paciente');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserInFirestore(
      User user, String name, String role) async {
    // Check if user already exists
    final userDoc = await _firestore
        .collection('usuarios')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    // Only create a new document if user doesn't exist
    if (userDoc.docs.isEmpty) {
      await _firestore.collection('usuarios').add({
        'uid': user.uid,
        'nombre': name,
        'email': user.email,
        'rol': role,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'imageUrl': user.photoURL,
        'isSuspended': false,
      });
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions with custom messages
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception(
            'No se encontró ninguna cuenta con este correo electrónico');
      case 'wrong-password':
        return Exception('Contraseña incorrecta');
      case 'email-already-in-use':
        return Exception('Ya existe una cuenta con este correo electrónico');
      case 'weak-password':
        return Exception('La contraseña es demasiado débil');
      case 'invalid-email':
        return Exception('Correo electrónico inválido');
      case 'user-disabled':
        return Exception('Esta cuenta ha sido deshabilitada');
      case 'operation-not-allowed':
        return Exception('Operación no permitida');
      default:
        return Exception('Error: ${e.message}');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
}
