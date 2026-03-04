import 'dart:io';

import 'package:dart_ari/webserver/models/base.dart';
// Assuming your existing Model and DB connection package is imported here
// import 'package:your_project/models/model.dart';

void main() async {
  final String outputFile = 'pjsip_endpoints.conf';
  final StringBuffer buffer = StringBuffer();

  // 1. Establish connection
  final db = await Model.getDbConnection();

  try {
    // 2. Query only necessary columns: number (endpoint) and name
    // Assuming 'name' is the column for the Agent's full name
    List<Map<String, dynamic>> agents =
        await db.table('agents').select(['endpoint', 'name']).get();

    print("Generating PJSIP config for ${agents.length} agents...");

    for (var agent in agents) {
      String ext = agent['endpoint'].toString();
      String name = agent['name'] ?? "Agent $ext";

      // Determine template based on extension
      String template = (ext == '6001') ? 'phone_endpoint' : 'webrtc_endpoint';

      // --- [Endpoint Section] ---
      buffer.writeln('[$ext](basic_endpoint,$template)');
      buffer.writeln('type=endpoint');
      buffer.writeln('callerid="$name" <$ext>');
      buffer.writeln('auth=$ext');
      buffer.writeln('aors=$ext');

      // --- [AOR Section] ---
      buffer.writeln('[$ext](single_aor)');
      buffer.writeln('type=aor');
      buffer.writeln('');

      // --- [Auth Section] ---
      buffer.writeln('[$ext](userpass_auth)');
      buffer.writeln('type=auth');
      buffer.writeln('username=$ext');
      buffer.writeln('password=$ext');
      buffer.writeln(''); // Space for readability
    }

    // 3. Save to file
    final File file = File(outputFile);
    await file.writeAsString(buffer.toString());

    print("Successfully synchronized $outputFile");
  } catch (e) {
    print("Database Error: $e");
  } finally {
    await db.disconnect();
  }
}
