// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/schemas/cell_message_schema.dart';

void main() {
  test("Verify JSON", () {
    var result = CellMessageSchema.fromJson({
      "bars": 2,
      "network": "AT&T",
      "technology": "5G",
      "rsrp": -17,
      "rsrq": 56,
      "apn": "stable",
      "ip_addr": "192.167.1.2",
      "pin_status": "READY",
      "reg_status": 1,
    });
    expect(result.bars, equals(2));
    expect(result.network, equals("AT&T"));
    expect(result.technology, equals("5G"));
    expect(result.rsrp, equals(-17));
    expect(result.rsrq, equals(56));
    expect(result.apn, equals("stable"));
    expect(result.ipAddress, equals("192.167.1.2"));
    expect(result.pinStatus, equals("READY"));
    expect(result.regStatus, equals(1));
  });
}
