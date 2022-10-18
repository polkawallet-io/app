import 'dart:convert';

import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferPageParams {
  TransferPageParams({
    this.address,
  });
  final String address;
}

class TransferPage extends StatefulWidget {
  const TransferPage(this.service, {Key key}) : super(key: key);

  static const String route = '/assets/transfer';
  final AppService service;

  @override
  TransferPageState createState() => TransferPageState();
}

class TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = TextEditingController();

  KeyPairData _accountTo;
  bool _keepAlive = true;

  String _accountToError;
  String _accountWarn;

  TxFeeEstimateResult _fee;

  Future<String> _checkBlackList(KeyPairData acc) async {
    final addresses = await widget.service.plugin.sdk.api.account
        .decodeAddress([acc.address]);
    if (addresses != null) {
      final pubKey = addresses.keys.toList()[0];
      if (widget.service.plugin.sdk.blackList.indexOf(pubKey) > -1) {
        return I18n.of(context)
            .getDic(i18n_full_dic_app, 'account')['bad.scam'];
      }
    }
    return null;
  }

  Future<String> _validateAccountTo(KeyPairData acc) async {
    final blackListCheck = await _checkBlackList(acc);
    if (blackListCheck != null) return blackListCheck;

    return null;
  }

  Future<void> _checkAccountWaring(KeyPairData acc) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final dicUI = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    String warn;

    /// check account risk for Polkadot address
    if (widget.service.plugin.basic.name == relay_chain_name_dot) {
      final risk = await WalletApi.getAddressRisk(acc.address);
      if (risk != null && risk['data'] != null) {
        final data = jsonDecode(risk['data']);
        if (data['risk_level'] > 1) {
          warn = data['tag_type_verbose'] == 'Exchange'
              ? dic['bad.risk.cex']
              : ['bad.risk'];
        }
      }
    }

    /// check account format
    if (warn == null &&
        widget.service.keyring.allAccounts
                .indexWhere((e) => e.pubKey == acc.pubKey) <
            -1) {
      final addressCheckValid = await widget.service.plugin.sdk.webView
          .evalJavascript('(account.checkAddressFormat != undefined ? {}:null)',
              wrapPromise: false);
      if (addressCheckValid != null) {
        final res = await widget.service.plugin.sdk.api.account
            .checkAddressFormat(acc.address, widget.service.plugin.basic.ss58);
        if (res != null && !res) {
          warn = dicUI['ss58.mismatch'];
        }
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

    _updateAccountTo(to.address.address,
        name: to.address.name.isNotEmpty
            ? to.address.name
            : Fmt.address(to.address.address));
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_accountToError == null && _formKey.currentState.validate()) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      // params: [to, amount]
      final params = [
        _accountTo.address,
        Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
      ];
      return TxConfirmParams(
        txTitle: '${dic['transfer']} $symbol',
        module: 'balances',
        call: _keepAlive ? 'transferKeepAlive' : 'transfer',
        txDisplayBold: {
          dic['to']: Row(
            children: [
              AddressIcon(_accountTo.address, svg: _accountTo.icon),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 16, 0, 16),
                  child: Text(
                    Fmt.address(_accountTo.address, pad: 8),
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
            ],
          ),
          dic['amount']: Text(
            '${_amountCtrl.text.trim()} $symbol',
            style: Theme.of(context).textTheme.headline1,
          ),
        },
        params: params,
      );
    }
    return null;
  }

  Future<String> _getTxFee({bool isXCM = false, bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    TxConfirmParams txParams;
    if (_fee == null) {
      txParams = TxConfirmParams(
        txTitle: '',
        module: 'balances',
        call: _keepAlive ? 'transferKeepAlive' : 'transfer',
        txDisplay: {},
        params: [
          widget.service.keyring.allWithContacts[0].address,
          '10000000000',
        ],
      );
    } else {
      txParams = await _getTxParams();
    }

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
        (Fmt.balanceInt(fee) ~/ BigInt.from(5)) -
        (_keepAlive ? existAmount : BigInt.zero);
    if (mounted) {
      setState(() {
        _amountCtrl.text = max > BigInt.zero
            ? Fmt.bigIntToDouble(max, decimals).toStringAsFixed(8)
            : '0';
      });
    }
  }

  Future<void> _updateAccountTo(String address, {String name}) async {
    final acc = KeyPairData();
    acc.address = address;
    if (name != null) {
      acc.name = name;
    }
    setState(() {
      _accountTo = acc;
    });

    final res = await Future.wait([
      widget.service.plugin.sdk.api.account.getAddressIcons([acc.address]),
      _validateAccountTo(acc),
    ]);

    if (res[1] == null) {
      _checkAccountWaring(acc);
    }

    if (res != null && res[0] != null) {
      final accWithIcon = KeyPairData();
      accWithIcon.address = address;
      if (name != null) {
        accWithIcon.name = name;
      }

      final List icon = res[0];
      accWithIcon.icon = icon[0][1];

      setState(() {
        _accountTo = accWithIcon;
        _accountToError = res[1];
      });
    }
  }

  void _onSwitchCheckAlive(bool res, BigInt notTransferable) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    if (!res) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return PolkawalletAlertDialog(
            title: Text(dic['note']),
            content: Text(dic['note.msg1']),
            actions: <Widget>[
              PolkawalletActionSheetAction(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_ui, 'common')['cancel']),
                onPressed: () => Navigator.of(context).pop(),
              ),
              PolkawalletActionSheetAction(
                isDefaultAction: true,
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop();

                  if (notTransferable > BigInt.zero) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PolkawalletAlertDialog(
                          title: Text(dic['note']),
                          content: Text(dic['note.msg2']),
                          actions: <Widget>[
                            CupertinoButton(
                              child: Text(I18n.of(context)
                                  .getDic(i18n_full_dic_ui, 'common')['ok']),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    setState(() {
                      _keepAlive = res;
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _keepAlive = res;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      final TransferPageParams args = ModalRoute.of(context).settings.arguments;
      if (args?.address != null) {
        _updateAccountTo(args.address);
      } else {
        setState(() {
          _accountTo = widget.service.keyring.current;
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
    return Observer(
      builder: (_) {
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
        final symbol =
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
        final decimals =
            (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

        final connected = widget.service.plugin.sdk.api.connectedNode != null;

        final available = Fmt.balanceInt(
            (widget.service.plugin.balances.native?.availableBalance ?? 0)
                .toString());
        final notTransferable = Fmt.balanceInt(
                (widget.service.plugin.balances.native?.reservedBalance ?? 0)
                    .toString()) +
            Fmt.balanceInt(
                (widget.service.plugin.balances.native?.lockedBalance ?? 0)
                    .toString());

        final existDeposit = Fmt.balanceInt(
            ((widget.service.plugin.networkConst['balances'] ??
                        {})['existentialDeposit'] ??
                    0)
                .toString());
        final existAmount = _getExistAmount(notTransferable, existDeposit);

        final labelStyle = Theme.of(context)
            .textTheme
            .headline4
            ?.copyWith(fontWeight: FontWeight.bold);
        final subTitleStyle = Theme.of(context).textTheme.headline5?.copyWith(
            height: 1,
            fontWeight: FontWeight.w300,
            fontSize: 12,
            color: UI.isDarkTheme(context)
                ? Colors.white
                : const Color(0xBF565554));
        final infoValueStyle = Theme.of(context)
            .textTheme
            .headline5
            .copyWith(fontWeight: FontWeight.w600);
        return Scaffold(
          appBar: AppBar(
              systemOverlayStyle: UI.isDarkTheme(context)
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              title: Text('${dic['transfer']} $symbol'),
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
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dic['from'], style: labelStyle),
                                  Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: AddressFormItem(
                                          widget.service.keyring.current)),
                                  Container(height: 8.h),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AddressTextFormField(
                                          widget.service.plugin.sdk.api,
                                          widget.service.keyring.allWithContacts
                                              .toList(),
                                          labelText: dic['cross.to'],
                                          labelStyle: labelStyle,
                                          hintText: dic['address'],
                                          initialValue: _accountTo,
                                          onChanged: (KeyPairData acc) async {
                                            final accValid =
                                                await _validateAccountTo(acc);
                                            if (accValid == null) {
                                              _checkAccountWaring(acc);
                                            }
                                            setState(() {
                                              _accountTo = acc;
                                              _accountToError = accValid;
                                            });
                                          },
                                          sdk: widget.service.plugin.sdk,
                                          key:
                                              ValueKey<KeyPairData>(_accountTo),
                                        ),
                                        Visibility(
                                            visible: _accountToError != null,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              child: ToAddressWarning(
                                                  _accountToError),
                                            )),
                                        Visibility(
                                            visible: _accountWarn != null &&
                                                _accountToError == null,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              child: ToAddressWarning(
                                                  _accountWarn),
                                            )),
                                        Container(height: 10.h),
                                        v3.TextInputWidget(
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          decoration: v3.InputDecorationV3(
                                            hintText: dic['amount.hint'],
                                            labelText:
                                                '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                                              available,
                                              decimals,
                                              lengthMax: 6,
                                            )})',
                                            labelStyle: labelStyle,
                                            suffix: GestureDetector(
                                              child: Text(dic['amount.max'],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .toggleableActiveColor)),
                                              onTap: () => _setMaxAmount(
                                                  available, existAmount),
                                            ),
                                          ),
                                          inputFormatters: [
                                            UI.decimalInputFormatter(decimals)
                                          ],
                                          controller: _amountCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          validator: (v) {
                                            final error =
                                                Fmt.validatePrice(v, context);
                                            if (error != null) {
                                              return error;
                                            }
                                            final input =
                                                Fmt.tokenInt(v, decimals);
                                            final feeLeft = available -
                                                input -
                                                (_keepAlive
                                                    ? existAmount
                                                    : BigInt.zero);
                                            BigInt fee = BigInt.zero;
                                            if (feeLeft <
                                                    Fmt.tokenInt(
                                                        '0.02', decimals) &&
                                                _fee?.partialFee != null) {
                                              fee = Fmt.balanceInt(
                                                  _fee.partialFee.toString());
                                            }
                                            if (feeLeft - fee < BigInt.zero) {
                                              return dic['amount.low'];
                                            }
                                            return null;
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 20.h, bottom: 7.h)),
                                ])),
                        RoundedCard(
                          margin: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              Column(children: [
                                Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Container(
                                              padding: const EdgeInsets.only(
                                                  right: 60),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(dic['amount.exist'],
                                                      style:
                                                          labelStyle?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400)),
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 2),
                                                      child: Text(
                                                        dic['amount.exist.msg'],
                                                        style: subTitleStyle
                                                            ?.copyWith(
                                                                height: 1.3),
                                                      )),
                                                ],
                                              )),
                                        ),
                                        Text(
                                            '${Fmt.priceCeilBigInt(existDeposit, decimals, lengthMax: 6)} $symbol',
                                            style: infoValueStyle),
                                      ],
                                    )),
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Divider(height: 1))
                              ]),
                              Visibility(
                                  visible: _fee?.partialFee != null,
                                  child: Column(children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4),
                                              child: Text(dic['amount.fee'],
                                                  style: labelStyle?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w400)),
                                            ),
                                          ),
                                          Text(
                                              '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")), decimals, lengthMax: 6)} $symbol',
                                              style: infoValueStyle),
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(height: 1))
                                  ])),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Container(
                                          padding:
                                              const EdgeInsets.only(right: 60),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(dic['transfer.alive'],
                                                  style: labelStyle?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w400)),
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2),
                                                  child: Text(
                                                    dic['transfer.alive.msg'],
                                                    style: subTitleStyle
                                                        ?.copyWith(height: 1.3),
                                                  )),
                                            ],
                                          )),
                                    ),
                                    v3.CupertinoSwitch(
                                      value: _keepAlive,
                                      // account is not allow_death if it has
                                      // locked/reserved balances
                                      onChanged: (v) => _onSwitchCheckAlive(
                                          v, notTransferable),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TxButton(
                    text: connected ? dic['make'] : 'connecting...',
                    getTxParams: connected ? _getTxParams : () => null,
                    onFinish: (res) {
                      if (res != null) {
                        Navigator.of(context).pop(res);
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
