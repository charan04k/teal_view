part of 'watchlist_bloc.dart';

class WatchlistState extends Equatable {
  final List<SymbolModel> symbols;
  final Map<String, Tick> ticks;

  const WatchlistState({
    this.symbols = const [],
    this.ticks = const {},
  });

  WatchlistState copyWith({
    List<SymbolModel>? symbols,
    Map<String, Tick>? ticks,
  }) {
    return WatchlistState(
      symbols: symbols ?? this.symbols,
      ticks: ticks ?? this.ticks,
    );
  }

  @override
  List<Object> get props => [symbols, ticks];
}
