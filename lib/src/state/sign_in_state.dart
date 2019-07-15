import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


/// SNS ログイン/ログアウトおよびユーザ情報管理を行います。
class SignInState {
  // 管理する状態
  FirebaseUser _user;
  _SignInCase _signInCase = _SignInCase.None;

  // 状態アクセッサ
  FirebaseUser get user => _user;
  bool get isNotSignIn => _user == null;

  /// 認証連携の実装参考先
  ///
  /// Firebase Authentication
  /// https://flutter.institute/firebase-signin/
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = new GoogleSignIn();


  // サインイン状態をクリアする
  void _clear(){
    _user = null;
    _signInCase = _SignInCase.None;
  }

  Future<void> signInWithGoogle() async {
    if (_signInCase != _SignInCase.None) return;

    try {
      // Attempt to get the currently authenticated user
      GoogleSignInAccount currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        // Attempt to sign in without user interaction
        currentUser = await _googleSignIn.signInSilently();
      }
      if (currentUser == null) {
        // Force the user to interactively sign in
        currentUser = await _googleSignIn.signIn();
      }
      final GoogleSignInAuthentication auth = await currentUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      // Authenticate with firebase
      _user = await _auth.signInWithCredential(credential);

      assert(_user != null);
      assert(!_user.isAnonymous);

      _signInCase = _SignInCase.Google;

    } catch(error) {
      print('Something went wrong.');
      print("  type ⇒ ${error?.runtimeType??''}");
      print("  error ⇒ {\n${error?.toString()??''}\n}");
      if (error is Error) {
        print("  stacktrace ⇒ {\n${error?.stackTrace??''}\n}");
      }
      rethrow;
    }
  }

  Future<void> _signOutWithGoogle() async {
    if (_signInCase != _SignInCase.Google) return;

    try {
      // Sign out with firebase
      await _auth.signOut();
      // Sign out with google
      await _googleSignIn.signOut();
      // ユーザ情報をクリア
      _clear();

    } catch(error) {
      print('Something went wrong.');
      print("  type ⇒ ${error?.runtimeType??''}");
      print("  error ⇒ {\n${error?.toString()??''}\n}");
      if (error is Error) {
        print("  stacktrace ⇒ {\n${error?.stackTrace??''}\n}");
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    switch (_signInCase) {
      case _SignInCase.Google:
        await _signOutWithGoogle();
        break;
      case _SignInCase.None:
      default:
        break;
    }
  }
}

enum _SignInCase {
  Google,
  Twitter,
  Facebook,
  None,
}