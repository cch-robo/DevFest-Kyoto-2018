import 'dart:async';

import 'package:flutter/material.dart';

import 'package:devfest_2018/src/state/state_provider.dart';
import 'package:devfest_2018/src/state/sign_in_state.dart';
import 'package:devfest_2018/src/state/permanent_state.dart';
import 'package:devfest_2018/src/page/chat_page.dart';


/// この SignInPage クラスの内容は、
/// google_sign_in 3.0.5 プラグインの動作を確認する example を参考にしています。
/// https://pub.dartlang.org/packages/google_sign_in#-example-tab-
class SignInPage extends StatefulWidget {
  @override
  State createState() => new SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  SignInState _signIn;
  AppDataState _appData;

  Future<Null> _handleSignIn() async {
    try {
      await _signIn.signInWithGoogle();
      setState(() {
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
      await _signIn.signOut();
      setState(() {
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

  Widget _buildBody(BuildContext context) {
    if (!_signIn.isNotSignIn) {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new ListTile(
            leading: CircleAvatar(
                backgroundImage: Image.network(
                    _signIn.user?.photoUrl??'',
                    fit: BoxFit.cover,
                    width: 50.0,
                    height: 50.0).image,
                radius: 25.0),
            title: Text(_signIn.user.displayName),
            subtitle: new Text(_signIn.user.email),
          ),
          const Text("Signed in successfully."),
          new RaisedButton(
            color: Colors.white,
            textColor: Colors.black,
            child: const Text('DevFest 2018'),
            onPressed: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()) );
            },
          ),
          new RaisedButton(
            color: Colors.white,
            textColor: Colors.black,
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
          // スペース調整用
          const SizedBox(height: 100.0),
        ],
      );
    } else {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          new FlatButton(
              child: Image.asset(
                'assets/images/btn_google_signin_dark_normal_web_2x.png',
                width: 200.0,
                fit: BoxFit.cover,
              ),
              onPressed: _handleSignIn
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    /// アプリ全体共有のサインイン情報を取得
    _signIn = DevFestStateProvider.of(context).signIn;

    /// アプリ全体共有の永続化情報を取得
    _appData = DevFestStateProvider.of(context).appData;

    return new Scaffold(
        appBar: new AppBar(
          title: const Text('DevFest Sign In'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(context),
        ));
  }
}
