import 'package:app/pages/homePage.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:rive/src/widgets/rive_animation.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage(
      this.service, this.changeLang, this.changeNode, this.changeDarkTheme);
  final AppService service;
  final Function(String) changeLang;
  final Future<void> Function(NetworkParams) changeNode;
  final Function(bool) changeDarkTheme;
  static final String route = '/profile/settings';

  @override
  _Settings createState() => _Settings();
}

class _Settings extends State<SettingsPage> {
  final _langOptions = ['', 'en', 'zh'];
  final _priceCurrencyOptions = [
    'USD',
    'CNY',
    'EUR',
    'GBP',
    'RUB',
    'HKD',
    'NZD',
    'AUD',
    'TWD',
    'KRW',
    'JPY'
  ];
  bool _isLoading = false;

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
// CNY（人民币）Chinese Yuan (¥)
// USD（美元）United States Dollar ($)
// EUR（欧元）Euro (€)
// GBP（英镑）Pound Sterling (£)
// RUB（卢布）Russian Ruble (₽)
// HKD（港币）Hong Kong Dollar ($)
// NZD（新西兰元）New Zealand Dollar ($)
// AUD（澳元）Australian Dollar ($)
// TWD（台币）New Taiwan Dollar (NT$)
// KRW（韩元）South Korean Won (₩)
// JPY（日元）Japanese Yen (¥)
    switch (currency) {
      case 'CNY':
        return '￥ CNY';
      case 'EUR':
        return '€ EUR';
      case 'GBP':
        return '£ GBP';
      case 'RUB':
        return '₽ RUB';
      case 'HKD':
        return '\$ HKD';
      case 'NZD':
        return '\$ NZD';
      case 'AUD':
        return '\$ AUD';
      case 'TWD':
        return 'NT\$ TWD';
      case 'KRW':
        return '₩ KRW';
      case 'JPY':
        return '¥ JPY';
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
                  padding: EdgeInsets.all(16),
                  child:
                      Text(_getLang(i), style: TextStyle(color: Colors.black)));
            }).toList(),
            onSelectedItemChanged: (v) {
              selected = v;
            },
          ),
          onWillPop: () async {
            final code = _langOptions[selected];
            if (code != cached) {
              widget.changeLang(code == ''
                  ? Localizations.localeOf(context).toString()
                  : code);
              setState(() {
                _isLoading = true;
              });
              Future.delayed(Duration(milliseconds: 1500), () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    HomePage.route, (route) => false,
                    arguments: {"tab": 0});
              });
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
                  child: Text(_getPriceCurrency(i),
                      style: TextStyle(color: Colors.black)));
            }).toList(),
            onSelectedItemChanged: (v) {
              selected = v;
            },
          ),
          onWillPop: () async {
            final currency = _priceCurrencyOptions[selected];
            if (currency != cached) {
              widget.service.store.settings.setPriceCurrency(currency);
              setState(() {});
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
    return _isLoading
        ? Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Container(
                  margin: EdgeInsets.only(bottom: 100),
                  width: 150,
                  child: RiveAnimation.asset(
                    'assets/images/public/switchLanguage.riv',
                    fit: BoxFit.contain,
                  )),
            ),
          )
        : Scaffold(
            appBar: AppBar(
                title: Text(dic['setting']),
                centerTitle: true,
                leading: BackBtn()),
            body: Observer(
              builder: (_) {
                final hideBalanceTip =
                    widget.service.store.settings.isHideBalance
                        ? dic['setting.currency.tip']
                        : '';
                final currencyTip =
                    widget.service.store.settings.priceCurrency != "USD"
                        ? ' (${dic['setting.currency.tip']})'
                        : '';
                return SafeArea(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: RoundedCard(
                      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                      padding: UI.isDarkTheme(context)
                          ? EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h)
                          : EdgeInsets.fromLTRB(
                              8.75.w, 16.75.h, 8.75.w, 16.75.h),
                      child: Column(
                        children: <Widget>[
                          SettingsPageListItem(
                            label: dic['setting.balance.hide'],
                            subtitle:
                                hideBalanceTip.isEmpty ? null : hideBalanceTip,
                            content: v3.CupertinoSwitch(
                              value:
                                  widget.service.store.settings.isHideBalance,
                              onChanged: (v) => widget.service.store.settings
                                  .setIsHideBalance(v),
                            ),
                          ),
                          Divider(height: 24.h),
                          SettingsPageListItem(
                            label: dic['setting.theme.dark'],
                            content: v3.CupertinoSwitch(
                              value: widget.service.store.settings.isDarkTheme,
                              onChanged: (v) {
                                widget.changeDarkTheme(v);
                              },
                            ),
                          ),
                          Divider(height: 24.h),
                          SettingsPageListItem(
                            label: dic['setting.currency'],
                            subtitle: _getPriceCurrency(widget
                                    .service.store.settings.priceCurrency) +
                                currencyTip,
                            onTap: _onCurrencyTap,
                          ),
                          Divider(height: 24.h),
                          SettingsPageListItem(
                            label: dic['setting.lang'],
                            subtitle: _getLang(
                                widget.service.store.settings.localeCode),
                            onTap: _onLanguageTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
