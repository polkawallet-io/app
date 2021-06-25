import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/parachain/auctionData.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AuctionPanel extends StatelessWidget {
  AuctionPanel(this.auction, this.config, this.decimals, this.tokenSymbol,
      this.expectedBlockTime, this.endingPeriodBlocks);
  final AuctionData auction;
  final Map config;
  final int decimals;
  final String tokenSymbol;
  final int expectedBlockTime;
  final int endingPeriodBlocks;

  @override
  Widget build(BuildContext context) {
    final grayColor = Theme.of(context).unselectedWidgetColor;
    final titleStyle =
        TextStyle(color: grayColor, fontSize: 20, fontWeight: FontWeight.bold);
    final textStyleSmall = TextStyle(fontSize: 12);

    final auctionPeriodBlocks = endingPeriodBlocks * 3 ~/ 8;
    final endBlock = int.parse(auction.auction?.endBlock ?? '0');
    final startBlock = endBlock - auctionPeriodBlocks;
    final closeBlock = endBlock + endingPeriodBlocks;
    final currentBlock = int.parse(auction.auction?.bestNumber ?? '0');
    final ending = endBlock - currentBlock;
    final stageTitle = ending > 0 ? 'Auction Stage' : 'Ending Stage';
    final progress = ending > 0
        ? (auctionPeriodBlocks - ending) / auctionPeriodBlocks
        : (0 - ending) / endingPeriodBlocks;
    final endingTime = Fmt.blockToTime(
        ending > 0 ? ending : endingPeriodBlocks + ending, expectedBlockTime);
    return RoundedCard(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      child: auction.auction == null
          ? Container(
              height: MediaQuery.of(context).size.width / 2,
              child: Center(
                child: Text('No Data'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        child: Text('#${auction.auction?.numAuctions}'),
                      ),
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auction #${auction.auction?.numAuctions}',
                          style: titleStyle,
                        ),
                        Text(
                          stageTitle,
                          style: textStyleSmall,
                        ),
                      ],
                    )),
                    Column(
                      children: [
                        Text(
                            '${auction.auction?.leasePeriod} - ${auction.auction?.leaseEnd}'),
                        Text('Leases', style: textStyleSmall)
                      ],
                    )
                  ],
                ),
                Divider(height: 32),
                InfoItemRow('Auction Stage', '$startBlock - $endBlock'),
                InfoItemRow('Ending Stage', '$endBlock - $closeBlock'),
                InfoItemRow('Current Block', '#$currentBlock'),
                Container(
                  margin: EdgeInsets.only(top: 16, bottom: 8),
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                      ),
                      Container(
                        height: 16,
                        width:
                            (MediaQuery.of(context).size.width - 64) * progress,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                      ),
                    ],
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$stageTitle - $endingTime',
                      style: TextStyle(color: Colors.blue, fontSize: 12))
                ]),
                Divider(height: 32),
                Text('Bids', style: Theme.of(context).textTheme.headline4),
                ...(auction.winners ?? []).map((e) {
                  final raised =
                      Fmt.balance(e.value.toString(), decimals, length: 2);
                  final logoUri = (config[e.paraId] ?? {})['logo'] as String;
                  return Container(
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: logoUri != null
                                ? logoUri.contains('.svg')
                                    ? SvgPicture.network(logoUri,
                                        height: 32, width: 32)
                                    : Image.network(logoUri,
                                        height: 32, width: 32)
                                : CircleAvatar(
                                    radius: 16,
                                    child: Text('#'),
                                  ),
                          ),
                        ),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((config[e.paraId] ?? {})['name'] ?? e.paraId),
                            Text(
                              '$raised $tokenSymbol${e.isCrowdloan ? ' (crowdloan)' : ''}',
                              style: textStyleSmall,
                            )
                          ],
                        )),
                        Column(
                          children: [
                            Text('${e.firstSlot} - ${e.lastSlot}'),
                            Text('Leases', style: textStyleSmall)
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
