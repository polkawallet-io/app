import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/parachain/auctionData.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AuctionPanel extends StatelessWidget {
  AuctionPanel(this.auction, this.config, this.decimals, this.tokenSymbol,
      this.expectedBlockTime);
  final AuctionData auction;
  final Map config;
  final int decimals;
  final String tokenSymbol;
  final int expectedBlockTime;

  @override
  Widget build(BuildContext context) {
    final grayColor = Theme.of(context).unselectedWidgetColor;
    final titleStyle =
        TextStyle(color: grayColor, fontSize: 20, fontWeight: FontWeight.bold);
    final textStyleSmall = TextStyle(fontSize: 12);

    final end = Fmt.blockToTime(
        int.parse(auction.auction?.endBlock ?? '0') -
            int.parse(auction.bestNumber ?? '0'),
        expectedBlockTime);
    return RoundedCard(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  child: Text('#${auction.auction.numAuctions}'),
                ),
              ),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auction #${auction.auction.numAuctions}',
                    style: titleStyle,
                  ),
                  Text(
                    'Ending: $end',
                    style: textStyleSmall,
                  ),
                ],
              )),
              Column(
                children: [
                  Text(
                      '${auction.auction.leasePeriod} - ${auction.auction.leaseEnd}'),
                  Text('Leases', style: textStyleSmall)
                ],
              )
            ],
          ),
          Divider(height: 32),
          Text('Bids', style: Theme.of(context).textTheme.headline4),
          ...auction.winners.map((e) {
            final raised = Fmt.balance(e.value.toString(), decimals, length: 2);
            final logoUri = config[e.paraId]['logo'] as String;

            return Container(
              margin: EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
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
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config[e.paraId]['name']),
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
