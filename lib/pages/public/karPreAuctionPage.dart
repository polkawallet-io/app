import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class KarPreAuctionPage extends StatefulWidget {
  KarPreAuctionPage(this.service);
  final AppService service;

  static final String route = '/public/kar/pre';

  @override
  _KarPreAuctionPageState createState() => _KarPreAuctionPageState();
}

class _KarPreAuctionPageState extends State<KarPreAuctionPage> {
  final _emailRegEx = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  final FocusNode _emailFocusNode = FocusNode();

  KeyPairData _account = KeyPairData();

  bool _submitting = false;
  bool _emailValid = false;
  String _email = '';

  Future<void> _selectAccount() async {
    final res = await Navigator.of(context).pushNamed(AccountListPage.route,
        arguments: AccountListPageParams(
            list: widget.service.keyring.keyPairs, title: 'Accounts'));
    if (res != null) {
      setState(() {
        _account = res;
      });
    }
  }

  void _onEmailChange(String value) {
    final v = value.trim();
    final valid = _emailRegEx.hasMatch(v);
    setState(() {
      _emailValid = valid;
      _email = v;
    });
  }

  Future<void> _signAndSubmit() async {
    if (_submitting || !_emailValid) return;

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
        "data": 'Acala & Karura Testnet Festival Season 5',
      };

      final signRes = await widget.service.plugin.sdk.api.keyring
          .signAsExtension(password, params);
      final submitted = await widget.service.account
          .postKarPreAuction(_account.pubKey, _email, signRes.signature);
      if (submitted != null && (submitted['result'] ?? false)) {
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
      } else {
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text('Failed'),
              content: Text(submitted['reason']),
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

      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _account = widget.service.keyring.current;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _emailFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final karColor = Colors.red;
    final grayColor = Colors.white70;
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
            padding: EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 4, bottom: 24, top: 64),
                    child: Image.asset(
                      'assets/images/public/kar_logo.png',
                      width: MediaQuery.of(context).size.width * 2 / 3,
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pre-support the',
                      style: TextStyle(fontSize: 24, color: cardColor)),
                  Container(
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: karColor),
                        borderRadius: BorderRadius.all(Radius.circular(64))),
                    child: Row(
                      children: [
                        Expanded(
                            child: FittedBox(
                                child: Text('Karura Parachain Auction',
                                    style: TextStyle(
                                        color: karColor,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic))))
                      ],
                    ),
                  ),
                  Text('Crowdsourcing event now live!',
                      style: TextStyle(fontSize: 22, color: cardColor)),
                  Container(
                    margin: EdgeInsets.only(top: 24, bottom: 32),
                    child: Text(
                      'Karura is the decentralized financial hub of Kusama. The blockchain, optimized for DeFi and powered by KAR, was built to enable scalable financial applications with micro gas fees and communication with other networks on Kusama, Polkadot, and beyond.',
                      style: TextStyle(color: cardColor),
                    ),
                  )
                ],
              ),
              Container(
                margin: EdgeInsets.only(bottom: 4),
                child: Divider(color: grayColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address',
                    style: TextStyle(color: grayColor, fontSize: 18),
                  ),
                  GestureDetector(
                    child: Container(
                      margin: EdgeInsets.only(top: 8, bottom: 8),
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
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
                  Text(
                    'Email',
                    style: TextStyle(color: grayColor, fontSize: 18),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 8, bottom: 24),
                    child: CupertinoTextField(
                      padding: EdgeInsets.all(16),
                      placeholder: 'Email',
                      placeholderStyle:
                          TextStyle(color: grayColor, fontSize: 18),
                      style: TextStyle(color: cardColor, fontSize: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(64)),
                        border: Border.all(
                            color: _emailFocusNode.hasFocus
                                ? karColor
                                : grayColor),
                      ),
                      cursorColor: karColor,
                      focusNode: _emailFocusNode,
                      onChanged: _onEmailChange,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 32),
                    child: RoundedButton(
                      text: 'Sign & Submit',
                      icon: _submitting ? CupertinoActivityIndicator() : null,
                      color:
                          _emailValid && !_submitting ? karColor : Colors.grey,
                      onPressed: _signAndSubmit,
                    ),
                  )
                ],
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 24, left: 8),
            child: Row(
              children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: cardColor),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ),
          )
        ],
      ),
    );
  }
}
