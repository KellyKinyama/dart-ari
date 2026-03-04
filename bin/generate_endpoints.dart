import 'dart:io';

void main() async {
  // 1. Define your list of numbers
  final List<String> extensions = ['6001', '6002', '6003', '6004', '6005'];
  
  // 2. Define the output file path
  final File file = File('pjsip_endpoints.conf');
  
  // 3. Open a buffer for writing
  StringBuffer buffer = StringBuffer();

  for (var ext in extensions) {
    // Logic for specific extensions (like 6001 being unique)
    String templates = (ext == '6001') 
        ? 'basic_endpoint,phone_endpoint' 
        : 'basic_endpoint,webrtc_endpoint';
    
    String transport = (ext == '6001') 
        ? 'transport=transport-ws' 
        : 'transport=transport-wss'; // Defaulting to WSS for others

    String callerId = (int.parse(ext) < 6003) 
        ? '"ISD" <$ext>' 
        : '"Conrad de Wet" <$ext>';

    buffer.writeln('[$ext]($templates)');
    if (ext == '6001') buffer.writeln(transport);
    buffer.writeln('type=endpoint');
    buffer.writeln('callerid=$callerId');
    buffer.writeln('auth=$ext');
    buffer.writeln('aors=$ext');
    
    buffer.writeln('[$ext](single_aor)');
    buffer.writeln('type=aor');
    if (int.parse(ext) >= 6003) buffer.writeln('mailboxes=User1@default');
    
    buffer.writeln('[$ext](userpass_auth)');
    buffer.writeln('type=auth');
    buffer.writeln('username=$ext');
    buffer.writeln('password=$ext');
    buffer.writeln(''); // Empty line for readability
  }

  // 4. Write to file
  try {
    await file.writeAsString(buffer.toString());
    print('Successfully generated ${file.path}');
  } catch (e) {
    print('Error writing to file: $e');
  }
}