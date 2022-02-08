import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class CupertinoAlertDialogContentWithCheckbox extends StatefulWidget {
  CupertinoAlertDialogContentWithCheckbox({this.content});
  final Widget content;
  @override
  _CupertinoAlertDialogContentWithCheckboxState createState() =>
      _CupertinoAlertDialogContentWithCheckboxState();
}

class _CupertinoAlertDialogContentWithCheckboxState
    extends State<CupertinoAlertDialogContentWithCheckbox> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 16),
          child: widget.content,
        ),
        GestureDetector(
          child: Row(
            children: [
              Container(
                width: 32,
                margin: EdgeInsets.only(right: 8),
                child: FittedBox(
                  child: CupertinoSwitch(
                      value: _confirmed,
                      onChanged: (v) {
                        setState(() {
                          _confirmed = v;
                        });
                      }),
                ),
              ),
              Expanded(
                  child: Text(
                dic['dot.bridge.ok'],
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.bold),
              ))
            ],
          ),
          onTap: () {
            setState(() {
              _confirmed = !_confirmed;
            });
          },
        ),
        Container(height: 8),
        Divider(),
        CupertinoButton(
            padding: EdgeInsets.fromLTRB(32, 8, 32, 0),
            child:
                Text(I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
            onPressed: _confirmed ? () => Navigator.of(context).pop() : null)
      ],
    );
  }
}
