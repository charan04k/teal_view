part of 'chart_bloc.dart';

class ChartState extends Equatable {
  final bool isLoading;
  final List<HistoricalData> data;
  final String? symbol;
  final String range;

  const ChartState({
    this.isLoading = false,
    this.data = const [],
    this.symbol,
    this.range = '1D',
  });

  ChartState copyWith({
    bool? isLoading,
    List<HistoricalData>? data,
    String? symbol,
    String? range,
  }) {
    return ChartState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      symbol: symbol ?? this.symbol,
      range: range ?? this.range,
    );
  }

  @override
  List<Object?> get props => [isLoading, data, symbol, range];
}
