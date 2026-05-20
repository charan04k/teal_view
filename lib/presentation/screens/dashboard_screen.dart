import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/portfolio/portfolio_bloc.dart';
import 'chart_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No holdings yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Go to Portfolio tab to add holdings.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          final isProfit = state.totalUnrealizedPnL >= 0;
          final pnlColor = isProfit ? Colors.greenAccent : Colors.redAccent;
          final pnlPct = state.totalInvested > 0
              ? (state.totalUnrealizedPnL / state.totalInvested) * 100
              : 0.0;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Portfolio Value',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${state.totalCurrentValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invested', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(
                              '₹${state.totalInvested.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Unrealised P&L', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Row(
                              children: [
                                Icon(
                                  isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: pnlColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '₹${state.totalUnrealizedPnL.abs().toStringAsFixed(2)} (${pnlPct.toStringAsFixed(2)}%)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: pnlColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Per-Stock Breakdown (LTP vs VWAP)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final tick = state.ticks[item.symbol];
                    final ltp = tick?.ltp ?? item.averageBuyPrice;
                    final vwap = tick?.vwap ?? item.averageBuyPrice;
                    final currentVal = item.quantity * ltp;
                    final invested = item.quantity * item.averageBuyPrice;
                    final pnl = currentVal - invested;
                    final isAboveVwap = ltp >= vwap;
                    final vwapColor = isAboveVwap ? Colors.greenAccent : Colors.redAccent;
                    final pnlItemColor = pnl >= 0 ? Colors.greenAccent : Colors.redAccent;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChartDetailScreen(symbol: item.symbol),
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.symbol,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: ${item.quantity}  |  Avg: ₹${item.averageBuyPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'P&L: ₹${pnl.toStringAsFixed(2)}',
                                      style: TextStyle(color: pnlItemColor, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'LTP: ₹${ltp.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'VWAP: ₹${vwap.toStringAsFixed(2)}',
                                    style: TextStyle(color: vwapColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
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
