import 'package:app/common/consts.dart';
import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class KarCrowdLoanPageParams {
  KarCrowdLoanPageParams(this.account, this.paraId, this.email);
  final KeyPairData account;
  final String paraId;
  final String email;
}

class KarCrowdLoanFormPage extends StatefulWidget {
  KarCrowdLoanFormPage(this.service, this.connectedNode);
  final AppService service;
  final NetworkParams connectedNode;

  static final String route = '/public/kar/auction/2';

  @override
  _KarCrowdLoanFormPageState createState() => _KarCrowdLoanFormPageState();
}

class _KarCrowdLoanFormPageState extends State<KarCrowdLoanFormPage> {
  final _referralRegEx = RegExp(r'^0x[0-9a-z]{64}$');
  final _amountFocusNode = FocusNode();
  final _referralFocusNode = FocusNode();

  bool _submitting = false;

  double _amount = 0;
  String _referral = '';
  bool _amountValid = false;
  bool _referralValid = false;

  double _amountKar = 0;

  bool _emailAccept = true;

  void _onAmountChange(String value, BigInt balanceInt) {
    final v = value.trim();
    if (v.isEmpty) {
      setState(() {
        _amount = 0;
        _amountValid = false;
        _amountKar = 0;
      });
      return;
    }

    final amt = double.parse(v);

    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final valid = amt < Fmt.bigIntToDouble(balanceInt, decimals) && amt >= 1;
    setState(() {
      _amountValid = valid;
      _amount = amt;
      _amountKar = valid ? amt * 12 : 0;
    });
  }

  Future<void> _onReferralChange(String value) async {
    final v = value.trim();
    if (v.isEmpty) {
      setState(() {
        _referral = v;
        _referralValid = false;
      });
      return;
    }

    final valid = _referralRegEx.hasMatch(v);
    if (!valid) {
      setState(() {
        _referral = v;
        _referralValid = valid;
      });
      return;
    }
    final karApis = widget.service.store.storage.read(kar_crowd_loan_api_key);
    final res = await WalletApi.verifyKarReferralCode(v, karApis.split('|')[0]);
    print(res);
    final valid2 = res != null && res['result'];
    setState(() {
      _referral = v;
      _referralValid = valid2;
    });
  }

  Future<void> _signAndSubmit(KeyPairData account) async {
    if (_submitting ||
        widget.connectedNode == null ||
        !(_amountValid && (_referralValid || _referral.isEmpty))) return;

    setState(() {
      _submitting = true;
    });
    final karApi = widget.service.store.storage.read(kar_crowd_loan_api_key);
    final karApis = karApi.split('|');
    final KarCrowdLoanPageParams params =
        ModalRoute.of(context).settings.arguments;
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final amountInt = Fmt.tokenInt(_amount.toString(), decimals);
    final signed = widget.service.store.storage
        .read('$kar_statement_store_key${account.pubKey}');
    final signingRes = await widget.service.account.postKarCrowdLoan(
        account.address,
        amountInt,
        params.email,
        _referral,
        signed,
        karApis[0]);
    if (signingRes != null && (signingRes['result'] ?? false)) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'crowdloan',
            call: 'contribute',
            txTitle: dic['auction.contribute'],
            txDisplay: {
              "paraIndex": params.paraId,
              "amount": '$_amount KSM',
              // "signingPayload": signingPayload
            },
            params: [params.paraId, amountInt.toString(), null],
          ))) as Map;
      if (res != null) {
        if (params.email.isNotEmpty && _emailAccept) {
          WalletApi.postKarSubscribe(params.email, karApis[1]);
        }
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              content: Text('Success'),
              actions: <Widget>[
                CupertinoButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        Navigator.of(context).pop(res);
      }

      setState(() {
        _submitting = false;
      });
    } else {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Failed'),
            content: Text(signingRes == null
                ? 'Get Karura crowdloan info failed.'
                : signingRes['message']),
            actions: <Widget>[
              CupertinoButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      setState(() {
        _submitting = false;
      });
    }
  }

  Widget _getTitle(String title) {
    return Container(
      margin: EdgeInsets.only(left: 16, bottom: 4),
      child: Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _referralFocusNode.dispose();
    _amountFocusNode.dispose();
  }

  @override
  Widget build(_) {
    return Observer(builder: (BuildContext context) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      final cardColor = Theme.of(context).cardColor;
      final karColor = Colors.red;
      final grayColor = Colors.white70;
      final errorStyle = TextStyle(color: karColor, fontSize: 10);
      final karStyle = TextStyle(
          color: cardColor, fontSize: 32, fontWeight: FontWeight.bold);
      final karKeyStyle = TextStyle(color: cardColor);
      final karInfoStyle =
          TextStyle(color: karColor, fontSize: 20, fontWeight: FontWeight.bold);

      final KarCrowdLoanPageParams params =
          ModalRoute.of(context).settings.arguments;
      final balanceInt = Fmt.balanceInt(
          widget.service.plugin.balances.native.availableBalance.toString());
      final balanceView =
          Fmt.priceFloorBigInt(balanceInt, decimals, lengthMax: 8);

      final inputValid = _amountValid && (_referralValid || _referral.isEmpty);
      final isConnected = widget.connectedNode != null;

      return CrowdLoanPageLayout(dic['auction.contribute'], [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 16),
              child: _getTitle(dic['auction.address']),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  border: Border.all(color: grayColor),
                  borderRadius: BorderRadius.all(Radius.circular(64))),
              child: Row(
                children: [
                  AddressIcon(
                    params.account.address ?? '',
                    svg: params.account.icon,
                    size: 36,
                    tapToCopy: false,
                  ),
                  Expanded(
                      child: Container(
                    margin: EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          params.account.name ?? '',
                          style: TextStyle(fontSize: 18, color: cardColor),
                        ),
                        Text(
                          Fmt.address(params.account.address ?? ''),
                          style: TextStyle(color: grayColor, fontSize: 14),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _getTitle(dic['auction.amount'])),
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    '${dic['auction.balance']}: $balanceView KSM',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(bottom: 4),
              child: CupertinoTextField(
                padding: EdgeInsets.all(16),
                placeholder: dic['auction.amount1'],
                placeholderStyle: TextStyle(color: grayColor, fontSize: 18),
                style: TextStyle(color: cardColor, fontSize: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.all(Radius.circular(64)),
                  border: Border.all(
                      color: _amountFocusNode.hasFocus ? karColor : grayColor),
                ),
                cursorColor: karColor,
                clearButtonMode: OverlayVisibilityMode.editing,
                inputFormatters: [UI.decimalInputFormatter(decimals)],
                focusNode: _amountFocusNode,
                onChanged: (v) => _onAmountChange(v, balanceInt),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 16, bottom: 4),
              child: _amount == 0 || _amountValid
                  ? Container()
                  : Text(
                      '${dic['auction.invalid']} ${dic['auction.amount']}',
                      style: errorStyle,
                    ),
            ),
            _getTitle(dic['auction.referral']),
            Container(
              margin: EdgeInsets.only(bottom: 4),
              child: CupertinoTextField(
                padding: EdgeInsets.all(16),
                placeholder: dic['auction.referral'],
                placeholderStyle: TextStyle(color: grayColor, fontSize: 18),
                style: TextStyle(color: cardColor, fontSize: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.all(Radius.circular(64)),
                  border: Border.all(
                      color:
                          _referralFocusNode.hasFocus ? karColor : grayColor),
                ),
                cursorColor: karColor,
                clearButtonMode: OverlayVisibilityMode.editing,
                focusNode: _referralFocusNode,
                onChanged: (v) => _onReferralChange(v),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 16, bottom: 4),
              child: _referral.isEmpty || _referralValid
                  ? Container()
                  : Text(
                      '${dic['auction.invalid']} ${dic['auction.referral']}',
                      style: errorStyle,
                    ),
            ),
            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white30,
                  border: Border.all(color: grayColor),
                  borderRadius: BorderRadius.all(Radius.circular(24))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(dic['auction.estimate'], style: karKeyStyle),
                      TapTooltip(
                        message: dic['auction.note'],
                      )
                    ],
                  ),
                  Text('${Fmt.priceFloor(_amountKar)} KAR', style: karStyle),
                  _referralValid
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('+ ${Fmt.priceFloor(_amountKar * 0.05)} KAR',
                                style: TextStyle(
                                    color: cardColor,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                                child: Text(' (+5%)', style: karInfoStyle)),
                          ],
                        )
                      : Container(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dic['auction.init'],
                        style: karKeyStyle,
                      ),
                      Text('30%', style: karInfoStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dic['auction.vest'], style: karKeyStyle),
                      Text('70%', style: karInfoStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dic['auction.lease'], style: karKeyStyle),
                      Text('48 WEEKS', style: karInfoStyle),
                    ],
                  ),
                ],
              ),
            ),
            params.email.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Theme(
                        child: SizedBox(
                          height: 48,
                          width: 32,
                          child: Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Checkbox(
                              value: _emailAccept,
                              onChanged: (v) {
                                setState(() {
                                  _emailAccept = v;
                                });
                              },
                            ),
                          ),
                        ),
                        data: ThemeData(
                          primarySwatch: karColor,
                          unselectedWidgetColor: karColor, // Your color
                        ),
                      ),
                      Expanded(
                          child: Text(
                        dic['auction.notify'],
                        style: TextStyle(color: cardColor, fontSize: 10),
                      ))
                    ],
                  )
                : Container(height: 16),
            Container(
              margin: EdgeInsets.only(top: 4, bottom: 32),
              child: RoundedButton(
                text: isConnected
                    ? dic['auction.submit']
                    : dic['auction.connecting'],
                icon: _submitting || !isConnected
                    ? CupertinoActivityIndicator()
                    : null,
                color: inputValid && !_submitting && isConnected
                    ? karColor
                    : Colors.grey,
                onPressed: () => _signAndSubmit(params.account),
              ),
            )
          ],
        )
      ]);
    });
  }
}
