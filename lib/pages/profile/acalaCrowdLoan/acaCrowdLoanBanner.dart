import 'package:app/common/consts.dart';
import 'package:app/pages/profile/acalaCrowdLoan/acaCrowdLoanPage.dart';
import 'package:app/pages/profile/crowdLoan/crowdLoanPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ACACrowdLoanBanner extends StatelessWidget {
  ACACrowdLoanBanner(this.service, this.switchNetwork);
  final AppService service;
  final Future<void> Function(String) switchNetwork;

  Future<void> _goToCrowdLoan(BuildContext context, bool active) async {
    if (service.plugin.basic.name != relay_chain_name_ksm) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Switching to Polkadot...'),
            content: Container(height: 64, child: CupertinoActivityIndicator()),
          );
        },
      );
      await switchNetwork(relay_chain_name_ksm);
      Navigator.of(context).pop();
    }

    Navigator.of(context)
        .pushNamed(!active ? AcaCrowdLoanPage.route : CrowdLoanPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final active =
          service.store.settings.adBannerState['startedAca'] ?? false;
      return Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          GestureDetector(
            child: Container(
              margin: EdgeInsets.all(8),
              child: Image.asset('assets/images/public/banner_aca_plo.png'),
            ),
            onTap: () => _goToCrowdLoan(context, active),
          ),
        ],
      );
    });
  }
}
