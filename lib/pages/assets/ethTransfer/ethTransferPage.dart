import 'dart:convert';

import 'package:app/common/components/flexTextFormField.dart';
import 'package:app/pages/assets/ethTransfer/ethTxConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EthTransferPageParams {
  EthTransferPageParams({
    this.token,
    this.address,
  });
  final TokenBalanceData token;
  final String address;
}

class EthTransferPage extends StatefulWidget {
  const EthTransferPage(this.service, {Key key}) : super(key: key);

  static const String route = '/eth/assets/transfer';
  final AppService service;

  @override
  EthTransferPageState createState() => EthTransferPageState();
}

class EthTransferPageState extends State<EthTransferPage> {
  final _formKey0 = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = TextEditingController();

  EthTransferPageParams pageParams;
  EthWalletData _accountTo;

  String _accountToError;
  String _accountWarn;
  String _amountError;

  int _step = 0;

  TxFeeEstimateResult _fee;

  Future<void> _checkAccountWaring(String address) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    String warn;

    /// check account risk for Polkadot address
    final risk = await WalletApi.getAddressRisk(address);
    if (risk != null && risk['data'] != null) {
      final data = jsonDecode(risk['data']);
      if (data['risk_level'] > 1) {
        warn = data['tag_type_verbose'] == 'Exchange'
            ? dic['bad.risk.cex']
            : ['bad.risk'];
      }
    }

    setState(() {
      _accountWarn = warn;
    });
  }

  Future<void> _onScan() async {
    final to =
        (await Navigator.of(context).pushNamed(ScanPage.route) as QRCodeResult);
    if (to == null) return;

    _updateAccountTo(to.address.address, name: to.address.name);
  }

  Future<void> _onSubmit() async {
    if (_step < 1) {
      if (!_formKey0.currentState.validate()) return;

      setState(() {
        _step += 1;
      });
      return;
    }
    if (_step == 1 && _amountError != null) return;

    final params = EthTransferConfirmPageParams(
        tokenSymbol: pageParams.token.symbol,
        contractAddress:
            pageParams.token.id.startsWith('0x') ? pageParams.token.id : '',
        accountTo: _accountTo,
        amount: double.tryParse(_amountCtrl.text.trim()) ?? '0');
    final res = await Navigator.of(context)
        .pushNamed(EthTransferConfirmPage.route, arguments: params);
    print('eth transfer sending ============================');
    print(res);
  }

  Future<String> _getTxFee({bool isXCM = false, bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final txParams = TxConfirmParams(
      txTitle: '',
      module: 'balances',
      call: 'transfer',
      txDisplay: {},
      params: [
        widget.service.keyring.allWithContacts[0].address,
        '10000000000',
      ],
    );

    final txInfo = TxInfoData(
        txParams.module,
        txParams.call,
        TxSenderData(widget.service.keyring.current.address,
            widget.service.keyring.current.pubKey));

    final fee = await widget.service.plugin.sdk.api.tx
        .estimateFees(txInfo, txParams.params);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  BigInt _getExistAmount(BigInt notTransferable, BigInt existentialDeposit) {
    return notTransferable > BigInt.zero
        ? notTransferable >= existentialDeposit
            ? BigInt.zero
            : existentialDeposit - notTransferable
        : existentialDeposit;
  }

  Future<void> _setMaxAmount(BigInt available, BigInt existAmount) async {
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final fee = await _getTxFee();
    // keep 1.2 * amount of estimated fee left
    final max = available -
        Fmt.balanceInt(fee) -
        (Fmt.balanceInt(fee) ~/ BigInt.from(5));
    if (mounted) {
      setState(() {
        _amountCtrl.text = max > BigInt.zero
            ? Fmt.bigIntToDouble(max, decimals).toStringAsFixed(8)
            : '0';
      });
    }
  }

  Future<void> _updateAccountTo(String address, {String name}) async {
    final acc = EthWalletData()..address = address;
    if (name != null) {
      acc.name = name;
    }

    try {
      final plugin = widget.service.plugin as PluginEvm;
      final res = await Future.wait([
        plugin.sdk.api.service.eth.account.getAddress(address),
        plugin.sdk.api.service.eth.account.getAddressIcons([address])
      ]);
      if (res[1] != null) {
        acc.icon = (res[1] as List)[0][1];
      }

      _checkAccountWaring(address);

      setState(() {
        _accountTo = acc;
      });
    } catch (err) {
      setState(() {
        _accountToError = err.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // _getTxFee();

      final argsObj = (ModalRoute.of(context).settings.arguments as Map) ?? {};
      pageParams = EthTransferPageParams(
          token: TokenBalanceData(
              symbol: argsObj['symbol'] ?? widget.service.pluginEvm.nativeToken,
              id: argsObj['id'],
              decimals: argsObj['decimals']),
          address: argsObj['address']);
      if (pageParams.address != null) {
        _updateAccountTo(pageParams.address);
      } else {
        setState(() {
          _accountTo = widget.service.keyringEVM.current;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.service.plugin as PluginEvm;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final symbol = pageParams?.token?.symbol ?? 'ACA';
    final decimals = pageParams?.token?.decimals ?? 18;

    final connected = plugin.sdk.api.connectedNode != null;

    final available = Fmt.balanceInt(
        (plugin.balances.native?.availableBalance ?? 0).toString());

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.bold);
    final subTitleStyle = Theme.of(context).textTheme.headline5?.copyWith(
        height: 1,
        fontWeight: FontWeight.w300,
        fontSize: 12,
        color:
            UI.isDarkTheme(context) ? Colors.white : const Color(0xBF565554));
    final infoValueStyle = Theme.of(context)
        .textTheme
        .headline5
        .copyWith(fontWeight: FontWeight.w600);

    return WillPopScope(
      onWillPop: () async {
        print(_step);
        if (_step > 0) {
          setState(() {
            _step -= 1;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
            systemOverlayStyle: UI.isDarkTheme(context)
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            title: Text(dic['evm.send.$_step'] ?? ''),
            centerTitle: true,
            actions: <Widget>[
              v3.IconButton(
                  margin: const EdgeInsets.only(right: 8),
                  icon: SvgPicture.asset(
                    'assets/images/scan.svg',
                    color: Theme.of(context).cardColor,
                    width: 24,
                  ),
                  onPressed: _onScan,
                  isBlueBg: true)
            ],
            leading: const BackBtn()),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// step0: send to
                      Visibility(
                          visible: _step == 0,
                          child: Text(dic['from'], style: labelStyle)),
                      Visibility(
                          visible: _step == 0,
                          child: Padding(
                              padding: const EdgeInsets.only(top: 3, bottom: 8),
                              child: AddressFormItem(
                                  widget.service.keyringEVM.current))),
                      Visibility(
                          visible: _step == 0,
                          child: Form(
                            key: _formKey0,
                            child: AddressTextFormField(
                              widget.service.plugin.sdk.api,
                              const [],
                              localEthAccounts: widget
                                  .service.keyringEVM.allWithContacts
                                  .toList(),
                              labelText: dic['to'],
                              labelStyle: labelStyle,
                              hintText: dic['address'],
                              initialValue: _accountTo?.toKeyPairData(),
                              onChanged: (KeyPairData acc) async {
                                _checkAccountWaring(acc.address);
                                setState(() {
                                  _accountTo = EthWalletData()
                                    ..address = acc.address
                                    ..name = acc.name
                                    ..icon = acc.icon;
                                });
                              },
                              sdk: widget.service.plugin.sdk,
                              key: ValueKey<EthWalletData>(_accountTo),
                            ),
                          )),
                      Visibility(
                          visible: _accountToError != null,
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: ToAddressWarning(_accountToError),
                          )),
                      Visibility(
                          visible: _step == 0 &&
                              _accountWarn != null &&
                              _accountToError == null,
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: ToAddressWarning(_accountWarn),
                          )),

                      /// step1: set amount
                      Visibility(
                          visible: _step == 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TokenIcon(
                                pageParams?.token?.id ?? '',
                                widget.service.plugin.tokenIcons,
                                symbol: pageParams?.token?.symbol,
                              ),
                              Text(pageParams?.token?.symbol ?? symbol)
                            ],
                          )),
                      Visibility(
                          visible: _step == 1,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: FlexTextFormField(
                              key: Key(_amountCtrl.text),
                              bottom: Text(
                                '${dic['balance']}: ${Fmt.priceFloorBigInt(
                                  available,
                                  decimals,
                                  lengthMax: 6,
                                )}',
                                style: Theme.of(context).textTheme.headline4,
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                prefix: Container(width: 32, height: 24),
                                suffixIcon: GestureDetector(
                                  child: Container(
                                    margin: EdgeInsets.only(top: 8),
                                    child: Icon(Icons.cancel,
                                        color: Colors.grey, size: 16),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _amountCtrl.text = '';
                                    });
                                  },
                                ),
                              ),
                              inputFormatters: [
                                UI.decimalInputFormatter(decimals)
                              ],
                              controller: _amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                final error = Fmt.validatePrice(v, context);
                                _amountError = error;
                                if (error != null) {
                                  return _amountError;
                                }
                                final input = Fmt.tokenInt(v, decimals);
                                final feeLeft = available - input;
                                if (feeLeft < BigInt.zero) {
                                  _amountError = dic['amount.low'];
                                }

                                return _amountError;
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: v3.Button(
                  title: connected ? dicUI['next'] : 'connecting...',
                  onPressed: connected ? _onSubmit : () => null,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ToAddressWarning extends StatelessWidget {
  const ToAddressWarning(this.message, {Key key}) : super(key: key);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: const Color(0x18FF7847),
          border: Border.all(color: const Color(0xFFFF7847)),
          borderRadius: const BorderRadius.all(Radius.circular(4))),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Image.asset('assets/images/icons/warning.png', width: 32),
          ),
          Flexible(
              child: Text(
            message,
            style: Theme.of(context).textTheme.headline5.copyWith(
                fontSize: UI.getTextSize(13, context),
                fontWeight: FontWeight.bold,
                height: 1.1),
          ))
        ],
      ),
    );
  }
}
