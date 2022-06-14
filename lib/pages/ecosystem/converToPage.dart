import 'dart:convert';

import 'package:app/pages/ecosystem/completedPage.dart';
import 'package:app/pages/ecosystem/transitingWidget.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class ConverToPage extends StatefulWidget {
  ConverToPage(this.service, {Key key}) : super(key: key);
  AppService service;
  static final String route = '/ecosystem/converTo';

  @override
  State<ConverToPage> createState() => _ConverToPageState();
}

class _ConverToPageState extends State<ConverToPage> {
  TextEditingController _amountCtrl = TextEditingController();

  String _error1;
  bool _isMax = false;

  String _fee;
  String _receiver;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee('100000000');
    });
  }

  // void _onSetMax(BigInt max, int decimals) {
  //   setState(() {
  //     _amountCtrl.text = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
  //     _getTxFee(_amountCtrl.text);
  //     _isMax = true;
  //   });
  // }

  Future<XcmTxConfirmParams> _getTxParams() async {
    if (_error1 == null && _amountCtrl.text.trim().length > 0) {
      final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
      final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
      final data = ModalRoute.of(context).settings.arguments as Map;
      final TokenBalanceData balance = data["balance"];

      final xcmParams = await _getXcmParams(
          (Fmt.tokenInt(_amountCtrl.text.trim(), balance.decimals)).toString());
      if (xcmParams != null) {
        final convertToKen = data["convertToKen"];
        final fromNetwork = data["fromNetwork"];
        var plugin;
        if (widget.service.plugin is PluginKarura) {
          plugin = widget.service.plugin as PluginKarura;
        } else if (widget.service.plugin is PluginAcala) {
          plugin = widget.service.plugin as PluginAcala;
        }
        final fromIcon =
            plugin.store.assets.crossChainIcons[fromNetwork] as String;
        final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
        final feeTokenSymbol =
            ((tokensConfig['xcmChains'] ?? {})[fromNetwork] ??
                {})['nativeToken'];
        final feeToken = plugin.store.assets.allTokens.firstWhere((e) =>
            e.symbol.toUpperCase() == feeTokenSymbol.toString().toUpperCase());
        return XcmTxConfirmParams(
            txTitle:
                "${I18n.of(context)?.getDic(i18n_full_dic_app, 'public')['ecosystem.convertTo']} $convertToKen (1/2)",
            module: xcmParams['module'],
            call: xcmParams['call'],
            txDisplay: {
              dicAcala['cross.chain']:
                  widget.service.plugin.basic.name?.toUpperCase(),
            },
            txDisplayBold: {
              dic['amount']: Text(
                Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                        lengthMax: 8) +
                    ' ${balance.symbol}',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(color: PluginColorsDark.headline1),
              ),
              dic['address']: Row(
                children: [
                  AddressIcon(widget.service.keyring.current.address,
                      svg: widget.service.keyring.current.icon),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                      child: Text(
                        Fmt.address(widget.service.keyring.current.address,
                            pad: 8),
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(color: PluginColorsDark.headline1),
                      ),
                    ),
                  ),
                ],
              ),
            },
            params: xcmParams['params'],
            chainFrom: fromNetwork,
            chainFromIcon: fromIcon.contains('.svg')
                ? SvgPicture.network(fromIcon)
                : Image.network(fromIcon),
            feeToken: feeToken,
            isPlugin: true,
            waitingWidget: TransitingWidget(
                fromNetwork, widget.service.plugin.basic.name, balance.symbol));
      }
    }
    return null;
  }

  Future<Map> _getXcmParams(String amount) async {
    var plugin;
    if (widget.service.plugin is PluginKarura) {
      plugin = widget.service.plugin as PluginKarura;
    } else if (widget.service.plugin is PluginAcala) {
      plugin = widget.service.plugin as PluginAcala;
    }
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];
    final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
    final chainFromInfo = (tokensConfig['xcmChains'] ?? {})[fromNetwork] ?? {};
    final chainToInfo =
        (tokensConfig['xcmChains'] ?? {})[widget.service.plugin.basic.name] ??
            {};
    final sendFee = List.of(
        (tokensConfig['xcmSendFee'] ?? {})[widget.service.plugin.basic.name] ??
            []);

    final address = widget.service.keyring.current.address;

    final Map xcmParams = await widget.service.plugin.sdk.webView?.evalJavascript(
        'xcm.getTransferParams('
        '{name: "$fromNetwork", paraChainId: ${chainFromInfo['id']}},'
        '{name: "${widget.service.plugin.basic.name}", paraChainId: ${chainToInfo['id']}},'
        '"${balance.symbol}", "$amount", "$address", ${jsonEncode(sendFee)})');
    return xcmParams;
  }

  _getTxFee(String amount) async {
    setState(() {
      _isLoading = true;
    });
    final data = ModalRoute.of(context).settings.arguments as Map;
    final TokenBalanceData balance = data["balance"];

    if (_fee == null) {
      final sender = TxSenderData(widget.service.keyring.current.address,
          widget.service.keyring.current.pubKey);

      final xcmParams = await _getXcmParams(
          Fmt.tokenInt(_amountCtrl.text.trim(), balance.decimals).toString());
      if (xcmParams == null) return '0';

      final txInfo = TxInfoData(xcmParams['module'], xcmParams['call'], sender);

      String fee = '0';
      final fromNetwork = data["fromNetwork"];
      final feeData = await widget.service.plugin.sdk.webView?.evalJavascript(
          'keyring.txFeeEstimate(xcm.getApi("$fromNetwork"), ${jsonEncode(txInfo)}, ${jsonEncode(xcmParams['params'])})');
      if (feeData != null) {
        fee = feeData['partialFee'].toString();
      }
      setState(() {
        _fee = fee;
      });
    }

    if (mounted) {
      setState(() {
        if (_amountCtrl.text.trim().length > 0) {
          _receiver = (Fmt.tokenInt(_amountCtrl.text.trim(), balance.decimals) -
                  Fmt.balanceInt(_fee))
              .toString();
        }
        _isLoading = false;
      });
    }
  }

  String _validateAmount(String value, BigInt available, int decimals) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    String v = value.trim();
    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    BigInt input = Fmt.tokenInt(v, decimals);
    if (!_isMax && input > available) {
      return dic['amount.low'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final TokenBalanceData balance = data["balance"];
    final fromNetwork = data["fromNetwork"];
    final convertToKen = data["convertToKen"];

    var plugin;
    if (widget.service.plugin is PluginKarura) {
      plugin = widget.service.plugin as PluginKarura;
    } else if (widget.service.plugin is PluginAcala) {
      plugin = widget.service.plugin as PluginAcala;
    }

    final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};

    final tokenXcmInfo = (tokensConfig['xcmInfo'] ?? {})[fromNetwork] ?? {};

    final destExistDeposit = Fmt.balanceInt(balance.minBalance);
    final destFee =
        Fmt.balanceInt((tokenXcmInfo[balance.symbol] ?? {})['receiveFee']);

    final nativeToken = widget.service.plugin.networkState.tokenSymbol[0];
    final nativeTokenDecimals = widget
            .service.plugin.networkState.tokenDecimals[
        widget.service.plugin.networkState.tokenSymbol.indexOf(nativeToken)];

    final feeTokenSymbol =
        ((tokensConfig['xcmChains'] ?? {})[fromNetwork] ?? {})['nativeToken'];

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: PluginColorsDark.headline1);
    final infoValueStyle = Theme.of(context).textTheme.headline5.copyWith(
        fontWeight: FontWeight.w600, color: PluginColorsDark.headline1);

    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text("${dic['ecosystem.convertTo']} $convertToKen (1/2)"),
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
                    margin: EdgeInsets.only(
                        top: 24, bottom: _error1 == null ? 24 : 2),
                    titleTag:
                        "${dic['ecosystem.bringTo']} ${widget.service.plugin.basic.name}",
                    inputCtrl: _amountCtrl,
                    // onSetMax: (Fmt.balanceInt(balance.amount) ?? BigInt.zero) >
                    //         BigInt.zero
                    //     ? (max) => _onSetMax(max, balance.decimals)
                    //     : null,
                    onInputChange: (v) {
                      var error = _validateAmount(
                          v, Fmt.balanceInt(balance.amount), balance.decimals);
                      if (error == null) {
                        _getTxFee(_amountCtrl.text);
                      }
                      setState(() {
                        _error1 = error;
                        _isMax = false;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _error1 = null;
                        _amountCtrl.text = "";
                        _fee = null;
                        _receiver = null;
                        _isMax = false;
                      });
                    },
                    balance: balance,
                    tokenIconsMap: widget.service.plugin.tokenIcons,
                  ),
                  ErrorMessage(
                    _error1,
                    margin: EdgeInsets.only(bottom: 24),
                  ),
                  Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: PluginAddressFormItem(
                        label: dic['ecosystem.destinationAccount'],
                        account: widget.service.keyring.current,
                      )),
                  Visibility(
                      visible: _isLoading,
                      child: Container(
                        width: double.infinity,
                        child: PluginLoadingWidget(),
                      )),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                            padding: EdgeInsets.only(right: 40),
                            child: Text(dicAcala['cross.exist'],
                                style: labelStyle)),
                      ),
                      Expanded(
                          flex: 0,
                          child: Text(
                              '${Fmt.priceCeilBigInt(destExistDeposit, balance.decimals, lengthMax: 6)} ${balance.symbol}',
                              style: infoValueStyle)),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: 4),
                            child:
                                Text(dicAcala['cross.fee'], style: labelStyle),
                          ),
                        ),
                        Text(
                          '${Fmt.priceCeilBigInt(destFee, balance.decimals, lengthMax: 6)} ${balance.symbol}',
                          style: infoValueStyle,
                        )
                      ],
                    ),
                  ),
                  Visibility(
                      visible: _fee != null,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Text(dicAcala['transfer.fee'],
                                    style: labelStyle),
                              ),
                            ),
                            Text(
                                '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee), nativeTokenDecimals, lengthMax: 6)} $feeTokenSymbol',
                                style: infoValueStyle),
                          ],
                        ),
                      )),
                ],
              ))),
              Padding(
                  padding: EdgeInsets.only(top: 37, bottom: 38),
                  child: PluginButton(
                    title: dic['auction.submit'],
                    onPressed: () async {
                      final params = await _getTxParams();
                      if (params != null) {
                        final res = await Navigator.of(context).pushNamed(
                            XcmTxConfirmPage.route,
                            arguments: params);
                        if (res != null) {
                          // Navigator.of(context).pop(res);
                          Navigator.of(context)
                              .popAndPushNamed(CompletedPage.route, arguments: {
                            "balance": balance,
                            "fromNetwork": fromNetwork,
                            "convertToKen": convertToKen,
                            "fee": _fee,
                          });
                        }
                      }
                    },
                  )),
            ],
          ),
        )));
  }
}

class ErrorMessage extends StatelessWidget {
  ErrorMessage(this.error, {this.margin});
  final error;
  final EdgeInsetsGeometry margin;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: error == null
          ? EdgeInsets.zero
          : margin ?? EdgeInsets.only(left: 16, top: 4),
      child: error == null
          ? null
          : Row(children: [
              Expanded(
                  child: Text(
                error,
                style: TextStyle(
                    fontSize: UI.getTextSize(12, context), color: Colors.red),
              ))
            ]),
    );
  }
}
