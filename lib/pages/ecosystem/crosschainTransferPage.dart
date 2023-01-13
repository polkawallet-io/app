import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/ecosystemPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/format.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/bottomSheetContainer.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';

class CrossChainTransferPage extends StatefulWidget {
  const CrossChainTransferPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/ecosystem/crosschainTransfer';

  @override
  State<CrossChainTransferPage> createState() => _CrossChainTransferPageState();
}

class _CrossChainTransferPageState extends State<CrossChainTransferPage> {
  final TextEditingController _amountCtrl = TextEditingController();

  String _amountError;
  String _chainTo;
  List<String> _chainToList;

  /// from chain props
  BridgeNetworkProperties _props;

  /// dest chain fee
  BridgeAmountInputConfig _config;

  /// all icon widget
  Map<String, Widget> _crossChainIcons;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initBridgeConfig();
      _updateBridgeConfig();
    });
  }

  Future<void> _initBridgeConfig() async {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];

    final chainInfo =
        await widget.service.plugin.sdk.api.bridge.getChainsInfo();
    _crossChainIcons = Map<String, Widget>.from(chainInfo?.map((k, v) =>
        MapEntry(
            k.toUpperCase(),
            v.icon.contains('.svg')
                ? SvgPicture.network(v.icon)
                : Image.network(v.icon))));

    final props = await widget.service.plugin.sdk.api.bridge
        .getNetworkProperties(fromNetwork);
    _props = props;

    final routes = await widget.service.plugin.sdk.api.bridge.getRoutes();
    routes.retainWhere(
        (e) => e.from == fromNetwork && e.token == balance.tokenNameId);
    _chainToList = routes.map((e) => e.to).toList();
    _chainTo = _chainToList.isNotEmpty ? _chainToList[0] : null;
  }

  Future<void> _updateBridgeConfig() async {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];

    final config = await widget.service.plugin.sdk.api.bridge
        .getAmountInputConfig(
            fromNetwork,
            _chainTo,
            balance.tokenNameId,
            widget.service.keyring.current.address,
            widget.service.keyring.current.address);

    setState(() {
      _config = config;
    });
  }

  void _validateAmount(String value) {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final TokenBalanceData balance = data["balance"];

    String v = value.trim();
    int decimals = balance?.decimals ?? 12;
    String error = Fmt.validatePrice(v, context);

    if (error != null) {
      setState(() {
        _amountError = error;
      });
      return;
    }

    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final input = double.parse(v);
    final max = Fmt.balanceDouble(_config?.maxInput ?? '0', decimals);
    final min = Fmt.balanceDouble(_config?.minInput ?? '0', decimals);
    if (input > max) {
      error =
          '${dic['bridge.max']} ${max > 0 ? Fmt.priceFloor(max, lengthMax: 6) : BigInt.zero}';
    } else if (input < min) {
      error = '${dic['bridge.min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
    }
    setState(() {
      _amountError = error;
    });
  }

  Future<XcmTxConfirmParams> _getTxParams(TokenBalanceData feeToken) async {
    if (_amountError == null &&
        _amountCtrl.text.trim().isNotEmpty &&
        _config != null) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final dicAss = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final data = ModalRoute.of(context).settings.arguments as Map;
      final TokenBalanceData balance = data["balance"];
      final fromNetwork = data["fromNetwork"];

      final xcmParams = await widget.service.plugin.sdk.api.bridge.getTxParams(
          fromNetwork,
          _chainTo,
          balance?.tokenNameId,
          widget.service.keyring.current.address,
          Fmt.tokenInt(_amountCtrl.text.trim(), balance?.decimals).toString(),
          balance?.decimals,
          widget.service.keyring.current.address);

      if (xcmParams != null) {
        final tokenView = AppFmt.tokenView(balance?.symbol);
        return XcmTxConfirmParams(
            txTitle: dic['hub.bridge'],
            module: xcmParams.module,
            call: xcmParams.call,
            txDisplay: {
              dic['bridge.to']: _chainTo?.toUpperCase(),
            },
            txDisplayBold: {
              dicAss['amount']: Text(
                  '${Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()), lengthMax: 8)} $tokenView',
                  style: const TextStyle(
                      fontSize: 30,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Titillium Web SemiBold',
                      color: Colors.white)),
              dicAss['address']: Row(
                children: [
                  AddressIcon(widget.service.keyring.current.address,
                      svg: widget.service.keyring.current.icon),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 16, 0, 16),
                      child: Text(
                          Fmt.address(widget.service.keyring.current.address,
                              pad: 8),
                          style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Titillium Web Regular',
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            },
            params: xcmParams.params,
            chainFrom: fromNetwork,
            chainFromIcon: TokenIcon(
              fromNetwork,
              _crossChainIcons,
            ),
            feeToken: feeToken,
            isPlugin: true,
            isBridge: true,
            txHex: xcmParams.txHex);
      }
    }
    return null;
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
              _updateBridgeConfig();
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
    final data = ModalRoute.of(context).settings.arguments as Map;
    final fromNetwork = data["fromNetwork"];
    final TokenBalanceData balance = data["balance"];

    final feeToken = TokenBalanceData(
        decimals: _props?.tokenDecimals?.first,
        symbol: _props?.tokenSymbol?.first,
        amount: '0');

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: PluginColorsDark.headline1);
    final infoValueStyle = Theme.of(context).textTheme.headline5.copyWith(
        fontWeight: FontWeight.w600, color: PluginColorsDark.headline1);
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['ecosystem.crosschainTransfer']),
          centerTitle: true,
        ),
        body: Observer(builder: (_) {
          if (_chainToList == null || _chainToList.isEmpty) {
            return Container();
          }

          final isFromKar = fromNetwork == plugin_name_karura ||
              fromNetwork == plugin_name_acala;

          return SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChainSelected(dic['ecosystem.from'], fromNetwork),
                              isFromKar
                                  ? PluginTagCard(
                                      margin: const EdgeInsets.only(top: 24),
                                      titleTag: dic['ecosystem.to'],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 16),
                                      child: GestureDetector(
                                        onTap: () {
                                          _selectChain(context, 0,
                                              _crossChainIcons, _chainToList);
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _chainTo,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  ?.copyWith(
                                                      color: PluginColorsDark
                                                          .headline1),
                                            ),
                                            const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color:
                                                    PluginColorsDark.headline1)
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.only(top: 24),
                                      child: ChainSelected(
                                          dic['ecosystem.to'], _chainTo),
                                    ),
                              PluginInputBalance(
                                margin: EdgeInsets.only(
                                    top: 24,
                                    bottom: _amountError == null ? 24 : 2),
                                titleTag:
                                    "${balance.symbol} ${I18n.of(context)?.getDic(i18n_full_dic_app, 'assets')['amount']}",
                                inputCtrl: _amountCtrl,
                                onSetMax: (_) {
                                  if (_config == null) return;

                                  final max = Fmt.balanceInt(_config?.maxInput);
                                  if (max > BigInt.zero) {
                                    setState(() {
                                      _amountCtrl.text = Fmt.balanceDouble(
                                              _config?.maxInput,
                                              balance.decimals)
                                          .toString();
                                    });

                                    _validateAmount(_amountCtrl.text);
                                  }
                                },
                                onInputChange: _validateAmount,
                                onClear: () {
                                  setState(() {
                                    _amountError = null;
                                    _amountCtrl.text = "";
                                  });
                                },
                                balance: balance,
                                tokenIconsMap: widget.service.plugin.tokenIcons,
                              ),
                              ErrorMessage(
                                _amountError,
                                margin: const EdgeInsets.only(bottom: 24),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: PluginAddressFormItem(
                                    label: dic['ecosystem.destinationAccount'],
                                    account: widget.service.keyring.current,
                                  )),
                              Visibility(
                                  visible: _config == null,
                                  child: const SizedBox(
                                    width: double.infinity,
                                    child: PluginLoadingWidget(),
                                  )),
                              Visibility(
                                  visible: _config != null,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: Text(
                                                dic['hub.origin.transfer.fee'],
                                                style: labelStyle),
                                          ),
                                        ),
                                        Text(
                                            '${Fmt.priceCeilBigInt(Fmt.balanceInt(_config?.estimateFee), _props?.tokenDecimals?.first ?? 12, lengthMax: 6)} ${feeToken.symbol}',
                                            style: infoValueStyle),
                                      ],
                                    ),
                                  )),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Text(
                                            dic['hub.destination.transfer.fee'],
                                            style: labelStyle),
                                      ),
                                    ),
                                    Text(
                                      '${Fmt.priceCeilBigInt(Fmt.balanceInt(_config?.destFee?.amount), balance.decimals, lengthMax: 6)} ${balance.symbol}',
                                      style: infoValueStyle,
                                    )
                                  ],
                                ),
                              ),
                            ]),
                      )),
                      Padding(
                          padding: const EdgeInsets.only(top: 37, bottom: 38),
                          child: PluginButton(
                            title: dic['auction.submit'],
                            onPressed: () async {
                              final params = await _getTxParams(feeToken);
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
  const ChainSelector(
      {Key key,
      @required this.options,
      @required this.crossChainIcons,
      @required this.onSelect})
      : super(key: key);
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

class ChainSelected extends StatelessWidget {
  const ChainSelected(this.title, this.fromNetwork, {Key key})
      : super(key: key);
  final String title;
  final String fromNetwork;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PluginTextTag(
          backgroundColor: PluginColorsDark.headline3,
          title: title,
        ),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: const BoxDecoration(
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
                  ?.copyWith(color: const Color(0xFFFFFFFF).withAlpha(102)),
            )),
      ],
    );
  }
}
