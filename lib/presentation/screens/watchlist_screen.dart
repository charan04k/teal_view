import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import 'chart_detail_screen.dart';
import 'search_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, state) {
          if (state.symbols.isEmpty) {
            return const Center(child: Text('Watchlist is empty. Tap + to add symbols.'));
          }

          return ListView.builder(
            itemCount: state.symbols.length,
            itemBuilder: (context, index) {
              final symbol = state.symbols[index];
              final tick = state.ticks[symbol.symbol];

              final ltp = tick?.ltp ?? 0.0;
              final change = tick?.change ?? 0.0;
              final changePct = tick?.changePct ?? 0.0;
              final isPositive = change >= 0;
              final color = isPositive ? Colors.greenAccent : Colors.redAccent;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(symbol.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(symbol.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: tick == null
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ltp.toStringAsFixed(2),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${changePct.toStringAsFixed(2)}%)',
                              style: TextStyle(color: color, fontSize: 12),
                            ),
                          ],
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChartDetailScreen(symbol: symbol.symbol),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
