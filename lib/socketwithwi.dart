import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveChartScreen extends StatefulWidget {
  @override
  _LiveChartScreenState createState() =>
      _LiveChartScreenState();
}

class _LiveChartScreenState extends State<LiveChartScreen> {
  List<FlSpot> spots = [];
  double xValue = 0;

  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(
      Uri.parse(
        'wss://ws.finnhub.io?token=YOUR_API_KEY',
      ),
    );

    channel.sink.add(jsonEncode({
      "type": "subscribe",
      "symbol": "AAPL"
    }));

    channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['data'] != null) {
        final price = data['data'][0]['p'];

        setState(() {
          spots.add(
            FlSpot(xValue, price.toDouble()),
          );

          xValue++;

          if (spots.length > 30) {
            spots.removeAt(0);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Stock Chart"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}