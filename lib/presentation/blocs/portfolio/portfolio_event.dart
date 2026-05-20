part of 'portfolio_bloc.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object> get props => [];
}

class LoadPortfolio extends PortfolioEvent {}

class AddPortfolioItem extends PortfolioEvent {
  final PortfolioItem item;

  const AddPortfolioItem(this.item);

  @override
  List<Object> get props => [item];
}

class RemovePortfolioItem extends PortfolioEvent {
  final String symbol;

  const RemovePortfolioItem(this.symbol);

  @override
  List<Object> get props => [symbol];
}

class PortfolioTickReceived extends PortfolioEvent {
  final Tick tick;

  const PortfolioTickReceived(this.tick);

  @override
  List<Object> get props => [tick];
}
