import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logger/components/sized_text.dart';

class IncomingVsOutgoingTile extends StatelessWidget {
  final double spacing;
  final int incomingCallsCount, outgoingCallsCount;
  const IncomingVsOutgoingTile({
    super.key,
    required this.incomingCallsCount,
    required this.outgoingCallsCount,
    this.spacing = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedText(
          "Incoming vs Outgoing Calls",
          size: 20.0,
        ),
        SizedBox(
          height: spacing - 5,
        ),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(250, 42, 40, 40),
            borderRadius: BorderRadius.circular(10.0),
          ),
          width: double.infinity,
          height: 200.0,
          child: PieChart(PieChartData(sections: [
            PieChartSectionData(
              value: incomingCallsCount.toDouble(),
              color: Colors.blue,
            ),
            PieChartSectionData(
              value: outgoingCallsCount.toDouble(),
              color: Colors.red,
            ),
          ])),
        ),
        SizedBox(
          height: spacing,
        ),
      ],
    );
  }
}