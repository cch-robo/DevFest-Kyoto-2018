# DevFest Kyoto 2018 アプリ（ささっと作っチャッター）

[DevFest Kyoto 2018](https://gdgkyoto.connpass.com/event/99527/) での発表として、  
Flutter と Firebase を使えば、ささっとサービスを作れることを紹介するコンセプトアプリです。

イベントで気軽にメッセージを投稿できるよう、以下の機能を有します。
* Google アカウントでログインするだけで使えます。
* メッセージと写真を自由に投稿することができます。
* 自分が投稿したメッセージなら編集や削除できます。
* Google Play で [ささっと作っチャッター](https://play.google.com/store/apps/details?id=app.cchlab.flutter.android.devfest2018) として公開されています。
* ビルドに必要な作業についての資料が公開されています。  
[FlutterとFirebaseでささっとサービスを作ろう](https://drive.google.com/open?id=1P5MGdy1XozBugQcSJx954zyrlRfz7d-M)

## 注意事項

Firestoreを使っているため、このままビルドしてもアプリは稼働しません。

独自のアプリ(チャットサービス)として使いたい場合は、Firestoreが使えるよう、  
アプリへの独自署名と独自Firebaseプロジェクトへのアプリ登録が必要です。

上記の手順については、DevFest Kyoto 2018 資料 [FlutterとFirebaseでささっとサービスを作ろう](https://drive.google.com/open?id=1P5MGdy1XozBugQcSJx954zyrlRfz7d-M) を御参照ください。

