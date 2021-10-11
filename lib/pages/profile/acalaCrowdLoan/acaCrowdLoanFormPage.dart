import 'package:app/common/consts.dart';
import 'package:app/pages/profile/acalaCrowdLoan/acaCrowdLoanPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

enum AcaPloType { proxy, direct }

class AcaCrowdLoanPageParams {
  AcaCrowdLoanPageParams(
    this.account,
    this.statement,
    this.ploType,
    this.promotion,
    this.fundInfo,
  );
  final KeyPairData account;
  final Map statement;
  final AcaPloType ploType;
  final Map promotion;
  final Map fundInfo;
}

class AcaCrowdLoanFormPage extends StatefulWidget {
  AcaCrowdLoanFormPage(this.service, this.connectedNode);
  final AppService service;
  final NetworkParams connectedNode;

  static final String route = '/public/aca/auction/2';

  @override
  _AcaCrowdLoanFormPageState createState() => _AcaCrowdLoanFormPageState();
}

class _AcaCrowdLoanFormPageState extends State<AcaCrowdLoanFormPage> {
  final _emailRegEx = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  final _emailFocusNode = FocusNode();

  final _referralRegEx = RegExp(r'^0x[0-9a-z]{64}$');
  final _amountFocusNode = FocusNode();
  final _referralFocusNode = FocusNode();

  final _rewardMultiplier = 300;
  final _rewardDivider = 100;
  final double _contributeMin = 5;

  bool _submitting = false;

  double _amount = 0;
  String _referral = '';
  bool _amountValid = false;
  bool _amountEnough = false;
  bool _referralValid = false;

  String _email = '';
  bool _emailValid = true;
  bool _emailAccept = true;

  void _onAmountChange(String value, BigInt balanceInt, Map promotion) {
    final v = value.trim();
    double amt = 0;
    bool inputValid = true;
    try {
      amt = double.parse(v);
    } catch (err) {
      inputValid = false;
    }
    if (v.isEmpty || !inputValid) {
      setState(() {
        _amount = 0;
        _amountValid = false;
      });
      return;
    }

    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final enough = amt < Fmt.bigIntToDouble(balanceInt, decimals);
    final AcaCrowdLoanPageParams params =
        ModalRoute.of(context).settings.arguments;
    final valid = enough &&
        amt >=
            (params.ploType == AcaPloType.direct
                ? _contributeMin
                : _contributeMin / 5);
    setState(() {
      _amountValid = valid;
      _amountEnough = enough;
      _amount = amt;
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
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    final res = await WalletApi.verifyKarReferralCode(v, endpoint);
    final valid2 = res != null && res['result'];
    setState(() {
      _referral = v;
      _referralValid = valid2;
    });
  }

  void _onEmailChange(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      setState(() {
        _email = v;
        _emailValid = true;
      });
      return;
    }

    final valid = _emailRegEx.hasMatch(v);
    setState(() {
      _emailValid = valid;
      _email = v;
    });
  }

  Future<void> _signAndSubmit(KeyPairData account) async {
    if (_submitting ||
        widget.connectedNode == null ||
        !_emailValid ||
        !(_amountValid && (_referralValid || _referral.isEmpty))) return;

    setState(() {
      _submitting = true;
    });
    final AcaCrowdLoanPageParams params =
        ModalRoute.of(context).settings.arguments;
    if (params.ploType == AcaPloType.proxy) {
      await _proxySubmit();
    } else {
      await _directSubmit(account);
    }
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _directSubmit(KeyPairData account) async {
    final AcaCrowdLoanPageParams params =
        ModalRoute.of(context).settings.arguments;
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final amountInt = Fmt.tokenInt(_amount.toString(), decimals);
    final signed = widget.service.store.storage
        .read('$aca_statement_store_key${account.pubKey}');
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    final signingRes = await widget.service.account.postKarCrowdLoan(
        account.address,
        amountInt,
        _emailValid ? _email : '',
        _emailAccept,
        _referral,
        signed,
        endpoint);
    if (signingRes != null && (signingRes['result'] ?? false)) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final txParams = [
        params.statement['paraId'].toString(),
        amountInt.toString(),
        null
      ];
      final txArgs = TxConfirmParams(
        module: 'crowdloan',
        call: 'contribute',
        txTitle: dic['auction.contribute'],
        txDisplay: {
          "type": 'direct contribute',
          "paraIndex": params.statement['paraId'],
          "amount": '$_amount DOT',
          // "signingPayload": signingPayload
        },
        params: txParams,
      );
      final res = (await Navigator.of(context)
          .pushNamed(TxConfirmPage.route, arguments: txArgs)) as Map;
      if (res != null) {
        _saveLocalTxData(txArgs, txParams, res);

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
    } else {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Failed'),
            content: Text(signingRes == null
                ? 'Get Acala crowdloan info failed.'
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
    }
  }

  Future<void> _proxySubmit() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final AcaCrowdLoanPageParams params =
        ModalRoute.of(context).settings.arguments;

    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final amountInt = Fmt.tokenInt(_amount.toString(), decimals);

    final batchTxs = [
      'api.tx.balances.transfer("${params.statement['proxyAddress']}", "$amountInt")',
      'api.tx.system.remarkWithEvent("${params.statement['statement']}")'
    ];
    if (_referral.isNotEmpty && _referralValid) {
      batchTxs.add('api.tx.system.remarkWithEvent("referrer:$_referral")');
    }
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    await widget.service.account.postKarCrowdLoan(
        params.account.address,
        amountInt,
        _emailValid ? _email : '',
        _emailAccept,
        _referral,
        '',
        endpoint,
        isProxy: true);
    final txArgs = TxConfirmParams(
        module: 'utility',
        call: 'batchAll',
        txTitle: dic['auction.contribute'],
        txDisplay: {
          "type": 'via Acala proxy',
          "amount": '$_amount DOT',
          // "signingPayload": signingPayload
        },
        params: [],
        rawParams: '[[${batchTxs.join(',')}]]');
    final res = (await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: txArgs)) as Map;
    if (res != null) {
      final txParams = [
        params.statement['paraId'].toString(),
        amountInt.toString(),
      ];
      _saveLocalTxData(TxConfirmParams(module: 'crowdloan', call: 'contribute'),
          txParams, res);

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
  }

  Widget _getTitle(String title, {double marginTop = 12}) {
    return Container(
      margin: EdgeInsets.only(left: 16, top: marginTop),
      child: Text(title,
          style: TextStyle(
              color: Color(0xff2b2b2b),
              fontSize: 46.sp,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none)),
    );
  }

  // todo: make this local-tx-storage a plugin function
  void _saveLocalTxData(TxConfirmParams txArgs, List txParams, Map txRes) {
    final pubKey = widget.service.keyring.current.pubKey;
    final Map cache =
        widget.service.store.storage.read('$local_tx_store_key:$pubKey') ?? {};
    final txs = cache[pubKey] ?? [];
    txs.add({
      'module': txArgs.module,
      'call': txArgs.call,
      'args': txParams,
      'hash': txRes['hash'],
      'blockHash': txRes['blockHash'],
      'eventId': txRes['eventId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    cache[pubKey] = txs;
    widget.service.store.storage.write('$local_tx_store_key:$pubKey', cache);
  }

  @override
  void dispose() {
    super.dispose();
    _referralFocusNode.dispose();
    _amountFocusNode.dispose();
    _emailFocusNode.dispose();
  }

  @override
  Widget build(_) {
    return Observer(builder: (BuildContext context) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

      final titleColor = Colors.black87;
      final errorStyle = TextStyle(color: Colors.red, fontSize: 10);
      final karStyle = TextStyle(
          color: titleColor, fontSize: 26, fontWeight: FontWeight.bold);
      final karKeyStyle = TextStyle(color: titleColor);
      final karInfoStyle = TextStyle(
          color: acaThemeColor, fontSize: 20, fontWeight: FontWeight.bold);

      final AcaCrowdLoanPageParams params =
          ModalRoute.of(context).settings.arguments;
      final balanceInt = Fmt.balanceInt(
          widget.service.plugin.balances.native.availableBalance.toString());
      final balanceView =
          Fmt.priceFloorBigInt(balanceInt, decimals, lengthMax: 8);

      final isConnected = widget.connectedNode != null;

      final minContribute = params.ploType == AcaPloType.direct
          ? _contributeMin
          : _contributeMin / 5;

      final double amountAca =
          _amountValid ? _amount * _rewardMultiplier / _rewardDivider : 0;
      final raised = BigInt.parse(params.fundInfo['raised'].toString());
      final double ratioAcaMax = raised > AcaCrowdLoanPage.contributeAmountMax
          ? raised / AcaCrowdLoanPage.contributeAmountMaxDivider
          : AcaCrowdLoanPage.rewardAmountMax;

      double acaAmountTotal = amountAca * (_referralValid ? 1.05 : 1);
      double karPromotion = 0;
      double acaPromotion = 0;
      if (params.promotion['result']) {
        if (params.promotion['karRate'] > 0) {
          karPromotion = amountAca * params.promotion['karRate'];
        }
        if (params.promotion['acaRate'] > 0) {
          acaPromotion = amountAca * params.promotion['acaRate'];
        }
      }
      acaAmountTotal += acaPromotion;
      return AcaPloPageLayout(
          dic['auction.contribute'],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                child: Image.asset("assets/images/public/aca_plo_bg_1.png"),
              ),
              _getTitle(dic['auction.address'], marginTop: 0),
              Container(
                margin: EdgeInsets.only(
                    left: 16, right: 16, top: 20.h, bottom: 16.h),
                child: AddressFormItem(
                  widget.service.keyring.current,
                  svg: widget.service.keyring.current.icon,
                  color: acaThemeColor,
                  borderWidth: 4.w,
                  imageRight: 48.w,
                  margin: EdgeInsets.zero,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _getTitle(dic['auction.amount'])),
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text(
                      '${dic['auction.balance']}: $balanceView DOT',
                      style: TextStyle(color: acaThemeColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(
                    left: 16, right: 16, top: 20.h, bottom: 16.h),
                child: CupertinoTextField(
                  padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                  placeholder: dic['auction.amount1'],
                  placeholderStyle:
                      TextStyle(fontSize: 16, color: acaThemeColor),
                  style: TextStyle(color: titleColor, fontSize: 18),
                  decoration: BoxDecoration(
                    color: _amountFocusNode.hasFocus
                        ? acaThemeColor.shade100
                        : Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    border: Border.all(width: 4.w, color: acaThemeColor),
                  ),
                  cursorColor: acaThemeColor,
                  clearButtonMode: OverlayVisibilityMode.editing,
                  inputFormatters: [UI.decimalInputFormatter(decimals)],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  focusNode: _amountFocusNode,
                  onChanged: (v) =>
                      _onAmountChange(v, balanceInt, params.promotion),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 16, bottom: 4),
                child: _amount == 0 || _amountValid
                    ? Container()
                    : Text(
                        _amountEnough
                            ? '${dic['auction.invalid']} ${dic['auction.amount.error']} ${minContribute.toInt()} DOT'
                            : dic['balance.insufficient'],
                        style: errorStyle,
                      ),
              ),
              _getTitle(dic['auction.referral']),
              Container(
                margin: EdgeInsets.only(
                    left: 16, right: 16, top: 20.h, bottom: 16.h),
                child: CupertinoTextField(
                  padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                  placeholder: dic['auction.referral'],
                  placeholderStyle:
                      TextStyle(fontSize: 16, color: acaThemeColor),
                  style: TextStyle(color: titleColor, fontSize: 18),
                  decoration: BoxDecoration(
                    color: _referralFocusNode.hasFocus
                        ? acaThemeColor.shade100
                        : Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    border: Border.all(width: 4.w, color: acaThemeColor),
                  ),
                  cursorColor: acaThemeColor,
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
                margin: EdgeInsets.only(
                    left: 16, right: 16, top: 48.h, bottom: 16.h),
                padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.all(width: 4.w, color: acaThemeColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    params.ploType == AcaPloType.proxy
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dic['auction.receive.dot'],
                                  style: karKeyStyle),
                              Text(
                                  '${Fmt.priceFloor(_amount, lengthMax: 4)} lcDOT',
                                  style: karStyle),
                              Divider(color: acaThemeColor),
                            ],
                          )
                        : Container(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          child:
                              Text(dic['auction.estimate'], style: karKeyStyle),
                        ),
                        TapTooltip(
                          message: '\n${dic['auction.note']}\n',
                          child: Icon(
                            Icons.info,
                            size: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                        )
                      ],
                    ),
                    Text(
                        '${Fmt.priceFloor(acaAmountTotal, lengthMax: 4)} - ${Fmt.priceFloor(acaAmountTotal / 3 * ratioAcaMax, lengthMax: 4)} ACA' +
                            (karPromotion > 0
                                ? ' + ${Fmt.priceFloor(karPromotion, lengthMax: 4)} KAR'
                                : ''),
                        style: karStyle),
                    amountAca > 0
                        ? RewardDetailPanel(
                            amountAca,
                            ratioAcaMax,
                            _referralValid,
                            params.promotion,
                            karPromotion,
                            acaPromotion)
                        : Container(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dic['auction.init'],
                          style: karKeyStyle,
                        ),
                        Text('20%', style: karInfoStyle),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dic['auction.vest'], style: karKeyStyle),
                        Text('80%', style: karInfoStyle),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dic['auction.lease'], style: karKeyStyle),
                        Text('24 Months', style: karInfoStyle),
                      ],
                    ),
                  ],
                ),
              ),
              _getTitle(dic['auction.email']),
              Container(
                margin: EdgeInsets.only(
                    left: 16, right: 16, top: 20.h, bottom: 16.h),
                child: CupertinoTextField(
                  padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                  placeholder: 'Email (optional)',
                  placeholderStyle:
                      TextStyle(fontSize: 16, color: acaThemeColor),
                  style: TextStyle(fontSize: 18),
                  decoration: BoxDecoration(
                    color: _emailFocusNode.hasFocus
                        ? acaThemeColor.shade100
                        : Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    border: Border.all(width: 4.w, color: acaThemeColor),
                  ),
                  cursorColor: acaThemeColor,
                  clearButtonMode: OverlayVisibilityMode.editing,
                  focusNode: _emailFocusNode,
                  onChanged: _onEmailChange,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 16, bottom: 4),
                child: _email.isEmpty || _emailValid
                    ? Container()
                    : Text(
                        '${dic['auction.invalid']} ${dic['auction.email']}',
                        style: TextStyle(color: Colors.red, fontSize: 10),
                      ),
              ),
              _email.isNotEmpty
                  ? Container(
                      margin: EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Theme(
                            child: SizedBox(
                              height: 32,
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
                              primarySwatch: acaThemeColor,
                              unselectedWidgetColor:
                                  acaThemeColor, // Your color
                            ),
                          ),
                          Expanded(
                              child: Text(
                            dic['auction.notify'],
                            style: TextStyle(color: titleColor, fontSize: 10),
                          ))
                        ],
                      ),
                    )
                  : Container(height: 16),
              Container(
                margin:
                    EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 32),
                child: RoundedButton(
                  text: isConnected
                      ? dic['auction.submit']
                      : dic['auction.connecting'],
                  icon: _submitting || !isConnected
                      ? CupertinoActivityIndicator()
                      : null,
                  color: acaThemeColor,
                  borderRadius: 8,
                  onPressed: () => _signAndSubmit(params.account),
                ),
              )
            ],
          ));
    });
  }
}

class RewardDetailPanel extends StatelessWidget {
  RewardDetailPanel(this.acaAmountMin, this.ratioAcaMax, this.referralValid,
      this.promotion, this.karPromotion, this.acaPromotion);

  final double acaAmountMin;
  final double ratioAcaMax;
  final bool referralValid;
  final Map promotion;
  final double karPromotion;
  final double acaPromotion;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final titleColor = Colors.black87;
    final karAmountStyle =
        TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold);
    final karInfoStyle = TextStyle(color: titleColor, fontSize: 12);

    final acaAmountMax = acaAmountMin / 3 * ratioAcaMax;
    return Container(
      margin: EdgeInsets.only(top: 4, bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: acaThemeColor.shade200,
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                  child: Text('1DOT : 3 - ${Fmt.priceFloor(ratioAcaMax)}ACA',
                      style: karInfoStyle)),
              Text(
                  '${Fmt.priceFloor(acaAmountMin, lengthMax: 4)} - ${Fmt.priceFloor(acaAmountMax, lengthMax: 4)} ACA',
                  style: karAmountStyle),
            ],
          ),
          referralValid
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text('+5% ${dic['auction.invite']}',
                            style: karInfoStyle)),
                    Text(
                        '${Fmt.priceFloor(acaAmountMin * 0.05, lengthMax: 4)} - ${Fmt.priceFloor(acaAmountMax * 0.05, lengthMax: 4)} ACA',
                        style: karInfoStyle),
                  ],
                )
              : Container(),
          karPromotion > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text(
                            '+${Fmt.ratio(promotion['karRate'])} ${promotion['name']}',
                            style: karInfoStyle)),
                    Text('${Fmt.priceFloor(karPromotion, lengthMax: 4)} KAR',
                        style: karInfoStyle),
                  ],
                )
              : Container(),
          acaPromotion > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text(
                            '+${Fmt.ratio(promotion['acaRate'])} ${promotion['name']}',
                            style: karInfoStyle)),
                    Text('${Fmt.priceFloor(acaPromotion, lengthMax: 4)} ACA',
                        style: karInfoStyle),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}
