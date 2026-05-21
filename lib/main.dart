import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/portfolio_item.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/portfolio_repository.dart';
import 'data/repositories/watchlist_repository.dart';
import 'presentation/blocs/chart/chart_bloc.dart';
import 'presentation/blocs/portfolio/portfolio_bloc.dart';
import 'presentation/blocs/symbol_search/symbol_search_bloc.dart';
import 'presentation/blocs/watchlist/watchlist_bloc.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PortfolioItemAdapter());

  final marketRepository = MarketRepository();
  final portfolioRepository = PortfolioRepository();
  final watchlistRepository = WatchlistRepository();

  await portfolioRepository.init();
  await watchlistRepository.init();
  marketRepository.initializeSocket();

  runApp(MyApp(
    marketRepository: marketRepository,
    portfolioRepository: portfolioRepository,
    watchlistRepository: watchlistRepository,
  ));
}

class MyApp extends StatelessWidget {
  final MarketRepository marketRepository;
  final PortfolioRepository portfolioRepository;
  final WatchlistRepository watchlistRepository;

  const MyApp({
    super.key,
    required this.marketRepository,
    required this.portfolioRepository,
    required this.watchlistRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: marketRepository),
        RepositoryProvider.value(value: portfolioRepository),
        RepositoryProvider.value(value: watchlistRepository),
      ],
      child: MultiBlocProvider(
        providers: [
        BlocProvider<WatchlistBloc>(
          create: (context) => WatchlistBloc(
            marketRepository: marketRepository,
            watchlistRepository: watchlistRepository,
          )..add(const LoadWatchlist()),
        ),
        BlocProvider<PortfolioBloc>(
          create: (context) => PortfolioBloc(
            marketRepository: marketRepository,
            portfolioRepository: portfolioRepository,
          )..add(LoadPortfolio()),
        ),
        BlocProvider<ChartBloc>(
          create: (context) => ChartBloc(marketRepository: marketRepository),
        ),
        BlocProvider<SymbolSearchBloc>(
          create: (context) => SymbolSearchBloc(marketRepository: marketRepository)..add(LoadSymbols()),
        ),
      ],
      child: MaterialApp(
        title: 'TealVue',
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    ),
    );
  }
}