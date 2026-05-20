part of 'portfolio_bloc.dart';

class PortfolioState extends Equatable {
  final List<PortfolioItem> items;
  final Map<String, Tick> ticks;

  const PortfolioState({
    this.items = const [],
    this.ticks = const {},
  });

  double get totalInvested {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.averageBuyPrice));
  }

  double get totalCurrentValue {
    return items.fold(0.0, (sum, item) {
      final currentPrice = ticks[item.symbol]?.ltp ?? item.averageBuyPrice;
      return sum + (item.quantity * currentPrice);
    });
  }

  double get totalUnrealizedPnL => totalCurrentValue - totalInvested;
  
  double get totalUnrealizedPnLPct {
    if (totalInvested == 0) return 0.0;
    return (totalUnrealizedPnL / totalInvested) * 100;
  }

  PortfolioState copyWith({
    List<PortfolioItem>? items,
    Map<String, Tick>? ticks,
  }) {
    return PortfolioState(
      items: items ?? this.items,
      ticks: ticks ?? this.ticks,
    );
  }

  @override
  List<Object> get props => [items, ticks];
}
