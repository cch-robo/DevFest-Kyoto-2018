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
