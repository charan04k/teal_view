part of 'watchlist_bloc.dart';

abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object> get props => [];
}

class LoadWatchlist extends WatchlistEvent {
  const LoadWatchlist();
}

class AddSymbolToWatchlist extends WatchlistEvent {
  final SymbolModel symbol;

  const AddSymbolToWatchlist(this.symbol);

  @override
  List<Object> get props => [symbol];
}

class RemoveSymbolFromWatchlist extends WatchlistEvent {
  final SymbolModel symbol;

  const RemoveSymbolFromWatchlist(this.symbol);

  @override
  List<Object> get props => [symbol];
}

class TickReceived extends WatchlistEvent {
  final Tick tick;

  const TickReceived(this.tick);

  @override
  List<Object> get props => [tick];
}
