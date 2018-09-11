import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devfest_2018/firebase_firestore_check_main.dart' as firestore_check;
import 'package:firebase_auth/firebase_auth.dart';


// この GoogleSignIn クラスの内容は、
// アプリにログインしているユーザのみ Firestore に書き込めることの確認実装です。
//
//  アプリへのログインを確認する Firestore Rules 設定
//  service cloud.firestore {
//    match /databases/{database}/documents {
//      match /{document=**} {
//        function isAuthenticated() {
//          return request.auth.uid != null;
//        }
//
//        allow read;
//        allow write: if isAuthenticated();
//      }
//    }
//  }
//
// google_sign_in 3.0.5 プラグインの動作を確認する example と、
// cloud_firestore 0.8.0 プラグインの動作を確認する example を合成しています。
// https://pub.dartlang.org/packages/google_sign_in#-example-tab-
// https://pub.dartlang.org/packages/cloud_firestore#-example-tab-
//
final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

void main() {
  runApp(
    new MaterialApp(
      title: 'Google Sign In',
      home: new SignInDemo(),
    ),
  );
}

class SignInDemo extends StatefulWidget {
  @override
  State createState() => new SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {
  String _contactText;
  FirebaseUser _user;

  Future<Null> _handleSignIn() async {
    try {
      GoogleSignInAccount currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        currentUser = await _googleSignIn.signInSilently();
      }
      if (currentUser == null) {
        currentUser = await _googleSignIn.signIn();
      }

      final GoogleSignInAuthentication googleAuth = await currentUser.authentication;
      _user = await _auth.signInWithGoogle(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      print("handleSignIn()  user{name=${_user.displayName}, iconUrl=${_user.photoUrl}");
      setState(() {
        _contactText = "this is auth test.";
      });

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

  Future<Null> _handleSignOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
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

  Widget _buildBody() {
    if (_user != null) {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new ListTile(
            leading: CircleAvatar(
                backgroundImage: Image.network(
                    _user?.photoUrl??'',
                    fit: BoxFit.cover,
                    width: 30.0,
                    height: 30.0).image,
                radius: 15.0),
            title: Text(_user.displayName),
            subtitle: new Text(_user.email),
          ),
          const Text("Signed in successfully."),
          new Text(_contactText),
          new RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
          new RaisedButton(
            child: const Text('Firestore'),
            onPressed: () async {
              final FirebaseApp app = FirebaseApp.instance; // auth認証結果を引き継げるよう、生成済みのインスタンスを利用する
              final Firestore firestore = new Firestore(app: app);

              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => firestore_check.MyHomePage( firestore: firestore ) ) );
            },
          ),
        ],
      );
    } else {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          new RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Google Sign In'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
