import 'package:app/common/consts.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/ecosystem/ecosystemPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_plugin_laminar/pages/currencySelectPage.dart';
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
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/v3/bottomSheetContainer.dart';
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

  bool _keepAlive = true;
  String _chainTo;
  TxFeeEstimateResult _fee;

  // Future<String> _getTxFee({reload = false}) async {
  //   if (_fee != null && !reload) {
  //     return _fee!;
  //   }

  //   final sender = TxSenderData(
  //       widget.service.keyring.current.address, widget.keyring.current.pubKey);
  //   final xcmParams = await _getXcmParams('100000000', feeEstimate: true);
  //   if (xcmParams == null) return '0';

  //   final txInfo = TxInfoData(xcmParams['module'], xcmParams['call'], sender);

  //   String fee = '0';
  //   if (_chainFrom == plugin_name_karura) {
  //     final feeData = await widget.plugin.sdk.api.tx
  //         .estimateFees(txInfo, xcmParams['params']);
  //     fee = feeData.partialFee.toString();
  //   } else {
  //     final feeData = await widget.plugin.sdk.webView?.evalJavascript(
  //         'keyring.txFeeEstimate(xcm.getApi("$_chainFrom"), ${jsonEncode(txInfo)}, ${jsonEncode(xcmParams['params'])})');
  //     if (feeData != null) {
  //       fee = feeData['partialFee'].toString();
  //     }
  //   }

  //   if (mounted) {
  //     setState(() {
  //       _fee = fee;
  //     });
  //   }
  //   return fee;
  // }

  Future<void> _selectChain(BuildContext context, int index,
      Map<String, Widget> crossChainIcons, List<String> options) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BottomSheetContainer(
          title: Text(dic['cross.chain.select']),
          content: ChainSelector(
            options: options,
            crossChainIcons: crossChainIcons,
            onSelect: (chain) {
              setState(() {
                _chainTo = chain;
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final dicAssets = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];
    return Observer(builder: (_) {
      final plugin = widget.service.plugin as PluginKarura;

      final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
      final tokenXcmConfig = List<String>.from(
          (tokensConfig['xcm'] ?? {})[balance.tokenNameId] ?? []);
      final crossChainIcons = Map<String, Widget>.from(
          plugin.store.assets.crossChainIcons.map((k, v) => MapEntry(
              k.toUpperCase(),
              (v as String).contains('.svg')
                  ? SvgPicture.network(v)
                  : Image.network(v))));

      final notTransferable = Fmt.balanceInt(
              (widget.service.plugin.balances.native?.reservedBalance ?? 0)
                  .toString()) +
          Fmt.balanceInt(
              (widget.service.plugin.balances.native?.lockedBalance ?? 0)
                  .toString());

      final destChainName = _chainTo ?? widget.service.plugin.basic.name;

      final destExistDeposit =
          Fmt.balanceInt(xcm_send_fees[destChainName]['existentialDeposit']);
      final destFee = Fmt.balanceInt(xcm_send_fees[destChainName]['fee']);

      final existDeposit = Fmt.balanceInt(
          ((widget.service.plugin.networkConst['balances'] ??
                      {})['existentialDeposit'] ??
                  0)
              .toString());
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    _selectChain(context, 0, crossChainIcons,
                                        [plugin.basic.name, ...tokenXcmConfig]);
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        destChainName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color:
                                                    PluginColorsDark.headline1),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          color: PluginColorsDark.headline1)
                                    ],
                                  ),
                                ),
                              ),
                              PluginInputBalance(
                                margin: EdgeInsets.only(top: 24, bottom: 24),
                                titleTag:
                                    "${balance.symbol} ${I18n.of(context)?.getDic(i18n_full_dic_app, 'assets')['amount']}",
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
                                balance: balance,
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
                                            '${Fmt.priceCeilBigInt(destExistDeposit, balance.decimals, lengthMax: 6)} ${balance.symbol}',
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
                                        '${Fmt.priceCeilBigInt(destFee, balance.decimals, lengthMax: 6)} ${balance.symbol}',
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
                                        '${Fmt.priceCeilBigInt(existDeposit, balance.decimals, lengthMax: 6)} ${balance.symbol}',
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
                                            '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")), balance.decimals, lengthMax: 6)} ${balance.symbol}',
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
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(EcosystemPage.route, arguments: {
                                "balance": balance,
                                "convertNetwork": _chainTo ??
                                    widget.service.plugin.basic.name,
                              });
                            },
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
          _chainTo == para_chain_name_acala) {
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

class ChainSelector extends StatelessWidget {
  ChainSelector(
      {@required this.options,
      @required this.crossChainIcons,
      @required this.onSelect});
  final List<String> options;
  final Map<String, Widget> crossChainIcons;
  final Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: options.map((i) {
        return ListTile(
          title: CurrencyWithIcon(
            i.toUpperCase(),
            TokenIcon(i, crossChainIcons),
            textStyle: Theme.of(context).textTheme.headline4,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: Theme.of(context).unselectedWidgetColor,
          ),
          onTap: () {
            onSelect(i);
          },
        );
      }).toList(),
    );
  }
}
