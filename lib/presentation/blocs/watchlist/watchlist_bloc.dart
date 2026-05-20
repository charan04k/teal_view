import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/symbol_model.dart';
import '../../../data/models/tick_model.dart';
import '../../../data/repositories/market_repository.dart';
import '../../../data/repositories/watchlist_repository.dart';

part 'watchlist_event.dart';
part 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final MarketRepository _marketRepository;
  final WatchlistRepository _watchlistRepository;
  late final StreamSubscription<Tick> _tickSubscription;

  WatchlistBloc({
    required MarketRepository marketRepository,
    required WatchlistRepository watchlistRepository,
  })  : _marketRepository = marketRepository,
        _watchlistRepository = watchlistRepository,
        super(const WatchlistState()) {
    on<LoadWatchlist>(_onLoadWatchlist);
    on<AddSymbolToWatchlist>(_onAddSymbol);
    on<RemoveSymbolFromWatchlist>(_onRemoveSymbol);
    on<TickReceived>(_onTickReceived);

    _tickSubscription = _marketRepository.tickStream.listen((tick) {
      add(TickReceived(tick));
    });
  }

  Future<void> _onLoadWatchlist(LoadWatchlist event, Emitter<WatchlistState> emit) async {
    final symbols = _watchlistRepository.getSymbols();
    emit(state.copyWith(symbols: symbols));

    for (final s in symbols) {
      _marketRepository.subscribe(s.symbol);
      
      // Seed with last known price from API
      try {
        final data = await _marketRepository.fetchRealtimeCurrent(s.symbol);
        if (data.isNotEmpty) {
          final last = data.last;
          final tick = Tick(
            symbol: s.symbol,
            ltp: last.close,
            change: last.close - last.open, // Approximation for initial view
            changePct: last.open > 0 ? ((last.close - last.open) / last.open) * 100 : 0.0,
            vwap: last.close, // Fallback
            timestamp: last.timestamp,
          );
          add(TickReceived(tick));
        }
      } catch (_) {}
    }
  }

  Future<void> _onAddSymbol(AddSymbolToWatchlist event, Emitter<WatchlistState> emit) async {
    if (!state.symbols.any((s) => s.symbol == event.symbol.symbol)) {
      await _watchlistRepository.addSymbol(event.symbol);
      final updatedSymbols = List<SymbolModel>.from(state.symbols)..add(event.symbol);
      _marketRepository.subscribe(event.symbol.symbol);
      emit(state.copyWith(symbols: updatedSymbols));
    }
  }

  Future<void> _onRemoveSymbol(RemoveSymbolFromWatchlist event, Emitter<WatchlistState> emit) async {
    await _watchlistRepository.removeSymbol(event.symbol.symbol);
    final updatedSymbols = List<SymbolModel>.from(state.symbols)
      ..removeWhere((s) => s.symbol == event.symbol.symbol);
    _marketRepository.unsubscribe(event.symbol.symbol);
    final updatedTicks = Map<String, Tick>.from(state.ticks)..remove(event.symbol.symbol);
    emit(state.copyWith(symbols: updatedSymbols, ticks: updatedTicks));
  }

  void _onTickReceived(TickReceived event, Emitter<WatchlistState> emit) {
    if (state.symbols.any((s) => s.symbol == event.tick.symbol)) {
      final updatedTicks = Map<String, Tick>.from(state.ticks);
      updatedTicks[event.tick.symbol] = event.tick;
      emit(state.copyWith(ticks: updatedTicks));
    }
  }

  @override
  Future<void> close() {
    _tickSubscription.cancel();
    return super.close();
  }
}
