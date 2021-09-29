import 'dart:async';

import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/inputItem.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';

const aca_statement_store_key = 'aca_statement_store_key';

class AcalaCrowdLoanPage extends StatefulWidget {
  final AppService service;
  final Color themeColor = Color(0xFF7E74FA);

  static final String route = '/profile/crowd/acalaCrowdLoanPage';
  AcalaCrowdLoanPage(this.service, {Key key}) : super(key: key);

  @override
  _AcalaCrowdLoanPageState createState() => _AcalaCrowdLoanPageState();
}

class _AcalaCrowdLoanPageState extends State<AcalaCrowdLoanPage> {
  KeyPairData _account = KeyPairData();

  bool _accepted0 = false;
  bool _accepted2 = false;

  Map _statement;
  Map _promotion;
  bool _signed = false;

  List _contributions = [];
  Timer _txQueryTimer;
  bool _txQuerying = true;

  Future<void> _getCrowdLoanHistory() async {
    setState(() {
      _txQuerying = true;
    });
    final endpoint = widget.service.store.settings.adBannerState['endpoint'];
    final res =
        await WalletApi.getKarCrowdLoanHistory(_account.address, endpoint);
    print(res);
    if (res != null && mounted) {
      final txs = _mergeLocalTxData(res.reversed.toList());
      print(res);
      setState(() {
        _contributions = txs;
        _txQuerying = false;
      });
    }

    // we can get users' statement signature if we got the history
    if (!_signed && res.length > 0) {
      final signed = res[0]['statement']['signature'];
      widget.service.store.storage
          .write('$aca_statement_store_key${_account.pubKey}', signed);
      if (mounted) {
        setState(() {
          _signed = true;
        });
      }
    }
  }

  List _mergeLocalTxData(List txs) {
    final pubKey = widget.service.keyring.current.pubKey;
    final Map cache =
        widget.service.store.storage.read('$local_tx_store_key:$pubKey') ?? {};
    final local = cache[pubKey] ?? [];
    if (local.length == 0) return txs;

    bool isInBlock = false;
    int inBlockTxCount = 0;
    int inBlockTxIndex = 0;
    local.forEach((e) {
      if (e['module'] == 'crowdloan' && e['call'] == 'contribute') {
        txs.forEach((tx) {
          if (tx['blockHash'] == e['blockHash']) {
            isInBlock = true;
            inBlockTxIndex = inBlockTxCount;
          }
        });
      }
      inBlockTxCount++;
    });
    if (isInBlock) {
      local.removeAt(inBlockTxIndex);
      cache[pubKey] = local;
      widget.service.store.storage.write('$local_tx_store_key:$pubKey', cache);
      if (_txQueryTimer != null) {
        _txQueryTimer.cancel();
      }
      return txs;
    } else {
      final tx = local[inBlockTxIndex];
      final List res = [
        {
          'ksmAmount': tx['args'][1],
          'timestamp': tx['timestamp'],
          'eventId': tx['hash'],
        }
      ];
      res.addAll(txs);
      setState(() {
        _txQueryTimer = Timer(Duration(seconds: 6), _getCrowdLoanHistory);
      });
      return res;
    }
  }

  Future<void> _selectAccount() async {
    final res = await Navigator.of(context).pushNamed(AccountListPage.route,
        arguments: AccountListPageParams(
            list: widget.service.keyring.keyPairs, title: 'Accounts'));
    if (res != null) {
      final acc = res as KeyPairData;
      if (acc.pubKey == _account.pubKey) return;

      // change account in app so we can get the balance
      widget.service.keyring.setCurrent(acc);
      widget.service.plugin.changeAccount(acc);
      widget.service.store.assets
          .loadCache(acc, widget.service.plugin.basic.name);

      final signed = widget.service.store.storage
          .read('$aca_statement_store_key${acc.pubKey}');

      setState(() {
        _account = acc;
        _accepted0 = false;
        _accepted2 = false;
        _signed = signed != null;
      });

      _getCrowdLoanHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: Image.asset(
                "assets/images/public/polka-parachain-08.png",
              ),
            ),
            _buildStep1(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 53.w, right: 54.w, top: 19.85.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Address",
            style: TextStyle(
                color: Color(0xff2b2b2b),
                fontSize: 46.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none),
          ),
          Padding(
            padding: EdgeInsets.only(top: 15.h, bottom: 43.h),
            child: AddressFormItem(
              widget.service.keyring.current,
              svg: widget.service.keyring.current.icon,
              onTap: _selectAccount,
              color: widget.themeColor,
              borderWidth: 4.w,
              imageRight: 54.5.w,
              margin: EdgeInsets.zero,
            ),
          ),
          Text(
            "Email (optional)",
            style: TextStyle(
                color: Color(0xff2b2b2b),
                fontSize: 46.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none),
          ),
          Padding(
            padding: EdgeInsets.only(top: 15.h),
            child: InputItem(
              color: widget.themeColor,
              borderWidth: 4.w,
              onChanged: (String value) {},
              hintStyle: TextStyle(
                  color: widget.themeColor,
                  fontSize: 46.sp,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none),
              hintText: 'Email (optional)',
              style: TextStyle(
                  color: Color(0xff1b1b1b),
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 38.5.h, bottom: 15.h),
            child: Row(
              children: [
                Container(
                  child: Icon(
                    Icons.radio_button_off,
                    size: 63.2.w,
                    color: widget.themeColor,
                  ),
                  margin: EdgeInsets.only(right: 42.49.h),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("I have read and accept the",
                        style: TextStyle(
                            color: Color(0xff2b2b2b),
                            fontSize: 46.sp,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.none)),
                    Row(
                      children: [
                        Text("Terms & Conditions",
                            style: TextStyle(
                                color: widget.themeColor,
                                fontSize: 46.sp,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.none)),
                        Container(
                          margin: EdgeInsets.only(left: 10.w),
                          child: Image.asset(
                            "assets/images/share.png",
                            width: 30.w,
                            fit: BoxFit.contain,
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 49.5.h),
            child: Row(
              children: [
                Container(
                  child: Icon(
                    Icons.radio_button_off,
                    size: 63.2.w,
                    color: widget.themeColor,
                  ),
                  margin: EdgeInsets.only(right: 42.49.h),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("I have read and accept the",
                        style: TextStyle(
                            color: Color(0xff2b2b2b),
                            fontSize: 46.sp,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.none)),
                    Row(
                      children: [
                        Text("Privacy Policy ",
                            style: TextStyle(
                                color: widget.themeColor,
                                fontSize: 46.sp,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.none)),
                        Container(
                          margin: EdgeInsets.only(left: 10.w),
                          child: Image.asset(
                            "assets/images/share.png",
                            width: 30.w,
                            fit: BoxFit.contain,
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.h))),
                    fixedSize:
                        MaterialStateProperty.all(Size(double.infinity, 146.w)),
                    backgroundColor:
                        MaterialStateProperty.all(widget.themeColor)),
                child: Text("Accept & Sign",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 50.sp,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none)),
              ))
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 53.w, right: 54.w, top: 19.85.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Address",
            style: TextStyle(
                color: Color(0xff2b2b2b),
                fontSize: 46.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none),
          ),
          Padding(
            padding: EdgeInsets.only(top: 15.h, bottom: 43.h),
            child: AddressFormItem(
              widget.service.keyring.current,
              svg: widget.service.keyring.current.icon,
              onTap: () async {
                print("");
              },
              color: widget.themeColor,
              borderWidth: 4.w,
              imageRight: 54.5.w,
              margin: EdgeInsets.zero,
            ),
          ),
          Text(
            "My Contributions",
            style: TextStyle(
                color: Color(0xff2b2b2b),
                fontSize: 46.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none),
          ),
          Container(
            margin: EdgeInsets.only(top: 15.h, bottom: 97.5.h),
            padding: EdgeInsets.only(
                left: 49.w, top: 41.h, right: 46.w, bottom: 48.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.all(color: widget.themeColor, width: 4.w),
            ),
            child: Column(
              children: [
                Container(
                    margin: EdgeInsets.only(bottom: 9.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "10 KSM",
                          style: TextStyle(
                              color: Color(0xff2b2b2b),
                              fontSize: 46.sp,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none),
                        ),
                        Text(
                          "Confirming…",
                          style: TextStyle(
                              color: Color(0xff242424),
                              fontSize: 46.sp,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none),
                        ),
                      ],
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "6/8 2021 10:41",
                      style: TextStyle(
                          color: widget.themeColor,
                          fontSize: 46.sp,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none),
                    ),
                    Row(
                      children: [
                        Text(
                          "9du19d1…9838h",
                          style: TextStyle(
                              color: widget.themeColor,
                              fontSize: 46.sp,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 19.w),
                          child: Image.asset(
                            "assets/images/share.png",
                            width: 37.w,
                            fit: BoxFit.contain,
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.h))),
                    fixedSize:
                        MaterialStateProperty.all(Size(double.infinity, 146.w)),
                    backgroundColor:
                        MaterialStateProperty.all(widget.themeColor)),
                child: Text("Accept & Sign",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 50.sp,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none)),
              ))
        ],
      ),
    );
  }
}
