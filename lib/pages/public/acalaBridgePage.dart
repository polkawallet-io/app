import 'package:app/common/consts.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AcalaBridgePage extends StatelessWidget {
  static const route = '/bridge/aca';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).popAndPushNamed(TransferPage.route,
          arguments: TransferPageParams(chainTo: para_chain_name_acala));
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(width: 1, height: 1),
    );
  }
}
