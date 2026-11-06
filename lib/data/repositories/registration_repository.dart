import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/error_mapper.dart';
import '../firebase/users_remote_data_source.dart';
import '../models/registered_user.dart';

/// Регистрация: запись в Realtime Database + отметка на устройстве,
/// чтобы при следующем запуске сразу открывать список постов.
/// Ошибки наружу выходят только как [AppException].
class RegistrationRepository {
  RegistrationRepository({required this._remote, required this._prefs});

  final UsersRemoteDataSource _remote;
  final SharedPreferences _prefs;

  static const _userKeyKey = 'registration.user_key';
  static const _userNameKey = 'registration.user_name';

  bool get isRegistered => _prefs.getString(_userKeyKey) != null;

  String? get registeredName => _prefs.getString(_userNameKey);

  Future<String> register(RegisteredUser user) async {
    try {
      final key = await _remote.saveUser(user.toJson());
      await _prefs.setString(_userKeyKey, key);
      await _prefs.setString(_userNameKey, user.name);
      return key;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
