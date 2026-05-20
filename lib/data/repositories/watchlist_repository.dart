import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/symbol_model.dart';

class WatchlistRepository {
  static const String boxName = 'watchlistBox';
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  List<SymbolModel> getSymbols() {
    return _box.values.map((raw) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return SymbolModel(
          symbol: map['symbol'] as String,
          name: map['name'] as String,
        );
      } catch (_) {
        return null;
      }
    }).whereType<SymbolModel>().toList();
  }

  Future<void> addSymbol(SymbolModel symbol) async {
    // Use symbol as key to avoid duplicates
    await _box.put(symbol.symbol, jsonEncode({'symbol': symbol.symbol, 'name': symbol.name}));
  }

  Future<void> removeSymbol(String symbol) async {
    await _box.delete(symbol);
  }
}
