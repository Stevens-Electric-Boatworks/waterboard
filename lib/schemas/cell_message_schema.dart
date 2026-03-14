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
}
