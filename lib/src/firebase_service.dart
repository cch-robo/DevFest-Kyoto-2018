import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// Firestote サービス
///
/// Flutter での基本的な Firestore 機能を提供(操作手順代行)するサービスです。
class FirestoreService {

  /// テスト用 FirebaseApp 生成
  ///
  /// Firebase プロジェクトを利用する Firebase アプリのインスタンスを生成します。
  static Future<FirebaseApp> getFirebaseApp() async {
    final FirebaseApp app = await FirebaseApp.configure(
      name: 'test',
      options: const FirebaseOptions(
        // FIXME Firebaseプロジェクト設定のアプリからDevFestアプリのアプリケーションIDを直書き
        googleAppID: '1:564478734383:android:7b842dcad4186a6a',

        // FIXME Firebaseプロジェクト設定のウエブAPIキーを直書き
        // apiKey: 'AIzaSyBPAu2_DdR9uzLS1c7Bwcr-kYVfvDdM7e8',

        // FIXME Firebaseプロジェクト設定のプロジェクトIDを直書き
        projectID: 'practice-9b35a',
      ),
    );
    return app;
  }

  /// Firestore 生成
  ///
  /// 既存の Firebase アプリケーション環境を引き継いで Firestore インスタンスを生成する。
  static Firestore createFirestore({initApp : FirebaseApp}) {
    FirebaseApp firebaseApp = initApp != null ? initApp : FirebaseApp.instance;
    if (firebaseApp == null) throw AssertionError("Firebase Application has not created.");

    return Firestore(app: firebaseApp);
  }

  /// firestoreから、コレクションを取得（未作成の場合の新規作成を含む）
  static CollectionReference getCollection(Firestore firestore, String collectionName) {
    return firestore.collection(collectionName);
  }

  /// コレクションから、現時点のドキュメント一覧を取得
  static Future<List<DocumentSnapshot>> getDocuments(CollectionReference collection) async {
    final QuerySnapshot querySnapshot = await collection.getDocuments();
    return querySnapshot.documents;
  }

  /// 現時点のドキュメントから、参照(実態確定)を取得
  static DocumentReference convertDocumentReference(DocumentSnapshot docSnap) {
    return docSnap.reference;
  }

  /// 現時点のドキュメントから、プロパティマップを取得
  static Map<String, dynamic> getProperties(DocumentSnapshot docSnap) {
    Map<String, dynamic> map;
    if (docSnap != null && docSnap.exists) {
      map = docSnap.data;
    }
    return map;
  }

  /// コレクションから、現時点のドキュメントを取得
  static Future<DocumentSnapshot> getDocument(CollectionReference collection, String documentName) async {
    DocumentSnapshot document;
    List<DocumentSnapshot> documents = await getDocuments(collection);
    documents.forEach((DocumentSnapshot docSnap){
      if (docSnap.documentID == documentName) document = docSnap;
    });
    return document;
  }

  /// コレクションから、現時点のドキュメントの存在を確認
  static Future<bool> existDocument(CollectionReference collection, String documentName) async {
    DocumentSnapshot document = await getDocument(collection, documentName);
    return document != null;
  }

  /// コレクションに、ドキュメントを追加
  static Future<DocumentSnapshot> createDocument(CollectionReference collection, String documentName, {Map<String, dynamic> initProperties}) async {
    if (documentName == null || documentName.length == 0) {
      throw AssertionError("argument documentName is must not empty.");
    }

    final DocumentReference docReference = collection.document(documentName);
    if (initProperties != null) {
      await docReference.setData(initProperties);
    }

    // 現時点のドキュメント内容を Firestore から取得
    DocumentSnapshot docSnapshot = await getDocument(collection, documentName);
    return docSnapshot;
  }

  /// コレクションから、参照(実態不確定)のドキュメント一覧を取得
  static Future<List<DocumentReference>> getDocumentReferences(CollectionReference collection) async {
    List<DocumentSnapshot> documentSnapshots = await getDocuments(collection);
    List<DocumentReference> documents = [];
    documentSnapshots.forEach((DocumentSnapshot docSnapshot){
      documents.add(docSnapshot.reference);
    });
    return documents;
  }

  /// コレクションから、参照(実態不確定)のドキュメントを取得
  static DocumentReference getDocumentReference(CollectionReference collection, String documentName) {
    if (documentName == null || documentName.length == 0) {
      throw AssertionError("argument documentName is must not empty.");
    }

    return collection.document(documentName);
  }

  /// 参照(実態不確定)なドキュメントのプロパティを設定
  static Future<void> setup(DocumentReference docRef, Map<String, dynamic> setupProperties) async {
    await docRef.setData(setupProperties);
  }

  /// 参照(実態不確定)なドキュメントのプロパティを更新
  static Future<void> update(DocumentReference docRef, Map<String, dynamic> updateProperties) async {
    await docRef.updateData(updateProperties);
  }

  /// 参照(実態不確定)なドキュメントを削除
  static Future<void> delete(DocumentReference docRef) async {
    await docRef.delete();
  }

  /// 参照(実態不確定)なドキュメントのプロパティを設定
  static Future<void> transactionSetup(DocumentReference docRef, Map<String, dynamic> setupProperties) async {
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot docSnapshot = await tx.get(docRef);
      if (docSnapshot.exists) {
        await tx.set(docRef, setupProperties);
      }
    });
  }

  /// 参照(実態不確定)なドキュメントのプロパティを更新
  static Future<void> transactionUpdate(DocumentReference docRef, Map<String, dynamic> updateProperties) async {
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot docSnapshot = await tx.get(docRef);
      if (docSnapshot.exists) {
        await tx.update(docRef, updateProperties);
      }
    });
  }

  /// 参照(実態不確定)なドキュメントを削除
  static Future<void> transactionDelete(DocumentReference docRef) async {
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot docSnapshot = await tx.get(docRef);
      if (docSnapshot.exists) {
        await tx.delete(docRef);
      }
    });
  }
}

/// アプリデータ
/// アプリで利用するデータ(Firestorオブジェクト)のCRUDを提供します。
class AppData {
  Firestore _firestore;
  CollectionReference _admins;
  CollectionReference _events;

  final String adminCollectionName = "evtn_admins";
  final String adminDocumentPrefix = "evtn_admin";
  final String eventCollectionName = "evtn_events";
  final String eventDocumentPrefix = "evtn_event";
  final String postMessageCollectionPrefix = "evtn_event_messages";
  final String postMessageDocumentPrefix = "evtn_event_message_post";
  final String editMessageCollectionPrefix = "evtn_event_message_edits";
  final String editMessageDocumentPrefix = "evtn_event_message_edit";

  AppData({Firestore firestore}) {
    _firestore = firestore != null ? firestore : FirestoreService.createFirestore();
    _admins = FirestoreService.getCollection(_firestore, adminCollectionName);
    _events = FirestoreService.getCollection(_firestore, eventCollectionName);
  }

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
    Map<String, dynamic> map = FirestoreService.getProperties(eventSnap);
    return FirestoreService.getCollection(_firestore, map["SUB_COLLECTION"]);
  }

  /// 編集メッセージコレクションを取得
  CollectionReference getEditMessageCollection(DocumentSnapshot postMessageSnap) {
    Map<String, dynamic> map = FirestoreService.getProperties(postMessageSnap);
    return FirestoreService.getCollection(_firestore, map["SUB_COLLECTION"]);
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
    CollectionReference postMessages = getPostMessageCollection(event);
    return await FirestoreService.getDocument(postMessages, documentName);
  }

  /// 編集メッセージを取得
  Future<DocumentSnapshot> getEditMessageDocument(DocumentSnapshot postMessage, String documentName, FirebaseUser user) async {
    if (! await isDocumentOwnerUser(postMessage, user)) return null;
    CollectionReference editMessages = getEditMessageCollection(postMessage);
    return await FirestoreService.getDocument(editMessages, documentName);
  }

  /// 管理者追加
  Future<DocumentSnapshot> createAdminDocument(FirebaseUser admin, FirebaseUser member) async {
    if (! await isAdminUser(admin)) return null;

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
  Future<DocumentSnapshot> addPostMessageDocument(DocumentSnapshot event, FirebaseUser user, String message) async {

    Map<String, dynamic> map = _createPostMessageContent(user, message);
    String documentName = map["NAME"];

    CollectionReference postMessages = getPostMessageCollection(event);
    map.addAll({
      "PARENT_COLLECTION": postMessages.id,
      "SUB_COLLECTION": editMessageCollectionPrefix + postMessages.id.replaceFirst(postMessageCollectionPrefix, "")
    });

    DocumentSnapshot document = await FirestoreService.createDocument(postMessages, documentName, initProperties: map);
    _debugProperties("postMessage", map);
    return document;
  }

  /// メッセージ投稿更新
  Future<DocumentSnapshot> updatePostMessageDocument(DocumentSnapshot postMessage, FirebaseUser user, String message) async {
    if (! await isDocumentOwnerUser(postMessage, user)) return null;

    Map<String, dynamic> editMap = _createEditMessageContent(postMessage, user, message);
    String documentName = editMap["NAME"];

    Map<String, dynamic> postMap = FirestoreService.getProperties(postMessage);
    postMap.addAll({"OWNER": user.uid, "MESSAGE": message});

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

    final String namePrefix = adminDocumentPrefix;
    final String nameSuffix = "_${member.uid}";
    final String documentName = namePrefix + nameSuffix;

    final Map<String, dynamic> map = {
      "OWNER": owner.uid,
      "OWNER_DISPLAY_NAME": owner.displayName,
      "MEMBER": member.uid,
      "NAME": documentName,
      "TIMESTAMP": DateTime.now().toIso8601String(),
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
      "OWNER": user.uid,
      "NAME": documentName,
      "PARENT_COLLECTION": _events.id,
      "SUB_COLLECTION": subCollectionName,
      "TITLE": title,
      "PLACE": place,
      "DESC": desc,
      "START": startFormat,
      "END": endFormat,
      "TIMESTAMP": DateTime.now().toIso8601String(),
    };
    return map;
  }

  Map<String, dynamic> _createPostMessageContent(FirebaseUser user, String message) {
    if (user == null) throw AssertionError("user error => null");
    if (message == null || message.isEmpty) throw AssertionError("message error => $message");

    final String namePrefix = postMessageDocumentPrefix;
    final String nameSuffix = "_${DateTime.now().toIso8601String()}_${user.uid}";
    final String documentName = namePrefix + nameSuffix;

    final Map<String, dynamic> map = {
      "OWNER": user.uid,
      "DISPLAY_NAME": user.displayName,
      "PHOTO_URL": user.photoUrl,
      "NAME": documentName,
      "MESSAGE": message,
      "TIMESTAMP": DateTime.now().toIso8601String(),
    };
    return map;
  }

  Map<String, dynamic> _createEditMessageContent(DocumentSnapshot postMessage, FirebaseUser user, String message) {
    if (postMessage == null) throw AssertionError("postMessage error => null");
    if (user == null) throw AssertionError("user error => null");
    if (message == null || message.isEmpty) throw AssertionError("message error => $message");


    final String namePrefix = editMessageDocumentPrefix;
    final String nameSuffix = "_${DateTime.now().toIso8601String()}_${user.uid}";
    final String documentName = namePrefix + nameSuffix;

    final Map<String, dynamic> map = _createPostMessageContent(user, message);
    final Map<String, dynamic> postMap = FirestoreService.getProperties(postMessage);
    final String beforeMessage = postMap["MESSAGE"];
    final String parentCollectionName = postMap["SUB_COLLECTION"];
    map.addAll({
      "BEFORE_MESSAGE": beforeMessage,
      "NAME": documentName,
      "PARENT_COLLECTION": parentCollectionName,
      "SUB_COLLECTION": null,
    });
    return map;
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
