import 'package:app/common/consts.dart';
import 'package:app/pages/account/bind/accountBindStep1.dart';
import 'package:app/pages/account/bind/accountBindStep2.dart';
import 'package:app/pages/account/bind/accountBindStep3.dart';
import 'package:app/pages/account/bind/accountBindSuccess.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/plugin/PluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AccountBindPage extends StatefulWidget {
  const AccountBindPage(this.service, {Key key}) : super(key: key);
  final AppService service;
  static const String route = '/account/accountBind';

  @override
  State<AccountBindPage> createState() => _AccountBindPageState();
}

class _AccountBindPageState extends State<AccountBindPage> {
  int _step = 0;
  Map _signMessage;
  EthWalletData _ethWalletData;
  KeyPairData _keyPairData;
  BridgeTokenBalance _tokenBalance;
  bool _isAcala;
  String _bindError;
  @override
  initState() {
    super.initState();
    _ethWalletData = widget.service.keyringEVM.current;
    _keyPairData = widget.service.keyring.current;
    _isAcala = (widget.service.plugin is PluginEvm &&
            (widget.service.plugin as PluginEvm).network ==
                para_chain_name_acala) ||
        widget.service.plugin.basic.name == para_chain_name_acala;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBridge();
    });
  }

  _initBridge() async {
    final chain = _isAcala ? 'acala' : 'karura';
    await widget.service.plugin.sdk.api.bridge.init();

    // todo: remove testnet before release
    await widget.service.plugin.sdk.api.bridge.connectFromChains([
      chain
    ], nodeList: {
      'karura': ['wss://karura-dev.aca-dev.network/rpc/ws'],
      'acala': ['wss://acala-dev.aca-dev.network/rpc/ws']
    });
    _subscribeBalance();
    _queryBindAddress();
  }

  _unSubscribeBalance() {
    final chain = _isAcala ? 'acala' : 'karura';
    widget.service.plugin.sdk.api.bridge
        .unsubscribeBalances(chain, _keyPairData.address);
  }

  _subscribeBalance() {
    final chain = _isAcala ? 'acala' : 'karura';
    widget.service.plugin.sdk.api.bridge
        .subscribeBalances(chain, _keyPairData.address, (res) async {
      final balance = res[_isAcala ? 'ACA' : 'KAR'];
      setState(() {
        _tokenBalance = balance;
      });
    });
  }

  void _queryBindAddress() async {
    final chain = _isAcala ? 'acala' : 'karura';
    final subAddress = await widget.service.plugin.sdk.api.bridge.service
        .evalJavascript(
            'bridge.getApi("$chain").query.evmAccounts.accounts("${_ethWalletData.address}")');

    final evmAddress = await widget.service.plugin.sdk.api.bridge.service
        .evalJavascript(
            'bridge.getApi("$chain").query.evmAccounts.evmAddresses("${_keyPairData.address}")');

    if (subAddress == null && evmAddress == null) {
      setState(() {
        _bindError = null;
      });
      return;
    }
    String addressName;
    String address;
    if (subAddress != null && evmAddress != null) {
      if (subAddress == widget.service.keyring.current.address) {
        Navigator.of(context).popAndPushNamed(AccountBindSuccess.route,
            arguments: {'ethAccount': _ethWalletData});
        return;
      }
    } else if (subAddress != null) {
      addressName = "EVM";
      address = Fmt.address(subAddress);
    } else if (evmAddress != null) {
      addressName = "Substrate";
      address = Fmt.address(evmAddress);
    }
    if (subAddress != null || evmAddress != null) {
      setState(() {
        _bindError =
            "The above $addressName address has been bound to $address";
      });
    }
  }

  @override
  dispose() {
    widget.service.plugin.sdk.api.bridge.disconnectFromChains();
    widget.service.plugin.sdk.api.bridge.dispose();
    super.dispose();
  }

  showStep2() {
    final controller =
        BottomSheet.createAnimationController(Navigator.of(context));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _step == 1) {
        setState(() {
          _step = _step - 1;
        });
      }
    });
    final isPlugin =
        (ModalRoute.of(context).settings.arguments as Map)['isPlugin'] == true;
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      transitionAnimationController: controller,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight -
              130,
          width: double.infinity,
          child: AccountBindStep2(
              widget.service, isPlugin, _keyPairData, _ethWalletData),
        );
      },
      context: context,
    ).then((value) {
      if (value != null) {
        setState(() {
          _step = 2;
          _signMessage = value;
        });
      }
    });
  }

  Future<XcmTxConfirmParams> _getTxParams() async {
    final isPlugin =
        (ModalRoute.of(context).settings.arguments as Map)['isPlugin'] == true;
    Map<String, Widget> txDisplayBold = {
      "Substrate Address": Padding(
        padding: const EdgeInsets.only(right: 30),
        child: Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Text(
              _keyPairData.address,
              style: Theme.of(context).textTheme.headline4?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPlugin || UI.isDarkTheme(context)
                      ? Colors.white
                      : const Color(0xFF565554)),
            )),
      ),
      "Binding EVM Account": Padding(
          padding: const EdgeInsets.only(right: 30),
          child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Text(
                '${_signMessage['address']}',
                style: Theme.of(context).textTheme.headline4?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPlugin || UI.isDarkTheme(context)
                        ? Colors.white
                        : const Color(0xFF565554)),
              ))),
    };
    final chain = _isAcala ? 'acala' : 'karura';

    final txHex = await widget.service.plugin.sdk.api.bridge.service.evalJavascript(
        'Promise.all([bridge.getApi("$chain").tx.evmAccounts.claimAccount("${_signMessage['address']}","${_signMessage['signature']}").toHex()])');

    return XcmTxConfirmParams(
        module: 'evmAccounts',
        call: 'claimAccount',
        txTitle: 'Bind account',
        txDisplayBold: txDisplayBold,
        params: [_signMessage['address'], _signMessage['signature']],
        isPlugin: isPlugin,
        isBridge: true,
        txHex: txHex[0],
        chainFrom: _isAcala ? "acala" : "karura",
        sender: _keyPairData,
        feeToken: TokenBalanceData(
            amount: _tokenBalance.available,
            symbol: _tokenBalance.token,
            decimals: _tokenBalance.decimals));
  }

  @override
  Widget build(BuildContext context) {
    final isPlugin =
        (ModalRoute.of(context).settings.arguments as Map)['isPlugin'] == true;
    final title = '${(_isAcala ? "Acala" : "Karura")} EVM+ Claim';

    void backAction() {
      if (_step == 0) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _step = _step - 1;
          if (_step == 1) {
            showStep2();
          }
        });
      }
    }

    return WillPopScope(
        onWillPop: () {
          if (_step == 0) {
            return Future.value(true);
          } else {
            setState(() {
              _step = _step - 1;
              if (_step == 1) {
                showStep2();
              }
            });
          }
          return Future.value(false);
        },
        child: isPlugin
            ? PluginScaffold(
                appBar: PluginAppBar(
                    title: Text(title),
                    centerTitle: true,
                    leading: PluginIconButton(
                        icon: Image.asset(
                          "packages/polkawallet_ui/assets/images/icon_back_plugin.png",
                          width: 9,
                        ),
                        onPressed: () => backAction())),
                body: Padding(
                    padding: const EdgeInsets.all(16), child: _buildBody()))
            : Scaffold(
                appBar: AppBar(
                    title: Text(title),
                    centerTitle: true,
                    elevation: 0,
                    leading: BackBtn(
                      onBack: () => backAction(),
                    )),
                body: Padding(
                    padding: const EdgeInsets.all(16), child: _buildBody())));
  }

  Widget _buildBody() {
    final isPlugin =
        (ModalRoute.of(context).settings.arguments as Map)['isPlugin'] == true;
    return Column(children: [
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return index == _step
                ? Container(
                    width: index == 0
                        ? 144
                        : index == 1
                            ? 119
                            : 137,
                    padding: const EdgeInsets.only(left: 10, top: 6),
                    decoration: BoxDecoration(
                      image: isPlugin || UI.isDarkTheme(context)
                          ? const DecorationImage(
                              image: AssetImage(
                                  "assets/images/big_icon_bg_dark.png"),
                              fit: BoxFit.fill)
                          : const DecorationImage(
                              image: AssetImage(
                                  "assets/images/big_icon_bg_grey.png"),
                              fit: BoxFit.fill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5, top: 2),
                          child: Text(
                            "${index + 1}",
                            style: Theme.of(context).textTheme.button?.copyWith(
                                fontFamily: "TitilliumWeb",
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: isPlugin || UI.isDarkTheme(context)
                                    ? const Color(0xFF242528)
                                    : Colors.white),
                          ),
                        ),
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  index == 0
                                      ? "Binding ${isPlugin ? 'EVM' : 'Substrate'} account"
                                      : index == 1
                                          ? "Create Claim signature"
                                          : "Claim\naccount",
                                  style: Theme.of(context)
                                      .textTheme
                                      .button
                                      ?.copyWith(
                                          fontFamily: "TitilliumWeb",
                                          fontSize: 12,
                                          height: 1.2,
                                          color: isPlugin ||
                                                  UI.isDarkTheme(context)
                                              ? const Color(0xFF242528)
                                              : Colors.white),
                                )))
                      ],
                    ),
                  )
                : Container(
                    width: 48,
                    decoration: BoxDecoration(
                      image: isPlugin || UI.isDarkTheme(context)
                          ? const DecorationImage(
                              image:
                                  AssetImage("assets/images/icon_bg_dark.png"),
                              fit: BoxFit.fill)
                          : const DecorationImage(
                              image:
                                  AssetImage("assets/images/icon_bg_grey.png"),
                              fit: BoxFit.fill),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: Theme.of(context).textTheme.button?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: isPlugin || UI.isDarkTheme(context)
                                ? const Color(0xFF242528)
                                : const Color(0xFFA9A9A9),
                            height: 1.3),
                      ),
                    ),
                  );
          },
          itemCount: 3,
          separatorBuilder: (context, index) => Container(
            width: 8,
          ),
        ),
      ),
      Expanded(
          child: _step == 2
              ? AccountBindStep3(widget.service, isPlugin, _signMessage,
                  _keyPairData, _ethWalletData, () async {
                  final param = await _getTxParams();
                  final result = await Navigator.of(context)
                      .pushNamed(XcmTxConfirmPage.route, arguments: param);
                  if (result != null) {
                    if (isPlugin) {
                      await Navigator.of(context).pushNamed(
                          AccountBindSuccess.route,
                          arguments: {"ethAccount": _ethWalletData});
                    }
                    Navigator.of(context).pop(result);
                  }
                })
              : AccountBindStep1(
                  widget.service,
                  isPlugin,
                  _tokenBalance,
                  _keyPairData,
                  _ethWalletData,
                  _bindError, (keyPairData, ethWalletData) {
                  _unSubscribeBalance();
                  setState(() {
                    _keyPairData = keyPairData;
                    _ethWalletData = ethWalletData;
                    _subscribeBalance();
                    _queryBindAddress();
                  });
                }, () {
                  setState(() {
                    _step = _step + 1;
                    if (_step == 1) {
                      showStep2();
                    }
                  });
                }))
    ]);
  }
}
