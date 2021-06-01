import 'package:app/pages/public/adPage.dart';
import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';

class KarCrowdLoanWaitPage extends StatelessWidget {
  static final String route = '/public/kar/auction/wait';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final cardColor = Theme.of(context).cardColor;
    final karColor = Colors.red;
    return CrowdLoanPageLayout('', [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8, top: 16),
            child: Text(dic['auction.support'],
                style: TextStyle(fontSize: 24, color: cardColor)),
          ),
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/public/kusama_logo.svg',
                width: MediaQuery.of(context).size.width * 2 / 3,
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 4, bottom: 32),
            child: Text(dic['auction.kar'],
                style: TextStyle(
                    fontSize: 28,
                    color: karColor,
                    fontWeight: FontWeight.bold)),
          ),
          KarCrowdLoanTitleSet(dic['auction.coming'])
        ],
      )
    ]);
  }
}
