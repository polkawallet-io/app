import 'dart:math';

import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
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

  TxConfirmParams _getTxParams() {
    if (_formKey.currentState.validate()) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final symbol = widget.service.plugin.networkState.tokenSymbol;
      final decimals = widget.service.plugin.networkState.tokenDecimals;
      return TxConfirmParams(
        txTitle: '${dic['transfer']} $symbol',
        module: 'balances',
        call: 'transfer',
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
      final TransferPageParams args = ModalRoute.of(context).settings.arguments;
      if (args.address != null) {
        _initAccountTo(args.address);
      } else {
        if (widget.service.keyring.optionals.length > 0) {
          setState(() {
            _accountTo = widget.service.keyring.optionals[0];
          });
        }
        // else if (widget.store.settings.contactList.length > 0) {
        //   setState(() {
        //     _accountTo = widget.store.settings.contactList[0];
        //   });
        // }
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
        final decimals = widget.service.plugin.networkState.tokenDecimals;
        final symbol = widget.service.plugin.networkState.tokenSymbol;

        final available = Fmt.balanceInt(
            widget.service.plugin.balances.native.availableBalance.toString());

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['transfer']),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                icon: SvgPicture.asset(
                  'assets/images/scan.svg',
                  color: Theme.of(context).cardColor,
                  width: 20,
                ),
                onPressed: _onScan,
              )
            ],
          ),
          body: SafeArea(
            child: Column(
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
                          ),
                          inputFormatters: [UI.decimalInputFormatter(decimals)],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v.isEmpty) {
                              return dic['amount.error'];
                            }
                            if (double.parse(v.trim()) >=
                                available / BigInt.from(pow(10, decimals)) -
                                    0.001) {
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
                                  Text(
                                    dic['currency'],
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .unselectedWidgetColor),
                                  ),
                                  CurrencyWithIcon(symbol,
                                      widget.service.plugin.tokenIcons[symbol]),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              )
                            ],
                          ),
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
                    onFinish: (success) {
                      if (success ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
