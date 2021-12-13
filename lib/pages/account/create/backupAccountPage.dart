import 'package:app/pages/account/create/accountAdvanceOption.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class BackupAccountPage extends StatefulWidget {
  const BackupAccountPage(this.service);
  final AppService service;

  static final String route = '/account/backup';

  @override
  _BackupAccountPageState createState() => _BackupAccountPageState();
}

class _BackupAccountPageState extends State<BackupAccountPage> {
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();
  int _step = 0;

  List<String> _wordsSelected;
  List<String> _wordsLeft;

  AddressIconDataWithMnemonic _addressIcon = AddressIconDataWithMnemonic();

  Future<void> _generateAccount({String key = ''}) async {
    final addressInfo = await widget.service.plugin.sdk.api.keyring
        .generateMnemonic(widget.service.plugin.basic.ss58,
            cryptoType: _advanceOptions.type,
            derivePath: _advanceOptions.path,
            key: key);
    setState(() {
      _addressIcon = addressInfo;
    });

    if (key.isEmpty) {
      widget.service.store.account.setNewAccountKey(addressInfo.mnemonic);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAccount();
    });
  }

  Widget _buildStep0(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Observer(
      builder: (_) {
        final mnemonics = widget.service.store.account.newAccount.key ?? '';
        return Scaffold(
          appBar: AppBar(
              title: Text(dic['create']),
              centerTitle: true,
              leading: BackBtn()),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(top: 16),
                    children: <Widget>[
                      Visibility(
                          visible: _addressIcon.svg != null,
                          child: Padding(
                              padding: EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: AddressFormItem(
                                  KeyPairData()
                                    ..icon = _addressIcon.svg
                                    ..address = _addressIcon.address,
                                  isShowSubtitle: false))),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Text(
                          dic['create.warn3'],
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Text(dic['create.warn4']),
                      ),
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        child: Text(
                          mnemonics,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      AccountAdvanceOption(
                        api: widget.service.plugin.sdk.api.keyring,
                        seed: mnemonics,
                        onChange: (data) {
                          setState(() {
                            _advanceOptions = data;
                          });

                          _generateAccount(key: mnemonics);
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Button(
                    title: I18n.of(context)
                        .getDic(i18n_full_dic_ui, 'common')['next'],
                    onPressed: () {
                      final isKeyValid = mnemonics.split(' ').length == 12;
                      if ((_advanceOptions.error ?? false) || !isKeyValid)
                        return;

                      setState(() {
                        _step = 1;
                        _wordsSelected = <String>[];
                        _wordsLeft = mnemonics.split(' ');
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['create']),
          leading: BackBtn(
            onBack: () {
              setState(() {
                _step = 0;
              });
            },
          )),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    dic['backup'],
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      dic['backup.confirm'],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      GestureDetector(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            dic['backup.reset'],
                            style: TextStyle(fontSize: 14, color: Colors.pink),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _wordsLeft = widget
                                .service.store.account.newAccount.key
                                .split(' ');
                            _wordsSelected = [];
                          });
                        },
                      )
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black12,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _wordsSelected.join(' ') ?? '',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                  _buildWordsButtons(),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Button(
                title:
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
                onPressed: _wordsSelected.join(' ') ==
                        widget.service.store.account.newAccount.key
                    ? () => Navigator.of(context).pop(_advanceOptions)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordsButtons() {
    if (_wordsLeft.length > 0) {
      _wordsLeft.sort();
    }

    // List<Widget> rows = <Widget>[];
    // for (var r = 0; r * 3 < _wordsLeft.length; r++) {
    //   if (_wordsLeft.length > r * 3) {
    //     rows.add(Row(
    //       children: _wordsLeft
    //           .getRange(
    //               r * 3,
    //               _wordsLeft.length > (r + 1) * 3
    //                   ? (r + 1) * 3
    //                   : _wordsLeft.length)
    //           .map(
    //             (i) => Container(
    //               padding: EdgeInsets.only(left: 4, right: 4),
    //               child: RaisedButton(
    //                 child: Text(
    //                   i,
    //                 ),
    //                 onPressed: () {
    //                   setState(() {
    //                     _wordsLeft.remove(i);
    //                     _wordsSelected.add(i);
    //                   });
    //                 },
    //               ),
    //             ),
    //           )
    //           .toList(),
    //     ));
    //   }
    // }
    return Container(
      padding: EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 2,
        runSpacing: 3,
        children: _wordsLeft
            .map((e) => Container(
                  padding: EdgeInsets.only(left: 4, right: 4),
                  child: ElevatedButton(
                    child: Text(
                      e,
                    ),
                    onPressed: () {
                      setState(() {
                        _wordsLeft.remove(e);
                        _wordsSelected.add(e);
                      });
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildStep0(context);
      case 1:
        return _buildStep1(context);
      default:
        return Container();
    }
  }
}
