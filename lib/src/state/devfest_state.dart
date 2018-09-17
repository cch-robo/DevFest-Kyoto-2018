import 'package:devfest_2018/src/state/sign_in_state.dart';
import 'package:devfest_2018/src/state/permanent_state.dart';

/// DevFest Kyoto 2018 アプリ状態クラス
class DevFestState {
  // 管理する状態
  SignInState signIn = SignInState();
  AppDataState appData = AppDataState();
}
