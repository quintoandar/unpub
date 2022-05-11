import 'package:oauth2/oauth2.dart';

extension Ext on Credentials {
  bool isValid() => refreshToken != null && refreshToken!.isNotEmpty;
}
