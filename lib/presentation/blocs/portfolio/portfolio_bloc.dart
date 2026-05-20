import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/portfolio_item.dart';
import '../../../data/models/tick_model.dart';
import '../../../data/repositories/portfolio_repository.dart';
import '../../../data/repositories/market_repository.dart';

part 'portfolio_event.dart';
part 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final PortfolioRepository _portfolioRepository;
  final MarketRepository _marketRepository;
  late final StreamSubscription<Tick> _tickSubscription;

  PortfolioBloc({
    required PortfolioRepository portfolioRepository,
    required MarketRepository marketRepository,
  })  : _portfolioRepository = portfolioRepository,
        _marketRepository = marketRepository,
        super(const PortfolioState()) {
    on<LoadPortfolio>(_onLoadPortfolio);
    on<AddPortfolioItem>(_onAddPortfolioItem);
    on<RemovePortfolioItem>(_onRemovePortfolioItem);
    on<PortfolioTickReceived>(_onTickReceived);

    _tickSubscription = _marketRepository.tickStream.listen((tick) {
      add(PortfolioTickReceived(tick));
    });
  }

  void _onLoadPortfolio(LoadPortfolio event, Emitter<PortfolioState> emit) {
    final items = _portfolioRepository.getItems();
    for (var item in items) {
      _marketRepository.subscribe(item.symbol);
    }
    emit(state.copyWith(items: items));
  }

  Future<void> _onAddPortfolioItem(AddPortfolioItem event, Emitter<PortfolioState> emit) async {
    await _portfolioRepository.addOrUpdateItem(event.item);
    _marketRepository.subscribe(event.item.symbol);
    final items = _portfolioRepository.getItems();
    emit(state.copyWith(items: items));
  }

  Future<void> _onRemovePortfolioItem(RemovePortfolioItem event, Emitter<PortfolioState> emit) async {
    await _portfolioRepository.removeItem(event.symbol);
    _marketRepository.unsubscribe(event.symbol);
    final items = _portfolioRepository.getItems();
    final updatedTicks = Map<String, Tick>.from(state.ticks)..remove(event.symbol);
    emit(state.copyWith(items: items, ticks: updatedTicks));
  }

  void _onTickReceived(PortfolioTickReceived event, Emitter<PortfolioState> emit) {
    // Only process ticks for symbols in the portfolio
    if (state.items.any((item) => item.symbol == event.tick.symbol)) {
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
