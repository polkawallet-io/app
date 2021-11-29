import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage(this.service, this.changeLang, this.changeNode);
  final AppService service;
  final Function(String) changeLang;
  final Future<void> Function(NetworkParams) changeNode;
  static final String route = '/profile/settings';

  @override
  _Settings createState() => _Settings();
}

class _Settings extends State<SettingsPage> {
  final _langOptions = ['', 'en', 'zh'];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    String getLang(String code) {
      switch (code) {
        case 'zh':
          return '简体中文';
        case 'en':
          return 'English';
        default:
          return dic['setting.lang.auto'];
      }
    }

    void _onLanguageTap() {
      final cached = widget.service.store.settings.localeCode;
      _selected = _langOptions.indexOf(cached);
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          child: WillPopScope(
            child: CupertinoPicker(
              backgroundColor: Colors.white,
              itemExtent: 58,
              scrollController:
                  FixedExtentScrollController(initialItem: _selected),
              children: _langOptions.map((i) {
                return Padding(
                    padding: EdgeInsets.all(16), child: Text(getLang(i)));
              }).toList(),
              onSelectedItemChanged: (v) {
                setState(() {
                  _selected = v;
                });
              },
            ),
            onWillPop: () async {
              String code = _langOptions[_selected];
              if (code != cached) {
                widget.changeLang(code);
              }
              return true;
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['setting']),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) => SafeArea(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: Text(dic['setting.lang']),
                subtitle:
                    Text(getLang(widget.service.store.settings.localeCode)),
                trailing: Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () => _onLanguageTap(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
