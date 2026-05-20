import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/historical_data_model.dart';
import '../../../data/models/tick_model.dart';
import '../../../data/repositories/market_repository.dart';

part 'chart_event.dart';
part 'chart_state.dart';

class ChartBloc extends Bloc<ChartEvent, ChartState> {
  final MarketRepository _marketRepository;
  late final StreamSubscription<Tick> _tickSubscription;

  ChartBloc({required MarketRepository marketRepository})
      : _marketRepository = marketRepository,
        super(const ChartState()) {
    on<LoadChartData>(_onLoadChartData);
    on<ChartTickReceived>(_onTickReceived);

    _tickSubscription = _marketRepository.tickStream.listen((tick) {
      add(ChartTickReceived(tick));
    });
  }

  Future<void> _onLoadChartData(LoadChartData event, Emitter<ChartState> emit) async {
    emit(state.copyWith(isLoading: true, symbol: event.symbol, range: event.range, data: []));

    List<HistoricalData> data = [];

    if (event.range == '1D') {
      // Use POST /realtime-current for intraday (09:15 to now)
      data = await _marketRepository.fetchRealtimeCurrent(event.symbol);
    } else {
      // API strictly limits historical data to 2026-05-04 → 2026-05-07
      const apiMaxDate = '2026-05-07';
      const apiMinDate = '2026-05-04';

      String startDate;
      if (event.range == '1W') {
        startDate = '2026-05-04'; // Spans all available days
      } else {
        startDate = apiMinDate; // full range for 1M
      }

      data = await _marketRepository.fetchHistoricalData(event.symbol, startDate, apiMaxDate);
    }

    // Fallback: generate mock data if API returns empty
    if (data.isEmpty) {
      final basePrice = event.symbol == 'RELIANCE'
          ? 2450.0
          : event.symbol == 'TCS'
              ? 3410.0
              : 1500.0;
      int intervalMinutes = 1;
      if (event.range == '1W') intervalMinutes = 60;
      if (event.range == '1M') intervalMinutes = 60 * 6;

      data = List.generate(80, (i) {
        final t = DateTime.now().subtract(Duration(minutes: (80 - i) * intervalMinutes));
        final price = basePrice + (i % 20 - 10) * 1.5;
        return HistoricalData(
          timestamp: t.millisecondsSinceEpoch,
          open: price,
          high: price + 4,
          low: price - 3,
          close: price + 2,
          volume: 1000,
        );
      });
    }

    // Deduplicate by timestamp (handles socket pre-population burst overlap)
    final seen = <int>{};
    final unique = data.where((d) => seen.add(d.timestamp)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Subscribe to socket so live ticks continue updating the chart
    _marketRepository.subscribeForChart(event.symbol);

    emit(state.copyWith(isLoading: false, data: unique, symbol: event.symbol, range: event.range));
  }

  void _onTickReceived(ChartTickReceived event, Emitter<ChartState> emit) {
    // Only append ticks for the currently displayed symbol and in 1D mode
    if (state.symbol != event.tick.symbol || state.data.isEmpty) return;
    if (state.range != '1D') return; // Historical views stay static

    final updatedData = List<HistoricalData>.from(state.data);
    final lastTs = updatedData.last.timestamp;
    final tickTs = event.tick.timestamp;
    final ltp = event.tick.ltp;

    // Skip ticks older than or equal to current last point (handles burst deduplication)
    if (tickTs <= lastTs) return;

    // Add each new tick as a new point to the line chart for smooth updates
    updatedData.add(HistoricalData(
        timestamp: tickTs,
        open: ltp,
        high: ltp,
        low: ltp,
        close: ltp,
        volume: 0,
    ));

    emit(state.copyWith(data: updatedData));
  }

  @override
  Future<void> close() {
    _tickSubscription.cancel();
    return super.close();
  }
}
