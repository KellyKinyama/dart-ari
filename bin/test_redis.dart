import 'package:redis/redis.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  // Pulling from your .env config
  final String redisIp = env['REDIS_ADDRESS'] ?? '127.0.0.1';
  final int redisPort = int.parse(env['REDIS_PORT'] ?? '6379');
  final String redisPassword = env['REDIS_PASSWORD'] ?? 'zsco@123deraboof';

  print('--- Redis Connection Test ---');
  print('Connecting to: $redisIp:$redisPort');

  final connection = RedisConnection();

  try {
    // 1. Establish TCP Connection
    Command command = await connection.connect(redisIp, redisPort);
    print('✅ TCP Connection Established');

    // 2. Authenticate
    // In Dart redis package, send_object is used for AUTH
    var authResult = await command.send_object(["AUTH", redisPassword]);
    print('✅ Authentication: $authResult');

    // 3. Simple PING Test
    var pingResult = await command.send_object(["PING"]);
    print('✅ Ping Response: $pingResult');

    // 4. Test PubSub Setup
    print('Testing PubSub subscription on channel "monkey"...');
    PubSub pubsub = PubSub(command);
    pubsub.subscribe(["monkey"]);

    print('✅ Subscribed successfully.');
    print('----------------------------');
    print('Redis is READY for your WebServer.');

    // Close test connection
    await connection.close();
    exit(0);
  } catch (e) {
    print('❌ Redis Test Failed!');
    print('Error: $e');
    exit(1);
  }
}
