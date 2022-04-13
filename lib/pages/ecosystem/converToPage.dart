import 'package:app/pages/ecosystem/completedPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';

class ConverToPage extends StatefulWidget {
  ConverToPage(this.service, {Key key}) : super(key: key);
  AppService service;
  static final String route = '/ecosystem/converTo';

  @override
  State<ConverToPage> createState() => _ConverToPageState();
}

class _ConverToPageState extends State<ConverToPage> {
  TextEditingController _amountCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    final fromNetwork = data["fromNetwork"];
    final amount = data["amount"];
    final convertToKen = data["convertToKen"];

    final balan = widget.service.plugin.noneNativeTokensAll
        .firstWhere((data) => data.symbol == token.toUpperCase());
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(
              "${dic['ecosystem.convertTo']} ${convertToKen.toUpperCase()} (1/2)"),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                  child: SingleChildScrollView(
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PluginTextTag(
                    backgroundColor: PluginColorsDark.headline3,
                    title: dic['ecosystem.from'],
                  ),
                  Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      decoration: BoxDecoration(
                          color: Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4))),
                      child: Text(
                        fromNetwork,
                        style: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(color: Color(0xFFFFFFFF).withAlpha(102)),
                      )),
                  PluginInputBalance(
                    margin: EdgeInsets.only(top: 24, bottom: 24),
                    titleTag:
                        "${dic['ecosystem.bringTo']} ${widget.service.plugin.basic.name}",
                    inputCtrl: _amountCtrl,
                    // onSetMax: (balance ?? BigInt.zero) > BigInt.zero
                    //     ? (max) => _onSetMax(max, tokenPair[0]!.decimals)
                    //     : null,
                    onInputChange: (v) {
                      // var error = _validateAmount(
                      //     v, balance, tokenPair[0]!.decimals);
                      // setState(() {
                      //   _error1 = error;
                      //   _isMax = false;
                      // });
                    },
                    balance: TokenBalanceData(
                        symbol: balan.symbol,
                        decimals: balan.decimals,
                        amount: balan.amount),
                    tokenIconsMap: widget.service.plugin.tokenIcons,
                  ),
                  Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: PluginAddressFormItem(
                        label: dic['ecosystem.destinationAccount'],
                        account: widget.service.keyring.current,
                      )),
                  Text(
                    "Receive",
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        ?.copyWith(color: PluginColorsDark.headline1),
                  ),
                  InfoItemRow(
                    "99.7999",
                    balan.symbol,
                    labelStyle: Theme.of(context).textTheme.headline5?.copyWith(
                        color: PluginColorsDark.headline1,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                    contentStyle: Theme.of(context)
                        .textTheme
                        .headline5
                        ?.copyWith(color: PluginColorsDark.headline1),
                  ),
                  InfoItemRow(
                    "Network Fee",
                    "0.2 ${balan.symbol}",
                    labelStyle: Theme.of(context)
                        .textTheme
                        .headline5
                        ?.copyWith(color: PluginColorsDark.headline1),
                    contentStyle: Theme.of(context)
                        .textTheme
                        .headline5
                        ?.copyWith(color: PluginColorsDark.headline1),
                  ),
                ],
              ))),
              Padding(
                  padding: EdgeInsets.only(top: 37, bottom: 38),
                  child: PluginButton(
                    title: dic['auction.submit'],
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(CompletedPage.route, arguments: {
                        "token": token,
                        "fromNetwork": fromNetwork,
                        "amount": amount,
                        "convertToKen": convertToKen
                      });
                    },
                  )),
            ],
          ),
        )));
  }
}
