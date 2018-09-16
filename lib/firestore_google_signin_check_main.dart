import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devfest_2018/firebase_firestore_check_main.dart' as firestore_check;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:devfest_2018/src/firebase_service.dart';


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
              final Firestore firestore = FirestoreService.createFirestore(initApp: app);

/*
              // FIXME イベントデータの仮追加
              createData(firestore);
*/
///*
              // FIXME イベントデータの確認
              readData(firestore);
//*/
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

  Future<void> createData(Firestore firestore) async {
    try {
      print("Step.0");
      AppData appData = AppData(firestore: firestore);
      print("Step.1");
      await appData.createAdminDocument(_user, _user);
      print("Step.2");
      DocumentSnapshot event = await appData.addEventDocument(
          2018, 9, 24, 13, 30, 16, 30, "kyoto", _user, "DevFest Kyoto 2018", "GDG Kyoto's DevFest", "Kyoto");
      print("Step.3");

      List<DocumentSnapshot> events = await appData.getEventDocuments();
      print("getEventDocuments  events=${events.length}");
      print("Step.4");
      DocumentSnapshot post1 = await appData.addPostMessageDocument(event, _user, "DevFest Kyoto 2018 始まった");
      print("Step.5");
      DocumentSnapshot post2 = await appData.addPostMessageDocument(event, _user, "Kotlin イケイケですね~。");
      print("Step.6");
      DocumentSnapshot post3 = await appData.addPostMessageDocument(event, _user, "Flutter 頑張れ。");
      print("Step.7");
      DocumentSnapshot post4 = await appData.addPostMessageDocument(event, _user, "ちょっと休憩？");
      await appData.deletePostMessageDocument(post4, _user);

      print("Step.8");
      CollectionReference postMessages = appData.getPostMessageCollection(event);
      print("Step.9");
      List<DocumentSnapshot> postMessageList = await appData.getPostMessageDocuments(postMessages);
      print("Step.10");
      int index = 0;
      postMessageList.forEach((DocumentSnapshot docSnap) {
        Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
        debugPrint("postMessage[${index++}]{\n  user=${map["DISPLAY_NAME"]}\n  icon=${map["PHOTO_URL"]}\n  ${map["MESSAGE"]}\n  edit=${map["EDITED"]}\n  delete=${map["DELETED"]}\n}"); // FIXME
      });
      print("Step.11");
      await appData.updatePostMessageDocument(post3, _user, "Flutter やるじゃん。");
      print("Step.12");

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

  Future<void> readData(Firestore firestore) async {
    try {
      print("Step.0");
      AppData appData = AppData(firestore: firestore);
      print("firestore.app.name=${firestore.app.name}");
      print("Step.1");
      DocumentSnapshot admin = await appData.getAdminDocument(_user.uid, _user);
      if (admin != null) {
        Map<String, dynamic> map = FirestoreService.getProperties(admin);
        print("Admin=${map['OWNER_DISPLAY_NAME']}");
      } else{
        print("Admin is null");
      }
      print("Step.2");
      int index;
      List<DocumentSnapshot> admins = await appData.getAdminDocuments(_user);
      if (admins != null) {
        index = 0;
        admins.forEach((DocumentSnapshot docSnap){
          Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
          print("Admin[${index++}]=${map['OWNER_DISPLAY_NAME']}");
        });
      } else {
        print("Admins is null");
      }
      print("Step.3");
      List<DocumentSnapshot> events = await appData.getEventDocuments();
      index = 0;
      events.forEach((DocumentSnapshot docSnap){
        Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
        print("Event[${index++}]=${map['TITLE']}");
      });
      print("Step.4");
      DocumentSnapshot eventSnap = events[0];
      CollectionReference postMessages = appData.getPostMessageCollection(eventSnap);
      List<DocumentSnapshot> postDocuments = await appData.getPostMessageDocuments(postMessages);
      index = 0;
      postDocuments.forEach((DocumentSnapshot docSnap){
        Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
        print("PostMessage[${index++}]=${map['MESSAGE']}, edit=${map['EDITED']}, delete=${map['DELETED']}");
      });
      print("Step.5");
      CollectionReference editMessages = appData.getEditMessageCollection(postDocuments[2]);
      List<DocumentSnapshot> editDocuments = await appData.getEditMessageDocuments(editMessages, _user);
      if (editDocuments != null) {
        index = 0;
        editDocuments.forEach((DocumentSnapshot docSnap){
          Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
          print("editMessage[${index++}]=${map['MESSAGE']}, ${map["BEFORE_MESSAGE"]}");
        });
      } else {
        print("editMessage is null");
      }
      print("Step.6");

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

}
