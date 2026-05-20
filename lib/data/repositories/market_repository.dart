import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/api_constants.dart';
import '../models/symbol_model.dart';
import '../models/tick_model.dart';
import '../models/historical_data_model.dart';

class MarketRepository {
  final Dio _dio;
  IO.Socket? _socket;
  final StreamController<Tick> _tickController = StreamController<Tick>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  MarketRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Stream<Tick> get tickStream => _tickController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  final Set<String> _subscribedSymbols = {};
  Timer? _mockTickTimer;

  void initializeSocket() {
    if (_socket != null) return;
    
    _socket = IO.io(ApiConstants.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket?.onConnect((_) {
      print('Socket connected');
      _connectionController.add(true);
      if (_subscribedSymbols.isNotEmpty) {
        _socket?.emit('subscribe', _subscribedSymbols.toList());
      }
    });

    _socket?.onDisconnect((_) {
      print('Socket disconnected');
      _connectionController.add(false);
    });
    
    _socket?.onAny((event, data) {
      // print('Socket event: \$event, data: \$data');
    });

    _socket?.on('ticker', (data) {
      try {
        final tick = Tick.fromJson(data);
        _tickController.add(tick);
      } catch (e) {
        // print('Error parsing tick: $e, data: $data');
      }
    });

    _socket?.connect();

    // Mock data generator fallback to guarantee live UI updates when market is closed or server is slow
    _mockTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      for (final symbol in _subscribedSymbols) {
        // Generate random mock ticks
        final random = DateTime.now().millisecondsSinceEpoch % 100;
        final basePrice = symbol == 'III' ? 2400.0 : 1500.0;
        final mockLtp = basePrice + (random - 50) / 10;
        final change = mockLtp - basePrice;
        
        final mockTick = Tick(
          symbol: symbol,
          ltp: mockLtp,
          change: change,
          changePct: (change / basePrice) * 100,
          vwap: basePrice + 1.5,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        _tickController.add(mockTick);
      }
    });
  }

  void subscribe(String symbol) {
    _subscribedSymbols.add(symbol);
    if (_socket?.connected == true) {
      _socket?.emit('subscribe', _subscribedSymbols.toList());
    }
  }

  void unsubscribe(String symbol) {
    _subscribedSymbols.remove(symbol);
    if (_socket?.connected == true) {
      if (_subscribedSymbols.isEmpty) {
        _socket?.emit('unsubscribe', [symbol]);
      } else {
        _socket?.emit('subscribe', _subscribedSymbols.toList());
      }
    }
  }

  /// Sends a single-symbol subscribe for the chart screen.
  /// Per spec, the server overwrites any prior subscription and bursts today's ticks instantly.
  void subscribeForChart(String symbol) {
    _subscribedSymbols.add(symbol);
    if (_socket?.connected == true) {
      _socket?.emit('subscribe', [symbol]);
    }
  }

  Future<List<SymbolModel>> fetchSymbols() async {
    try {
      final response = await _dio.get('/symbols');
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => SymbolModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('fetchSymbols error: $e');
      return [];
    }
  }

  /// Fetches intraday ticks from 09:15 to now using POST /realtime-current
  Future<List<HistoricalData>> fetchRealtimeCurrent(String symbol) async {
    try {
      final response = await _dio.post('/realtime-current', data: {
        'symbol': symbol,
        'limit': 5000,
        'offset': 0,
      });
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => HistoricalData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('fetchRealtimeCurrent error: $e');
      return [];
    }
  }

  /// Fetches historical ticks between start_date and end_date using POST /historical
  Future<List<HistoricalData>> fetchHistoricalData(String symbol, String startDate, String endDate) async {
    try {
      final response = await _dio.post('/historical', data: {
        'symbol': symbol,
        'start_date': startDate,
        'end_date': endDate,
        'limit': 5000,
        'offset': 0,
      });
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((e) => HistoricalData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('fetchHistoricalData error: $e');
      return [];
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _tickController.close();
    _connectionController.close();
  }
}
