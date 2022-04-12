import 'package:app/common/consts.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';

class CrosschainTransferPage extends StatefulWidget {
  CrosschainTransferPage(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/crosschainTransfer';

  @override
  State<CrosschainTransferPage> createState() => _CrosschainTransferPageState();
}

class _CrosschainTransferPageState extends State<CrosschainTransferPage> {
  TextEditingController _amountCtrl = TextEditingController();

  bool _keepAlive = true;
  PolkawalletPlugin _chainTo;
  TxFeeEstimateResult _fee;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final dicAssets = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    final fromNetwork = data["fromNetwork"];
    final amount = data["amount"];

    final balan = widget.service.plugin.noneNativeTokensAll
        .firstWhere((data) => data.symbol == token.toUpperCase());
    return Observer(builder: (_) {
      final notTransferable = Fmt.balanceInt(
              (widget.service.plugin.balances.native?.reservedBalance ?? 0)
                  .toString()) +
          Fmt.balanceInt(
              (widget.service.plugin.balances.native?.lockedBalance ?? 0)
                  .toString());

      final destChainName =
          _chainTo?.basic?.name ?? widget.service.plugin.basic.name;

      final destExistDeposit =
          Fmt.balanceInt(xcm_send_fees[destChainName]['existentialDeposit']);
      final destFee = Fmt.balanceInt(xcm_send_fees[destChainName]['fee']);

      final existDeposit = Fmt.balanceInt(
          ((widget.service.plugin.networkConst['balances'] ??
                      {})['existentialDeposit'] ??
                  0)
              .toString());

      final decimals = balan.decimals;
      final symbol = balan.symbol;
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
                                            color: Color(0xFFFFFFFF)
                                                .withAlpha(102)),
                                  )),
                              PluginTagCard(
                                margin: EdgeInsets.only(top: 24),
                                titleTag: dic['ecosystem.to'],
                                child: Container(
                                  height: 48,
                                  width: double.infinity,
                                ),
                              ),
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
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Container(
                                          padding: EdgeInsets.only(right: 40),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(dicAssets['cross.exist'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color:
                                                              PluginColorsDark
                                                                  .headline1)),
                                              Text(
                                                dicAssets['amount.exist.msg'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'SF_Pro',
                                                ),
                                              ),
                                            ],
                                          )),
                                    ),
                                    Expanded(
                                        flex: 0,
                                        child: Text(
                                            '${Fmt.priceCeilBigInt(destExistDeposit, decimals, lengthMax: 6)} $symbol',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5
                                                .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: PluginColorsDark
                                                        .headline1))),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(dicAssets['cross.fee'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4
                                                ?.copyWith(
                                                    color: PluginColorsDark
                                                        .headline1)),
                                      ),
                                    ),
                                    Text(
                                        '${Fmt.priceCeilBigInt(destFee, decimals, lengthMax: 6)} $symbol',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: PluginColorsDark
                                                    .headline1)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Container(
                                          padding: EdgeInsets.only(right: 60),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(dicAssets['amount.exist'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color:
                                                              PluginColorsDark
                                                                  .headline1)),
                                              Text(
                                                dicAssets['amount.exist.msg'],
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w200),
                                              ),
                                            ],
                                          )),
                                    ),
                                    Text(
                                        '${Fmt.priceCeilBigInt(existDeposit, decimals, lengthMax: 6)} $symbol',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: PluginColorsDark
                                                    .headline1)),
                                  ],
                                ),
                              ),
                              Visibility(
                                  visible: _fee?.partialFee != null,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Text(dicAssets['amount.fee'],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline4
                                                    ?.copyWith(
                                                        color: PluginColorsDark
                                                            .headline1)),
                                          ),
                                        ),
                                        Text(
                                            '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")), decimals, lengthMax: 6)} $symbol',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5
                                                .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: PluginColorsDark
                                                        .headline1)),
                                      ],
                                    ),
                                  )),
                              Container(
                                margin: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Container(
                                          padding: EdgeInsets.only(right: 60),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(dicAssets['transfer.alive'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color:
                                                              PluginColorsDark
                                                                  .headline1)),
                                              Text(
                                                dicAssets['transfer.alive.msg'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'SF_Pro',
                                                ),
                                              ),
                                            ],
                                          )),
                                    ),
                                    v3.CupertinoSwitch(
                                      value: _keepAlive,
                                      // account is not allow_death if it has
                                      // locked/reserved balances
                                      onChanged: (v) => _onSwitchCheckAlive(
                                          v, notTransferable),
                                    )
                                  ],
                                ),
                              )
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
    });
  }

  void _onSwitchCheckAlive(bool res, BigInt notTransferable) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    if (!res) {
      // todo: remove this after polkadot xcm alive
      if (widget.service.plugin.basic.name == relay_chain_name_polkadot &&
          _chainTo?.basic?.name == para_chain_name_acala) {
        return;
      }

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(dic['note']),
            content: Text(dic['note.msg1']),
            actions: <Widget>[
              CupertinoButton(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_ui, 'common')['cancel']),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoButton(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop();

                  if (notTransferable > BigInt.zero) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CupertinoAlertDialog(
                          title: Text(dic['note']),
                          content: Text(dic['note.msg2']),
                          actions: <Widget>[
                            CupertinoButton(
                              child: Text(I18n.of(context)
                                  .getDic(i18n_full_dic_ui, 'common')['ok']),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    setState(() {
                      _keepAlive = res;
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _keepAlive = res;
      });
    }
  }
}
