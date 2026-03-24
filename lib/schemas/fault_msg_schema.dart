import 'package:waterboard/pages/page_utils.dart';

class FaultMsgSchema {
  final int errorCode;
  final String message;
  final DateTime time;

  FaultMsgSchema({required this.errorCode, required this.message, required this.time});

  static FaultMsgSchema fromJson(Map<String, dynamic> json) =>
      FaultMsgSchema(
        errorCode: json["error_code"] as int,
        message: json["message"] as String,
        time: PageUtils.fromROSTimeStamp(json["timestamp"])
      );
}
