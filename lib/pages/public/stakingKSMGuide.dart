import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/index.dart';

class StakingKSMGuide extends StatelessWidget {
  StakingKSMGuide(this.service);
  final AppService service;

  static const route = '/guide/staking/ksm';

  void _onRoute(BuildContext context, String path, Map args) {
    Navigator.of(context).pushNamed(path, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final greyStyle = Theme.of(context).textTheme.headline5;
    return Scaffold(
      appBar: AppBar(
        title: Text('KSM Staking'),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Color.fromARGB(16, 0, 0, 0),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Row(
                children: [Text(dic['event.0415.2'], style: greyStyle)],
              ),
            ),
            RoundedCard(
              margin: EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoItem(
                    index: '1.',
                    title: dic['event.0415.3'],
                    subtitle: '',
                    button: dic['event.0415.8'],
                    onClick: () => _onRoute(context, '/bridge', {
                      'token': 'KSM',
                      'chainFrom': 'kusama',
                      'chainTo': 'karura',
                    }),
                  ),
                  Divider(height: 8),
                  _InfoItem(
                    index: '2.',
                    title: dic['event.0415.4'],
                    subtitle: '',
                    button: dic['event.0415.9'],
                    onClick: () => _onRoute(context, '/karura/homa', {}),
                  ),
                  Divider(height: 8),
                  _InfoItem(
                    index: '3.',
                    title: dic['event.0415.6'],
                    subtitle: dic['event.0415.7'],
                    button: dic['event.0415.10'],
                    onClick: () => _onRoute(context, '/karura/earn', {
                      'tab': '1',
                    }),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  _InfoItem({this.index, this.title, this.subtitle, this.button, this.onClick});
  final String index;
  final String title;
  final String subtitle;
  final String button;
  final Function onClick;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                index,
                style: Theme.of(context)
                    .textTheme
                    .headline3
                    .copyWith(color: Theme.of(context).toggleableActiveColor),
              ),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Text(subtitle, style: Theme.of(context).textTheme.headline6),
          Container(
            margin: EdgeInsets.only(left: 120, top: 8),
            child: Button(
              title: button,
              onPressed: onClick,
              height: 40,
              style: Theme.of(context)
                  .textTheme
                  .button
                  .copyWith(fontSize: UI.getTextSize(14, context)),
            ),
          )
        ],
      ),
    );
  }
}
