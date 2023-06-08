import 'dart:async';

import 'package:app/pages/bridge/bridgeChainSelector.dart';
import 'package:app/pages/bridge/bridgePageParams.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/format.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:async/async.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart' as v3;
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextFormField.dart';
import 'package:polkawallet_ui/pages/v3/plugin/pluginAccountListPage.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

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
  bool _accountToFocus = false;

  /// amount input control
  final TextEditingController _amountCtrl = TextEditingController();

  /// eth address input control
  final TextEditingController _address20Ctrl = TextEditingController();

  /// from key
  final _formKey = GlobalKey<FormState>();

  /// account to warn
  String _accountToWarn;

  /// amount error
  String _amountError;

  /// token balance
  Map<String, TokenBalanceData> _balanceMap;

  /// isReady
  bool _isReady = false;

  /// fromConnecting
  bool _fromConnecting = false;

  /// submitting
  bool _submitting = false;

  /// all icon widget
  Map<String, Widget> _crossChainIcons;

  /// connection error
  String _connectionError;

  CancelableOperation _cancelable;

  ///handle androidOnRenderProcessGone crash
  static const String reloadKey = 'BridgeWebReloadKey';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context).settings.arguments;
      loadConfig(args != null
          ? BridgePageParams.fromJson(Map<String, String>.from(args))
          : null);
    });
  }

  @override
  void dispose() {
    _disconnectFromChain();
    _address20Ctrl.dispose();
    _amountCtrl.dispose();
    widget.service.plugin.sdk.api.bridge.unsubscribeReloadAction(reloadKey);
    widget.service.plugin.sdk.api.bridge.dispose();
    super.dispose();
  }

  void loadConfig(BridgePageParams args) async {
    await widget.service.bridge.initBridgeRunner();
    widget.service.plugin.sdk.api.bridge.subscribeReloadAction(reloadKey,
        () async {
      await _connectFromChain(_chainFrom);
      _subscribeBalance();
    });
    final chainFromAll =
        await widget.service.plugin.sdk.api.bridge.getFromChainsAll();
    final chainInfo =
        await widget.service.plugin.sdk.api.bridge.getChainsInfo();
    final routes = await widget.service.plugin.sdk.api.bridge.getRoutes();
    chainFromAll.retainWhere((e) => routes.indexWhere((r) => r.from == e) > -1);

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
    final from = args?.chainFrom;
    final to = args?.chainTo;
    final token = args?.token;
    final address = args?.address;
    _chainFrom = from ??
        (_chainFromAll.contains(widget.service.plugin.basic.name)
            ? widget.service.plugin.basic.name
            : _chainFromAll.first);
    _chainTo = to ??
        (_chainToMap[_chainFrom].contains('acala')
            ? 'acala'
            : _chainToMap[_chainFrom].contains('karura')
                ? 'karura'
                : _chainToMap[_chainFrom].first);
    _token = token ??
        (_tokensMap[_chainFrom + _chainTo].contains(_token)
            ? _token
            : _tokensMap[_chainFrom + _chainTo].first);
    if (address != null) {
      if (address.startsWith('0x') && address.length == 42) {
        _address20Ctrl.text = address;
      } else {
        _updateAccountTo(address);
      }
    }

    setState(() {
      _isReady = true;
    });
    _loadingActionConfig();
    await _connectFromChain(_chainFrom);
    _subscribeBalance();
  }

  Future<void> _updateAccountTo(String address) async {
    final acc = KeyPairData();
    acc.address = address;
    setState(() {
      _accountTo = acc;
    });

    final res = await Future.wait([
      widget.service.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _checkAccountTo(acc),
    ]);
    if (res != null && res[0] != null) {
      final accWithIcon = KeyPairData();
      accWithIcon.address = address;

      final List icon = res[0];
      accWithIcon.icon = icon[0][1];

      setState(() {
        _accountTo = accWithIcon;
        _accountToWarn = res[1];
      });
    }
  }

  Future<String> _getConnectionError() async {
    await Future.delayed(const Duration(seconds: 30));
    if (!mounted) return '';
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return dic['bridge.connecting.warn'];
  }

  void _loadingActionConfig() {
    setState(() {
      _connectionError = null;
    });
    _cancelable?.cancel();
    _cancelable = null;
    _cancelable = CancelableOperation.fromFuture(_getConnectionError(),
        onCancel: () => null).then((p0) {
      if (p0 == null) return;
      showCupertinoDialog(
          context: context,
          builder: (_) {
            return PolkawalletAlertDialog(
              type: DialogType.warn,
              content: Text(p0),
            );
          });
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    });
  }

  Future<void> _connectFromChain(String chainFrom) async {
    if (!_fromConnecting) {
      setState(() {
        _fromConnecting = true;
        _config = null;
      });
    }
    await widget.service.plugin.sdk.api.bridge.connectFromChains([chainFrom]);

    if (chainFrom == _chainFrom) {
      _props = await widget.service.plugin.sdk.api.bridge
          .getNetworkProperties(chainFrom);
    }
    _cancelable?.cancel();
    setState(() {
      _fromConnecting = false;
      _connectionError = null;
    });

    if (_accountTo != null) {
      final accWarn = await _checkAccountTo(_accountTo);
      if (_accountToWarn != accWarn && mounted) {
        setState(() {
          _accountToWarn = accWarn;
        });
      }
    }
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

    if (_config != null) {
      setState(() {
        _config = null;
      });
    }

    final toAddress =
        _isToMoonBeam() ? _address20Ctrl.text.trim() : _accountTo.address;
    final config = await widget.service.plugin.sdk.api.bridge
        .getAmountInputConfig(_chainFrom, _chainTo, _token, toAddress,
            widget.service.keyring.current.address);
    setState(() {
      _config = config;
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
    setState(() {
      _chainFrom = from;
      _chainTo = _chainToMap[_chainFrom].contains(_chainTo)
          ? _chainTo
          : _chainToMap[_chainFrom].first;
      _token = _tokensMap[_chainFrom + _chainTo].contains(_token)
          ? _token
          : _tokensMap[_chainFrom + _chainTo].first;

      /// clear amount input
      _amountError = null;
      _amountCtrl.text = "";
    });

    if (!_fromConnecting) {
      setState(() {
        _fromConnecting = true;
        _config = null;
      });
    }
    _loadingActionConfig();
    widget.service.plugin.sdk.api.bridge.reload();
  }

  void _toChange(String to) async {
    setState(() {
      _chainTo = to;
      _token = _tokensMap[_chainFrom + _chainTo].contains(_token)
          ? _token
          : _tokensMap[_chainFrom + _chainTo].first;
    });

    _updateInputConfig();

    final accWarn = await _checkAccountTo(_accountTo);
    if (_accountToWarn != accWarn && mounted) {
      setState(() {
        _accountToWarn = accWarn;
      });
    }
  }

  void _tokenChange(String token) {
    if (_token != token) {
      _token = token;

      _updateInputConfig();
    }
  }

  Future<String> _checkAccountTo(KeyPairData acc) async {
    if (_props == null) return null;

    if (widget.service.keyring.allWithContacts
            .indexWhere((e) => e.pubKey == acc.pubKey) >
        -1) {
      return null;
    }

    final error =
        I18n.of(context).getDic(i18n_full_dic_ui, 'account')['ss58.mismatch'];
    final res = await widget.service.plugin.sdk.api.bridge
        .checkAddressFormat(acc.address, _chainInfo[_chainTo].ss58Prefix);
    if (res != null && !res) {
      return error;
    }

    return null;
  }

  void _validateAmount(String value) {
    if (_balanceMap == null) return;

    String v = value.trim();
    int decimals = _balanceMap[_token]?.decimals ?? 12;
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

  Future<XcmTxConfirmParams> _getTxParams(
      Widget chainFromIcon, TokenBalanceData feeToken) async {
    if (_amountError == null &&
        _amountCtrl.text.trim().isNotEmpty &&
        _formKey.currentState.validate() &&
        !_submitting &&
        _config != null) {
      setState(() {
        _submitting = true;
      });

      TokenBalanceData token = _balanceMap[_token];
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final dicAss = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

      final tokenView = AppFmt.tokenView(token.symbol);

      final xcmParams = await widget.service.plugin.sdk.api.bridge.getTxParams(
          _chainFrom,
          _chainTo,
          _token,
          _isToMoonBeam() ? _address20Ctrl.text.trim() : _accountTo.address,
          Fmt.tokenInt(_amountCtrl.text.trim(), token.decimals).toString(),
          token.decimals,
          widget.service.keyring.current.address);

      if (xcmParams != null) {
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
                  v3.AddressIcon(_accountTo.address, svg: _accountTo.icon),
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
            isBridge: true,
            txHex: xcmParams.txHex);
      }
    }
    return null;
  }

  void _changeSenderAccount() async {
    final res = await Navigator.of(context).pushNamed(
      PluginAccountListPage.route,
      arguments: PluginAccountListPageParams(
          list: widget.service.keyring.allAccounts.toList(),
          current: widget.service.keyring.current),
    );
    final sender = res as KeyPairData;
    if (sender != null &&
        sender.pubKey != widget.service.keyring.current.pubKey) {
      setState(() {
        _accountTo = sender;
      });

      widget.service.keyring.setCurrent(sender);
      widget.service.account.handleAccountChanged(sender);

      _subscribeBalance();
    }
  }

  String _validateAddress20(String v) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final input = v?.trim();
    if (input == null || input.isEmpty) {
      return dic['input.empty'];
    }
    try {
      final output = checksumEthereumAddress(input);
      debugPrint(output);
    } catch (err) {
      return dic['address.error.eth'];
    }
    return null;
  }

  bool _isToMoonBeam() {
    return _chainTo == 'moonriver' || _chainTo == 'moonbeam';
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
          Center(
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                  color: const Color(0x24FFFFFF),
                  borderRadius: BorderRadius.circular(8)),
              child: IconButton(
                onPressed: () => _changeSenderAccount(),
                padding: EdgeInsets.zero,
                iconSize: 30,
                // bgColor: const Color(0x24FFFFFF),
                icon: AddressIcon(
                  widget.service.keyring.current.address,
                  svg: widget.service.keyring.current.icon,
                  size: 22,
                  tapToCopy: false,
                  borderColor: const Color(0xFF242528),
                  borderWidth: 2,
                ),
              ),
            ),
          )
        ],
      ),
      body: Builder(builder: (_) {
        final List<TokenBalanceData> tokenBalances = _config != null
            ? _tokensMap[_chainFrom + _chainTo]
                .toList()
                .map((e) => _balanceMap[e])
                .toList()
            : [];

        final tokenIcons = _tokensMap.isNotEmpty
            ? _tokensMap[_chainFrom + _chainTo].toList().asMap().map((_, v) =>
                MapEntry(
                    v,
                    Image.network(
                        'https://resources.acala.network/tokens/$v.png')))
            : <String, Widget>{};

        final TokenBalanceData tokenBalance = _config != null
            ? _balanceMap[_token]
            : TokenBalanceData(decimals: 12, symbol: _token, amount: '0');

        final feeToken = TokenBalanceData(
            decimals: _props?.tokenDecimals?.first,
            symbol: _props?.tokenSymbol?.first,
            amount: '0');

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
                        chainsInfo: _chainInfo,
                        onChanged: _changeChain,
                        loading: !_isReady,
                        connecting: _fromConnecting,
                        toConnecting:
                            _isReady && !_fromConnecting && _config == null,
                      ),
                      Visibility(
                          visible: !_fromConnecting && _balanceMap != null,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20, bottom: 16),
                                  child: Column(
                                    children: [
                                      _isToMoonBeam()
                                          ? PluginTextFormField(
                                              label: dic['hub.to.address'],
                                              controller: _address20Ctrl,
                                              validator: _validateAddress20,
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              suffix: GestureDetector(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: Icon(Icons.cancel,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .unselectedWidgetColor),
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    _address20Ctrl.text = '';
                                                  });
                                                },
                                              ),
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                            )
                                          : AddressTextFormField(
                                              widget.service.plugin.sdk.api,
                                              widget.service.keyring
                                                  .allWithContacts
                                                  .toList(),
                                              sdk: widget.service.plugin.sdk,
                                              labelText: dic['hub.to.address'],
                                              labelStyle: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  .copyWith(
                                                      color: Colors.white),
                                              hintText: dic['hub.to.address'],
                                              hintStyle: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  .copyWith(
                                                      color: PluginColorsDark
                                                          .headline2),
                                              initialValue: _accountTo,
                                              onChanged:
                                                  (KeyPairData acc) async {
                                                final error =
                                                    await _checkAccountTo(acc);
                                                setState(() {
                                                  _accountTo = acc;
                                                  _accountToWarn = error;
                                                });
                                              },
                                              key: ValueKey<KeyPairData>(
                                                  _accountTo),
                                              isHubTheme: true,
                                              onFocusChange: (hasFocus) {
                                                setState(() {
                                                  _accountToFocus = hasFocus;
                                                  if (hasFocus) {
                                                    _accountToWarn = null;
                                                  }
                                                });
                                              },
                                            ),
                                      ErrorMessage(
                                        !_isToMoonBeam()
                                            ? _accountToWarn ??
                                                (_accountToFocus
                                                    ? dic['bridge.address.warn']
                                                    : null)
                                            : null,
                                        margin: const EdgeInsets.only(left: 8),
                                      ),
                                    ],
                                  ),
                                ),
                                PluginInputBalance(
                                  canSearch: false,
                                  margin: EdgeInsets.only(
                                      bottom: _amountError == null ? 24 : 2),
                                  titleTag: dic['hub.amount'],
                                  inputCtrl: _amountCtrl,
                                  onInputChange: (v) => _validateAmount(v),
                                  onTokenChange: (token) {
                                    _tokenChange(token.symbol);
                                  },
                                  onClear: () {
                                    setState(() {
                                      _amountError = null;
                                      _amountCtrl.text = "";
                                    });
                                  },
                                  onSetMax: (_) {
                                    if (_config == null) return;

                                    final max =
                                        Fmt.balanceInt(_config?.maxInput);
                                    if (max > BigInt.zero) {
                                      setState(() {
                                        _amountCtrl.text = Fmt.balanceDouble(
                                                _config?.maxInput,
                                                tokenBalance.decimals)
                                            .toString();
                                      });

                                      _validateAmount(_amountCtrl.text);
                                    }
                                  },
                                  balance: tokenBalance,
                                  tokenIconsMap: tokenIcons,
                                  tokenOptions: tokenBalances ?? [],
                                  tokenSelectTitle: dic['hub.selectToken'],
                                  tokenViewFunction: AppFmt.tokenView,
                                ),
                                ErrorMessage(
                                  _amountError,
                                  margin: const EdgeInsets.only(
                                      left: 8, bottom: 24),
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
                                      Visibility(
                                        visible: _config != null,
                                        child: Text(
                                            '${Fmt.priceFloorBigInt(BigInt.parse(_config?.estimateFee ?? '0'), feeToken.decimals ?? 12, lengthMax: 6)} ${AppFmt.tokenView(feeToken.symbol ?? '')}',
                                            style: feeStyle),
                                      )
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
                                      Visibility(
                                        visible: _config != null,
                                        child: Text(
                                            '${Fmt.priceFloorBigInt(BigInt.parse(_config?.destFee?.amount ?? '0'), _config?.destFee?.decimals ?? 12, lengthMax: 6)} ${AppFmt.tokenView(_config?.destFee?.token ?? '')}',
                                            style: feeStyle),
                                      )
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
                                              _chainFrom.toUpperCase(),
                                              _crossChainIcons,
                                            ),
                                            feeToken);
                                        if (params != null) {
                                          if (!mounted) return;
                                          final res =
                                              await Navigator.of(context)
                                                  .pushNamed(
                                                      XcmTxConfirmPage.route,
                                                      arguments: params);
                                          if (res != null) {
                                            if (!mounted) return;

                                            _updateInputConfig();
                                          }

                                          setState(() {
                                            _submitting = false;
                                          });
                                        }
                                      },
                                    ))
                              ],
                            ),
                          ))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
      }),
    );
  }
}
