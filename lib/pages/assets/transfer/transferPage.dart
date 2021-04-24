import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferPageParams {
  TransferPageParams({
    this.address,
    this.redirect,
  });
  final String address;
  final String redirect;
}

class TransferPage extends StatefulWidget {
  const TransferPage(this.service);

  static final String route = '/assets/transfer';
  final AppService service;

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData _accountTo;
  bool _keepAlive = true;

  TxFeeEstimateResult _fee;

  Future<void> _onScan() async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address.address;
    acc.name = (to as QRCodeResult).address.name;
    final icon = await widget.service.plugin.sdk.api.account
        .getAddressIcons([acc.address]);
    if (icon != null && icon[0] != null) {
      acc.icon = icon[0][1];
    }
    setState(() {
      _accountTo = acc;
    });
    print(_accountTo.address);
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_formKey.currentState.validate()) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
      return TxConfirmParams(
        txTitle: '${dic['transfer']} $symbol',
        module: 'balances',
        call: _keepAlive ? 'transferKeepAlive' : 'transfer',
        txDisplay: {
          "destination": _accountTo.address,
          "currency": symbol,
          "amount": _amountCtrl.text.trim(),
        },
        params: [
          // params.to
          _accountTo.address,
          // params.amount
          Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
        ],
      );
    }
    return null;
  }

  Future<String> _getTxFee({bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final sender = TxSenderData(widget.service.keyring.current.address,
        widget.service.keyring.current.pubKey);
    final txInfo = TxInfoData('balances', 'transfer', sender);
    final fee = await widget.service.plugin.sdk.api.tx.estimateFees(
        txInfo, [widget.service.keyring.current.address, '10000000000']);
    setState(() {
      _fee = fee;
    });
    return fee.partialFee.toString();
  }

  Future<void> _setMaxAmount(BigInt available, String amountExist) async {
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final fee = await _getTxFee();
    // keep double amount of estimated fee
    final max = available -
        Fmt.balanceInt(fee) * BigInt.two -
        (_keepAlive ? Fmt.balanceInt(amountExist) : BigInt.zero);
    if (mounted) {
      setState(() {
        _amountCtrl.text = max > BigInt.zero
            ? Fmt.bigIntToDouble(max, decimals).toStringAsFixed(8)
            : '0';
      });
    }
  }

  Future<void> _initAccountTo(String address) async {
    final acc = KeyPairData();
    acc.address = address;
    setState(() {
      _accountTo = acc;
    });
    final icon =
        await widget.service.plugin.sdk.api.account.getAddressIcons([address]);
    if (icon != null) {
      final accWithIcon = KeyPairData();
      accWithIcon.address = address;
      accWithIcon.icon = icon[0][1];
      setState(() {
        _accountTo = accWithIcon;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee();

      final TransferPageParams args = ModalRoute.of(context).settings.arguments;
      if (args.address != null) {
        _initAccountTo(args.address);
      } else {
        if (widget.service.keyring.allWithContacts.length > 0) {
          setState(() {
            _accountTo = widget.service.keyring.allWithContacts[0];
          });
        }
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
    return Observer(
      builder: (_) {
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
        final symbol =
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
        final decimals =
            (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

        final available = Fmt.balanceInt(
            (widget.service.plugin.balances.native?.availableBalance ?? 0)
                .toString());

        final amountExist = widget
            .service.plugin.networkConst['balances']['existentialDeposit']
            .toString();
        return Scaffold(
          appBar: AppBar(
            title: Text(dic['transfer']),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                padding: EdgeInsets.only(right: 8),
                icon: SvgPicture.asset(
                  'assets/images/scan.svg',
                  color: Theme.of(context).cardColor,
                  width: 28,
                ),
                onPressed: _onScan,
              )
            ],
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: <Widget>[
                      AddressInputField(
                        widget.service.plugin.sdk.api,
                        widget.service.keyring.allAccounts,
                        label: dic['address'],
                        initialValue: _accountTo,
                        onChanged: (KeyPairData acc) {
                          setState(() {
                            _accountTo = acc;
                          });
                        },
                        key: ValueKey<KeyPairData>(_accountTo),
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: dic['amount'],
                          labelText:
                              '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                            available,
                            decimals,
                            lengthMax: 6,
                          )})',
                          suffix: GestureDetector(
                            child: Text(dic['amount.max'],
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor)),
                            onTap: () => _setMaxAmount(available, amountExist),
                          ),
                        ),
                        inputFormatters: [UI.decimalInputFormatter(decimals)],
                        controller: _amountCtrl,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v.isEmpty) {
                            return dic['amount.error'];
                          }
                          final feeLeft = available -
                              Fmt.tokenInt(v, decimals) -
                              (_keepAlive
                                  ? Fmt.balanceInt(amountExist)
                                  : BigInt.zero);
                          BigInt fee = BigInt.zero;
                          if (feeLeft < Fmt.tokenInt('0.02', decimals) &&
                              _fee?.partialFee != null) {
                            fee = Fmt.balanceInt(_fee.partialFee.toString());
                          }
                          if (feeLeft - fee < BigInt.zero) {
                            return dic['amount.low'];
                          }
                          return null;
                        },
                      ),
                      Container(
                        color: Theme.of(context).canvasColor,
                        margin: EdgeInsets.only(top: 16, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    dic['currency'],
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                        fontSize: 12),
                                  ),
                                ),
                                CurrencyWithIcon(
                                    symbol,
                                    TokenIcon(symbol,
                                        widget.service.plugin.tokenIcons)),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text(dic['amount.exist']),
                            ),
                            TapTooltip(
                              message: dic['amount.exist.msg'],
                              child: Icon(
                                Icons.info,
                                size: 16,
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                            Expanded(child: Container(width: 2)),
                            Text(
                                '${Fmt.balance(amountExist, decimals)} $symbol'),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text(dic['transfer.alive']),
                          ),
                          TapTooltip(
                            message: dic['transfer.alive.msg'],
                            child: Icon(
                              Icons.info,
                              size: 16,
                              color: Theme.of(context).unselectedWidgetColor,
                            ),
                          ),
                          Expanded(child: Container(width: 2)),
                          CupertinoSwitch(
                            value: _keepAlive,
                            onChanged: (res) {
                              setState(() {
                                _keepAlive = res;
                              });
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: TxButton(
                  text: dic['make'],
                  getTxParams: _getTxParams,
                  onFinish: (res) {
                    if (res != null) {
                      Navigator.of(context).pop(res);
                    }
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
