import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/parachain/fundData.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class CrowdLoanList extends StatelessWidget {
  CrowdLoanList(
      {this.title,
      this.funds,
      this.expanded,
      this.config,
      this.contributions,
      this.decimals,
      this.tokenSymbol,
      this.onContribute,
      this.onToggle});
  final String title;
  final List<FundData> funds;
  final bool expanded;
  final Map config;
  final Map contributions;
  final int decimals;
  final String tokenSymbol;
  final Future<void> Function(FundData) onContribute;
  final Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final grayColor = Theme.of(context).unselectedWidgetColor;
    final titleStyle =
        TextStyle(color: grayColor, fontSize: 20, fontWeight: FontWeight.bold);
    final textStyleSmall = TextStyle(fontSize: 12);

    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Container(
                margin: EdgeInsets.only(left: 16),
                child: Text(title, style: titleStyle),
              )),
              IconButton(
                  onPressed: () => onToggle(!expanded),
                  iconSize: 32,
                  icon: Icon(expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down))
            ],
          ),
          Visibility(
              visible: expanded,
              child: Column(
                children: funds.map((e) {
                  final logoUri = config[e.paraId]['logo'] as String;
                  return Column(
                    children: [
                      Divider(height: 32),
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: logoUri.contains('.svg')
                                  ? SvgPicture.network(logoUri,
                                      height: 32, width: 32)
                                  : Image.network(logoUri,
                                      height: 32, width: 32),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Text(
                                    config[e.paraId]['name'],
                                    style: titleStyle,
                                  ),
                                ),
                                JumpToLink(
                                  config[e.paraId]['homepage'],
                                  text: '',
                                  color: Colors.blueAccent,
                                )
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text('${e.firstSlot} - ${e.lastSlot}'),
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
                                    contributions[e.paraId] == null
                                        ? '--.--'
                                        : Fmt.balance(
                                            contributions[e.paraId], decimals,
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
                                        Fmt.balance(
                                            e.value.toString(), decimals,
                                            length: 0),
                                        style: titleStyle),
                                    Text(
                                        '/${Fmt.balance(e.cap.toString(), decimals, length: 0)}',
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
                      Visibility(
                          visible: (!e.isWinner && !e.isEnded),
                          child: RoundedButton(
                            text: e.isCapped ? 'Capped' : 'Contribute',
                            onPressed:
                                e.isCapped ? null : () => onContribute(e),
                          )),
                    ],
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }
}
