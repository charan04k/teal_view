import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/portfolio/portfolio_bloc.dart';
import 'chart_detail_screen.dart';
import 'search_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen(isPortfolioAdd: true)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Portfolio is empty.', style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first holding.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          // Totals
          double totalInvested = 0;
          double totalCurrent = 0;
          for (final item in state.items) {
            final ltp = state.ticks[item.symbol]?.ltp ?? item.averageBuyPrice;
            totalInvested += item.quantity * item.averageBuyPrice;
            totalCurrent += item.quantity * ltp;
          }
          final totalPnl = totalCurrent - totalInvested;
          final totalPnlPct = totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;
          final totalPnlColor = totalPnl >= 0 ? Colors.greenAccent : Colors.redAccent;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Value', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          '₹${totalCurrent.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total P&L', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          '${totalPnl >= 0 ? '+' : ''}₹${totalPnl.toStringAsFixed(2)} (${totalPnlPct.toStringAsFixed(2)}%)',
                          style: TextStyle(color: totalPnlColor, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final tick = state.ticks[item.symbol];
                    final ltp = tick?.ltp ?? item.averageBuyPrice;
                    final invested = item.quantity * item.averageBuyPrice;
                    final currentVal = item.quantity * ltp;
                    final pnl = currentVal - invested;
                    final pnlPct = invested > 0 ? (pnl / invested) * 100 : 0.0;
                    final isProfit = pnl >= 0;
                    final color = isProfit ? Colors.greenAccent : Colors.redAccent;

                    return Dismissible(
                      key: Key(item.symbol),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        context.read<PortfolioBloc>().add(RemovePortfolioItem(item.symbol));
                      },
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChartDetailScreen(symbol: item.symbol),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.symbol,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Qty: ${item.quantity}  |  Avg: ₹${item.averageBuyPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Invested: ₹${invested.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${currentVal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${isProfit ? '+' : ''}₹${pnl.toStringAsFixed(2)}',
                                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '(${isProfit ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)',
                                      style: TextStyle(color: color, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
