import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/symbol_model.dart';
import '../../data/models/portfolio_item.dart';
import '../../data/models/historical_data_model.dart';
import '../../data/repositories/market_repository.dart';
import '../blocs/symbol_search/symbol_search_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import '../blocs/portfolio/portfolio_bloc.dart';

class SearchScreen extends StatefulWidget {
  final bool isPortfolioAdd;
  const SearchScreen({Key? key, this.isPortfolioAdd = false}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search symbols...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            context.read<SymbolSearchBloc>().add(SearchSymbols(value));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<SymbolSearchBloc>().add(const SearchSymbols(''));
            },
          )
        ],
      ),
      body: BlocBuilder<SymbolSearchBloc, SymbolSearchState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = state.searchResults;

          if (results.isEmpty && state.query.isNotEmpty) {
            // Allow manual addition of a symbol if not found
            return ListTile(
              title: Text('Add "${state.query.toUpperCase()}" manually'),
              leading: const Icon(Icons.add_circle_outline),
              onTap: () {
                final newSymbol = SymbolModel(symbol: state.query.toUpperCase(), name: 'Manual Entry');
                _handleAdd(context, newSymbol);
              },
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final symbol = results[index];
              return ListTile(
                title: Text(symbol.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(symbol.name),
                trailing: const Icon(Icons.add),
                onTap: () => _handleAdd(context, symbol),
              );
            },
          );
        },
      ),
    );
  }

  void _handleAdd(BuildContext context, SymbolModel symbol) {
    if (widget.isPortfolioAdd) {
      _showAddPortfolioDialog(context, symbol);
    } else {
      context.read<WatchlistBloc>().add(AddSymbolToWatchlist(symbol));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\${symbol.symbol} added to Watchlist')));
    }
  }

  void _showAddPortfolioDialog(BuildContext context, SymbolModel symbol) {
    final qtyController = TextEditingController();
    final priceFuture = context.read<MarketRepository>().fetchRealtimeCurrent(symbol.symbol);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<HistoricalData>>(
          future: priceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Fetching current price...'),
                  ],
                ),
              );
            }

            double currentPrice = 0.0;
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              currentPrice = snapshot.data!.last.close;
            } else if (snapshot.hasError || (snapshot.hasData && snapshot.data!.isEmpty)) {
              // Fallback for demo or if API fails
              currentPrice = symbol.symbol == 'RELIANCE' ? 2450.0 : 1500.0;
            }

            return StatefulBuilder(
              builder: (context, setState) {
                final qty = int.tryParse(qtyController.text) ?? 0;
                final total = qty * currentPrice;

                return AlertDialog(
                  title: Text('Add ${symbol.symbol} to Portfolio'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Price: ₹${currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          hintText: 'Enter quantity',
                        ),
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      if (qty > 0) ...[
                        const Text('Total Investment:', style: TextStyle(color: Colors.grey)),
                        Text('₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: qty > 0 && currentPrice > 0
                          ? () {
                              final item = PortfolioItem(
                                symbol: symbol.symbol,
                                quantity: qty,
                                averageBuyPrice: currentPrice,
                              );
                              dialogContext.read<PortfolioBloc>().add(AddPortfolioItem(item));
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close search screen
                            }
                          : null,
                      child: const Text('Add to Portfolio'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
