// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// この チャット パッケージの内容は、
/// （旧 Flutter コードラボ）flutter/friendlychat-steps friendly chat アプリのソースを元にしています。
/// https://github.com/flutter/friendlychat-steps

import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:devfest_2018/src/state/state_provider.dart';
import 'package:devfest_2018/src/state/sign_in_state.dart';
import 'package:devfest_2018/src/state/permanent_state.dart';


final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);


@override
class ChatMessage extends StatelessWidget {
  ChatMessage({this.snapshot, this.animation});
  final DocumentSnapshot snapshot;
  final Animation animation;

  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: animation, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(backgroundImage: new NetworkImage(snapshot.data['ICON_URL'])),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(
                      snapshot.data['DISPLAY_NAME'],
                      style: Theme.of(context).textTheme.subhead),
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: snapshot.data['IMAGE_URL'] != null ?
                    new Image.network(
                      snapshot.data['IMAGE_URL'],
                      width: 250.0,
                    ) :
                    new Text(snapshot.data['MESSAGE']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen>  with SingleTickerProviderStateMixin {
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;
  SignInState _signIn;
  AppDataState _appData;
  bool _isSetup;
  List<DocumentSnapshot> _latestPostMessages;

  Animation<double> animation;
  AnimationController controller;
  ScrollController scrollController;

  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final CurvedAnimation curve = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    animation = Tween(begin: 0.0, end: 1.0).animate(curve);
    controller.forward();
    _isSetup = true;
    _latestPostMessages = <DocumentSnapshot>[];
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    /// アプリ全体共有のサインイン情報を取得
    _signIn = DevFestStateProvider.of(context).signIn;

    /// アプリ全体共有の永続化情報を取得
    _appData = DevFestStateProvider.of(context).appData;

    if (_isSetup) {
      /// 非同期遅延セットアップ
      _lateSetup(context);

    } else {
      /// 最新の投稿メッセージ・ウイジェット一覧を設定
      _setupLatestPostMessages(_latestPostMessages);
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text("DevFeat Chat"),
          elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: new Column(children: <Widget>[
          new Flexible(
            child: new ListView.builder(
              controller: scrollController,
              itemCount: _latestPostMessages.length,
              itemBuilder: (BuildContext context, int index) {
                return new ChatMessage(
                      snapshot: _latestPostMessages[index],
                      animation: animation,
                    );
              },
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration:
            new BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ]));
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row(children: <Widget>[
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                  icon: new Icon(Icons.photo_camera),
                  onPressed: () async {
                    /// イメージピッカーで選択したギャラリー画像を、Firebase Storage にアップロードする。
                    /// (カメラ画像にする場合は、picImage の source: に ImageSource.camera を指定してください)
                    ///
                    /// 【併せて参照】firebase_storage 1.0.2 > example _uploadFile()
                    /// https://pub.dartlang.org/packages/firebase_storage#-example-tab-

                    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
                    int random = new Random().nextInt(100000);
                    StorageReference ref = FirebaseStorage.instance
                        .ref().child("evtn_event").child("image_$random.jpg");
                    StorageUploadTask uploadTask = ref.putFile(imageFile);
                    Uri downloadUrl = (await uploadTask.future).downloadUrl;
                    await _sendMessage(imageUrl: downloadUrl.toString());
                  }
              ),
            ),
            new Flexible(
              child: new TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: _handleSubmitted,
                decoration:
                new InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? new CupertinoButton(
                  child: new Text("Send"),
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                )
                    : new IconButton(
                  icon: new Icon(Icons.send),
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                )),
          ]),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
              border:
              new Border(top: new BorderSide(color: Colors.grey[200])))
              : null),
    );
  }

  Future<Null> _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    await _sendMessage(message: text);
  }

  Future<void> _sendMessage({ String message, String imageUrl }) async {
    debugPrint("_sendMessage  message=$message, imageUrl=$imageUrl");
    if (_appData.postMessagesSelectorEvent == null) return;
    await _appData.addPostMessageDocument(_appData.postMessagesSelectorEvent, _signIn.user, message, imageUrl);
  }

  /// 非同期遅延セットアップ
  Future<void> _lateSetup(BuildContext context) async {
    if (!_isSetup) return; // 二重セットアップ抑止

    /// 投稿メッセージの追加/更新イベントリスナーが設定されていれば削除する。
    if(_appData.postMessagesSelectorEvent != null){
      _appData.removePostMessageEventListener(_appData.postMessagesSelectorEvent);
    }

    /// ListView のスクロールコントローラ生成
    scrollController = ScrollController();

    /// 投稿メッセージの追加/更新イベントリスナーを登録する。
    List<DocumentSnapshot> eventDocuments = await _appData.getEventDocuments();
    if (eventDocuments.isNotEmpty) {
      // FIXME イベントを仮選択取得する
      DocumentSnapshot eventSnap = eventDocuments[0];

      /// 投稿メッセージの追加/更新イベント時の処理を登録
      await _appData.setPostMessageEventListener(eventSnap,
              (QuerySnapshot querySnap){
                debugPrint("PostMessageEvent  changes=${querySnap.documentChanges.length}");

                /// 最新の投稿メッセージ一覧を設定
                _latestPostMessages = querySnap.documents.where(
                    (DocumentSnapshot docSnap) {
                      return !docSnap.data["DELETED"];
                    }).toList();

                /// 画面更新
                setState(() {});
              });

      /// イベントの投稿メッセージ一覧を取得
      List<DocumentSnapshot> postMessageList;
      CollectionReference postMessages = _appData.getPostMessageCollection(_appData.postMessagesSelectorEvent);
      postMessageList = await _appData.getPostMessageDocuments(postMessages);

      /// 最新の投稿メッセージ一覧を設定
      _latestPostMessages = postMessageList.where(
              (DocumentSnapshot docSnap) {
                return !docSnap.data["DELETED"];
              }).toList();

      /// 画面更新
      setState(() {});

    } else {
      // FIXME イベントを仮選択しているための暫定処理
      /// イベント一覧がなければ、イベントに紐づくメッセージ投稿ができないので画面を戻す。
      Navigator.pop(context);
    }

    _isSetup = false;
  }

  /// 最新の投稿メッセージ・ウイジェット一覧を設定する。
  void _setupLatestPostMessages(List<DocumentSnapshot> postMessageList) {
    // デバッグ出力
    int index = 0;
    for(DocumentSnapshot postMessage in postMessageList){
      String message = postMessage.data['MESSAGE'];
      String imageUrl = postMessage.data['IMAGE_URL'];
      debugPrint("postMessage[${index++}]=${message != null ? message : imageUrl}");
    }

    /// 遅延投稿メッセージ一覧スクロール
    _lateScrollToLastPostMessage();
  }

  /// 遅延投稿メッセージ一覧スクロール
  ///
  /// 非同期にして遅延実行させることにより、
  /// 投稿メッセージ一覧が設定されてから最終メッセージまでスクロールさせる。
  Future<void> _lateScrollToLastPostMessage() async {
    // 実行待機
    await Future.delayed(Duration(milliseconds: 500));

    // スクロールポジション情報を取得
    ScrollPosition scrollPosition = scrollController.position;

    // 各種スクロール情報のデバッグ出力
    debugPrint("_setupLatestPostMessages  scrollPosition={"
        +"\n  minScrollExtent=${scrollPosition.minScrollExtent},"
        +"\n  maxScrollExtent=${scrollPosition.maxScrollExtent},"
        +"\n  extentInside=${scrollPosition.extentInside},"
        +"\n  extentAfter=${scrollPosition.extentAfter},"
        +"\n  extentBefore=${scrollPosition.extentBefore},"
        +"\n  pixels=${scrollPosition.pixels},"
        +"\n  physics=${scrollPosition.physics},"
        +"\n  viewportDimension=${scrollPosition.viewportDimension}"
        +"\n}");

    // (ListView ⇒ 投稿メッセージ一覧を)スクロール可能な最大位置までスクロールさせます。
    double offset = scrollPosition.maxScrollExtent;
    scrollController.animateTo(offset, duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

}