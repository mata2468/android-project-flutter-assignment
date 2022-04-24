
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

class AuthFirebase with ChangeNotifier{

  final _auth = FirebaseAuth.instance;
  Status _status = Status.uninitialized;
  User? _user;

  Status get status => _status;
  User? get user => _user;
  bool get isAuthenticated => status == Status.authenticated;
  String? get email => user?.email;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.authenticated;
    }
    notifyListeners();
  }

  AuthFirebase.instance(){
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      return null;
    }
  }


  Future<bool> logIn(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // sleep(const Duration(seconds: 2));
      return true;
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      // sleep(const Duration(seconds: 5));
      return false;
    }
  }

  Future logOut() async {
    _auth.signOut();
    _status = Status.unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void>? updateSavedSuggestions(Set<WordPair> savedSuggestions){
    // final pairsAsList = [for (var pair in savedSuggestions.toList()) (pair.asPascalCase)];
    final pairsAsList = [for (var pair in savedSuggestions.toList()) (pair.first + " " + pair.second)];

    _firestore.collection('users')
    .doc(user?.email)
    .collection('saved suggestions')
    .doc('suggestions')
    .set({"saved_suggestions" : pairsAsList});
    return null;
  }

  Future getSavedSuggestions(){
    return _firestore.collection('users')
        .doc(user?.email)
        .collection('saved suggestions')
        .doc('suggestions')
        // .get();
        .get().then((value) => value.data());
  }

  final _storage = FirebaseStorage.instance;
  final _imageSize = 1000000;

  Future uploadImage(File file) async {
    final imageRef = _storage.ref("images/users/${user!.email!}");
    await imageRef.putFile(file);
  }

  Future<String> getImage() async {
    try {
      final imageRef = _storage.ref("images/users/${user!.email!}");
      return imageRef.getDownloadURL();
    } catch(e){
      return await _storage.ref("default").getDownloadURL();
    }
  }
}