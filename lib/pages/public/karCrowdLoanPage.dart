import 'dart:async';

import 'package:app/common/consts.dart';
import 'package:app/pages/public/karCrowdLoanFormPage.dart';
import 'package:app/pages/public/adPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

const kar_statement_store_key = 'kar_statement_store_key';

class KarCrowdLoanPage extends StatefulWidget {
  KarCrowdLoanPage(this.service, this.connectedNode);
  final AppService service;
  final NetworkParams connectedNode;

  static final String route = '/public/kar/auction';

  @override
  _KarCrowdLoanPageState createState() => _KarCrowdLoanPageState();
}

class _KarCrowdLoanPageState extends State<KarCrowdLoanPage> {
  final _emailRegEx = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  final _emailFocusNode = FocusNode();

  int _bestNumber = 0;
  Map _fundInfo;

  KeyPairData _account = KeyPairData();

  bool _submitting = false;
  String _email = '';
  bool _emailValid = true;

  bool _accepted0 = false;
  bool _accepted1 = false;
  bool _accepted2 = false;

  Map _statement;
  bool _signed = false;

  List _contributions = [];

  Future<void> _updateBestNumber() async {
    final res = await widget.service.plugin.sdk.webView
        .evalJavascript('api.derive.chain.bestNumber()');
    if (mounted) {
      setState(() {
        _bestNumber = int.parse(res.toString());
      });
    }
  }

  Future<void> _getCrowdLoanInfo() async {
    await _getKarStatement();
    _getCrowdLoanHistory();

    if (widget.connectedNode == null) return;

    _updateBestNumber();
    final res = await widget.service.plugin.sdk.webView.evalJavascript(
        'api.query.crowdloan.funds("${_statement['paraId'].toString()}")');
    if (mounted) {
      setState(() {
        _fundInfo = res;
      });
    }
  }

  Future<void> _getCrowdLoanHistory() async {
    final karApis = widget.service.store.storage.read(kar_crowd_loan_api_key);
    final res = await WalletApi.getKarCrowdLoanHistory(
        _account.address, karApis.split('|')[0]);
    print(res);
    if (res != null && mounted) {
      setState(() {
        _contributions = res;
      });
    }

    // we can get users' statement signature if we got the history
    if (!_signed && res.length > 0) {
      final signed = res[0]['statement']['signature'];
      widget.service.store.storage
          .write('$kar_statement_store_key${_account.pubKey}', signed);
      if (mounted) {
        setState(() {
          _signed = true;
        });
      }
    }
  }

  Future<void> _getKarStatement() async {
    final karApis = widget.service.store.storage.read(kar_crowd_loan_api_key);
    final res = await WalletApi.getKarCrowdLoanStatement(karApis.split('|')[0]);
    if (res != null && mounted) {
      setState(() {
        _statement = res;
      });
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
          .read('$kar_statement_store_key${acc.pubKey}');

      setState(() {
        _account = acc;
        _accepted0 = false;
        _accepted1 = false;
        _accepted2 = false;
        _signed = signed != null;
      });

      _getCrowdLoanHistory();
    }
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

  Future<void> _acceptAndSign() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });

    final password =
        await widget.service.account.getPassword(context, _account);

    if (password != null) {
      final params = SignAsExtensionParam();
      params.msgType = "pub(bytes.sign)";
      params.request = {
        "address": _account.address,
        "data": _statement['statement'],
      };

      final signRes = await widget.service.plugin.sdk.api.keyring
          .signAsExtension(password, params);
      widget.service.store.storage.write(
          '$kar_statement_store_key${_account.pubKey}', signRes.signature);

      setState(() {
        _submitting = false;
        _signed = true;
      });

      await _goToContribute();
    } else {
      setState(() {
        _submitting = false;
      });
    }
  }

  Future<void> _goToContribute() async {
    final res = await Navigator.of(context).pushNamed(
        KarCrowdLoanFormPage.route,
        arguments: KarCrowdLoanPageParams(
            _account, _statement['paraId'].toString(), _email));
    if (res != null) {
      _getCrowdLoanInfo();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = widget.service.keyring.current;
      final signed = widget.service.store.storage
          .read('$kar_statement_store_key${acc.pubKey}');

      setState(() {
        _account = widget.service.keyring.current;
        _signed = signed != null;
      });

      _getCrowdLoanInfo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.connectedNode != null && _fundInfo == null) {
      _getCrowdLoanInfo();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _emailFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    DateTime endTime = DateTime.now();
    bool finished = false;
    if (_fundInfo != null) {
      final end = _fundInfo['end'];

      final now = DateTime.now().millisecondsSinceEpoch;
      final blockDuration = int.parse(
          widget.service.plugin.networkConst['babe']['expectedBlockTime']);
      endTime = DateTime.fromMillisecondsSinceEpoch(
          now + (end - _bestNumber) * blockDuration);

      finished = now > endTime.millisecondsSinceEpoch;
    }

    final cardColor = Theme.of(context).cardColor;
    final karColor = Colors.red;
    final grayColor = Colors.white70;
    final titleStyle = TextStyle(color: grayColor, fontSize: 18);

    final allAccepted = _accepted0 && _accepted1 && _accepted2 && _emailValid;
    return CrowdLoanPageLayout('', [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8, top: 16),
            child: Text(dic['auction.support'],
                style: TextStyle(fontSize: 24, color: cardColor)),
          ),
          Row(
            children: [
              Image.asset(
                'assets/images/public/kar_logo.png',
                width: MediaQuery.of(context).size.width * 2 / 3,
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 4, bottom: 20),
            child: Text(dic['auction.kar'],
                style: TextStyle(
                    fontSize: 28,
                    color: karColor,
                    fontWeight: FontWeight.bold)),
          ),
          _fundInfo == null
              ? Container()
              : KarCrowdLoanTitleSet(finished: finished),
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 32),
            child: widget.connectedNode == null || _fundInfo == null || finished
                ? null
                : CountdownPanel(
                    cardColor: Theme.of(context).cardColor,
                    cardTextColor: Colors.pink,
                    textColor: Colors.orangeAccent,
                    endTime: endTime,
                  ),
          )
        ],
      ),
      _fundInfo == null || finished
          ? _bestNumber == 0
              ? Theme(
                  data: ThemeData(
                      cupertinoOverrideTheme:
                          CupertinoThemeData(brightness: Brightness.dark)),
                  child: CupertinoActivityIndicator())
              : Container()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: Divider(color: grayColor),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Text(dic['auction.address'], style: titleStyle),
                ),
                GestureDetector(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                        color: Colors.white12,
                        border: Border.all(color: grayColor),
                        borderRadius: BorderRadius.all(Radius.circular(64))),
                    child: Row(
                      children: [
                        AddressIcon(
                          _account.address ?? '',
                          svg: _account.icon,
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
                                _account.name ?? '',
                                style:
                                    TextStyle(fontSize: 18, color: cardColor),
                              ),
                              Text(
                                Fmt.address(_account.address ?? ''),
                                style:
                                    TextStyle(color: grayColor, fontSize: 14),
                              ),
                            ],
                          ),
                        )),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 30,
                          color: grayColor,
                        )
                      ],
                    ),
                  ),
                  onTap: _selectAccount,
                ),
                _signed
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child:
                                Text(dic['auction.email'], style: titleStyle),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 4),
                            child: CupertinoTextField(
                              padding: EdgeInsets.all(16),
                              placeholder: dic['auction.email'],
                              placeholderStyle:
                                  TextStyle(color: grayColor, fontSize: 18),
                              style: TextStyle(color: cardColor, fontSize: 18),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(64)),
                                border: Border.all(
                                    color: _emailFocusNode.hasFocus
                                        ? karColor
                                        : grayColor),
                              ),
                              cursorColor: karColor,
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
                                    style: TextStyle(
                                        color: karColor, fontSize: 10),
                                  ),
                          ),
                        ],
                      ),
                _signed
                    ? Container()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Theme(
                            child: SizedBox(
                              height: 48,
                              width: 32,
                              child: Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Checkbox(
                                  value: _accepted0,
                                  onChanged: (v) {
                                    setState(() {
                                      _accepted0 = v;
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dic['auction.read'],
                                style: TextStyle(color: cardColor),
                              ),
                              JumpToLink(
                                'https://acala.network/terms',
                                text: ' ${dic['auction.term.0']}',
                                color: karColor,
                              )
                            ],
                          )
                        ],
                      ),
                _signed
                    ? _contributions.length == 0
                        ? Container()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child:
                                    Text(dic['auction.txs'], style: titleStyle),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: grayColor, width: 0.5),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16))),
                                child: Column(
                                  children: _contributions.map((e) {
                                    return Container(
                                      margin:
                                          EdgeInsets.only(top: 8, bottom: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${Fmt.balance(e['amount'], decimals)} KSM',
                                                style: TextStyle(
                                                    color: cardColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                  Fmt.dateTime(DateTime.parse(
                                                      e['createdAt'])),
                                                  style: TextStyle(
                                                      color: grayColor,
                                                      fontSize: 13))
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                'Event Id',
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                              JumpToLink(
                                                'https://kusama.subscan.io/extrinsic/${e['inBlock']['eventId']}',
                                                text: e['inBlock']['eventId'],
                                                color: karColor,
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            ],
                          )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Theme(
                            child: SizedBox(
                              height: 48,
                              width: 32,
                              child: Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Checkbox(
                                  value: _accepted1,
                                  onChanged: (v) {
                                    setState(() {
                                      _accepted1 = v;
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dic['auction.meet'],
                                style: TextStyle(color: cardColor),
                              ),
                              JumpToLink(
                                'https://acala.network/terms#check',
                                text: ' ${dic['auction.term.1']}',
                                color: karColor,
                              )
                            ],
                          )
                        ],
                      ),
                _signed
                    ? Container()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Theme(
                            child: SizedBox(
                              height: 48,
                              width: 32,
                              child: Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Checkbox(
                                  value: _accepted2,
                                  onChanged: (v) {
                                    setState(() {
                                      _accepted2 = v;
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dic['auction.read'],
                                style: TextStyle(color: cardColor),
                              ),
                              JumpToLink(
                                'https://acala.network/privacy',
                                text: ' ${dic['auction.term.2']}',
                                color: karColor,
                              )
                            ],
                          )
                        ],
                      ),
                Container(
                  margin: EdgeInsets.only(top: 16, bottom: 32),
                  child: _signed
                      ? RoundedButton(
                          text: dic['auction.contribute'],
                          color: _emailValid ? karColor : Colors.grey,
                          onPressed: _emailValid ? _goToContribute : () => null,
                        )
                      : RoundedButton(
                          icon:
                              _submitting ? CupertinoActivityIndicator() : null,
                          text: dic['auction.accept'],
                          color: allAccepted && !_submitting
                              ? karColor
                              : Colors.grey,
                          onPressed: allAccepted && !_submitting
                              ? _acceptAndSign
                              : () => null,
                        ),
                )
              ],
            )
    ]);
  }
}

class CrowdLoanPageLayout extends StatelessWidget {
  CrowdLoanPageLayout(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset(
                'assets/images/public/kar_bg.png',
                width: MediaQuery.of(context).size.width / 3,
              )
            ],
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(16, 72, 16, 16),
            children: children,
          ),
          Container(
            height: 56,
            margin: EdgeInsets.only(top: 32, left: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: cardColor),
                    onPressed: () => Navigator.of(context).pop()),
                Text(
                  title,
                  style: TextStyle(color: cardColor, fontSize: 24),
                ),
                Container(width: 48)
              ],
            ),
          )
        ],
      ),
    );
  }
}

class JumpToLink extends StatefulWidget {
  JumpToLink(this.url, {this.text, this.color});

  final String text;
  final String url;
  final Color color;

  @override
  _JumpToLinkState createState() => _JumpToLinkState();
}

class _JumpToLinkState extends State<JumpToLink> {
  bool _loading = false;

  Future<void> _launchUrl() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    await UI.launchURL(widget.url);

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text(
              widget.text ?? widget.url,
              style: TextStyle(
                  color: widget.color ?? Theme.of(context).primaryColor),
            ),
          ),
          Icon(Icons.open_in_new,
              size: 16, color: widget.color ?? Theme.of(context).primaryColor)
        ],
      ),
      onTap: _launchUrl,
    );
  }
}

class CountdownPanel extends StatefulWidget {
  CountdownPanel({
    this.cardColor,
    this.cardTextColor,
    this.textColor,
    this.endTime,
  });

  final Color cardColor;
  final Color cardTextColor;
  final Color textColor;
  final DateTime endTime;

  @override
  _CountdownPanel createState() => _CountdownPanel();
}

class _CountdownPanel extends State<CountdownPanel> {
  Timer _timer;

  void _updateTime() {
    setState(() {
      _timer = Timer(Duration(seconds: 1), _updateTime);
    });
  }

  Widget _buildCard(String text) {
    return Container(
      margin: EdgeInsets.only(left: 4, right: 2),
      padding: EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        color: widget.cardColor,
      ),
      constraints: BoxConstraints(minWidth: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: widget.cardTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            fontFamily: 'BebasNeue'),
      ),
    );
  }

  String formatTime(int num) {
    final str = num.toString();
    return str.length == 1 ? '0$str' : str;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = widget.endTime.difference(now);
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCard(left.inDays.toString()),
          Text(
            'days',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
          ),
          _buildCard(
              '${formatTime(left.inHours % 24)}:${formatTime(left.inMinutes % 60)}:${formatTime(left.inSeconds % 60)}'),
          Text(
            'left',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
          ),
        ],
      ),
    );
  }
}
