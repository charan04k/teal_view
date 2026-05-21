import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../blocs/chart/chart_bloc.dart';

class ChartDetailScreen extends StatefulWidget {
  final String symbol;

  const ChartDetailScreen({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  State<ChartDetailScreen> createState() =>
      _ChartDetailScreenState();
}

class _ChartDetailScreenState
    extends State<ChartDetailScreen> {
  bool showHistoryOptions = false;

  @override
  void initState() {
    super.initState();

    _loadRangeData('INTRADAY');

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }


  void _loadRangeData(String range) {
    print('RANGE => $range');

    context.read<ChartBloc>().add(
      LoadChartData(
        widget.symbol,
        range: range,
      ),
    );
  }

  Widget _buildRangeButton(
      BuildContext context,
      String label,
      VoidCallback onTap, {
        bool selected = false,
      }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFF38BDF8)
            : const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : Colors.grey,
          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape =
            orientation == Orientation.landscape;

        Widget chartWidget =
        BlocBuilder<ChartBloc, ChartState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.data.isEmpty) {
              return const Center(
                child: Text(
                  'No chart data available.',
                ),
              );
            }

            final minX =
            state.data.first.timestamp.toDouble();

            final maxX =
            state.data.last.timestamp.toDouble();

            final minY = state.data
                .map((e) => e.low)
                .reduce((a, b) => a < b ? a : b) -
                5;

            final maxY = state.data
                .map((e) => e.high)
                .reduce((a, b) => a > b ? a : b) +
                5;

            final spots = state.data.map((e) {
              return FlSpot(
                e.timestamp.toDouble(),
                e.close,
              );
            }).toList();

            final firstPrice = state.data.first.close;
            final lastPrice = state.data.last.close;

            final bool isPositive =
                lastPrice >= firstPrice;

            final chartColor = isPositive
                ? Colors.green
                : Colors.red;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData:
                    LineTouchTooltipData(
                      getTooltipItems:
                          (touchedSpots) {
                        return touchedSpots
                            .map((spot) {
                          final date = DateTime
                              .fromMillisecondsSinceEpoch(
                            spot.x.toInt(),
                            isUtc: true,
                          ).add(
                            const Duration(
                              hours: 5,
                              minutes: 30,
                            ),
                          );

                          return LineTooltipItem(
                            '₹${spot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm').format(date)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget:
                            (value, meta) {
                          return Text(
                            value
                                .toStringAsFixed(
                                1),
                            style:
                            const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                      color: Colors.grey
                          .withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine:
                        (value) => FlLine(
                      color: Colors.grey
                          .withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey
                          .withOpacity(0.2),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: chartColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData:
                      const FlDotData(
                        show: false,
                      ),
                      belowBarData:
                      BarAreaData(
                        show: true,
                        color: chartColor
                            .withOpacity(
                            0.2),
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
            backgroundColor:
            const Color(0xFF0F172A),
            body: SafeArea(
              child: Stack(
                children: [
                  chartWidget,
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.fullscreen_exit,
                        color:
                        Colors.white70,
                      ),
                      onPressed: () {
                        SystemChrome
                            .setPreferredOrientations([
                          DeviceOrientation
                              .portraitUp,
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor:
          const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor:
            const Color(0xFF0F172A),
            title: Text(widget.symbol),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.fullscreen,
                ),
                onPressed: () {
                  SystemChrome
                      .setPreferredOrientations([
                    DeviceOrientation
                        .landscapeLeft,
                  ]);
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
              Container(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 20,
                ),
                color:
                const Color(0xFF0F172A),
                child: Column(
                  children: [
                    BlocBuilder<ChartBloc,
                        ChartState>(
                      builder:
                          (context, state) {
                        return Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceEvenly,
                          children: [
                            _buildRangeButton(
                              context,
                              'Intraday',
                                  () {
                                setState(() {
                                  showHistoryOptions =
                                  false;
                                });

                                _loadRangeData(
                                    'INTRADAY');
                              },
                              selected:
                              state.range ==
                                  'INTRADAY',
                            ),
                            _buildRangeButton(
                              context,
                              'History',
                                  () {
                                setState(() {
                                  showHistoryOptions =
                                  !showHistoryOptions;
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    if (showHistoryOptions)
                      ...[
                        const SizedBox(
                            height: 16),
                        BlocBuilder<
                            ChartBloc,
                            ChartState>(
                          builder:
                              (context,
                              state) {
                            return Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceEvenly,
                              children: [
                                _buildRangeButton(
                                  context,
                                  'One Day',
                                      () =>
                                      _loadRangeData(
                                          '1D'),
                                  selected:
                                  state.range ==
                                      '1D',
                                ),
                                _buildRangeButton(
                                  context,
                                  'One Week',
                                      () =>
                                      _loadRangeData(
                                          '1W'),
                                  selected:
                                  state.range ==
                                      '1W',
                                ),
                                _buildRangeButton(
                                  context,
                                  'One Month',
                                      () =>
                                      _loadRangeData(
                                          '1M'),
                                  selected:
                                  state.range ==
                                      '1M',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}