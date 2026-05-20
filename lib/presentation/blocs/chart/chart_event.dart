part of 'chart_bloc.dart';

abstract class ChartEvent extends Equatable {
  const ChartEvent();

  @override
  List<Object> get props => [];
}

class LoadChartData extends ChartEvent {
  final String symbol;
  final String range;

  const LoadChartData(this.symbol, {this.range = '1D'});

  @override
  List<Object> get props => [symbol, range];
}

class ChartTickReceived extends ChartEvent {
  final Tick tick;

  const ChartTickReceived(this.tick);

  @override
  List<Object> get props => [tick];
}
