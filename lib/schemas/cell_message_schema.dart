class CellMessageSchema {
  final int bars;
  final String network;
  final String technology;
  final int rsrp;
  final int rsrq;
  final String ipAddress;
  final String apn;
  final int regStatus;
  final String pinStatus;

  CellMessageSchema({
    required this.bars,
    required this.network,
    required this.technology,
    required this.rsrp,
    required this.rsrq,
    required this.apn,
    required this.ipAddress,
    required this.pinStatus,
    required this.regStatus,
  });

  static CellMessageSchema fromJson(Map<String, dynamic> json) =>
      CellMessageSchema(
        bars: json["bars"] as int,
        network: json["network"] as String,
        technology: json["technology"] as String,
        rsrp: json["rsrp"] as int,
        rsrq: json["rsrq"] as int,
        apn: json["apn"] as String,
        ipAddress: json["ip_addr"] as String,
        pinStatus: json["pin_status"] as String,
        regStatus: json["reg_status"] as int,
      );
}
