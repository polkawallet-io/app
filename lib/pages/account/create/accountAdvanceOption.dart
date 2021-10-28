import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class AccountAdvanceOption extends StatefulWidget {
  AccountAdvanceOption({this.api, this.seed, this.onChange});

  final ApiKeyring api;
  final Function(AccountAdvanceOptionParams) onChange;
  final String seed;

  @override
  _AccountAdvanceOption createState() => _AccountAdvanceOption();
}

class _AccountAdvanceOption extends State<AccountAdvanceOption> {
  final TextEditingController _pathCtrl = new TextEditingController();

  final List<CryptoType> _typeOptions = [
    CryptoType.sr25519,
    CryptoType.ed25519,
  ];

  int _typeSelection = 0;

  bool _expanded = false;
  String _derivePath = '';
  String _pathError;

  Future<String> _doCheckPath(String path) async {
    if (path.isEmpty) return null;

    final invalidPath = 'Invalid derive path';
    if (!path.startsWith('/')) {
      return invalidPath;
    }
    return widget.api
        .checkDerivePath(widget.seed, path, _typeOptions[_typeSelection]);
  }

  String _checkDerivePath(String path, {bool forceCheck = false}) {
    if (widget.seed != "" && path != _derivePath || forceCheck) {
      final invalidPath = 'Invalid derive path';
      _doCheckPath(path).then((res) {
        setState(() {
          _derivePath = path;
          _pathError = res != null ? invalidPath : null;
        });
        widget.onChange(AccountAdvanceOptionParams(
          type: _typeOptions[_typeSelection],
          path: path,
          error: res != null,
        ));
      });
    }
    return _pathError;
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(left: 8, top: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    _expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 30,
                    color: Theme.of(context).unselectedWidgetColor,
                  ),
                  Text(dic['advanced'])
                ],
              ),
            ),
            onTap: () {
              // clear state while advanced options closed
              if (_expanded) {
                setState(() {
                  _typeSelection = 0;
                  _pathCtrl.text = '';
                });
                widget.onChange(AccountAdvanceOptionParams(
                  type: _typeOptions[0],
                  path: '',
                ));
              }
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
        ),
        Visibility(
            visible: _expanded,
            child: ListTile(
              title: Text(dic['import.encrypt']),
              subtitle:
                  Text(_typeOptions[_typeSelection].toString().split('.')[1]),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => Container(
                    height: MediaQuery.of(context).copyWith().size.height / 3,
                    child: CupertinoPicker(
                      backgroundColor: Colors.white,
                      itemExtent: 56,
                      scrollController: FixedExtentScrollController(
                          initialItem: _typeSelection),
                      children: _typeOptions
                          .map((i) => Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(i.toString().split('.')[1])))
                          .toList(),
                      onSelectedItemChanged: (v) {
                        setState(() {
                          _typeSelection = v;
                        });
                        String error;
                        if (_pathCtrl.text.isNotEmpty) {
                          error = _checkDerivePath(_pathCtrl.text,
                              forceCheck: true);
                        }
                        widget.onChange(AccountAdvanceOptionParams(
                          type: _typeOptions[v],
                          // path: _derivePath,
                          path: _pathCtrl.text,
                          error: error != null,
                        ));
                      },
                    ),
                  ),
                );
              },
            )),
        Visibility(
            visible: _expanded,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: '//hard/soft///password',
                  labelText: dic['path'],
                ),
                controller: _pathCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _checkDerivePath,
              ),
            )),
      ],
    );
  }
}

class AccountAdvanceOptionParams {
  AccountAdvanceOptionParams(
      {this.type = CryptoType.sr25519, this.path = '', this.error = false});
  CryptoType type;
  String path;
  bool error;
}
