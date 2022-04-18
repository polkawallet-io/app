import 'dart:convert';

import 'package:app/common/consts.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/ecosystemPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
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
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';

class CrosschainTransferPage extends StatefulWidget {
  CrosschainTransferPage(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/crosschainTransfer';

  @override
  State<CrosschainTransferPage> createState() => _CrosschainTransferPageState();
}

class _CrosschainTransferPageState extends State<CrosschainTransferPage> {
  TextEditingController _amountCtrl = TextEditingController();

  String _error1;
  bool _isMax = false;
  String _chainTo;

  String _fee;

  @override
  void initState() {
    super.initState();
    _chainTo = widget.service.plugin.basic.name;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee();
    });
  }

  void _onSetMax(BigInt max, int decimals) {
    setState(() {
      _amountCtrl.text = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);

      _isMax = true;
    });
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

  Future<XcmTxConfirmParams> _getTxParams() async {
    if (_error1 == null && _amountCtrl.text.trim().length > 0) {
      final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
      final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
      final data = ModalRoute.of(context).settings.arguments as Map;
      final TokenBalanceData balance = data["balance"];
      final fromNetwork = data["fromNetwork"];

      final xcmParams = await _getXcmParams(
          Fmt.tokenInt(_amountCtrl.text.trim(), balance.decimals).toString());
      if (xcmParams != null) {
        return XcmTxConfirmParams(
            txTitle:
                '${dicAcala['transfer']} ${balance.symbol} (${dicAcala['cross.xcm']})',
            module: xcmParams['module'],
            call: xcmParams['call'],
            txDisplay: {
              dicAcala['cross.chain']: _chainTo?.toUpperCase(),
            },
            txDisplayBold: {
              dic['amount']: Text(
                Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                        lengthMax: 8) +
                    ' ${balance.symbol}',
                style: Theme.of(context).textTheme.headline1,
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
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ),
                  ),
                ],
              ),
            },
            params: xcmParams['params'],
            chainFrom: fromNetwork,
            chainFromIcon: Container(), //todo chainFromIcon
            feeToken: balance.symbol,
            isPlugin: true);
      }
    }
    return null;
  }

  Future<Map> _getXcmParams(String amount, {bool feeEstimate = false}) async {
    //todo: as PluginAcala
    final plugin = widget.service.plugin as PluginKarura;
    final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];
    final chainFromInfo = (tokensConfig['xcmChains'] ?? {})[fromNetwork] ?? {};
    final chainToInfo = (tokensConfig['xcmChains'] ?? {})[_chainTo] ?? {};
    final sendFee = List.of((tokensConfig['xcmSendFee'] ?? {})[_chainTo] ?? []);

    final address = widget.service.keyring.current.address;

    final Map xcmParams = await widget.service.plugin.sdk.webView?.evalJavascript(
        'xcm.getTransferParams('
        '{name: "$fromNetwork", paraChainId: ${chainFromInfo['id']}},'
        '{name: "$_chainTo", paraChainId: ${chainToInfo['id']}},'
        '"${balance?.symbol}", "$amount", "$address", ${jsonEncode(sendFee)})');
    return xcmParams;
  }

  Future<String> _getTxFee({reload = false}) async {
    if (_fee != null && !reload) {
      return _fee;
    }
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];

    final sender = TxSenderData(widget.service.keyring.current.address,
        widget.service.keyring.current.pubKey);
    final xcmParams = await _getXcmParams('100000000', feeEstimate: true);
    if (xcmParams == null) return '0';

    final txInfo = TxInfoData(xcmParams['module'], xcmParams['call'], sender);

    String fee = '0';
    if (fromNetwork == plugin_name_karura) {
      final feeData = await widget.service.plugin.sdk.api.tx
          .estimateFees(txInfo, xcmParams['params']);
      fee = feeData.partialFee.toString();
    } else {
      final feeData = await widget.service.plugin.sdk.webView?.evalJavascript(
          'keyring.txFeeEstimate(xcm.getApi("$fromNetwork"), ${jsonEncode(txInfo)}, ${jsonEncode(xcmParams['params'])})');
      if (feeData != null) {
        fee = feeData['partialFee'].toString();
      }
    }

    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee;
  }

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
              _getTxFee(reload: true);
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
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
    final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: PluginColorsDark.headline1);
    final subTitleStyle = TextStyle(fontSize: 12, height: 1);
    final infoValueStyle = Theme.of(context).textTheme.headline5.copyWith(
        fontWeight: FontWeight.w600, color: PluginColorsDark.headline1);
    return Observer(builder: (_) {
      //todo: as PluginAcala
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

      final destChainName = _chainTo;

      final destExistDeposit =
          Fmt.balanceInt(xcm_send_fees[destChainName]['existentialDeposit']);
      final destFee = Fmt.balanceInt(xcm_send_fees[destChainName]['fee']);

      final existDeposit = Fmt.balanceInt(
          ((widget.service.plugin.networkConst['balances'] ??
                      {})['existentialDeposit'] ??
                  0)
              .toString());

      final isFromKar = fromNetwork == plugin_name_karura;
      final sendFee =
          List.of((tokensConfig['xcmSendFee'] ?? {})[destChainName] ?? []);

      final sendFeeAmount =
          sendFee.length > 0 ? Fmt.balanceInt(sendFee[1]) : BigInt.zero;
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
                                onSetMax: (Fmt.balanceInt(balance.amount) ??
                                            BigInt.zero) >
                                        BigInt.zero
                                    ? (max) => _onSetMax(max, balance.decimals)
                                    : null,
                                onInputChange: (v) {
                                  var error = _validateAmount(
                                      v,
                                      Fmt.balanceInt(balance.amount),
                                      balance.decimals);
                                  setState(() {
                                    _error1 = error;
                                    _isMax = false;
                                  });
                                },
                                onClear: () {
                                  setState(() {
                                    _error1 = null;
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
                                        child: Text(dicAcala['cross.fee'],
                                            style: labelStyle),
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
                                visible: isFromKar && sendFee.length > 0,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Text('XCM fee',
                                              style: labelStyle),
                                        ),
                                      ),
                                      Text(
                                          '${Fmt.priceFloorBigInt(sendFeeAmount, balance.decimals ?? 12, lengthMax: 6)} ${balance.symbol}',
                                          style: infoValueStyle),
                                    ],
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: isFromKar,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.only(right: 60),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(dicAcala['transfer.exist'],
                                                    style: labelStyle),
                                                Text(
                                                    dicAcala['cross.exist.msg'],
                                                    style: subTitleStyle),
                                              ],
                                            )),
                                      ),
                                      Text(
                                          '${Fmt.priceCeilBigInt(existDeposit, balance.decimals, lengthMax: 6)} ${balance.symbol}',
                                          style: infoValueStyle),
                                    ],
                                  ),
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
                                            child: Text(
                                                dicAcala['transfer.fee'],
                                                style: labelStyle),
                                          ),
                                        ),
                                        Text(
                                            '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee), balance.decimals, lengthMax: 6)} ${balance.symbol}',
                                            style: infoValueStyle),
                                      ],
                                    ),
                                  )),
                            ]),
                      )),
                      Padding(
                          padding: EdgeInsets.only(top: 37, bottom: 38),
                          child: PluginButton(
                            title: dic['auction.submit'],
                            onPressed: () async {
                              final params = await _getTxParams();
                              if (params != null) {
                                final res = await Navigator.of(context)
                                    .pushNamed(XcmTxConfirmPage.route,
                                        arguments: params);
                                if (res != null) {
                                  // Navigator.of(context).pop(res);
                                  Navigator.of(context).popAndPushNamed(
                                      EcosystemPage.route,
                                      arguments: {
                                        "balance": balance,
                                        "convertNetwork": _chainTo ??
                                            widget.service.plugin.basic.name,
                                      });
                                }
                              }
                            },
                          )),
                    ],
                  ))));
    });
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
