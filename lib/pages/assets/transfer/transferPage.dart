import 'package:app/common/components/cupertinoAlertDialogWithCheckbox.dart';
import 'package:app/common/components/jumpToLink.dart';
import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_chainx/common/components/UI.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
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
import 'package:polkawallet_ui/utils/index.dart' as polkawallet_ui;

class TransferPageParams {
  TransferPageParams({
    this.address,
    this.chainTo,
  });
  final String address;
  final String chainTo;
}

const relay_chain_name_polkadot = 'polkadot';

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
  List<KeyPairData> _accountOptions = [];
  bool _keepAlive = true;

  String _accountToError;

  TxFeeEstimateResult _fee;
  List _xcmEnabledChains;

  bool _submitting = false;

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

  Future<String> _checkAccountTo(KeyPairData acc) async {
    final blackListCheck = await _checkBlackList(acc);
    if (blackListCheck != null) return blackListCheck;

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
  }

  bool _isToParaChain() {
    return _chainTo.basic.name != relay_chain_name_ksm &&
        _chainTo.basic.name != relay_chain_name_dot &&
        _chainTo.basic.name != para_chain_name_statemine &&
        _chainTo.basic.name != para_chain_name_statemint;
  }

  TxConfirmParams _getDotAcalaBridgeTxParams() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    return TxConfirmParams(
      txTitle: '${dic['transfer']} $symbol (${dic['cross.chain']})',
      module: 'balances',
      call: 'transfer',
      txDisplay: {
        dic['to.chain']: _chainTo.basic.name,
      },
      txDisplayBold: {
        dic['amount']: Text(
          _amountCtrl.text.trim() + ' $symbol',
          style: Theme.of(context).textTheme.headline1,
        ),
        dic['to']: Row(
          children: [
            AddressIcon(_accountTo.address, svg: _accountTo.icon),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                child: Text(
                  Fmt.address(_accountTo.address, pad: 8),
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
            ),
          ],
        ),
      },
      params: [
        bridge_account[_chainTo.basic.name],
        Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
      ],
    );
  }

  Future<TxConfirmParams> _getTxParams() async {
    if (_accountToError == null &&
        _formKey.currentState.validate() &&
        !_submitting) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      /// send XCM tx if cross chain
      if (_chainTo.basic.name != widget.service.plugin.basic.name) {
        final isToParaChain = _isToParaChain();

        final isToParent = _chainTo.basic.name == relay_chain_name_ksm ||
            _chainTo.basic.name == relay_chain_name_dot;

        final txModule = isToParent ? 'polkadotXcm' : 'xcmPallet';
        final txCall =
            isToParaChain ? 'reserveTransferAssets' : 'limitedTeleportAssets';

        final amount =
            Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString();

        String destPubKey = _accountTo.pubKey;
        // we need to decode address for the pubKey here
        if (destPubKey == null || destPubKey.isEmpty) {
          setState(() {
            _submitting = true;
          });
          final pk = await widget.service.plugin.sdk.api.account
              .decodeAddress([_accountTo.address]);
          setState(() {
            _submitting = false;
          });
          if (pk == null) return null;

          destPubKey = pk.keys.toList()[0];
        }

        List paramsX;
        if (isToParaChain) {
          /// this is KSM/DOT transfer RelayChain <-> Acala/Karura
          /// paramsX: [dest, beneficiary, assets, dest_weight]
          final dest = {
            'X1': {'Parachain': _chainTo.basic.parachainId}
          };
          final beneficiary = {
            'X1': {
              'AccountId32': {'id': destPubKey, 'network': 'Any'}
            }
          };
          final assets = [
            {
              'ConcreteFungible': {'amount': amount}
            }
          ];
          paramsX = [
            {'V0': dest},
            {'V0': beneficiary},
            {'V0': assets},
            0
          ];
        } else {
          /// this is KSM/DOT transfer RelayChain <-> ParaChain
          /// paramsX: [dest, beneficiary, assets, fee_asset_item, dest_weight]
          final dest = isToParent
              ? {'interior': 'Here', 'parents': 1}
              : {
                  'interior': {
                    'X1': {'Parachain': _chainTo.basic.parachainId}
                  },
                  'parents': 0
                };
          final beneficiary = {
            'interior': {
              'X1': {
                'AccountId32': {'id': destPubKey, 'network': 'Any'}
              }
            },
            'parents': 0
          };
          final assets = [
            {
              'fun': {'Fungible': amount},
              'id': {
                'Concrete': {'interior': 'Here', 'parents': isToParent ? 1 : 0}
              },
            }
          ];
          paramsX = [
            {'V1': dest},
            {'V1': beneficiary},
            {'V1': assets},
            0,
            'Unlimited'
          ];
        }
        return TxConfirmParams(
          txTitle: '${dic['transfer']} $symbol (${dic['cross.chain']})',
          module: txModule,
          call: txCall,
          txDisplay: {
            dic['to.chain']: _chainTo.basic.name,
          },
          txDisplayBold: {
            dic['amount']: Text(
              _amountCtrl.text.trim() + ' $symbol',
              style: Theme.of(context).textTheme.headline1,
            ),
            dic['to']: Row(
              children: [
                AddressIcon(_accountTo.address, svg: _accountTo.icon),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                    child: Text(
                      Fmt.address(_accountTo.address, pad: 8),
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ),
              ],
            ),
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
        txDisplayBold: {
          dic['to']: Row(
            children: [
              AddressIcon(_accountTo.address, svg: _accountTo.icon),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                  child: Text(
                    Fmt.address(_accountTo.address, pad: 8),
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
            ],
          ),
          dic['amount']: Text(
            _amountCtrl.text.trim() + ' $symbol',
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
  ///
  /// DOT from polkadot to acala with acala bridge
  void _onSelectChain() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final allPlugins = widget.service.allPlugins.toList();
    allPlugins.retainWhere((e) {
      return [widget.service.plugin.basic.name, ..._xcmEnabledChains]
              .indexOf(e.basic.name) >
          -1;
    });

    showCupertinoModalPopup(
      context: context,
      builder: (_) => PolkawalletActionSheet(
        title: Text(dic['cross.para.select']),
        actions: allPlugins.map((e) {
          return PolkawalletActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
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
            onPressed: () async {
              if (e.basic.name != _chainTo.basic.name) {
                // set ss58 of _chainTo so we can get according address
                // from AddressInputField
                widget.service.keyring.setSS58(e.basic.ss58);
                final options = widget.service.keyring.allWithContacts.toList();
                widget.service.keyring
                    .setSS58(widget.service.plugin.basic.ss58);
                setState(() {
                  _chainTo = e;
                  _accountOptions = options;

                  if (e.basic.name != widget.service.plugin.basic.name) {
                    _accountTo = widget.service.keyring.current;
                  }
                });

                _validateAccountTo(_accountTo);

                if (_amountCtrl.text.trim().toString().length > 0) {
                  // update estimated tx fee if switch ToChain
                  _getTxFee(
                      isXCM: e.basic.name != relay_chain_name_ksm,
                      reload: true);
                }
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
        cancelButton: PolkawalletActionSheetAction(
          child: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _showAcalaBridgeAlert() async {
    await showCupertinoDialog(
        context: context,
        builder: (_) {
          final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
          return PolkawalletAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dic['dot.bridge']),
                JumpToLink(
                  'https://wiki.acala.network/acala/get-started/acalas-dot-bridge',
                  text: '',
                )
              ],
            ),
            content: CupertinoAlertDialogContentWithCheckbox(
              content: Text(dic['dot.bridge.info']),
            ),
          );
        });
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

      final xcmEnabledChains = await widget.service.store.settings
          .getXcmEnabledChains(widget.service.plugin.basic.name);
      setState(() {
        _accountOptions = widget.service.keyring.allWithContacts.toList();
        _xcmEnabledChains = xcmEnabledChains;

        if (args?.chainTo != null) {
          final chainToIndex = xcmEnabledChains.indexOf(args.chainTo);
          if (chainToIndex > -1) {
            _chainTo = widget.service.allPlugins
                .firstWhere((e) => e.basic.name == args.chainTo);
            _accountTo = widget.service.keyring.current;
            return;
          }
        }
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

        final canCrossChain =
            _xcmEnabledChains != null && _xcmEnabledChains.length > 0;

        final destChainName = _chainTo?.basic?.name ?? 'karura';
        final isCrossChain = widget.service.plugin.basic.name != destChainName;

        final existDeposit = Fmt.balanceInt(
            ((widget.service.plugin.networkConst['balances'] ??
                        {})['existentialDeposit'] ??
                    0)
                .toString());
        final existAmount = _getExistAmount(notTransferable, existDeposit);

        final destExistDeposit = isCrossChain
            ? Fmt.balanceInt(xcm_send_fees[destChainName]['existentialDeposit'])
            : BigInt.zero;
        final destFee = isCrossChain
            ? Fmt.balanceInt(xcm_send_fees[destChainName]['fee'])
            : BigInt.zero;

        final colorGrey = Theme.of(context).unselectedWidgetColor;

        final labelStyle = Theme.of(context)
            .textTheme
            .headline4
            ?.copyWith(fontWeight: FontWeight.bold);
        final subTitleStyle = Theme.of(context)
            .textTheme
            .headline6
            ?.copyWith(height: 1, fontWeight: FontWeight.w300);
        final infoValueStyle = Theme.of(context)
            .textTheme
            .headline5
            .copyWith(fontWeight: FontWeight.w600);
        return Scaffold(
          appBar: AppBar(
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              title: Text('${dic['transfer']} $symbol'),
              centerTitle: true,
              actions: <Widget>[
                v3.IconButton(
                    margin: EdgeInsets.only(right: 8),
                    icon: SvgPicture.asset(
                      'assets/images/scan.svg',
                      color: Theme.of(context).cardColor,
                      width: 23,
                    ),
                    onPressed: _onScan,
                    isBlueBg: true)
              ],
              leading: BackBtn()),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
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
                                      padding: EdgeInsets.only(top: 3),
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
                                          _accountOptions,
                                          labelText: dic['cross.to'],
                                          labelStyle: labelStyle,
                                          hintText: dic['address'],
                                          initialValue: _accountTo,
                                          onChanged: (KeyPairData acc) async {
                                            final accValid =
                                                await _checkAccountTo(acc);
                                            setState(() {
                                              _accountTo = acc;
                                              _accountToError = accValid;
                                            });
                                          },
                                          key:
                                              ValueKey<KeyPairData>(_accountTo),
                                        ),
                                        Visibility(
                                            visible: _accountToError != null,
                                            child: Container(
                                              margin: EdgeInsets.only(top: 4),
                                              child: Text(_accountToError ?? "",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .caption
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .errorColor)),
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
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true),
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
                                  Visibility(
                                      visible: canCrossChain,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              dic['to.chain'],
                                              style: labelStyle,
                                            ),
                                          ),
                                          GestureDetector(
                                            child: RoundedCard(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 9.h,
                                                  horizontal: 16.w),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Row(
                                                    children: <Widget>[
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            right: 8),
                                                        width: 32,
                                                        height: 32,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(32),
                                                          child: _chainTo
                                                              ?.basic?.icon,
                                                        ),
                                                      ),
                                                      Text(
                                                          destChainName
                                                              .toUpperCase(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .headline4)
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Visibility(
                                                          visible: isCrossChain,
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .fromLTRB(15.w,
                                                                    0, 15.w, 4),
                                                            height: 24,
                                                            margin:
                                                                EdgeInsets.only(
                                                                    right: 8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .transparent,
                                                              image: DecorationImage(
                                                                  image: AssetImage(
                                                                      "assets/images/icon_bg_2.png"),
                                                                  fit: BoxFit
                                                                      .contain),
                                                            ),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              dic['cross.chain'],
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .cardColor,
                                                                fontSize: polkawallet_ui
                                                                    .UI
                                                                    .getTextSize(
                                                                        12,
                                                                        context),
                                                                fontFamily: polkawallet_ui
                                                                    .UI
                                                                    .getFontFamily(
                                                                        'TitilliumWeb',
                                                                        context),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          )),
                                                      Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 18,
                                                        color: colorGrey,
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            onTap: _onSelectChain,
                                          ),
                                        ],
                                      ))
                                ])),
                        RoundedCard(
                          margin: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              Visibility(
                                  visible: isCrossChain,
                                  child: Column(children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Container(
                                                padding:
                                                    EdgeInsets.only(right: 40),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(dic['cross.exist'],
                                                        style: labelStyle
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400)),
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.only(
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
                                          Expanded(
                                              flex: 0,
                                              child: Text(
                                                  '${Fmt.priceCeilBigInt(destExistDeposit, decimals, lengthMax: 6)} $symbol',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline5
                                                      .copyWith(
                                                          fontWeight: FontWeight
                                                              .w600))),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(height: 1))
                                  ])),
                              Visibility(
                                  visible: isCrossChain,
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
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Text(dic['cross.fee'],
                                                  style: labelStyle?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w400)),
                                            ),
                                          ),
                                          Text(
                                              '${Fmt.priceCeilBigInt(destFee, decimals, lengthMax: 6)} $symbol',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(height: 1))
                                  ])),
                              Column(children: [
                                Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Container(
                                              padding:
                                                  EdgeInsets.only(right: 60),
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
                                                      padding: EdgeInsets.only(
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                      ],
                                    )),
                                Padding(
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
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Text(dic['amount.fee'],
                                                  style: labelStyle?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w400)),
                                            ),
                                          ),
                                          Text(
                                              '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")), decimals, lengthMax: 6)} $symbol',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Padding(
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
                                          padding: EdgeInsets.only(right: 60),
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
                                                      EdgeInsets.only(top: 2),
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
                  padding: EdgeInsets.all(16),
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
