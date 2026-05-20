import 'package:hive/hive.dart';
import '../models/portfolio_item.dart';

class PortfolioRepository {
  static const String boxName = 'portfolioBox';
  late Box<PortfolioItem> _box;

  Future<void> init() async {
    _box = await Hive.openBox<PortfolioItem>(boxName);
  }

  List<PortfolioItem> getItems() {
    return _box.values.toList();
  }

  Future<void> addOrUpdateItem(PortfolioItem item) async {
    final existingIndex = _box.values.toList().indexWhere((e) => e.symbol == item.symbol);
    if (existingIndex >= 0) {
      final existingItem = _box.getAt(existingIndex)!;
      final newQuantity = existingItem.quantity + item.quantity;
      final newAvgPrice = ((existingItem.averageBuyPrice * existingItem.quantity) +
              (item.averageBuyPrice * item.quantity)) /
          newQuantity;
      await _box.putAt(
        existingIndex,
        existingItem.copyWith(quantity: newQuantity, averageBuyPrice: newAvgPrice),
      );
    } else {
      await _box.add(item);
    }
  }

  Future<void> removeItem(String symbol) async {
    final existingIndex = _box.values.toList().indexWhere((e) => e.symbol == symbol);
    if (existingIndex >= 0) {
      await _box.deleteAt(existingIndex);
    }
  }
}
