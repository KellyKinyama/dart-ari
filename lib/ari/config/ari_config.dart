import 'package:dart_ari/dart_ari.dart' as dart_ari;

import 'package:dotenv/dotenv.dart';

import 'constants.dart';

class Config {
  Map<String, String> ariConfigs = {};
  Config() {
    DotEnv env = DotEnv(includePlatformEnvironment: true)..load();

    ariConfigs[ASTERISK_ARI_SCHEME] = env[ASTERISK_ARI_SCHEME]!;

    ariConfigs[ASTERISK_ARI_HOST] = env[ASTERISK_ARI_HOST]!;

    ariConfigs[ASTERISK_ARI_PORT] = env[ASTERISK_ARI_PORT]!;

    ariConfigs[ASTERISK_ARI_USERNAME] = env[ASTERISK_ARI_USERNAME]!;

    ariConfigs[ASTERISK_ARI_PASSWORD] = env[ASTERISK_ARI_PASSWORD]!;
  }
}
