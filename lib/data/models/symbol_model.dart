import 'package:equatable/equatable.dart';

class SymbolModel extends Equatable {
  final String symbol;
  final String name;

  const SymbolModel({required this.symbol, required this.name});

  factory SymbolModel.fromJson(Map<String, dynamic> json) {
    return SymbolModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String? ?? json['symbol'] as String,
    );
  }

  @override
  List<Object?> get props => [symbol, name];
}
