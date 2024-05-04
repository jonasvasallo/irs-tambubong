import 'package:flutter/material.dart';
import 'package:irs_capstone/widgets/incident_history_item.dart';

class TanodResponseHistoryPage extends StatefulWidget {
  const TanodResponseHistoryPage({Key? key}) : super(key: key);

  @override
  _TanodResponseHistoryPageState createState() =>
      _TanodResponseHistoryPageState();
}

class _TanodResponseHistoryPageState extends State<TanodResponseHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Response History"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              IncidentHistoryItem(),
            ],
          ),
        ),
      ),
    );
  }
}
