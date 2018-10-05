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
            child: const Text('DevFest Chat'),
            onPressed: () async {
              // FIXME
              /*
              await checkSingleSubscriptionStream();
              await Future.delayed(Duration(seconds: 10)); // 待機
              await checkBroadCastStream();
              await Future.delayed(Duration(seconds: 10)); // 待機
              */
              await checkStreamSubscription();
              await Future.delayed(Duration(seconds: 10)); // 待機
              await checkCreateStreamWithinEvent();
              await Future.delayed(Duration(seconds: 10)); // 待機
              await checkBlock();
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()) );
            },
          ),
          /// SIGN OUT ボタン
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
          /// SIGN IN ボタン
          new RaisedButton(
              padding: EdgeInsets.all(0.0),
              color: Colors.white,
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

  Future<void> checkSingleSubscriptionStream() async {
    StreamController<int> inState = new StreamController<int>();
    Stream<int> stream = inState.stream;
    // SingleSubscriptionStream では、無条件イベントハンドラのみ１つだけ登録できる。
    stream.listen((int event) {
      print("inState.stream  eventHandle('$event'), isBroadcast=${stream.isBroadcast}");
    });
    inState.add(1);
    inState.add(2);
    inState.add(3);
    inState.close();
  }
  Future<void> checkBroadCastStream() async {
    StreamController<int> inState = new StreamController<int>();
    Stream<int> broadcastStream = inState.stream.asBroadcastStream();
    // BroadcastStream でも、無条件イベントハンドラは１つのみ登録できる。
    broadcastStream.listen((int event){
      print("inState.stream.asBroadCastStream  eventHandle('$event'), isBroadcast=${broadcastStream.isBroadcast}");
    });
    // BroadcastStream では、条件付イベントハンドラが複数登録できる。
    broadcastStream.where((int event){return true;}).listen((int event){ print("broadcastStream  eventHandle1('$event')"); });
    broadcastStream.where((int event){return true;}).listen((int event){ print("broadcastStream  eventHandle2('$event')"); });
    broadcastStream.where((int event){return true;}).listen((int event){ print("broadcastStream  eventHandle3('$event')"); });
    inState.sink.add(1);
    inState.sink.add(2);
    inState.sink.add(3);
    inState.sink.close();
  }
  Future<void> checkStreamSubscription() async {
    StreamController<int> inState = new StreamController<int>();
    // StreamSubscriptionは、イベントリスナーを含むイベントコントローラです。
    StreamSubscription<int> subscription = inState.stream.listen((int event) {
      // 無条件ハンドラは、StreamSubscription#onData() があれば上書きされます。
      print("inState.stream  eventHandle('$event')");
    });
    subscription.onData((int data){
      print("inState.stream  StreamSubscription#onData('$data')");
    });
    subscription.onDone((){
      print("inState.stream  StreamSubscription#onDone()");
    });
    inState.onCancel = (){
      print("cancelled.");
    };
    inState.sink.add(1);
    print("add event 1 done!");
    inState.sink.add(2);
    print("add event 2 done!");
    await Future.delayed(Duration(seconds: 10)); // キュー内のisolateが先に実行されるよう10秒間待機する。
    inState.sink.add(3);
    print("add event 3 done!");
    await subscription.cancel(); // cancel()を使うとイベントが発行されません。
    inState.sink.close();
  }
  Future<void> checkCreateStreamWithinEvent() async {
    StreamController<int> inState = new StreamController<int>();

    // Iterable なデータから Stream を生成する。
    List<int> list = [3,4,5];
    Stream<int> srcStream = Stream.fromIterable(list);

    // ストリーム(stream: プロパティ)の内容をデータから生成したストリームに置換
    // 初期設定のストリームが無効になるため、
    // 対応する流し込みイベント溜め⇒流し台⇒シンク(sink: )も無効になります。
    inState.addStream(srcStream);

    // SingleSubscriptionStream では、無条件イベントハンドラのみ１つだけ登録できる。
    Stream<int> stream = inState.stream;
    stream.listen((int event) {
      print("inState.stream  eventHandle('$event'), isBroadcast=${stream.isBroadcast}");
    });
  }
  Future<void> checkBlock() async {
    StreamController<int> inEvent = new StreamController<int>();
    StreamController<String> outData = new StreamController<String>();

    // イベント入力 ~ リアクションのデータ生成およびキックの設定
    // （入出力のバインドとロジックの実装）
    inEvent.stream.listen((int event) {
      print("inEvent.stream  handleEvent('$event')");
      outData.add("<<<${event * 100}>>>");
    });

    // リアクション出力の設定
    // （Widget を更新する場合は、outData に StreamBuilder を使います）
    outData.stream.listen((String data) {
      print("outData.stream  handleData('$data')");
    });

    // イベント入力 （対応するリアクションは、自動的に発生する）
    inEvent.add(1);
    inEvent.add(2);
    inEvent.add(3);
  }
}
