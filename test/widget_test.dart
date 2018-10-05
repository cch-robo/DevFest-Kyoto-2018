// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devfest_2018/src/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(new DevFestApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}


/// Widget を使った動作確認を行うためだけの画面クラス
class OperationCheckPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    /*
    /// アプリ全体共有のサインイン情報を取得
    _signIn = DevFestStateProvider.of(context).signIn;

    /// アプリ全体共有の永続化情報を取得
    _appData = DevFestStateProvider.of(context).appData;
    */

    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Operation Check'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          /*
          child: _buildBody(context),
          */
        ));
  }

  Widget _buildInEventWidget(BuildContext context, String outData) {
    return
      new TextField(
        controller: TextEditingController(text: ""),
        /*
        onChanged: (String text) {
          setState(() {
            _isComposing = text.length > 0;
          });
        },
        onSubmitted: _handleSubmitted,
        */
        decoration: new InputDecoration.collapsed(hintText: "Send a message"),
    );
  }
  Widget _buildOutDataWidget(BuildContext context) {

  }
}

/// ２つの数字を保持するだけのクラス
class NumPair {
  final int left;
  final int right;

  NumPair(this.left, this.right);
}

class BusinessLogicComponent {
  /// 入力イベントをハンドルするストリーム
  StreamController<NumPair> inEvent;

  /// 出力データの投入をハンドルするストリーム
  StreamController<String> outData;

  /// 出力データ Widget のビルダー関数
  Widget Function(BuildContext context, String outData) buildOutDataWidget;

  /// コンストラクタ
  BusinessLogicComponent(this.buildOutDataWidget) {
    inEvent = StreamController<NumPair>();
    outData = StreamController<String>();
    _logic();
  }

  /// デストラクタ
  destroy() {
    // ストリーム（データの流れのハンドリング）を閉じます。
    inEvent.close();
    outData.close();

    inEvent = null;
    outData = null;
    buildOutDataWidget = null;
  }

  /// ロジック定義（入出力のリアクション定義）
  void _logic() {
    // 入力イベントからの出力データ作成と、入出力のバインドを行います。
    inEvent.stream.listen((NumPair event){
      // 入力イベントから出力データを作成
      String data = "${event.left + event.right}";

      // 出力データのストリームにデータを投入
      outData.add(data);
    });

    // 出力データWidget のリアクション定義 （出力データの投入に伴いWidgetを更新します）
    StreamBuilder<String> outWidget = new StreamBuilder<String>(
        stream: outData.stream,
        builder: (BuildContext context, AsyncSnapshot<String> outDataSnapshot) {
          return buildOutDataWidget(context, outDataSnapshot.data);
        }
    );
  }
}