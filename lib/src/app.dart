import 'package:flutter/material.dart';
import 'package:devfest_2018/src/state/state_provider.dart';
import 'package:devfest_2018/src/page/google_signin_page.dart';

class DevFestApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DevFestStateProvider(
        child: new MaterialApp(
          title: 'DevFest Kyoto 2018',
          theme: new ThemeData(
            primarySwatch: Colors.purple,
          ),
          home: new SignInPage(),
        ),
    );
  }
}
