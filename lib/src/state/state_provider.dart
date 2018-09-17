import 'package:flutter/material.dart';

import 'package:devfest_2018/src/state/devfest_state.dart';


/// DevFest Kyoto 2018 アプリの状態を提供する Widget です。
/// Widgetツリー内の子Widgetに、DevFestアプリ状態を提供します。
class DevFestStateProvider extends InheritedWidget {
  DevFestStateProvider({
    Key key,
    DevFestState devfestState,
    Widget child,
  }) :  this.devfestState = devfestState??DevFestState(),
        super(key: key,child: child);

  /// 管理する状態
  final DevFestState devfestState;

  @override
  /// 継承元の更新に伴い、自身も更新する必要があるか否かを明示する。
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  /// 管理する状態を Widget ツリーから参照可能にします。
  static DevFestState of(BuildContext context) {
    DevFestStateProvider widget = context
        .inheritFromWidgetOfExactType(DevFestStateProvider) as DevFestStateProvider;
    return widget.devfestState;
  }
}