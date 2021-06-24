import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/parachain/fundData.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class CrowdLoanList extends StatelessWidget {
  CrowdLoanList(this.funds, this.config, this.contributions, this.decimals,
      this.tokenSymbol, this.onContribute);
  final List<FundData> funds;
  final Map config;
  final Map contributions;
  final int decimals;
  final String tokenSymbol;
  final Future<void> Function(FundData) onContribute;

  @override
  Widget build(BuildContext context) {
    final grayColor = Theme.of(context).unselectedWidgetColor;
    final titleStyle =
        TextStyle(color: grayColor, fontSize: 20, fontWeight: FontWeight.bold);
    final textStyleSmall = TextStyle(fontSize: 12);
    return ListView.builder(
        itemCount: funds.length,
        itemBuilder: (_, int i) {
          final fund = funds[i];
          final logoUri = config[fund.paraId]['logo'] as String;
          return RoundedCard(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: logoUri.contains('.svg')
                            ? SvgPicture.network(logoUri, height: 32, width: 32)
                            : Image.network(logoUri, height: 32, width: 32),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text(
                              config[fund.paraId]['name'],
                              style: titleStyle,
                            ),
                          ),
                          JumpToLink(
                            config[fund.paraId]['website'],
                            text: '',
                            color: Colors.blueAccent,
                          )
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('${fund.firstSlot} - ${fund.lastSlot}'),
                        Text('Leases', style: textStyleSmall)
                      ],
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                              contributions[fund.paraId] == null
                                  ? '--.--'
                                  : Fmt.balance(
                                      contributions[fund.paraId], decimals,
                                      length: 2),
                              style: titleStyle),
                          Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('My Contribution($tokenSymbol)',
                                  style: textStyleSmall))
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  Fmt.balance(fund.value.toString(), decimals,
                                      length: 0),
                                  style: titleStyle),
                              Text(
                                  '/${Fmt.balance(fund.cap.toString(), decimals, length: 0)}',
                                  style: textStyleSmall)
                            ],
                          ),
                          Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Raised/Cap ($tokenSymbol)',
                                  style: textStyleSmall))
                        ],
                      )
                    ],
                  ),
                ),
                RoundedButton(
                  text: fund.isWinner
                      ? 'Winner'
                      : fund.isCapped
                          ? 'Capped'
                          : fund.isEnded
                              ? 'Ended'
                              : 'Contribute',
                  onPressed: fund.isWinner || fund.isCapped || fund.isEnded
                      ? null
                      : () => onContribute(fund),
                ),
              ],
            ),
          );
        });
  }
}
