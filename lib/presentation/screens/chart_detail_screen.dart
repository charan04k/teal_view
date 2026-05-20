import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/chart/chart_bloc.dart';
import 'package:intl/intl.dart';

class ChartDetailScreen extends StatefulWidget {
  final String symbol;

  const ChartDetailScreen({Key? key, required this.symbol}) : super(key: key);

  @override
  State<ChartDetailScreen> createState() => _ChartDetailScreenState();
}

class _ChartDetailScreenState extends State<ChartDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChartBloc>().add(LoadChartData(widget.symbol));
    // Allow all orientations for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore portrait lock when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        Widget chartWidget = BlocBuilder<ChartBloc, ChartState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.data.isEmpty) {
              return const Center(child: Text('No chart data available.'));
            }

            final minX = state.data.first.timestamp.toDouble();
            final maxX = state.data.last.timestamp.toDouble();
            final minY = state.data.map((e) => e.low).reduce((a, b) => a < b ? a : b) - 5;
            final maxY = state.data.map((e) => e.high).reduce((a, b) => a > b ? a : b) + 5;

            print("object $minX $minY");

            final spots = state.data.map((e) {
              return FlSpot(e.timestamp.toDouble(), e.close);
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

                          if (state.range == '1D') {
                            // Parse as UTC first, then adjust by 5:30 to match IST
                            final dateUtc = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
                            final dateIst = dateUtc.add(const Duration(hours: 5, minutes: 30));

                            if (value == meta.max || value == meta.min) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${DateFormat('HH:mm').format(dateIst)} IST',
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            );
                          } else {
                            String formatStr = 'HH:mm';
                            if (state.range == '1W') formatStr = 'EEE';
                            if (state.range == '1M') formatStr = 'dd MMM';

                            if (value == meta.max || value == meta.min) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat(formatStr).format(date),
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF38BDF8),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF38BDF8).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (isLandscape) {
          return Scaffold(
            body: SafeArea(child: chartWidget),
          );
        }

        Widget _buildRangeButton(BuildContext context, String range, String currentRange) {
          final isSelected = range == currentRange;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
              foregroundColor: isSelected ? Colors.white : Colors.grey,
            ),
            onPressed: () => context.read<ChartBloc>().add(LoadChartData(widget.symbol, range: range)),
            child: Text(range),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.symbol),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                flex: 3,
                child: chartWidget,
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BlocBuilder<ChartBloc, ChartState>(
                    builder: (context, state) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRangeButton(context, '1D', state.range),
                          _buildRangeButton(context, '1W', state.range),
                          _buildRangeButton(context, '1M', state.range),
                        ],
                      );
                    }
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
