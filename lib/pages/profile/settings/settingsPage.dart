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
  final _priceCurrencyOptions = ['USD', 'CNY'];

  int _selectedPriceCurrency = 0;

  String _getLang(String code) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    switch (code) {
      case 'zh':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return dic['setting.lang.auto'];
    }
  }

  String _getPriceCurrency(String currency) {
    switch (currency) {
      case 'CNY':
        return '¥ CNY';
      default:
        return '\$ USD';
    }
  }

  void _onLanguageTap() {
    final cached = widget.service.store.settings.localeCode;
    int selected = _langOptions.indexOf(cached);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: MediaQuery.of(context).copyWith().size.height / 3,
        child: WillPopScope(
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 58,
            scrollController:
                FixedExtentScrollController(initialItem: selected),
            children: _langOptions.map((i) {
              return Padding(
                  padding: EdgeInsets.all(16), child: Text(_getLang(i)));
            }).toList(),
            onSelectedItemChanged: (v) {
              selected = v;
            },
          ),
          onWillPop: () async {
            final code = _langOptions[selected];
            if (code != cached) {
              widget.changeLang(code);
            }
            return true;
          },
        ),
      ),
    );
  }

  void _onCurrencyTap() {
    final cached = widget.service.store.settings.priceCurrency;
    int selected = _priceCurrencyOptions.indexOf(cached);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: MediaQuery.of(context).copyWith().size.height / 3,
        child: WillPopScope(
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 58,
            scrollController:
                FixedExtentScrollController(initialItem: selected),
            children: _priceCurrencyOptions.map((i) {
              return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(_getPriceCurrency(i)));
            }).toList(),
            onSelectedItemChanged: (v) {
              selected = v;
            },
          ),
          onWillPop: () async {
            final currency = _priceCurrencyOptions[selected];
            if (currency != cached) {
              setState(() {
                _selectedPriceCurrency = selected;
              });
              widget.service.store.settings.setPriceCurrency(currency);
            }
            return true;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['setting']),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          final hideBalanceTip = widget.service.store.settings.isHideBalance
              ? dic['setting.currency.tip']
              : '';
          final currencyTip =
              widget.service.store.settings.priceCurrency == 'CNY'
                  ? ' (${dic['setting.currency.tip']})'
                  : '';
          return SafeArea(
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text(dic['setting.balance.hide']),
                  subtitle:
                      hideBalanceTip.isEmpty ? null : Text(hideBalanceTip),
                  trailing: CupertinoSwitch(
                    value: widget.service.store.settings.isHideBalance,
                    onChanged: (v) =>
                        widget.service.store.settings.setIsHideBalance(v),
                  ),
                ),
                ListTile(
                  title: Text(dic['setting.currency']),
                  subtitle: Text(_getPriceCurrency(
                          widget.service.store.settings.priceCurrency) +
                      currencyTip),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _onCurrencyTap,
                ),
                ListTile(
                  title: Text(dic['setting.lang']),
                  subtitle:
                      Text(_getLang(widget.service.store.settings.localeCode)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _onLanguageTap,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
