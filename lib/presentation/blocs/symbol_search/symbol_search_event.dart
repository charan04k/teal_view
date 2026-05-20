part of 'symbol_search_bloc.dart';

abstract class SymbolSearchEvent extends Equatable {
  const SymbolSearchEvent();

  @override
  List<Object> get props => [];
}

class LoadSymbols extends SymbolSearchEvent {}

class SearchSymbols extends SymbolSearchEvent {
  final String query;

  const SearchSymbols(this.query);

  @override
  List<Object> get props => [query];
}
