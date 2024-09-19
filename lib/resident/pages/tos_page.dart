import 'package:flutter/material.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/widgets/terms_widget.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TosPage extends StatelessWidget {
  const TosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Terms of Use"),
      ),
      body: SfPdfViewer.asset("assets/example_tos.pdf"),
    );
  }
}
