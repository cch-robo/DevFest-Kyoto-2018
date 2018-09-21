import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// Firestote サービス
///
/// Flutter での基本的な Firestore 機能を提供(操作手順代行)するサービスです。
class FirestoreService {

  /// Firestore 生成
  ///
  /// 既存の Firebase アプリケーション環境を引き継いで Firestore インスタンスを生成する。
  /// 【補足】Firebase Authentication を使う場合には、FirebaseApp の config 設定は行いません。
  static Firestore createFirestore({FirebaseApp initApp}) {
    FirebaseApp firebaseApp = initApp != null ? initApp : FirebaseApp.instance;
    if (firebaseApp == null) throw AssertionError("Firebase Application has not created.");

    return Firestore(app: firebaseApp);
  }

  /// firestoreから、コレクションを取得（未作成の場合の参照作成を含む）
  static CollectionReference getCollection(Firestore firestore, String collectionName) {
    return firestore.collection(collectionName);
  }

  /// コレクションにイベントリスナーを追加
  ///
  /// コレクションに、各ドキュメント更新/生成イベント時の処理関数のイベントリスナーを追加します。
  static Future<StreamSubscription<QuerySnapshot>> addCollectionEventListener(
      CollectionReference collection,
      void Function(QuerySnapshot document) onEvent,
      {Function onError, void onDone()}) async {

    // ドキュメント更新/生成のイベントを扱えるよう、
    // コレクションの Stream<QuerySnapshot> に、
    // 引数の onEvent(QuerySnapshot) 関数を登録します。
    // Stream<QuerySnapshot>#listen((QuerySnapshot snapshot){/* 何らかの処理 */})
    //
    // 【注意】
    // 初回 onEvent() コールバック時には、
    // documentChanges:List<DocumentChange> に生成済みのドキュメント/snapshotが渡されるため、
    // 新規生成/更新ドキュメントのみを対象とするよう（全てのドキュメント/snapshotを対象としないよう）
    // 予め初回のみスキップさせるよう設定し、全ての生成済みのドキュメント/snapshotを取得しておきます。
    //
    // 【参考】
    //　Single-Subscription vs. Broadcast Streams
    //　https://www.dartlang.org/articles/libraries/broadcast-streams
    Stream<QuerySnapshot> stream = collection.snapshots();
    Stream<QuerySnapshot> firstSkipStream = stream.skip(1); // 初回のみ処理をスキップ
    StreamSubscription<QuerySnapshot> streamSubscription = firstSkipStream.listen(
        onEvent, onError: onError, onDone: onDone, cancelOnError: true);

    // 予めドキュメントを生成/更新しない初回イベントをダミーで実行させます。
    await collection.getDocuments();

    return streamSubscription;
  }

  /// コレクションのイベントリスナーを削除
  ///
  /// コレクションに追加した、各ドキュメント更新/生成イベント時の処理関数のイベントリスナーを無効化(削除)します。
  static void removeCollectionEventListener(StreamSubscription<QuerySnapshot> collectionEventListener) {
    if (collectionEventListener == null) return;

    // コレクションの Stream から、ドキュメント更新/生成のイベントの処理先をクリアします。
    collectionEventListener.cancel();
  }

  /// コレクションから、現時点のドキュメント一覧を取得
  static Future<List<DocumentSnapshot>> getDocuments(CollectionReference collection) async {
    final QuerySnapshot querySnapshot = await collection.getDocuments();
    return querySnapshot.documents;
  }

  /// 現時点のドキュメントから、参照(実態未確定)を取得
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
