part of 'symbol_search_bloc.dart';

class SymbolSearchState extends Equatable {
  final bool isLoading;
  final List<SymbolModel> allSymbols;
  final List<SymbolModel> searchResults;
  final String query;

  const SymbolSearchState({
    this.isLoading = false,
    this.allSymbols = const [],
    this.searchResults = const [],
    this.query = '',
  });

  SymbolSearchState copyWith({
    bool? isLoading,
    List<SymbolModel>? allSymbols,
    List<SymbolModel>? searchResults,
    String? query,
  }) {
    return SymbolSearchState(
      isLoading: isLoading ?? this.isLoading,
      allSymbols: allSymbols ?? this.allSymbols,
      searchResults: searchResults ?? this.searchResults,
      query: query ?? this.query,
    );
  }

  @override
  List<Object> get props => [isLoading, allSymbols, searchResults, query];
}
