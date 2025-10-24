import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.updateDisplayName(displayName);

    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': null,
    });
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async => _auth.signOut();

  Future<void> updateDisplayName(String uid, String name) async {
    await _db.collection('users').doc(uid).update({'displayName': name});
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<String> uploadProfileImage(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({'photoUrl': url});
    return url;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
}
