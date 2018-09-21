import 'dart:async';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devfest_2018/src/service/firebase_service.dart';


/// アプリデータ
///
/// アプリで利用する永続化データ(Firestorオブジェクト)のCRUDを提供して、
/// アプリで利用するイベントや投稿メッセージなどの永続化情報管理を行います。
class AppDataState {
  // 管理する状態
  Firestore _firestore;
  CollectionReference _admins;
  CollectionReference _events;

  DocumentSnapshot _postMessagesSelectorEvent;
  DocumentSnapshot _editMessagesSelectorPostMessage;
  StreamSubscription<QuerySnapshot> _adminsCollectionEventListener;
  StreamSubscription<QuerySnapshot> _eventsCollectionEventListener;
  Map<String, StreamSubscription<QuerySnapshot>> _postMessagesCollectionEventListenerMap = Map<String, StreamSubscription<QuerySnapshot>>();
  Map<String, StreamSubscription<QuerySnapshot>> _editMessagesCollectionEventListenerMap = Map<String, StreamSubscription<QuerySnapshot>>();

  final String adminCollectionName = "evtn_admins";
  final String adminDocumentPrefix = "evtn_admin";
  final String eventCollectionName = "evtn_events";
  final String eventDocumentPrefix = "evtn_event";
  final String postMessageCollectionPrefix = "evtn_event_messages";
  final String postMessageDocumentPrefix = "evtn_event_message_post";
  final String editMessageCollectionPrefix = "evtn_event_message_edits";
  final String editMessageDocumentPrefix = "evtn_event_message_edit";

  AppDataState({Firestore firestore}) {
    _firestore = firestore != null ? firestore : FirestoreService.createFirestore();
    _admins = FirestoreService.getCollection(_firestore, adminCollectionName);
    _events = FirestoreService.getCollection(_firestore, eventCollectionName);
  }

  // 状態アクセッサ

  /// firestore
  Firestore get firestore => _firestore;

  /// 投稿メッセージ選択中のイベント
  DocumentSnapshot get postMessagesSelectorEvent => _postMessagesSelectorEvent;

  /// 編集メッセージ選択中の投稿メッセージ
  DocumentSnapshot get editMessagesSelectorPostMessage => _editMessagesSelectorPostMessage;

  /// 管理者コレクションを取得
  CollectionReference getAdminCollection() {
    return _admins;
  }

  /// イベントコレクションを取得
  CollectionReference getEventCollection() {
    return _events;
  }

  /// 投稿メッセージコレクションを取得
  CollectionReference getPostMessageCollection(DocumentSnapshot eventSnap) {
    _postMessagesSelectorEvent = eventSnap;
    Map<String, dynamic> map = FirestoreService.getProperties(eventSnap);
    /*
    // 投稿メッセージのコレクションを作成する。
    return FirestoreService.getCollection(_firestore, map["SUB_COLLECTION"]);
    */
    // 投稿メッセージをイベント・ドキュメントのサブコレクションにする。
    return eventSnap.reference.collection(map["SUB_COLLECTION"]);
  }

  /// 編集メッセージコレクションを取得
  CollectionReference getEditMessageCollection(DocumentSnapshot postMessageSnap) {
    _editMessagesSelectorPostMessage = postMessageSnap;
    Map<String, dynamic> map = FirestoreService.getProperties(postMessageSnap);
    /*
    // 編集メッセージのコレクションを作成する。
    return FirestoreService.getCollection(_firestore, map["SUB_COLLECTION"]);
    */
    // 編集メッセージを投稿メッセージ・ドキュメントのサブコレクションにする。
    return postMessageSnap.reference.collection(map["SUB_COLLECTION"]);
  }

  /// 管理者にドキュメント作成/更新イベント時の処理関数(イベントリスナー)を登録
  Future<void> setAdminEventListener(FirebaseUser user, void Function(QuerySnapshot document) onEvent) async {
    if (! await isAdminUser(user)) {
      // 管理者が存在しない場合、イベントリスナーが登録されないことに注意
      return;
    }
    if (_adminsCollectionEventListener != null) {
      return; // 多重登録を抑止
    }
    _adminsCollectionEventListener = await FirestoreService.addCollectionEventListener(_admins, onEvent);
  }

  /// イベントにドキュメント作成/更新イベント時の処理関数(イベントリスナー)を登録
  Future<void> setEventEventListener(void Function(QuerySnapshot document) onEvent) async {
    if (_eventsCollectionEventListener != null) {
      return; // 多重登録を抑止
    }
    _eventsCollectionEventListener = await FirestoreService.addCollectionEventListener(_events, onEvent);
  }

  /// 投稿メッセージにドキュメント作成/更新イベント時の処理関数(イベントリスナー)を登録
  Future<void> setPostMessageEventListener(DocumentSnapshot event, void Function(QuerySnapshot document) onEvent) async {
    _postMessagesSelectorEvent = event;
    CollectionReference postMessages = getPostMessageCollection(event);
    if (_postMessagesCollectionEventListenerMap.containsKey(postMessages.id)) {
      return; // 多重登録を抑止
    }
    _postMessagesCollectionEventListenerMap.addEntries([
      MapEntry(postMessages.id, await FirestoreService.addCollectionEventListener(postMessages, onEvent))
    ]);
  }

  /// 編集メッセージにドキュメント作成/更新イベント時の処理関数(イベントリスナー)を登録
  Future<void> setEditMessageEventListener(CollectionReference editMessages, FirebaseUser user, void Function(QuerySnapshot document) onEvent) async {
    List<DocumentSnapshot> editMessageList = await FirestoreService.getDocuments(editMessages);
    if(editMessageList == null ||
        editMessageList != null && editMessageList.isNotEmpty
            && ! await isDocumentOwnerUser(editMessageList[0], user)) {
      // 編集メッセージが存在しない場合、イベントリスナーが登録されないことに注意
      return;
    }
    if (_editMessagesCollectionEventListenerMap.containsKey(editMessages.id)) {
      return; // 多重登録を抑止
    }
    _editMessagesCollectionEventListenerMap.addEntries([
      MapEntry(editMessages.id, await FirestoreService.addCollectionEventListener(editMessages, onEvent))
    ]);
  }

  /// 管理者からドキュメント作成/更新イベント時の処理関数(イベントリスナー)を削除
  Future<void> removeAdminEventListener(FirebaseUser user) async {
    if (! await isAdminUser(user)) {
      // 管理者が存在しない場合、イベントリスナーが削除されないことに注意
      return;
    }
    FirestoreService.removeCollectionEventListener(_adminsCollectionEventListener);
    _adminsCollectionEventListener = null;
  }

  /// イベントからドキュメント作成/更新イベント時の処理関数(イベントリスナー)を削除
  Future<void> removeEventEventListener() async {
    FirestoreService.removeCollectionEventListener(_eventsCollectionEventListener);
    _eventsCollectionEventListener = null;
  }

  /// 投稿メッセージからドキュメント作成/更新イベント時の処理関数(イベントリスナー)を削除
  Future<void> removePostMessageEventListener(DocumentSnapshot event) async {
    _postMessagesSelectorEvent = event;
    CollectionReference postMessages = getPostMessageCollection(event);
    StreamSubscription<QuerySnapshot> eventListener = _postMessagesCollectionEventListenerMap[postMessages.id];
    FirestoreService.removeCollectionEventListener(eventListener);
    _postMessagesCollectionEventListenerMap.remove(postMessages.id);
  }

  /// 編集メッセージからドキュメント作成/更新イベント時の処理関数(イベントリスナー)を削除
  Future<void> removeEditMessageEventListener(CollectionReference editMessages, FirebaseUser user) async {
    List<DocumentSnapshot> editMessageList = await FirestoreService.getDocuments(editMessages);
    if(editMessageList != null && editMessageList.isNotEmpty
        && ! await isDocumentOwnerUser(editMessageList[0], user)) {
      // 編集メッセージが存在しない場合、イベントリスナーが削除されないことに注意
      return;
    }
    StreamSubscription<QuerySnapshot> eventListener = _editMessagesCollectionEventListenerMap[editMessages.id];
    FirestoreService.removeCollectionEventListener(eventListener);
    _editMessagesCollectionEventListenerMap.remove(editMessages.id);
  }

  /// 管理者一覧を取得
  Future<List<DocumentSnapshot>> getAdminDocuments(FirebaseUser user) async {
    if (! await isAdminUser(user)) return null;
    return await FirestoreService.getDocuments(_admins);
  }

  /// イベント一覧を取得
  Future<List<DocumentSnapshot>> getEventDocuments() async {
    return await FirestoreService.getDocuments(_events);
  }

  /// 投稿メッセージ一覧を取得
  Future<List<DocumentSnapshot>> getPostMessageDocuments(CollectionReference postMessages) async {
    return await FirestoreService.getDocuments(postMessages);
  }

  /// 編集メッセージ一覧を取得
  Future<List<DocumentSnapshot>> getEditMessageDocuments(CollectionReference editMessages, FirebaseUser user) async {
    /*
    return await FirestoreService.getDocuments(editMessages);
    */
    List<DocumentSnapshot> editMessageList = await FirestoreService.getDocuments(editMessages);
    return (editMessageList != null && editMessageList.isNotEmpty)
        ? (await isDocumentOwnerUser(editMessageList[0], user) ? editMessageList : null)
        : editMessageList;
  }

  /// 管理者を取得
  Future<DocumentSnapshot> getAdminDocument(String documentName, FirebaseUser user) async {
    if (! await isAdminUser(user)) return null;
    return await FirestoreService.getDocument(_admins, documentName);
  }

  /// イベントを取得
  Future<DocumentSnapshot> getEventDocument(String documentName) async {
    return await FirestoreService.getDocument(_events, documentName);
  }

  /// 投稿メッセージを取得
  Future<DocumentSnapshot> getPostMessageDocument(DocumentSnapshot event, String documentName) async {
    _postMessagesSelectorEvent = event;
    CollectionReference postMessages = getPostMessageCollection(event);
    return await FirestoreService.getDocument(postMessages, documentName);
  }

  /// 編集メッセージを取得
  Future<DocumentSnapshot> getEditMessageDocument(DocumentSnapshot postMessage, String documentName, FirebaseUser user) async {
    if (! await isDocumentOwnerUser(postMessage, user)) return null;
    _editMessagesSelectorPostMessage = postMessage;

    CollectionReference editMessages = getEditMessageCollection(postMessage);
    return await FirestoreService.getDocument(editMessages, documentName);
  }

  /// 管理者追加
  Future<DocumentSnapshot> createAdminDocument(FirebaseUser admin, FirebaseUser member) async {
    if (admin.uid != member.uid && ! await isAdminUser(admin)) return null;

    Map<String, dynamic> map = _createAdminContent(admin, member);
    String documentName = map["NAME"];

    DocumentSnapshot document = await FirestoreService.getDocument(_admins, documentName);
    if (document != null) {
      // 既に作成済みの場合は、流用する。
    } else {
      document = await FirestoreService.createDocument(_admins, documentName, initProperties: map);
    }
    _debugProperties("admin", map);
    return document;
  }

  /// イベント追加
  Future<DocumentSnapshot> addEventDocument(
      int year, int month, int day,
      int startHour, int startMinute, int endHour, int endMinute,
      String placeId,
      FirebaseUser user,
      String title, String desc, String place,) async {

    Map<String, dynamic> map = _createEventContent(
        year, month, day, startHour, startMinute, endHour, endMinute, placeId, user, title, desc, place);
    String documentName = map["NAME"];

    DocumentSnapshot document = await FirestoreService.getDocument(_events, documentName);
    if (document != null) {
      // 既に作成済みの場合は、更新する。
      await FirestoreService.update(document.reference, map);
    } else {
      document = await FirestoreService.createDocument(_events, documentName, initProperties: map);
    }
    _debugProperties("event", map);
    return document;
  }

  /// メッセージ投稿
  Future<DocumentSnapshot> addPostMessageDocument(DocumentSnapshot event, FirebaseUser user, String message, String imageUrl) async {
    _postMessagesSelectorEvent = event;

    CollectionReference postMessages = getPostMessageCollection(event);
    String subCollectionId = editMessageCollectionPrefix + postMessages.id.replaceFirst(postMessageCollectionPrefix, "");
    Map<String, dynamic> map = _createPostMessageContent(user, message, imageUrl, postMessages.id, subCollectionId);
    String documentName = map["NAME"];

    DocumentSnapshot document = await FirestoreService.createDocument(postMessages, documentName, initProperties: map);
    _debugProperties("postMessage", map);
    return document;
  }

  /// メッセージ投稿更新
  Future<DocumentSnapshot> updatePostMessageDocument(DocumentSnapshot postMessage, FirebaseUser user, String message, String imageUrl) async {
    if (! await isDocumentOwnerUser(postMessage, user)) return null;
    _editMessagesSelectorPostMessage = postMessage;

    Map<String, dynamic> editMap = _createEditMessageContent(postMessage, user, message, imageUrl);
    String documentName = editMap["NAME"];

    Map<String, dynamic> postMap = FirestoreService.getProperties(postMessage);
    postMap.addAll({"OWNER": user.uid, "MESSAGE": message, "IMAGE_URL": imageUrl, "EDITED": true, "DELETED": false});

    // 投稿を更新
    await FirestoreService.update(postMessage.reference, postMap);
    _debugProperties("postMessage", postMap);

    // 編集を追加
    CollectionReference editMessages = getEditMessageCollection(postMessage);
    await FirestoreService.createDocument(editMessages, documentName, initProperties: editMap);
    _debugProperties("editMessage", editMap);

    // 更新された投稿を返す
    return postMessage;
  }

  /// 管理者を削除
  Future<bool> deleteAdminDocument(FirebaseUser admin, FirebaseUser member) async {
    if (admin.uid != member.uid && ! await isAdminUser(admin)) return false;

    Map<String, dynamic> map = _createAdminContent(admin, member);
    String documentName = map["NAME"];

    DocumentSnapshot document = await FirestoreService.getDocument(_admins, documentName);
    if (document != null) {
      await FirestoreService.delete(document.reference);
    }
    return true;
  }

  /// メッセージ投稿削除 (論理削除)
  Future<bool> deletePostMessageDocument(DocumentSnapshot postMessage, FirebaseUser user) async {
    if (! await isDocumentOwnerUser(postMessage, user)) return false;
    _editMessagesSelectorPostMessage = postMessage;

    final String message = "** DELETED **";
    final String imageUrl = null;
    Map<String, dynamic> editMap = _createEditMessageContent(postMessage, user, message, imageUrl);
    String documentName = editMap["NAME"];

    Map<String, dynamic> postMap = FirestoreService.getProperties(postMessage);
    postMap.addAll({"OWNER": user.uid, "MESSAGE": message, "IMAGE_URL": imageUrl, "EDITED": false, "DELETED": true});

    // 投稿を更新
    await FirestoreService.update(postMessage.reference, postMap);
    _debugProperties("postMessage", postMap);

    // 編集を追加
    CollectionReference editMessages = getEditMessageCollection(postMessage);
    await FirestoreService.createDocument(editMessages, documentName, initProperties: editMap);
    _debugProperties("editMessage", editMap);

    return true;
  }

  /// FIXME (暫定)ユーザの管理者権限を確認
  ///
  /// Firestore Security Rules で、アクセス者のUIDがチェックできないため暫定追加
  Future<bool> isAdminUser(FirebaseUser user) async {
    return await FirestoreService.getDocument(_admins, user.uid) != null;
  }

  /// FIXME (暫定)ユーザのドキュメント・オーナ権限を確認
  ///
  /// Firestore Security Rules で、アクセス者のUIDがチェックできないため暫定追加
  Future<bool> isDocumentOwnerUser(DocumentSnapshot docSnap, FirebaseUser user) async {
    Map<String,dynamic> map = FirestoreService.getProperties(docSnap);
    return map != null ? map["OWNER"] == user.uid : false;
  }

  Map<String, dynamic> _createAdminContent(FirebaseUser owner, FirebaseUser member) {
    if (owner == null) throw AssertionError("owner error => null");
    if (member == null) throw AssertionError("member error => null");

    /* FIXME ユーザ情報として UID のみをドキュメント名に与える
    final String namePrefix = adminDocumentPrefix;
    final String nameSuffix = "_${member.uid}";
    */
    final String namePrefix = "";
    final String nameSuffix = "${member.uid}";
    final String documentName = namePrefix + nameSuffix;

    final Map<String, dynamic> map = {
      "MEMBER":              member.uid,         // 管理者メンバのUID
      "MEMBER_DISPLAY_NAME": member.displayName, // 管理者メンバ名
      "OWNER":               owner.uid,          // 作成者のUID
      "NAME":                documentName,       // ドキュメントID名
      "TIMESTAMP": _getTimeStamp(DateTime.now()) // 記録時タイムスタンプ
    };
    return map;
  }

  Map<String, dynamic> _createEventContent(
      int year, int month, int day,
      int startHour, int startMinute, int endHour, int endMinute,
      String placeId,
      FirebaseUser user,
      String title, String desc, String place,
      ) {
    if (month < 1 || month > 12) throw AssertionError("month error => $month");
    if (day < 1 || day > 31 ) throw AssertionError("day error => $day");
    if (startHour < 0 || startHour > 24) throw AssertionError("start hour error => $startHour");
    if (startMinute < 0 || startMinute > 60) throw AssertionError("start minute error => $startMinute");
    if (endHour < 0 || endHour > 24) throw AssertionError("end hour error => $endHour");
    if (endMinute < 0 || endMinute > 60) throw AssertionError("end minute error => $endMinute");
    if (placeId == null || placeId.isEmpty) throw AssertionError("placeId error => $placeId");
    if (user == null) throw AssertionError("user error => null");

    final String startFormat = "$year-${_zeroPadding(month, 2)}-${_zeroPadding(day, 2)} ${_zeroPadding(startHour, 2)}:${_zeroPadding(startMinute,2)}:00";
    final String endFormat = "$year-${_zeroPadding(month, 2)}-${_zeroPadding(day, 2)} ${_zeroPadding(endHour, 2)}:${_zeroPadding(endMinute,2)}:00";
    final DateTime startDateTime = DateTime.parse(startFormat);
    final DateTime endDateTime = DateTime.parse(endFormat);

    final String namePrefix = eventDocumentPrefix;
    final String nameSuffix = "_$year${_zeroPadding(month, 2)}${_zeroPadding(day, 2)}_${_zeroPadding(startHour, 2)}${_zeroPadding(startMinute,2)}00_$placeId";
    final String documentName = namePrefix + nameSuffix;

    final String subCollectionPrefix = postMessageCollectionPrefix;
    final String subCollectionName = subCollectionPrefix + nameSuffix;

    final Map<String, dynamic> map = {
      "TITLE":             title,                // イベントタイトル
      "PLACE":             place,                // イベント開催場所
      "DESC":              desc,                 // イベント内容の概要説明
      "START":             startFormat,          // イベント開始日時
      "END":               endFormat,            // イベント終了日時
      "OWNER":             user.uid,             // 作成者のUID
      "NAME":              documentName,         // ドキュメントID名
      "PARENT_COLLECTION": _events.id,           // 親コレクションID名
      "SUB_COLLECTION":    subCollectionName,    // サブコレクションID名
      "TIMESTAMP": _getTimeStamp(DateTime.now()) // 記録時タイムスタンプ
    };
    return map;
  }

  Map<String, dynamic> _createPostMessageContent(FirebaseUser user, String message, String imageUrl, String parentId, String subId) {
    if (user == null) throw AssertionError("user error => null");
    if (message == null && imageUrl == null) throw AssertionError("message and imageUrl must not null");
    if (message != null && message.isEmpty) throw AssertionError("message error => $message");
    if (imageUrl != null && imageUrl.isEmpty) throw AssertionError("imageUrl error => $imageUrl");
    if (message != null && imageUrl != null) throw AssertionError("both message and image URL must not be specified");
    /// message と imageUrl は、どちらか一方しか指定できません。

    final String namePrefix = postMessageDocumentPrefix;
    final String nameSuffix = "_${_getTimeStamp(DateTime.now())}_${user.uid}";
    final String documentName = namePrefix + nameSuffix;

    final Map<String, dynamic> map = {
      "DISPLAY_NAME":      user.displayName,  // 投稿者の名前
      "ICON_URL":          user.photoUrl,     // 投稿者のアイコンURL
      "MESSAGE":           message,           // 投稿メッセージ
      "IMAGE_URL":         imageUrl,          // 投稿画像URL
      "EDITED":            false,             // 投稿編集済フラグ
      "DELETED":           false,             // 投稿削除フラグ
      "OWNER":             user.uid,          // 投稿者のUID
      "NAME":              documentName,      // ドキュメントID名
      "PARENT_COLLECTION": parentId != null ? parentId : null, // 親コレクションID名
      "SUB_COLLECTION":    subId != null ? subId : null,       // サブコレクションID名
      "TIMESTAMP": _getTimeStamp(DateTime.now()), // 記録時タイムスタンプ
    };
    return map;
  }

  Map<String, dynamic> _createEditMessageContent(DocumentSnapshot postMessage, FirebaseUser user, String message, String imageUrl) {
    if (postMessage == null) throw AssertionError("postMessage error => null");
    if (user == null) throw AssertionError("user error => null");
    if (message == null && imageUrl == null) throw AssertionError("message and imageUrl must not null");
    if (message != null && message.isEmpty) throw AssertionError("message error => $message");
    if (imageUrl != null && imageUrl.isEmpty) throw AssertionError("imageUrl error => $imageUrl");
    if (message != null && imageUrl != null) throw AssertionError("both message and image URL must not be specified");
    /// message と imageUrl は、どちらか一方しか指定できません。


    final String namePrefix = editMessageDocumentPrefix;
    final String nameSuffix = "_${_getTimeStamp(DateTime.now())}_${user.uid}";
    final String documentName = namePrefix + nameSuffix;

    final Map<String, dynamic> postMap = FirestoreService.getProperties(postMessage);
    final String beforeMessage = postMap["MESSAGE"];
    final String beforeImageUrl = postMap["IMAGE_URL"];
    final String parentCollectionName = postMap["SUB_COLLECTION"];
    final Map<String, dynamic> map = {
      "DISPLAY_NAME":      user.displayName,     // 投稿者の名前
      "ICON_URL":          user.photoUrl,        // 投稿者のアイコンURL
      "BEFORE_MESSAGE":    beforeMessage,        // 編集前の投稿メッセージ
      "MESSAGE":           message,              // 編集後の投稿メッセージ
      "BEFORE_IMAGE_URL":  beforeImageUrl,       // 編集前の投稿画像URL
      "IMAGE_URL":         imageUrl,             // 編集後の投稿画像URL
      "OWNER":             user.uid,             // 投稿者のUID
      "NAME":              documentName,         // ドキュメントID名
      "PARENT_COLLECTION": parentCollectionName, // 親コレクションID名
      "SUB_COLLECTION":    null,                 // サブコレクションID名
      "TIMESTAMP": _getTimeStamp(DateTime.now()) // 記録時タイムスタンプ
    };
    return map;
  }

  static String _getTimeStamp(DateTime dateTime){
    return dateTime.toIso8601String();
  }

  static String _zeroPadding(int value, int width) {
    String num = "0000000000$value";
    int len = num.length;
    return num.substring(len - width, len);
  }

  static void _debugProperties(String title, Map<String, dynamic> map) {
    StringBuffer sb = StringBuffer();
    sb.writeln("$title{");

    map.keys.forEach((String key){
      dynamic value = map[key];
      sb.writeln("  $key:${value.toString()}");
    });
    sb.writeln("}");
    debugPrint(sb.toString());
  }
}


/// アプリ永続化情報の動作確認を行います。
class AppDataExample {
  /// インスタンスを生成できないように名前付きコンストラクタをプライベート化
  AppDataExample._();

  static Future<void> createData(Firestore firestore, FirebaseUser user) async {
    try {
      debugPrint("Step.0");
      AppDataState appData = AppDataState(firestore: firestore);
      debugPrint("Step.1");
      await appData.createAdminDocument(user, user);
      debugPrint("Step.2");
      DocumentSnapshot event = await appData.addEventDocument(
          2018, 9, 24, 13, 30, 16, 30, "kyoto", user, "DevFest Kyoto 2018", "GDG Kyoto's DevFest", "Kyoto");

      debugPrint("Step.3");
      await appData.setPostMessageEventListener(event, (QuerySnapshot querySnap) {
        List<DocumentChange> changes = querySnap.documentChanges;
        changes.forEach((DocumentChange change) {
          debugPrint("Event setPostMessageEventListener={MESSAGE=${change.document.data['MESSAGE']}, TIMESTAMP=${change.document.data['TIMESTAMP']}}");
        });
      });
      debugPrint("Step.4");

      // 投稿メッセージコレクションのイベントリスナーで、生成済の全ドキュメントが参照されないことをチェック。
      List<DocumentSnapshot> messages = await appData.getPostMessageDocuments(appData.getPostMessageCollection(event));
      debugPrint("getEventDocuments  messages=${messages.length}");

      debugPrint("Step.5");
      DocumentSnapshot post1 = await appData.addPostMessageDocument(event, user, "DevFest Kyoto 2018 始まった", null);
      debugPrint("Step.6");
      DocumentSnapshot post2 = await appData.addPostMessageDocument(event, user, "Kotlin イケイケですね~。", null);
      debugPrint("Step.7");
      DocumentSnapshot post3 = await appData.addPostMessageDocument(event, user, "Flutter 頑張れ。", null);
      debugPrint("Step.8");
      DocumentSnapshot post4 = await appData.addPostMessageDocument(event, user, "ちょっと休憩？", null);

      debugPrint("Step.9");
      await appData.removePostMessageEventListener(event);
      debugPrint("Step.10");

      debugPrint("Step.11");
      await appData.deletePostMessageDocument(post4, user);
      debugPrint("Step.12");
      CollectionReference postMessages = appData.getPostMessageCollection(event);
      debugPrint("Step.13");
      List<DocumentSnapshot> postMessageList = await appData.getPostMessageDocuments(postMessages);
      debugPrint("Step.14");
      int index = 0;
      postMessageList.forEach((DocumentSnapshot docSnap) {
        Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
        debugPrint("postMessage[${index++}]{\n  user=${map["DISPLAY_NAME"]}\n  icon=${map["ICON_URL"]}\n  ${map["MESSAGE"]}\n  image=${map["IMAGE_URL"]}\n  edit=${map["EDITED"]}\n  delete=${map["DELETED"]}\n}"); // FIXME
      });
      debugPrint("Step.15");
      await appData.updatePostMessageDocument(post3, user, "Flutter やるじゃん。", null);
      debugPrint("Step.16");

    } catch(error) {
      debugPrint('Something went wrong.');
      debugPrint("  type ⇒ ${error?.runtimeType??''}");
      debugPrint("  error ⇒ {\n${error?.toString()??''}\n}");
      if (error is Error) {
        debugPrint("  stacktrace ⇒ {\n${error?.stackTrace??''}\n}");
      }
      rethrow;
    }
  }

  static Future<void> readData(Firestore firestore, FirebaseUser user) async {
    try {
      debugPrint("Step.0");
      AppDataState appData = AppDataState(firestore: firestore);
      debugPrint("firestore.app.name=${firestore.app.name}");
      debugPrint("Step.1");
      DocumentSnapshot admin = await appData.getAdminDocument(user.uid, user);
      if (admin != null) {
        Map<String, dynamic> map = FirestoreService.getProperties(admin);
        debugPrint("Admin=${map['MEMBER_DISPLAY_NAME']}");
      } else{
        debugPrint("Admin is null");
      }
      debugPrint("Step.2");
      int index;
      List<DocumentSnapshot> admins = await appData.getAdminDocuments(user);
      if (admins != null) {
        index = 0;
        admins.forEach((DocumentSnapshot docSnap){
          Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
          debugPrint("Admin[${index++}]=${map['MEMBER_DISPLAY_NAME']}");
        });
      } else {
        debugPrint("Admins is null");
      }
      debugPrint("Step.3");
      List<DocumentSnapshot> events = await appData.getEventDocuments();
      index = 0;
      events.forEach((DocumentSnapshot docSnap){
        Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
        debugPrint("Event[${index++}]=${map['TITLE']}");
      });
      debugPrint("Step.4");
      DocumentSnapshot eventSnap = events[0];
      CollectionReference postMessages = appData.getPostMessageCollection(eventSnap);
      List<DocumentSnapshot> postDocuments = await appData.getPostMessageDocuments(postMessages);
      index = 0;
      postDocuments.forEach((DocumentSnapshot docSnap){
        Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
        debugPrint("PostMessage[${index++}]=${map['MESSAGE']}, imageUrl=${map['IMAGE_URL']}, edit=${map['EDITED']}, delete=${map['DELETED']}");
      });
      debugPrint("Step.5");
      CollectionReference editMessages = appData.getEditMessageCollection(postDocuments[2]);
      List<DocumentSnapshot> editDocuments = await appData.getEditMessageDocuments(editMessages, user);
      if (editDocuments != null) {
        index = 0;
        editDocuments.forEach((DocumentSnapshot docSnap){
          Map<String, dynamic> map = FirestoreService.getProperties(docSnap);
          debugPrint("editMessage[${index++}]=${map['MESSAGE']}, ${map['BEFORE_MESSAGE']}, ${map['IMAGE_URL']}, ${map['BEFORR_IMAGE_URL']}");
        });
      } else {
        debugPrint("editMessage is null");
      }
      debugPrint("Step.6");

    } catch(error) {
      debugPrint('Something went wrong.');
      debugPrint("  type ⇒ ${error?.runtimeType??''}");
      debugPrint("  error ⇒ {\n${error?.toString()??''}\n}");
      if (error is Error) {
        debugPrint("  stacktrace ⇒ {\n${error?.stackTrace??''}\n}");
      }
      rethrow;
    }
  }
}

