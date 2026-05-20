import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/symbol_model.dart';
import '../../../data/repositories/market_repository.dart';

part 'symbol_search_event.dart';
part 'symbol_search_state.dart';

class SymbolSearchBloc extends Bloc<SymbolSearchEvent, SymbolSearchState> {
  final MarketRepository _marketRepository;

  SymbolSearchBloc({required MarketRepository marketRepository})
      : _marketRepository = marketRepository,
        super(const SymbolSearchState()) {
    on<LoadSymbols>(_onLoadSymbols);
    on<SearchSymbols>(_onSearchSymbols);
  }

  Future<void> _onLoadSymbols(LoadSymbols event, Emitter<SymbolSearchState> emit) async {
    emit(state.copyWith(isLoading: true));
    final symbols = await _marketRepository.fetchSymbols();
    emit(state.copyWith(isLoading: false, allSymbols: symbols, searchResults: symbols));
  }

  void _onSearchSymbols(SearchSymbols event, Emitter<SymbolSearchState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: state.allSymbols, query: event.query));
      return;
    }

    final lowerQuery = event.query.toLowerCase();
    final results = state.allSymbols.where((symbol) {
      return symbol.symbol.toLowerCase().contains(lowerQuery) ||
          symbol.name.toLowerCase().contains(lowerQuery);
    }).toList();

    emit(state.copyWith(searchResults: results, query: event.query));
  }
}
