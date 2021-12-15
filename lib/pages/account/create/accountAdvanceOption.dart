import 'package:app/pages/profile/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/collapsedContainer.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/textFormField.dart' as v3;

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
    return CollapsedContainer(
      title: dic['advanced'],
      child: Column(
        children: [
          RoundedCard(
            margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
            padding: EdgeInsets.all(8.w),
            child: SettingsPageListItem(
              label: dic['import.encrypt'],
              subtitle: _typeOptions[_typeSelection].toString().split('.')[1],
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
            ),
          ),
          v3.TextInputWidget(
            decoration: v3.InputDecorationV3(
              hintText: '//hard/soft///password',
              labelText: dic['path'],
            ),
            controller: _pathCtrl,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _checkDerivePath,
          )
        ],
      ),
      onCollapse: (v) {
        // clear state while advanced options closed
        if (v) {
          setState(() {
            _typeSelection = 0;
            _pathCtrl.text = '';
          });
          widget.onChange(AccountAdvanceOptionParams(
            type: _typeOptions[0],
            path: '',
          ));
        }
      },
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
