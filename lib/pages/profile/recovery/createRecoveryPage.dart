import 'package:app/common/consts.dart';
import 'package:app/pages/profile/recovery/friendListPage.dart';
import 'package:app/pages/profile/recovery/recoverySettingPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class CreateRecoveryPage extends StatefulWidget {
  CreateRecoveryPage(this.service);
  final AppService service;

  static final String route = '/profile/recovery/create';

  @override
  _CreateRecoveryPage createState() => _CreateRecoveryPage();
}

class _CreateRecoveryPage extends State<CreateRecoveryPage> {
  final FocusNode _delayFocusNode = FocusNode();
  final TextEditingController _delayCtrl = new TextEditingController();

  final double _configDepositBase = 5 / 6;
  final double _friendDepositFactor = 0.5 / 6;

  List<KeyPairData> _friends = [];
  double _threshold = 1;
  double _delay = 90;
  String _delayError;

  Future<void> _handleFriendsSelect() async {
    var res = await Navigator.of(context)
        .pushNamed(FriendListPage.route, arguments: _friends);
    if (res != null) {
      setState(() {
        _friends = List<KeyPairData>.of(res);
      });
    }
  }

  void _setDelay(String v, {bool custom = false}) {
    if (!custom) {
      _delayFocusNode.unfocus();
      setState(() {
        _delayCtrl.text = '';
      });
    }
    try {
      double value = double.parse(v.trim());
      if (value == 0) {
        setState(() {
          _delayError = I18n.of(context)
              .getDic(i18n_full_dic_app, 'profile')['input.invalid'];
        });
      } else {
        setState(() {
          _delay = value;
          _delayError = null;
        });
      }
    } catch (err) {
      setState(() {
        _delayError = I18n.of(context)
            .getDic(i18n_full_dic_app, 'profile')['input.invalid'];
      });
    }
  }

  void _onValidateSubmit() {
    final decimals = widget.service.plugin.networkState.tokenDecimals[0];
    String deposit =
        (_configDepositBase + _friends.length * _friendDepositFactor)
            .toString();
    if (!AppUI.checkBalanceAndAlert(
      context,
      widget.service.plugin.balances.native,
      Fmt.tokenInt(deposit, decimals),
    )) {
      return;
    }

    if (_delay < 30) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
          final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
          return CupertinoAlertDialog(
            title:
                Text('${dic['recovery.delay']} $_delay ${dic['recovery.day']}'),
            content: Text(dic['recovery.delay.warn']),
            actions: <Widget>[
              CupertinoButton(
                child: Text(
                  dicCommon['cancel'],
                  style: TextStyle(
                    color: Theme.of(context).unselectedWidgetColor,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoButton(
                child: Text(dicCommon['ok']),
                onPressed: () {
                  Navigator.of(context).pop();
                  _onSubmit();
                },
              ),
            ],
          );
        },
      );
    } else {
      _onSubmit();
    }
  }

  Future<void> _onSubmit() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    List<String> friends = _friends.map((e) => e.address).toList();
    friends.sort();
    int delayBlocks = _delay * SECONDS_OF_DAY ~/ 6;
    double deposit =
        _configDepositBase + _friends.length * _friendDepositFactor;

    final params = TxConfirmParams(
        txTitle: dic['recovery.create'],
        module: 'recovery',
        call: 'createRecovery',
        txDisplay: {
          'friends': friends,
          'threshold': _threshold.toInt(),
          'delay': '$_delay ${dic['recovery.day']}',
          'deposit':
              '${Fmt.doubleFormat(deposit)} ${widget.service.plugin.networkState.tokenSymbol[0]}'
        },
        params: [
          friends,
          _threshold.toInt(),
          delayBlocks
        ]);

    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final primary = Theme.of(context).primaryColor;
    final grey = Theme.of(context).disabledColor;
    final symbol = widget.service.plugin.networkState.tokenSymbol[0];

    final String depositMsg = '''

${dic['recovery.deposit']} = ${dic['recovery.deposit.base']} +
${dic['recovery.deposit.factor']} * ${dic['recovery.deposit.friends']}

${dic['recovery.deposit.base']} = ${Fmt.doubleFormat(_configDepositBase)} $symbol
${dic['recovery.deposit.factor']} = ${Fmt.doubleFormat(_friendDepositFactor)} $symbol
''';

    double deposit =
        _configDepositBase + _friends.length * _friendDepositFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['recovery.create']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(dic['recovery.friends']),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => _handleFriendsSelect(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: RecoveryFriendList(friends: _friends),
                    ),
                    Visibility(
                        visible: _friends.length > 1,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dic['recovery.threshold'],
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${_threshold.toInt()} / ${_friends.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                            ],
                          ),
                        )),
                    Visibility(
                        visible: _friends.length > 1,
                        child: ThresholdSlider(
                          value: _threshold,
                          friends: _friends,
                          onChanged: (v) {
                            setState(() {
                              _threshold = v;
                            });
                          },
                        )),
                    Padding(
                      padding: EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        dic['recovery.delay'],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          OutlinedButtonSmall(
                            content: '30 ${dic['recovery.day']}',
                            active: _delay == 30,
                            onPressed: () => _setDelay('30'),
                          ),
                          OutlinedButtonSmall(
                            content: '90 ${dic['recovery.day']}',
                            active: _delay == 90,
                            onPressed: () => _setDelay('90'),
                          ),
                          OutlinedButtonSmall(
                            content: '180 ${dic['recovery.day']}',
                            active: _delay == 180,
                            onPressed: () => _setDelay('180'),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                CupertinoTextField(
                                  padding: EdgeInsets.fromLTRB(12, 3, 12, 3),
                                  placeholder: dic['recovery.custom'],
                                  inputFormatters: [
                                    UI.decimalInputFormatter(6)
                                  ],
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(24)),
                                    border: Border.all(
                                        width: 0.5,
                                        color: _delayFocusNode.hasFocus
                                            ? primary
                                            : grey),
                                  ),
                                  controller: _delayCtrl,
                                  focusNode: _delayFocusNode,
                                  onChanged: (v) => _setDelay(v, custom: true),
                                  suffix: Container(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Text(
                                      dic['recovery.day'],
                                      style: TextStyle(
                                          color: _delayFocusNode.hasFocus
                                              ? primary
                                              : grey),
                                    ),
                                  ),
                                ),
                                Visibility(
                                    visible: _delayError != null,
                                    child: Text(
                                      _delayError ?? "",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    ListTile(
                      title: Container(
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text(dic['recovery.deposit']),
                            ),
                            TapTooltip(
                              message: depositMsg,
                              child: Icon(
                                Icons.info,
                                color: Theme.of(context).unselectedWidgetColor,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(
                        '${Fmt.doubleFormat(deposit)} $symbol',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                  text: I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['next'],
                  onPressed: _friends.length > 0 && _delayError == null
                      ? () {
                          _onValidateSubmit();
                        }
                      : null,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ThresholdSlider extends StatelessWidget {
  ThresholdSlider({this.value, this.friends, this.onChanged});

  final List<KeyPairData> friends;
  final double value;
  final Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    TextStyle h4 = Theme.of(context).textTheme.headline4;
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: [
          Text('1', style: h4),
          Expanded(
            child: CupertinoSlider(
              min: 1,
              max: friends.length.toDouble(),
              divisions: friends.length - 1,
              value: value,
              onChanged: onChanged,
            ),
          ),
          Text(friends.length.toString(), style: h4),
        ],
      ),
    );
  }
}
