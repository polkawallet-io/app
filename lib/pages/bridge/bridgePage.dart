import 'dart:convert';
import 'package:app/pages/bridge/bridgeAddressTextFormField.dart';
import 'package:app/pages/bridge/bridgeChainSelector.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';

import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';

class BridgePage extends StatefulWidget {
  const BridgePage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/bridge';

  @override
  State<BridgePage> createState() => _BridgePageState();
}

class _BridgePageState extends State<BridgePage> {
  ///All from chains
  List<String> _chainFromAll;

  ///from ==> to chains
  final Map<String, Set<String>> _chainToMap = {};

  ///from-to ==> tokens
  final Map<String, Set<String>> _tokensMap = {};

  ///chainInfo
  Map<String, BridgeChainData> _chainInfo;

  ///destination chain fee
  BridgeAmountInputConfig _config;

  ///origin chain fee
  TxFeeEstimateResult _fee;

  /// current from
  String _chainFrom;

  /// current to
  String _chainTo;

  /// current token
  String _token;

  ///current account
  KeyPairData _account;

  /// amount input control
  final TextEditingController _amountCtrl = TextEditingController();

  /// from key
  final _formKey = GlobalKey<FormState>();

  /// account list
  List<KeyPairData> _accountOptions = [];

  /// account error
  String _accountError;

  /// amount error
  String _amountError;

  /// token balance
  Map<String, BridgeTokenBalance> _balanceMap;

  /// loading
  bool _loading = false;

  /// submitting
  bool _submitting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConfig();
    });
  }

  @override
  void dispose() {
    widget.service.plugin.sdk.api.bridge
        .unsubscribeBalances(_chainFrom, _account.address);
    widget.service.plugin.sdk.api.bridge.disconnectFromChains();
    super.dispose();
  }

  void loadConfig() async {
    List<String> chainFromAll =
        await widget.service.plugin.sdk.api.bridge.getFromChainsAll();

    Map<String, BridgeChainData> chainInfo =
        await widget.service.plugin.sdk.api.bridge.getChainsInfo();

    List<BridgeRouteData> routes =
        await widget.service.plugin.sdk.api.bridge.getRoutes();

    for (BridgeRouteData element in routes) {
      Set<String> from = _chainToMap[element.from];
      from ??= {};
      from.add(element.to);
      _chainToMap[element.from] = from;

      Set<String> tokens = _tokensMap[element.from + element.to];
      tokens ??= {};
      tokens.add(element.token);
      _tokensMap[element.from + element.to] = tokens;
    }
    _account = widget.service.keyring.current;
    setState(() {
      _accountOptions = widget.service.keyring.allWithContacts.toList();
      _chainFromAll = chainFromAll;
      _chainInfo = chainInfo;
    });
    _fromChange(chainFromAll.first);
  }

  void _fromChange(String from) {
    if (_chainFrom != null) {
      widget.service.plugin.sdk.api.bridge
          .unsubscribeBalances(_chainFrom, _account.address);
    }
    widget.service.plugin.sdk.api.bridge.connectFromChains([_chainFrom]);
    widget.service.plugin.sdk.api.bridge
        .subscribeBalances(from, _account.address, (p0) => _updateBalance(p0));
    setState(() {
      _chainFrom = from;
    });
    _toChange(_chainToMap[_chainFrom].contains(_chainTo)
        ? _chainTo
        : _chainToMap[_chainFrom].first);
  }

  void _toChange(String to) {
    setState(() {
      _chainTo = to;
    });

    _tokenChange(_tokensMap[_chainFrom + _chainTo].contains(_token)
        ? _token
        : _tokensMap[_chainFrom + _chainTo].first);
  }

  void _tokenChange(String token) {
    setState(() {
      _token = token;
    });
    _getFee();
  }

  void _getFee() async {
    setState(() {
      _loading = true;
    });
    BridgeAmountInputConfig config = await widget.service.plugin.sdk.api.bridge
        .getAmountInputConfig(_chainFrom, _chainTo, _token, _account.address);
    setState(() {
      _config = config;
      _loading = false;
    });
    _getTxFee();
  }

  Future<void> _getTxFee({bool reload = false}) async {
    if (_fee != null && !reload) {
      return _fee;
    }
    BridgeTokenBalance token = _balanceMap[_token];
    final sender = TxSenderData(widget.service.keyring.current.address,
        widget.service.keyring.current.pubKey);
    final xcmParams = await widget.service.plugin.sdk.api.bridge.getTxParams(
        _chainFrom,
        _chainTo,
        _token,
        _account.address,
        '100000000',
        token.decimals);

    if (xcmParams == null) return '0';

    final txInfo = TxInfoData(xcmParams.module, xcmParams.call, sender);

    TxFeeEstimateResult fee;
    if (_chainFrom == plugin_name_karura) {
      final feeData = await widget.service.plugin.sdk.api.tx
          .estimateFees(txInfo, xcmParams.params);
      fee = feeData;
    } else {
      final feeData = await widget.service.plugin.sdk.webView?.evalJavascript(
          'keyring.txFeeEstimate(xcm.getApi("$_chainFrom"), ${jsonEncode(txInfo)}, ${jsonEncode(xcmParams.params)})');
      if (feeData != null) {
        fee = feeData;
      }
    }

    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
  }

  void _addressChange(KeyPairData account, String error) {
    widget.service.plugin.sdk.api.bridge
        .unsubscribeBalances(_chainFrom, _account.address);
    widget.service.plugin.sdk.api.bridge.subscribeBalances(
        _chainFrom, account.address, (p0) => _updateBalance(p0));
    setState(() {
      _account = account;
      _accountError = error;
    });
    _getFee();
  }

  void _updateBalance(Map<String, BridgeTokenBalance> balance) {
    setState(() {
      _balanceMap = balance;
    });
  }

  void _changeChain(String from, String to) {
    if (_chainFrom != from) _fromChange(from);
    if (_chainTo != to) _toChange(to);
  }

  Future<String> _checkBlackList(KeyPairData acc) async {
    final addresses = await widget.service.plugin.sdk.api.account
        .decodeAddress([acc.address]);
    if (addresses != null) {
      final pubKey = addresses.keys.toList()[0];
      if (widget.service.plugin.sdk.blackList.indexOf(pubKey) > -1) {
        return I18n.of(context)
            .getDic(i18n_full_dic_app, 'common')['transfer.scam'];
      }
    }
    return null;
  }

  Future<String> _checkAccountFrom(KeyPairData acc) async {
    final blackListCheck = await _checkBlackList(acc);
    if (blackListCheck != null) return blackListCheck;
    return null;
  }

  String _validateAmount(String value, BigInt available, int decimals) {
    String v = value.trim();
    final error = Fmt.validatePrice(v, context);

    if (error != null) {
      return error;
    }
    BigInt input = Fmt.tokenInt(v, decimals);
    BigInt max = BigInt.parse(_config?.maxInput ?? '0');
    BigInt min = BigInt.parse(_config?.minInput ?? '0');
    if (input > max) {
      return 'Max. amount ${Fmt.priceFloorBigInt(max, decimals ?? 12, lengthMax: 6)}';
    } else if (input < min) {
      return 'Min. amount ${Fmt.priceFloorBigInt(min, decimals ?? 12, lengthMax: 6)}';
    }
    return null;
  }

  Future<XcmTxConfirmParams> _getTxParams(
      Widget chainFromIcon, TokenBalanceData feeToken) async {
    if (_accountError == null &&
        _amountError == null &&
        _formKey.currentState.validate() &&
        !_submitting &&
        !_loading) {
      setState(() {
        _submitting = true;
      });

      BridgeTokenBalance token = _balanceMap[_token];
      final dic_app = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
      final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
      final tokenView = PluginFmt.tokenView(token.token);

      final xcmParams = await widget.service.plugin.sdk.api.bridge.getTxParams(
          _chainFrom,
          _chainTo,
          _token,
          _account.address,
          _amountCtrl.text,
          token.decimals);

      if (xcmParams != null) {
        return XcmTxConfirmParams(
            txTitle: dic_app['hub.bridge'],
            module: xcmParams.module,
            call: xcmParams.call,
            txDisplay: {
              dicAcala['cross.chain']: _chainTo?.toUpperCase(),
            },
            txDisplayBold: {
              dic['amount']: Text(
                  '${Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()), lengthMax: 8)} $tokenView',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Titillium Web SemiBold',
                      color: Colors.white)),
              dic['address']: Row(
                children: [
                  AddressIcon(_account.address, svg: _account.icon),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 16, 0, 16),
                      child: Text(Fmt.address(_account?.address, pad: 8),
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
            chainFrom: _chainFrom,
            chainFromIcon: chainFromIcon,
            feeToken: feeToken,
            isPlugin: true,
            isBridge: true);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');

    TextStyle feeStyle = const TextStyle(
        fontFamily: 'Titillium Web Regular', fontSize: 14, color: Colors.white);

    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic["hub.bridge"] ?? "Bridge"),
        centerTitle: true,
        actions: [
          PluginAccountInfoAction(
            widget.service.keyring,
            onSelected: (index) => {},
          )
        ],
      ),
      body: Observer(builder: (_) {
        if (_chainFromAll == null ||
            _chainFromAll.isEmpty ||
            _balanceMap == null) {
          return Container();
        }

        final crossChainIcons = Map<String, Widget>.from(_chainInfo?.map(
            (k, v) => MapEntry(
                k.toUpperCase(),
                v.icon.contains('.svg')
                    ? SvgPicture.network(v.icon)
                    : Image.network(v.icon))));

        TokenBalanceData balance;
        final List<TokenBalanceData> tokenBalances = [];
        if (_balanceMap != null) {
          final tokenBalance = _balanceMap[_token.toUpperCase()];
          balance = TokenBalanceData(
              id: tokenBalance.token,
              amount: _config.maxInput,
              decimals: tokenBalance.decimals,
              minBalance: _config.minInput,
              symbol: tokenBalance.token);

          _tokensMap[_chainFrom + _chainTo].toList().forEach((element) {
            BridgeTokenBalance bridgeTokenBalance =
                _balanceMap.values.firstWhere((e) => e.token == element);
            tokenBalances.add(TokenBalanceData(
              id: bridgeTokenBalance.token,
              amount: bridgeTokenBalance.available,
              decimals: bridgeTokenBalance.decimals,
              symbol: bridgeTokenBalance.token,
              locked: bridgeTokenBalance.locked,
            ));
          });
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        BridgeChainSelector(
                          chainFromAll: _chainFromAll,
                          chainToMap: _chainToMap,
                          from: _chainFrom,
                          to: _chainTo,
                          chainInfo: _chainInfo,
                          onChanged: _changeChain,
                          fromConnecting: _loading,
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 20, bottom: 16),
                                child: Column(
                                  children: [
                                    BridgeAddressTextFormField(
                                      widget.service.plugin.sdk.api,
                                      _accountOptions,
                                      tag: dic['hub.to.address'],
                                      initialValue: _account,
                                      onChanged: (KeyPairData acc) async {
                                        final error =
                                            await _checkAccountFrom(acc);
                                        _addressChange(acc, error);
                                      },
                                      key: ValueKey<KeyPairData>(_account),
                                    ),
                                    Visibility(
                                      visible: _accountError != null,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        child: Text(_accountError ?? "",
                                            style: TextStyle(
                                                fontSize:
                                                    UI.getTextSize(12, context),
                                                color: Colors.red)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              PluginInputBalance(
                                margin: EdgeInsets.only(
                                    bottom: _amountError == null ? 24 : 2),
                                titleTag: dic['hub.amount'],
                                inputCtrl: _amountCtrl,
                                onInputChange: (v) {
                                  var error = _validateAmount(
                                      v,
                                      Fmt.balanceInt(balance.amount ?? 0),
                                      balance.decimals ?? 12);
                                  setState(() {
                                    _amountError = error;
                                  });
                                },
                                onTokenChange: (token) {
                                  _tokenChange(token.id);
                                },
                                onClear: () {
                                  setState(() {
                                    _amountError = null;
                                    _amountCtrl.text = "";
                                  });
                                },
                                balance: balance,
                                tokenIconsMap: widget.service.plugin.tokenIcons,
                                tokenOptions: tokenBalances ?? [],
                                tokenSelectTitle: dic['hub.selectToken'],
                              ),
                              ErrorMessage(
                                _amountError,
                                margin: const EdgeInsets.only(bottom: 24),
                              ),
                              Visibility(
                                // visible: sendFee.length > 0,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: Text(
                                              dic['hub.origin.transfer.fee'],
                                              style: feeStyle),
                                        ),
                                      ),
                                      Visibility(
                                          visible: _fee?.partialFee != null,
                                          child: Text(
                                              '${Fmt.priceFloorBigInt(BigInt.parse(_fee?.partialFee?.toString() ?? '0'), balance?.decimals ?? 12, lengthMax: 6)} ${balance?.symbol ?? ''}',
                                              style: feeStyle)),
                                    ],
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: _config?.destFee?.isNotEmpty ?? false,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: Text(
                                              dic['hub.destination.transfer.fee'],
                                              style: feeStyle),
                                        ),
                                      ),
                                      Text(
                                          '${Fmt.priceFloorBigInt(BigInt.parse(_config?.destFee ?? '0'), balance?.decimals ?? 12, lengthMax: 6)} ${_config?.token ?? ''}',
                                          style: feeStyle),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                  padding:
                                      EdgeInsets.only(top: 150.h, bottom: 38),
                                  child: PluginButton(
                                    title: dic['hub.transfer'],
                                    onPressed: () async {
                                      final params = await _getTxParams(
                                          TokenIcon(
                                            _chainFrom,
                                            crossChainIcons,
                                          ),
                                          balance);
                                      if (params != null) {
                                        final res = await Navigator.of(context)
                                            .pushNamed(XcmTxConfirmPage.route,
                                                arguments: params);
                                        if (res != null) {
                                          Navigator.of(context).pop(res);
                                        }

                                        setState(() {
                                          _submitting = false;
                                        });
                                      }
                                    },
                                  ))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
