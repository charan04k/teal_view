import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'portfolio_item.g.dart';

@HiveType(typeId: 0)
class PortfolioItem extends Equatable {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final double averageBuyPrice;

  const PortfolioItem({
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
  });

  PortfolioItem copyWith({
    String? symbol,
    int? quantity,
    double? averageBuyPrice,
  }) {
    return PortfolioItem(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
    );
  }

  @override
  List<Object?> get props => [symbol, quantity, averageBuyPrice];
}
