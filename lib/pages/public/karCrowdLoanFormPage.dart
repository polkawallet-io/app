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

class KarCrowdLoanFormPage extends StatefulWidget {
  KarCrowdLoanFormPage(this.service, this.connectedNode);
  final AppService service;
  final NetworkParams connectedNode;

  static final String route = '/public/kar/auction/2';

  @override
  _KarCrowdLoanFormPageState createState() => _KarCrowdLoanFormPageState();
}

const kar_para_index = '1000';

class _KarCrowdLoanFormPageState extends State<KarCrowdLoanFormPage> {
  final _emailRegEx = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  final _referralRegEx = RegExp(r'^0x[0-9a-z]{64}$');
  final _emailFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _referralFocusNode = FocusNode();

  bool _submitting = false;

  String _email = '';
  double _amount = 0;
  String _referral = '';
  bool _emailValid = false;
  bool _amountValid = false;
  bool _referralValid = false;

  double _amountKar = 0;

  bool _emailAccept = true;

  void _onEmailChange(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      setState(() {
        _email = v;
        _emailValid = false;
      });
      return;
    }

    final valid = _emailRegEx.hasMatch(v);
    setState(() {
      _emailValid = valid;
      _email = v;
    });
  }

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

    final decimals = 12;
    // final decimals = widget.service.plugin.networkState.tokenDecimals[0];
    final valid = amt < Fmt.bigIntToDouble(balanceInt, decimals);
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
    final res = await WalletApi.verifyKarReferralCode(v);
    print(res);
    // todo: valid2 = true for testing
    final valid2 = true;
    // final valid2 = res != null && res['result'];
    setState(() {
      _referral = v;
      _referralValid = valid2;
    });
  }

  Future<void> _signAndSubmit(KeyPairData account) async {
    if (_submitting ||
        widget.connectedNode == null ||
        !(_amountValid && _emailValid && (_referralValid || _referral.isEmpty)))
      return;

    setState(() {
      _submitting = true;
    });
    final decimals = 12;
    // final decimals = widget.service.plugin.networkState.tokenDecimals[0];
    final signed = widget.service.store.storage
        .read('$kar_statement_store_key${account.pubKey}');
    final amountInt = Fmt.tokenInt(_amount.toString(), decimals);
    // todo: add this post request while API is ready.
    // final res = await WalletApi.postKarCrowdLoan(
    //     account.address, amountInt, _email, _referral, signed);
    // print(res);
    final res = {'result': true};
    if (res != null && res['result']) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      // todo: use response data while API is ready.
      // final signingPayload = {'Sr25519': res['signingPayload']};
      final signingPayload = {'Sr25519': signed};
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'crowdloan',
            call: 'contribute',
            txTitle: dic['auction.contribute'],
            txDisplay: {
              "paraIndex": kar_para_index,
              "amount": '$_amount KSM',
              "signingPayload": signingPayload
            },
            params: [kar_para_index, amountInt.toString(), signingPayload],
          ))) as Map;
      if (res != null) {
        if (_emailAccept) {
          // todo: remove this await in production
          final resTest = await WalletApi.postKarSubscribe(_email);
          print(resTest);
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
        Navigator.of(context).pop();
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
            content: Text('Get Karura crowdloan info failed.'),
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

  @override
  void dispose() {
    super.dispose();
    _emailFocusNode.dispose();
    _referralFocusNode.dispose();
    _amountFocusNode.dispose();
  }

  @override
  Widget build(_) {
    return Observer(builder: (BuildContext context) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final decimals = 12;
      // final decimals = widget.service.plugin.networkState.tokenDecimals[0];

      final cardColor = Theme.of(context).cardColor;
      final karColor = Colors.red;
      final grayColor = Colors.white70;
      final errorStyle = TextStyle(color: karColor, fontSize: 10);
      final karStyle = TextStyle(
          color: cardColor, fontSize: 32, fontWeight: FontWeight.bold);
      final karKeyStyle = TextStyle(color: cardColor);
      final karInfoStyle =
          TextStyle(color: karColor, fontSize: 20, fontWeight: FontWeight.bold);

      final KeyPairData account = ModalRoute.of(context).settings.arguments;
      final balanceInt = Fmt.balanceInt(
          widget.service.plugin.balances.native.availableBalance.toString());
      final balanceView =
          Fmt.priceFloorBigInt(balanceInt, decimals, lengthMax: 8);

      final inputValid =
          _emailValid && _amountValid && (_referralValid || _referral.isEmpty);
      final isConnected = widget.connectedNode != null;

      return CrowdLoanPageLayout(dic['auction.contribute'], [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 16, bottom: 16),
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  border: Border.all(color: grayColor),
                  borderRadius: BorderRadius.all(Radius.circular(64))),
              child: Row(
                children: [
                  AddressIcon(
                    account.address ?? '',
                    svg: account.icon,
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
                          account.name ?? '',
                          style: TextStyle(fontSize: 18, color: cardColor),
                        ),
                        Text(
                          Fmt.address(account.address ?? ''),
                          style: TextStyle(color: grayColor, fontSize: 14),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 4),
              child: CupertinoTextField(
                padding: EdgeInsets.all(16),
                placeholder: dic['auction.email'],
                placeholderStyle: TextStyle(color: grayColor, fontSize: 18),
                style: TextStyle(color: cardColor, fontSize: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.all(Radius.circular(64)),
                  border: Border.all(
                      color: _emailFocusNode.hasFocus ? karColor : grayColor),
                ),
                cursorColor: karColor,
                clearButtonMode: OverlayVisibilityMode.editing,
                focusNode: _emailFocusNode,
                onChanged: _onEmailChange,
              ),
            ),
            Container(
              height: 12,
              margin: EdgeInsets.only(left: 16, bottom: 8),
              child: _email.isEmpty || _emailValid
                  ? Container()
                  : Text(
                      '${dic['auction.invalid']} ${dic['auction.email']}',
                      style: errorStyle,
                    ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '${dic['auction.balance']}: $balanceView KSM',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 4),
              child: CupertinoTextField(
                padding: EdgeInsets.all(16),
                placeholder: dic['auction.amount'],
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
              height: 12,
              margin: EdgeInsets.only(left: 16, bottom: 8),
              child: _amount == 0 || _amountValid
                  ? Container()
                  : Text(
                      '${dic['auction.invalid']} ${dic['auction.amount']}',
                      style: errorStyle,
                    ),
            ),
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
              height: 12,
              margin: EdgeInsets.only(left: 16, bottom: 8),
              child: _referral.isEmpty || _referralValid
                  ? Container()
                  : Text(
                      '${dic['auction.invalid']} ${dic['auction.referral']}',
                      style: errorStyle,
                    ),
            ),
            Container(
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
                      Text('12 MONTHS', style: karInfoStyle),
                    ],
                  ),
                ],
              ),
            ),
            Row(
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
            ),
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
                onPressed: () => _signAndSubmit(account),
              ),
            )
          ],
        )
      ]);
    });
  }
}
