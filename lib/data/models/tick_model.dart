import 'package:equatable/equatable.dart';

class Tick extends Equatable {
  final String symbol;
  final double ltp;
  final double change;
  final double changePct;
  final double vwap;
  final int timestamp;

  const Tick({
    required this.symbol,
    required this.ltp,
    required this.change,
    required this.changePct,
    required this.vwap,
    required this.timestamp,
  });

  factory Tick.fromJson(Map<String, dynamic> json) {
    final ltp = (json['LTP'] as num?)?.toDouble() ?? 0.0;
    final prevClose = (json['PREV_CLOSE'] as num?)?.toDouble() ?? ltp;
    final change = ltp - prevClose;
    final changePct = prevClose > 0 ? (change / prevClose) * 100 : 0.0;
    
    final tsString = json['TS'] as String?;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    if (tsString != null) {
      try {
        // Parse "2026-05-04 11:30:15+05:30"
        timestamp = DateTime.parse(tsString).millisecondsSinceEpoch;
      } catch (_) {}
    }

    return Tick(
      symbol: json['SYMBOL'] as String? ?? '',
      ltp: ltp,
      change: change,
      changePct: changePct,
      vwap: (json['ATP'] as num?)?.toDouble() ?? 0.0,
      timestamp: timestamp,
    );
  }

  @override
  List<Object?> get props => [symbol, ltp, change, changePct, vwap, timestamp];
}
