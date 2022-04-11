import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/consts.dart';

class CrosschainTransferPage extends StatefulWidget {
  CrosschainTransferPage(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/crosschainTransfer';

  @override
  State<CrosschainTransferPage> createState() => _CrosschainTransferPageState();
}

class _CrosschainTransferPageState extends State<CrosschainTransferPage> {
  TextEditingController _amountCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    final fromNetwork = data["fromNetwork"];
    final amount = data["amount"];

    final balan = widget.service.plugin.noneNativeTokensAll
        .firstWhere((data) => data.symbol == token.toUpperCase());
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['ecosystem.crosschainTransfer']),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
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
                                      ?.copyWith(
                                          color:
                                              Color(0xFFFFFFFF).withAlpha(102)),
                                )),
                            PluginInputBalance(
                              margin: EdgeInsets.only(top: 24, bottom: 24),
                              titleTag:
                                  "${balan.symbol} ${I18n.of(context)?.getDic(i18n_full_dic_app, 'assets')['amount']}",
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
                          ]),
                    )),
                    Padding(
                        padding: EdgeInsets.only(top: 37, bottom: 38),
                        child: PluginButton(
                          title: dic['auction.submit'],
                          onPressed: () {},
                        )),
                  ],
                ))));
  }
}
