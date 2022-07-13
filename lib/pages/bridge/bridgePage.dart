import 'package:app/pages/bridge/bridgeAddressTextFormField.dart';
import 'package:app/pages/bridge/bridgeChainSelector.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/format.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/v3/accountListPage.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

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

  /// send to account
  KeyPairData _accountTo;

  /// amount input control
  final TextEditingController _amountCtrl = TextEditingController();

  /// from key
  final _formKey = GlobalKey<FormState>();

  /// account to error
  String _accountToError;

  /// amount error
  String _amountError;

  /// token balance
  Map<String, TokenBalanceData> _balanceMap;

  /// loading
  bool _configLoading = true;

  /// isReady
  bool _isReady = false;

  /// fromConnecting
  bool _fromConnecting = true;

  /// submitting
  bool _submitting = false;

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
    _disconnectFromChain();
    super.dispose();
  }

  void loadConfig() async {
    final chainFromAll =
        await widget.service.plugin.sdk.api.bridge.getFromChainsAll();
    final chainInfo =
        await widget.service.plugin.sdk.api.bridge.getChainsInfo();
    final routes = await widget.service.plugin.sdk.api.bridge.getRoutes();

    for (BridgeRouteData element in routes) {
      final Set<String> from = _chainToMap[element.from] ?? {};
      from.add(element.to);
      _chainToMap[element.from] = from;

      final Set<String> tokens = _tokensMap[element.from + element.to] ?? {};
      tokens.add(element.token);
      _tokensMap[element.from + element.to] = tokens;
    }

    _crossChainIcons = Map<String, Widget>.from(chainInfo?.map((k, v) =>
        MapEntry(
            k.toUpperCase(),
            v.icon.contains('.svg')
                ? SvgPicture.network(v.icon)
                : Image.network(v.icon))));

    _chainFromAll = chainFromAll;
    _chainInfo = chainInfo;
    _accountTo = widget.service.keyring.current;

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

    await _connectFromChain();
    _subscribeBalance();
  }

  Future<void> _connectFromChain() async {
    if (!_fromConnecting) {
      setState(() {
        _fromConnecting = true;
        _fee = null;
        _configLoading = true;
      });
    }
    await widget.service.plugin.sdk.api.bridge.connectFromChains([_chainFrom]);

    _props = await widget.service.plugin.sdk.api.bridge
        .getNetworkProperties(_chainFrom);
    setState(() {
      _fromConnecting = false;
    });
  }

  Future<void> _disconnectFromChain() async {
    widget.service.plugin.sdk.api.bridge.unsubscribeBalances(
        _chainFrom, widget.service.keyring.current.address);
    widget.service.plugin.sdk.api.bridge.disconnectFromChains();
  }

  Future<bool> _subscribeBalance() async {
    if (!_fromConnecting) {
      widget.service.plugin.sdk.api.bridge.subscribeBalances(
          _chainFrom, widget.service.keyring.current.address, (res) async {
        _balanceMap = res.map((k, v) => MapEntry(
            k,
            TokenBalanceData(
                amount: v.available, symbol: v.token, decimals: v.decimals)));

        _updateInputConfig();
      });
    }
    return false;
  }

  Future<void> _updateInputConfig() async {
    if (_balanceMap == null || _balanceMap[_token] == null) return;

    if (!_configLoading) {
      setState(() {
        _configLoading = true;
      });
    }

    _getTxFee();
    _config = await widget.service.plugin.sdk.api.bridge.getAmountInputConfig(
        _chainFrom, _chainTo, _token, widget.service.keyring.current.address);

    setState(() {
      _configLoading = false;
    });

    if (_amountCtrl.text.isNotEmpty) {
      _validateAmount(_amountCtrl.text);
    }
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

    _disconnectFromChain();
    await _connectFromChain();
    _subscribeBalance();
  }

  void _toChange(String to) {
    _chainTo = to;
    _token = _tokensMap[_chainFrom + _chainTo].contains(_token)
        ? _token
        : _tokensMap[_chainFrom + _chainTo].first;
    _updateInputConfig();
  }

  void _tokenChange(String token) {
    if (_token != token) {
      _token = token;

      print(_token);
      _updateInputConfig();
    }
  }

  void _accountToChange(KeyPairData account, String error) {
    setState(() {
      _accountTo = account;
      _accountToError = error;
    });
  }

  Future<void> _getTxFee() async {
    final token = _balanceMap[_token];
    final sender = TxSenderData(widget.service.keyring.current.address,
        widget.service.keyring.current.pubKey);
    final tx = await widget.service.plugin.sdk.api.bridge.getTxParams(
        _chainFrom,
        _chainTo,
        _token,
        _accountTo.address,
        '100000000',
        token.decimals);

    if (tx == null) return '0';

    final txInfo = TxInfoData(tx.module, tx.call, sender);
    final feeData = await widget.service.plugin.sdk.api.tx
        .estimateFees(txInfo, tx.params, jsApi: 'bridge.getApi("$_chainFrom")');

    if (feeData != null) {
      setState(() {
        _fee = feeData;
      });
    }
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

  Future<String> _checkAccountTo(KeyPairData acc) async {
    final blackListCheck = await _checkBlackList(acc);
    if (blackListCheck != null) return blackListCheck;
    return null;
  }

  void _validateAmount(String value) {
    String v = value.trim();
    int decimals = _balanceMap[_token]?.decimals ?? 12;
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
    if (_accountToError == null &&
        _amountError == null &&
        _amountCtrl.text.trim().isNotEmpty &&
        _formKey.currentState.validate() &&
        !_submitting &&
        !_configLoading) {
      setState(() {
        _submitting = true;
      });

      TokenBalanceData token = _balanceMap[_token];
      final dicApp = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'common');
      final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

      final tokenView = AppFmt.tokenView(token.symbol);

      final xcmParams = await widget.service.plugin.sdk.api.bridge.getTxParams(
          _chainFrom,
          _chainTo,
          _token,
          _accountTo.address,
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
                  AddressIcon(_accountTo.address, svg: _accountTo.icon),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 16, 0, 16),
                      child: Text(Fmt.address(_accountTo.address, pad: 8),
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

  void _changeSenderAccount() async {
    var res = await Navigator.of(context).pushNamed(
      AccountListPage.route,
      arguments: AccountListPageParams(
          list: widget.service.keyring.allAccounts.toList()),
    );
    if (res != null) {
      widget.service.keyring.setCurrent(res);
      widget.service.plugin.changeAccount(res);
      widget.service.store.assets
          .loadCache(res, widget.service.plugin.basic.name);

      _subscribeBalance();
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
            onSelected: (index) => _changeSenderAccount(),
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

        final balanceLoaded =
            _balanceMap != null && _balanceMap[_token] != null;
        final List<TokenBalanceData> tokenBalances = balanceLoaded
            ? _tokensMap[_chainFrom + _chainTo]
                .toList()
                .map((e) => _balanceMap[e])
                .toList()
            : [];
        final tokensAll = ['ACA', 'KAR', 'DOT', 'KSM', 'AUSD'];
        final tokenIcons = _tokensMap[_chainFrom + _chainTo]
            .toList()
            .asMap()
            .map((_, v) => MapEntry(
                v,
                Image.network(
                    'https://resources.acala.network/tokens/$v.png')));

        final TokenBalanceData tokenBalance = balanceLoaded
            ? _balanceMap[_token]
            : TokenBalanceData(decimals: 12, symbol: _token, amount: '0');

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
                                      widget.service.keyring.allWithContacts
                                          .toList(),
                                      tag: dic['hub.to.address'],
                                      initialValue:
                                          widget.service.keyring.current,
                                      onChanged: (KeyPairData acc) async {
                                        final error =
                                            await _checkAccountTo(acc);
                                        _accountToChange(acc, error);
                                      },
                                      key: ValueKey<KeyPairData>(_accountTo),
                                    ),
                                    Visibility(
                                      visible: _accountToError != null,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        child: Text(_accountToError ?? "",
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
                                  _tokenChange(token.symbol.toUpperCase());
                                },
                                onClear: () {
                                  setState(() {
                                    _amountError = null;
                                    _amountCtrl.text = "";
                                  });
                                },
                                balance: tokenBalance,
                                tokenIconsMap: tokenIcons,
                                tokenOptions: tokenBalances ?? [],
                                quickTokenOptions: tokenBalances
                                        .where((element) => tokensAll.contains(
                                            element.symbol.toUpperCase()))
                                        .toList() ??
                                    [],
                                tokenSelectTitle: dic['hub.selectToken'],
                                tokenViewFunction: AppFmt.tokenView,
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
                                    _fee == null
                                        ? CupertinoActivityIndicator(
                                            color: const Color.fromARGB(
                                                150, 205, 205, 205),
                                            radius: 10.h)
                                        : Text(
                                            '${Fmt.priceFloorBigInt(BigInt.parse(_fee?.partialFee?.toString() ?? '0'), _props?.tokenDecimals?.first ?? 12, lengthMax: 6)} ${AppFmt.tokenView(_props?.tokenSymbol?.first ?? '')}',
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
                                    _configLoading
                                        ? CupertinoActivityIndicator(
                                            color: const Color.fromARGB(
                                                150, 205, 205, 205),
                                            radius: 10.h)
                                        : Text(
                                            '${Fmt.priceFloorBigInt(BigInt.parse(_config?.destFee ?? '0'), tokenBalance.decimals ?? 12, lengthMax: 6)} ${AppFmt.tokenView(_token)}',
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
                                          tokenBalance);
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
