import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_statemine/common/constants.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
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

  PolkawalletPlugin _chainTo;
  KeyPairData _accountTo;
  bool _keepAlive = true;

  String _accountToError;

  TxFeeEstimateResult _fee;

  Future<String> _checkAccountTo(KeyPairData acc) async {
    if (widget.service.keyring.allAccounts
            .indexWhere((e) => e.pubKey == acc.pubKey) >=
        0) {
      return null;
    }

    final addressCheckValid = await widget.service.plugin.sdk.webView
        .evalJavascript('(account.checkAddressFormat != undefined ? {}:null)',
            wrapPromise: false);
    if (addressCheckValid != null) {
      final res = await widget.service.plugin.sdk.api.account
          .checkAddressFormat(acc.address, _chainTo.basic.ss58);
      if (res != null && !res) {
        return I18n.of(context)
            .getDic(i18n_full_dic_ui, 'account')['ss58.mismatch'];
      }
    }
    return null;
  }

  Future<void> _validateAccountTo(KeyPairData acc) async {
    final error = await _checkAccountTo(acc);
    setState(() {
      _accountToError = error;
    });
  }

  Future<void> _onScan() async {
    final to =
        (await Navigator.of(context).pushNamed(ScanPage.route) as QRCodeResult);
    if (to == null) return;

    _updateAccountTo(to.address.address, name: to.address.name);
    print(to.address.address);
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_accountToError == null && _formKey.currentState.validate()) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      /// send XCM tx if cross chain
      if (_chainTo.basic.name != widget.service.plugin.basic.name) {
        final isToAca = _chainTo.basic.name == 'karura' ||
            _chainTo.basic.name == plugin_name_acala;
        final isToParent = _chainTo.basic.name == relay_chain_name_ksm ||
            _chainTo.basic.name == relay_chain_name_dot;
        // paramsX: [dest, beneficiary, assets, dest_weight]
        final paramsX = [
          {
            'X1': isToParent
                ? 'Parent'
                : {'Parachain': _chainTo.basic.parachainId}
          },
          {
            'X1': {
              'AccountId32': {'id': _accountTo.address, 'network': 'Any'}
            }
          },
          [
            {
              'ConcreteFungible': {
                'amount':
                    Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
                'id': isToParent ? {'X1': 'Parent'} : 'Here'
              }
            }
          ],
          xcm_dest_weight_ksm
        ];
        return TxConfirmParams(
          txTitle: '${dic['transfer']} $symbol (${dic['cross.chain']})',
          module: isToParent ? 'polkadotXcm' : 'xcmPallet',
          call: isToAca ? 'reserveTransferAssets' : 'teleportAssets',
          txDisplay: {
            "chain": _chainTo.basic.name,
            "destination": _accountTo.address,
            "currency": symbol,
            "amount": _amountCtrl.text.trim(),
          },
          params: paramsX,
        );
      }

      /// else send normal transfer
      // params: [to, amount]
      final params = [
        _accountTo.address,
        Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
      ];
      return TxConfirmParams(
        txTitle: '${dic['transfer']} $symbol',
        module: 'balances',
        call: _keepAlive ? 'transferKeepAlive' : 'transfer',
        txDisplay: {
          "destination": _accountTo.address,
          "currency": symbol,
          "amount": _amountCtrl.text.trim(),
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

    final isStatemint =
        widget.service.plugin.basic.name == network_name_statemine ||
            widget.service.plugin.basic.name == network_name_statemint;

    final sender = TxSenderData(widget.service.keyring.current.address,
        widget.service.keyring.current.pubKey);
    final txInfo = TxInfoData(
        isXCM ? 'xcmPallet' : 'balances',
        isXCM
            ? isStatemint
                ? 'teleportAssets'
                : 'reserveTransferAssets'
            : 'transfer',
        sender);
    final fee = await widget.service.plugin.sdk.api.tx.estimateFees(
        txInfo,
        isXCM
            ? [
                {
                  'X1': isStatemint ? 'Parent' : {'Parachain': '2000'}
                },
                {
                  'X1': {
                    'AccountId32': {
                      'id': widget.service.keyring.current.address,
                      'network': 'Any'
                    }
                  }
                },
                [
                  {
                    'ConcreteFungible': {
                      'amount': xcm_dest_weight_ksm,
                      'id': 'Here'
                    }
                  }
                ],
                xcm_dest_weight_ksm
              ]
            : [widget.service.keyring.current.address, '10000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  Future<void> _setMaxAmount(BigInt available, BigInt amountExist) async {
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final fee = await _getTxFee();
    // keep 1.2 * amount of estimated fee left
    final max = available -
        Fmt.balanceInt(fee) -
        (Fmt.balanceInt(fee) ~/ BigInt.from(5)) -
        (_keepAlive ? amountExist : BigInt.zero);
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
      _checkAccountTo(acc),
    ]);
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

  /// only support：
  /// Kusama -> Karura
  /// Kusama -> Statemine
  /// Statemine -> Kusama
  void _onSelectChain() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final isStateMint =
        widget.service.plugin.basic.name == network_name_statemine ||
            widget.service.plugin.basic.name == network_name_statemine;

    final allPlugins = widget.service.allPlugins.toList();

    if (isStateMint) {
      allPlugins.retainWhere((e) =>
          e.basic.name == relay_chain_name_ksm ||
          e.basic.name == network_name_statemine ||
          e.basic.name == network_name_statemint);
    } else {
      allPlugins.retainWhere((e) => e.basic.isXCMSupport);
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(dic['cross.para.select']),
        actions: allPlugins.map((e) {
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: e.basic.icon,
                  ),
                ),
                Text(
                  e.basic.name.toUpperCase(),
                )
              ],
            ),
            onPressed: () {
              if (e.basic.name != _chainTo.basic.name) {
                setState(() {
                  _chainTo = e;
                });
                _validateAccountTo(_accountTo);

                // update estimated tx fee if switch ToChain
                _getTxFee(
                    isXCM: e.basic.name != relay_chain_name_ksm, reload: true);
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee();

      final TransferPageParams args = ModalRoute.of(context).settings.arguments;
      if (args.address != null) {
        _updateAccountTo(args.address);
      } else {
        if (widget.service.keyring.allWithContacts.length > 0) {
          setState(() {
            _accountTo = widget.service.keyring.allWithContacts[0];
          });
        }
      }

      setState(() {
        _chainTo = widget.service.plugin;
      });
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

        final canCrossChain =
            widget.service.plugin.basic.name == relay_chain_name_ksm ||
                widget.service.plugin.basic.name == network_name_statemine ||
                widget.service.plugin.basic.name == network_name_statemint;

        final destChainName = _chainTo?.basic?.name ?? 'karura';
        final isCrossChain = widget.service.plugin.basic.name != destChainName;

        final existDeposit = Fmt.balanceInt(widget
            .service.plugin.networkConst['balances']['existentialDeposit']
            .toString());
        final destExistDeposit = isCrossChain
            ? Fmt.balanceInt(xcm_send_fees[destChainName]['existentialDeposit'])
            : BigInt.zero;
        final destFee = isCrossChain
            ? Fmt.balanceInt(xcm_send_fees[destChainName]['fee'])
            : BigInt.zero;

        final colorGrey = Theme.of(context).unselectedWidgetColor;
        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['transfer']} $symbol'),
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
                          widget.service.keyring.allWithContacts,
                          label: dic['cross.to'],
                          initialValue: _accountTo,
                          onChanged: (KeyPairData acc) async {
                            final accValid = await _checkAccountTo(acc);
                            setState(() {
                              _accountTo = acc;
                              _accountToError = accValid;
                            });
                          },
                          key: ValueKey<KeyPairData>(_accountTo),
                        ),
                        _accountToError != null
                            ? Container(
                                margin: EdgeInsets.only(top: 4),
                                child: Text(_accountToError,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.red)),
                              )
                            : Container(),
                        canCrossChain
                            ? GestureDetector(
                                child: Container(
                                  color: Theme.of(context).canvasColor,
                                  margin: EdgeInsets.only(top: 16, bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          dic['to.chain'],
                                          style: TextStyle(
                                              color: colorGrey, fontSize: 12),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 8),
                                                width: 32,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  child: _chainTo?.basic?.icon,
                                                ),
                                              ),
                                              Text(destChainName.toUpperCase())
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              isCrossChain
                                                  ? TextTag(dic['cross.chain'],
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      color: _chainTo?.basic
                                                              ?.primaryColor ??
                                                          colorGrey)
                                                  : Container(),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 18,
                                                color: colorGrey,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: _onSelectChain,
                              )
                            : Container(),
                        TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                              onTap: () =>
                                  _setMaxAmount(available, existDeposit),
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
                            final input = Fmt.tokenInt(v, decimals);
                            final feeLeft = available -
                                input -
                                (_keepAlive ? existDeposit : BigInt.zero);
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
                        isCrossChain
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(dic['cross.exist']),
                                    ),
                                    TapTooltip(
                                      message: dic['amount.exist.msg'],
                                      child: Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                      ),
                                    ),
                                    Expanded(child: Container(width: 2)),
                                    Text(
                                        '${Fmt.priceCeilBigInt(destExistDeposit, decimals, lengthMax: 6)} $symbol'),
                                  ],
                                ),
                              )
                            : Container(),
                        isCrossChain
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(dic['cross.fee']),
                                    ),
                                    Expanded(child: Container(width: 2)),
                                    Text(
                                        '${Fmt.priceCeilBigInt(destFee, decimals, lengthMax: 6)} $symbol'),
                                  ],
                                ),
                              )
                            : Container(),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
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
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
                                ),
                              ),
                              Expanded(child: Container(width: 2)),
                              Text(
                                  '${Fmt.priceCeilBigInt(existDeposit, decimals, lengthMax: 6)} $symbol'),
                            ],
                          ),
                        ),
                        _fee?.partialFee != null
                            ? Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(dic['amount.fee']),
                                    ),
                                    Expanded(child: Container(width: 2)),
                                    Text(
                                        '${Fmt.priceCeilBigInt(Fmt.balanceInt(_fee?.partialFee?.toString()), decimals, lengthMax: 6)} $symbol'),
                                  ],
                                ),
                              )
                            : Container(),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          child: Row(
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
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
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
          ),
        );
      },
    );
  }
}
