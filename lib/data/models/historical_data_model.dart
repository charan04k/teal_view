import 'package:equatable/equatable.dart';

class HistoricalData extends Equatable {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const HistoricalData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    final tsString = json['TS'] as String?;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    if (tsString != null) {
      try {
        timestamp = DateTime.parse(tsString).millisecondsSinceEpoch;
      } catch (_) {}
    }

    final close = (json['LTP'] as num?)?.toDouble() ?? 0.0;

    return HistoricalData(
      timestamp: timestamp,
      open: (json['OPEN'] as num?)?.toDouble() ?? close,
      high: (json['HIGH'] as num?)?.toDouble() ?? close,
      low: (json['LOW'] as num?)?.toDouble() ?? close,
      close: close,
      volume: json['VOLUME_DIFF'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [timestamp, open, high, low, close, volume];
}
