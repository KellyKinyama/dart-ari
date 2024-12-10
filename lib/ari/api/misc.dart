import 'dart:async';

class CallerID {
  CallerID(this.name, this.number);
  /**
     * Name.
     */
  String name; //: string;

  /**
     * Number.
     */
  String number; //: string;

  factory CallerID.fromJson(dynamic json) {
    return CallerID(json['name'] as String, json['number'] as String);
  }
}

Timer setTimeout(callback, [int duration = 1000]) {
  return Timer(Duration(milliseconds: duration), callback);
}

sec5Timer(bool isStopped) {
  Timer.periodic(Duration(seconds: 5), (timer) {
    if (isStopped) {
      timer.cancel();
    }
    print("Dekhi 5 sec por por kisu hy ni :/");
  });
}

void clearTimeout(Timer t) {
  t.cancel();
}
