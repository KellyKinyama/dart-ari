
import 'package:dotenv/dotenv.dart';

import 'constants.dart';

class Config {
  Map<String, String> ariConfigs = {};
  Map<String, String> dbConfigs = {};
  Config() {
    DotEnv env = DotEnv(includePlatformEnvironment: true)..load();

    ariConfigs[ASTERISK_ARI_SCHEME] = env[ASTERISK_ARI_SCHEME]!;

    ariConfigs[ASTERISK_ARI_HOST] = env[ASTERISK_ARI_HOST]!;

    ariConfigs[ASTERISK_ARI_PORT] = env[ASTERISK_ARI_PORT]!;

    ariConfigs[ASTERISK_ARI_USERNAME] = env[ASTERISK_ARI_USERNAME]!;

    ariConfigs[ASTERISK_ARI_PASSWORD] = env[ASTERISK_ARI_PASSWORD]!;

    dbConfigs[AST_DB_HOST] = env[AST_DB_HOST]!;
    dbConfigs[AST_DB_PORT] = env[AST_DB_PORT]!;
    dbConfigs[AST_DB_DATABASE] = env[AST_DB_DATABASE]!;
    dbConfigs[AST_DB_USERNAME] = env[AST_DB_USERNAME]!;
    dbConfigs[AST_DB_PASSWORD] = env[AST_DB_PASSWORD]!;
  }
}
