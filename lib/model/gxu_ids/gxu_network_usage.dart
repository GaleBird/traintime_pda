// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

class GxuNetworkUsage {
  final String account;
  final String settlementDate;
  final String usedTraffic;
  final String freeTraffic;
  final String availableTraffic;
  final String protection;
  final String balance;
  final DateTime refreshedAt;

  const GxuNetworkUsage({
    required this.account,
    required this.settlementDate,
    required this.usedTraffic,
    required this.freeTraffic,
    required this.availableTraffic,
    required this.protection,
    required this.balance,
    required this.refreshedAt,
  });

  factory GxuNetworkUsage.fromJson(Map<String, dynamic> json) {
    return GxuNetworkUsage(
      account: json["account"]?.toString() ?? "",
      settlementDate: json["settlementDate"]?.toString() ?? "",
      usedTraffic: json["usedTraffic"]?.toString() ?? "",
      freeTraffic: json["freeTraffic"]?.toString() ?? "",
      availableTraffic: json["availableTraffic"]?.toString() ?? "",
      protection: json["protection"]?.toString() ?? "",
      balance: json["balance"]?.toString() ?? "",
      refreshedAt: DateTime.parse(json["refreshedAt"]?.toString() ?? ""),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "account": account,
      "settlementDate": settlementDate,
      "usedTraffic": usedTraffic,
      "freeTraffic": freeTraffic,
      "availableTraffic": availableTraffic,
      "protection": protection,
      "balance": balance,
      "refreshedAt": refreshedAt.toIso8601String(),
    };
  }
}
