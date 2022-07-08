import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:app/pages/bridge/bridgeAddressTextFormField.dart';
import 'package:app/pages/bridge/bridgeChainSelector.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
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
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_ui/pages/v3/accountListPage.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';

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

  ///chainInfo
  Map<String, BridgeChainData> _chainInfo;

  ///from ==> to chains
  final Map<String, Set<String>> _chainToMap = {};

  ///from-to ==> tokens
  final Map<String, Set<String>> _tokensMap = {};

  ///destination chain fee
  BridgeAmountInputConfig _config;

  ///origin chain fee
  TxFeeEstimateResult _fee;

  ///origin chain props
  BridgeNetworkProperties _props;

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

  /// isReady
  bool _isReady = false;

  /// fromConnecting
  bool _fromConnecting = false;

  /// submitting
  bool _submitting = false;

  /// current balance
  TokenBalanceData _balance;

  /// all icon widget
  Map<String, Widget> _crossChainIcons;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConfig();
    });
  }

  @override
  void dispose() {
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

    _crossChainIcons = Map<String, Widget>.from(chainInfo?.map((k, v) =>
        MapEntry(
            k.toUpperCase(),
            v.icon.contains('.svg')
                ? SvgPicture.network(v.icon)
                : Image.network(v.icon))));

    _accountOptions = widget.service.keyring.allWithContacts.toList();
    _chainFromAll = chainFromAll;
    _chainInfo = chainInfo;
    _account = widget.service.keyring.current;

    //default current network
    _chainFrom = chainFromAll.contains(widget.service.plugin.basic.name)
        ? widget.service.plugin.basic.name
        : chainFromAll.first;
    _chainTo = _chainToMap[_chainFrom].contains('acala')
        ? 'acala'
        : _chainToMap[_chainFrom].contains('karura')
            ? 'karura'
            : _chainToMap[_chainFrom].first;
    _token = _tokensMap[_chainFrom + _chainTo].contains(_token)
        ? _token
        : _tokensMap[_chainFrom + _chainTo].first;

    setState(() {
      _isReady = true;
    });
    _loadData();
  }

  Future<bool> _loadData() async {
    setState(() {
      _loading = true;
      _fromConnecting = true;
    });
    // final connected = await widget.service.plugin.sdk.api.bridge
    //     .connectFromChains([_chainFrom]);
    final connected = await widget.service.plugin.sdk.api.bridge
        .connectFromChains([_chainFrom]);

    setState(() {
      _fromConnecting = false;
    });
    if (connected != null) {
      _props = await widget.service.plugin.sdk.api.bridge
          .getNetworkProperties(_chainFrom);

      _config = await widget.service.plugin.sdk.api.bridge
          .getAmountInputConfig(_chainFrom, _chainTo, _token, _account.address);

      widget.service.plugin.sdk.api.bridge
          .subscribeBalances(_chainFrom, _account.address, (res) async {
        _balanceMap = res;
        final tokenBalance =
            _balanceMap != null ? _balanceMap[_token.toUpperCase()] : null;
        _balance = TokenBalanceData(
            id: tokenBalance.token,
            amount: tokenBalance.available,
            decimals: tokenBalance.decimals,
            minBalance: _config.minInput,
            symbol: tokenBalance.token);
        await _getTxFee();
        if (_amountCtrl.text.isNotEmpty) {
          _validateAmount(_amountCtrl.text);
        }
        setState(() {
          _loading = false;
        });
        widget.service.plugin.sdk.api.bridge
            .unsubscribeBalances(_chainFrom, _account.address);
      });
    }
    return false;
  }

  void _changeChain(String from, String to) {
    if (_chainFrom != from) _fromChange(from);
    if (_chainTo != to) _toChange(to);
  }

  void _fromChange(String from) async {
    _chainFrom = from;
    _chainTo = _chainToMap[_chainFrom].contains(_chainTo)
        ? _chainTo
        : _chainToMap[_chainFrom].first;
    _token = _tokensMap[_chainFrom + _chainTo].contains(_token)
        ? _token
        : _tokensMap[_chainFrom + _chainTo].first;
    _loadData();
  }

  void _toChange(String to) {
    _chainTo = to;
    _token = _tokensMap[_chainFrom + _chainTo].contains(_token)
        ? _token
        : _tokensMap[_chainFrom + _chainTo].first;
    _loadData();
  }

  void _tokenChange(String token) {
    if (_token != token) {
      _token = token;
      final tokenBalance =
          _balanceMap != null ? _balanceMap[_token.toUpperCase()] : null;
      setState(() {
        _balance = TokenBalanceData(
            id: tokenBalance.token,
            amount: tokenBalance.available,
            decimals: tokenBalance.decimals,
            minBalance: '0',
            symbol: tokenBalance.token);
      });
      _loadData();
    }
  }

  void _addressChange(KeyPairData account, String error) {
    setState(() {
      _account = account;
      _accountError = error;
    });
    _loadData();
  }

  Future<void> _getTxFee({bool reload = false}) async {
    if (_fee != null && !reload) {
      return _fee;
    }
    BridgeTokenBalance token = _balanceMap[_token];
    final sender = TxSenderData(_account.address, _account.pubKey);
    final tx = await widget.service.plugin.sdk.api.bridge.getTxParams(
        _chainFrom,
        _chainTo,
        _token,
        _account.address,
        '100000000',
        token.decimals);

    if (tx == null) return '0';
    final txInfo = TxInfoData(tx.module, tx.call, sender);
    final feeData = await widget.service.plugin.sdk.api.tx.estimateFees(
        txInfo, tx.params,
        rawParam: jsonEncode(tx.params), jsApi: 'bridge.getApi("$_chainFrom")');

    if (feeData != null) {
      _fee = feeData;
    }
    return _fee;
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

  void _validateAmount(String value) {
    String v = value.trim();
    int decimals = _balance?.decimals ?? 12;
    String error = Fmt.validatePrice(v, context);

    if (error != null) {
      setState(() {
        _amountError = error;
      });
      return;
    }
    BigInt input = Fmt.tokenInt(v, decimals);
    BigInt max = BigInt.parse(_config?.maxInput ?? '0');
    BigInt min = BigInt.parse(_config?.minInput ?? '0');
    if (input > max) {
      error =
          'Max. amount ${Fmt.priceFloorBigInt(max, decimals ?? 12, lengthMax: 6)}';
    } else if (input < min) {
      error =
          'Min. amount ${Fmt.priceFloorBigInt(min, decimals ?? 12, lengthMax: 6)}';
    }
    setState(() {
      _amountError = error;
    });
  }

  Future<XcmTxConfirmParams> _getTxParams(
      Widget chainFromIcon, TokenBalanceData feeToken) async {
    if (_accountError == null &&
        _amountError == null &&
        _amountCtrl.text.trim().isNotEmpty &&
        _formKey.currentState.validate() &&
        !_submitting &&
        !_loading) {
      setState(() {
        _submitting = true;
      });

      BridgeTokenBalance token = _balanceMap[_token];
      final dicApp = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
      final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

      final tokenView = PluginFmt.tokenView(token.token);

      final xcmParams = await widget.service.plugin.sdk.api.bridge.getTxParams(
          _chainFrom,
          _chainTo,
          _token,
          _account.address,
          Fmt.tokenInt(_amountCtrl.text.trim(), token.decimals).toString(),
          token.decimals);

      if (xcmParams != null) {
        return XcmTxConfirmParams(
            txTitle: dicApp['hub.bridge'],
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
                      height: 1.5,
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

  void _changeAccount() async {
    var res = await Navigator.of(context).pushNamed(
      AccountListPage.route,
      arguments: AccountListPageParams(list: _accountOptions),
    );
    if (res != null) {
      _addressChange(res, null);
      widget.service.keyring.setCurrent(res);
      widget.service.plugin.changeAccount(res);
      widget.service.store.assets
          .loadCache(res, widget.service.plugin.basic.name);
    }
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
            onSelected: (index) => _changeAccount(),
          )
        ],
      ),
      body: Observer(builder: (_) {
        if (!_isReady) {
          return SafeArea(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: double.infinity,
                child: PluginLoadingWidget(),
              )
            ],
          ));
        }

        final List<TokenBalanceData> tokenBalances = [];
        if (_balanceMap != null && _config != null) {
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
        final tokensAll = ['ACA', 'KAR', 'DOT', 'KSM', 'AUSD'];

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
                          fromConnecting: _fromConnecting,
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
                                onInputChange: (v) => _validateAmount(v),
                                onTokenChange: (token) {
                                  _tokenChange(token.id);
                                },
                                onClear: () {
                                  setState(() {
                                    _amountError = null;
                                    _amountCtrl.text = "";
                                  });
                                },
                                balance: _balance ??
                                    TokenBalanceData(
                                        decimals: 12,
                                        symbol: _token,
                                        amount: '0'),
                                tokenIconsMap: widget.service.plugin.tokenIcons,
                                tokenOptions: tokenBalances ?? [],
                                quickTokenOptions: tokenBalances
                                        .where((element) => tokensAll.contains(
                                            element.symbol.toUpperCase()))
                                        .toList() ??
                                    [],
                                tokenSelectTitle: dic['hub.selectToken'],
                              ),
                              ErrorMessage(
                                _amountError,
                                margin: const EdgeInsets.only(bottom: 24),
                              ),
                              Padding(
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
                                    _loading
                                        ? CupertinoActivityIndicator(
                                            color: const Color.fromARGB(
                                                150, 205, 205, 205),
                                            radius: 10.h)
                                        : Text(
                                            '${Fmt.priceFloorBigInt(BigInt.parse(_fee?.partialFee?.toString() ?? '0'), _props?.tokenDecimals?.first ?? 12, lengthMax: 6)} ${_props?.tokenSymbol?.first ?? ''}',
                                            style: feeStyle),
                                  ],
                                ),
                              ),
                              Padding(
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
                                    _loading
                                        ? CupertinoActivityIndicator(
                                            color: const Color.fromARGB(
                                                150, 205, 205, 205),
                                            radius: 10.h)
                                        : Text(
                                            '${Fmt.priceFloorBigInt(BigInt.parse(_config?.destFee ?? '0'), _balance?.decimals ?? 12, lengthMax: 6)} ${_config?.token ?? ''}',
                                            style: feeStyle),
                                  ],
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
                                            _crossChainIcons,
                                          ),
                                          _balance);
                                      if (params != null) {
                                        if (!mounted) return;
                                        final res = await Navigator.of(context)
                                            .pushNamed(XcmTxConfirmPage.route,
                                                arguments: params);
                                        if (res != null) {
                                          if (!mounted) return;
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
