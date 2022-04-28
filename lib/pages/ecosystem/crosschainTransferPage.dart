import 'dart:convert';

import 'package:app/common/consts.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/ecosystemPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_plugin_laminar/pages/currencySelectPage.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/bottomSheetContainer.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';

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
  String _chainTo;
  List<String> _chainToList;

  String _fee;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ModalRoute.of(context).settings.arguments as Map;
      final fromNetwork = data["fromNetwork"];
      final TokenBalanceData balance = data["balance"];
      var plugin;
      if (widget.service.plugin is PluginKarura) {
        plugin = widget.service.plugin as PluginKarura;
      } else if (widget.service.plugin is PluginAcala) {
        plugin = widget.service.plugin as PluginAcala;
      }

      final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
      final tokenXcmConfig = List<String>.from(
          (tokensConfig['xcm'] ?? {})[balance.tokenNameId] ?? []);
      final to = [widget.service.plugin.basic.name, ...tokenXcmConfig];
      to.removeWhere((element) => element == fromNetwork);
      setState(() {
        _chainToList = to;
        _chainTo = to.length > 0 ? to[0] : null;
      });

      _getTxFee();
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
    if (input > available) {
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
      var plugin;
      if (widget.service.plugin is PluginKarura) {
        plugin = widget.service.plugin as PluginKarura;
      } else if (widget.service.plugin is PluginAcala) {
        plugin = widget.service.plugin as PluginAcala;
      }
      final fromIcon =
          plugin.store.assets.crossChainIcons[fromNetwork] as String;
      if (xcmParams != null) {
        var plugin;
        if (widget.service.plugin is PluginKarura) {
          plugin = widget.service.plugin as PluginKarura;
        } else if (widget.service.plugin is PluginAcala) {
          plugin = widget.service.plugin as PluginAcala;
        }
        final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
        final feeToken = ((tokensConfig['xcmChains'] ?? {})[fromNetwork] ??
            {})['nativeToken'];
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
            isPlugin: true);
      }
    }
    return null;
  }

  Future<Map> _getXcmParams(String amount, {bool feeEstimate = false}) async {
    var plugin;
    if (widget.service.plugin is PluginKarura) {
      plugin = widget.service.plugin as PluginKarura;
    } else if (widget.service.plugin is PluginAcala) {
      plugin = widget.service.plugin as PluginAcala;
    }
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
    setState(() {
      _isLoading = true;
    });
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
        _isLoading = false;
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
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['ecosystem.crosschainTransfer']),
          centerTitle: true,
        ),
        body: Observer(builder: (_) {
          if (_chainToList == null || _chainToList.length == 0) {
            return Container();
          }
          var plugin;
          if (widget.service.plugin is PluginKarura) {
            plugin = widget.service.plugin as PluginKarura;
          } else if (widget.service.plugin is PluginAcala) {
            plugin = widget.service.plugin as PluginAcala;
          }

          final tokensConfig =
              plugin.store.setting.remoteConfig['tokens'] ?? {};
          final crossChainIcons = Map<String, Widget>.from(
              plugin.store.assets.crossChainIcons.map((k, v) => MapEntry(
                  k.toUpperCase(),
                  (v as String).contains('.svg')
                      ? SvgPicture.network(v)
                      : Image.network(v))));

          final destChainName = _chainTo;

          final isFromKar = fromNetwork == plugin_name_karura;

          final tokenXcmInfo = (tokensConfig['xcmInfo'] ??
                  {})[isFromKar ? destChainName : fromNetwork] ??
              {};

          final isTokenFromStateMine =
              balance.src != null && balance.src['Parachain'] == '1,000';

          final destExistDeposit = isFromKar
              ? Fmt.balanceInt(
                  (tokenXcmInfo[balance.symbol] ?? {})['existentialDeposit'])
              : Fmt.balanceInt(balance.minBalance);
          final existDeposit = Fmt.balanceInt(plugin
              .store.assets.tokenBalanceMap[balance.tokenNameId].minBalance);
          final destFee = isFromKar
              ? isTokenFromStateMine
                  ? BigInt.zero
                  : Fmt.balanceInt((tokenXcmInfo[balance.symbol] ?? {})['fee'])
              : Fmt.balanceInt(
                  (tokenXcmInfo[balance.symbol] ?? {})['receiveFee']);
          final sendFee =
              List.of((tokenXcmInfo[balance.symbol] ?? {})['sendFee'] ?? []);

          final sendFeeAmount =
              sendFee.length > 0 ? Fmt.balanceInt(sendFee[1]) : BigInt.zero;

          final feeToken = ((tokensConfig['xcmChains'] ?? {})[fromNetwork] ??
              {})['nativeToken'];

          final nativeToken = widget.service.plugin.networkState.tokenSymbol[0];
          final nativeTokenDecimals =
              widget.service.plugin.networkState.tokenDecimals[widget
                  .service.plugin.networkState.tokenSymbol
                  .indexOf(nativeToken)];
          return SafeArea(
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
                                        _chainToList);
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
                                margin: EdgeInsets.only(
                                    top: 24, bottom: _error1 == null ? 24 : 2),
                                titleTag:
                                    "${balance.symbol} ${I18n.of(context)?.getDic(i18n_full_dic_app, 'assets')['amount']}",
                                inputCtrl: _amountCtrl,
                                onInputChange: (v) {
                                  var error = _validateAmount(
                                      v,
                                      Fmt.balanceInt(balance.amount),
                                      balance.decimals);
                                  setState(() {
                                    _error1 = error;
                                  });
                                },
                                onClear: () {
                                  setState(() {
                                    _error1 = null;
                                    _amountCtrl.text = "";
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
                                            '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee), nativeTokenDecimals, lengthMax: 6)} $feeToken',
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
                                  Navigator.of(context).popAndPushNamed(
                                      EcosystemPage.route,
                                      arguments: {
                                        "balance": balance,
                                        "transferBalance":
                                            _amountCtrl.text.trim(),
                                        "convertNetwork": _chainTo ??
                                            widget.service.plugin.basic.name,
                                        "type": "transferred"
                                      });
                                }
                              }
                            },
                          )),
                    ],
                  )));
        }));
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
