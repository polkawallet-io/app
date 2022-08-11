import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/profile/account/changeNamePage.dart';
import 'package:app/pages/profile/account/changePasswordPage.dart';
import 'package:app/pages/profile/account/exportAccountPage.dart';
import 'package:app/pages/profile/account/signPage.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/passwordInputDialog.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';

class AccountManagePage extends StatefulWidget {
  AccountManagePage(this.service);
  final AppService service;

  static final String route = '/profile/account';

  @override
  _AccountManagePageState createState() => _AccountManagePageState();
}

class _AccountManagePageState extends State<AccountManagePage> {
  bool _supportBiometric = false; // if device support biometric
  bool _isBiometricAuthorized = false; // if user authorized biometric usage
  BiometricStorageFile _authStorage;

  Future<void> _onDeleteAccount(BuildContext context) async {
    final password = await widget.service.account
        .getPassword(context, widget.service.keyring.current);
    if (password != null) {
      if (widget.service.store.account.accountType == AccountType.Substrate) {
        widget.service.plugin.sdk.api.keyring
            .deleteAccount(
                widget.service.keyring, widget.service.keyring.current)
            .then((_) {
          // refresh balance
          widget.service.plugin.changeAccount(widget.service.keyring.current);

          widget.service.store.assets.loadCache(
              widget.service.keyring.current, widget.service.plugin.basic.name);
        });
      } else {
        widget.service.plugin.sdk.api.eth.keyring
            .deleteAccount(
                widget.service.keyringEVM, widget.service.keyringEVM.current)
            .then((_) {
          // // refresh balance
          // widget.service.plugin.changeAccount(widget.service.keyring.current);

          // widget.service.store.assets.loadCache(
          //     widget.service.keyring.current, widget.service.plugin.basic.name);
        });
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateBiometricAuth(bool enable) async {
    print('enable: $enable');
    final pubKey = widget.service.keyring.current.pubKey;
    final password = await showCupertinoDialog(
      context: context,
      builder: (_) {
        return PasswordInputDialog(
          widget.service.plugin.sdk.api,
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_app, 'account')['unlock']),
          account: widget.service.keyring.current,
        );
      },
    );
    if (password == null) return;

    bool result = !enable;
    if (enable) {
      try {
        print('write: $password');
        await _authStorage.write(password);
        print('setBiometricEnabled');
        widget.service.account.setBiometricEnabled(pubKey);
        result = enable;
      } catch (err) {
        print(err);
        // user may cancel the biometric auth. then we set biometric disabled
        widget.service.account.closeBiometricDisabled(pubKey);
      }
    } else {
      widget.service.account.closeBiometricDisabled(pubKey);
      result = enable;
    }

    if (result == enable) {
      setState(() {
        _isBiometricAuthorized = enable;
      });
    }
  }

  Future<void> _checkBiometricAuth() async {
    final response = await BiometricStorage().canAuthenticate();
    final supportBiometric = response == CanAuthenticateResponse.success;
    print(response);
    if (!supportBiometric) {
      return;
    }
    setState(() {
      _supportBiometric = supportBiometric;
    });
    final pubKey = widget.service.keyring.current.pubKey;
    final storeFile =
        await widget.service.account.getBiometricPassStoreFile(context, pubKey);
    final isAuthorized =
        !widget.service.account.isCloseBiometricDisabled(pubKey);
    setState(() {
      _isBiometricAuthorized = isAuthorized;
      _authStorage = storeFile;
    });
  }

  Future<void> _onChangePass() async {
    final res = await Navigator.pushNamed(context, ChangePasswordPage.route);
    // refresh biometric auth status after password changed
    if (res ?? false) {
      _checkBiometricAuth();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    final dynamic acc =
        widget.service.store.account.accountType == AccountType.Substrate
            ? widget.service.keyring.current
            : widget.service.keyringEVM.current;

    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['account']),
          centerTitle: true,
          elevation: 0.0,
          leading: BackBtn()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  children: [
                    AddressIcon(acc.address, svg: acc.icon, size: 60.w),
                    Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(UI.accountName(context, acc),
                            style: Theme.of(context).textTheme.headline3)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Fmt.address(acc.address) ?? '',
                          style: TextStyle(
                              fontSize: UI.getTextSize(16, context),
                              color: Theme.of(context).unselectedWidgetColor),
                        ),
                        GestureDetector(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(4.w, 2.h, 8.w, 0),
                            child: SvgPicture.asset(
                              'assets/images/qr.svg',
                              color: Theme.of(context).toggleableActiveColor,
                              width: 24.w,
                            ),
                          ),
                          onTap: () => Navigator.pushNamed(
                              context, AccountQrCodePage.route),
                        )
                      ],
                    )
                  ],
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      label: dic['name.change'],
                      onTap: () async {
                        await Navigator.pushNamed(
                            context, ChangeNamePage.route);
                        setState(() {});
                      },
                    ),
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: dic['pass.change'],
                      onTap: () => _onChangePass(),
                    ),
                  ],
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      label: dic['sign'],
                      onTap: () {
                        Navigator.of(context).pushNamed(SignMessagePage.route);
                      },
                    ),
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: dic['export'],
                      onTap: () => Navigator.of(context)
                          .pushNamed(ExportAccountPage.route),
                    ),
                    Divider(height: 24.h),
                    SettingsPageListItem(
                      label: I18n.of(context).getDic(
                          i18n_full_dic_app, 'account')['unlock.bio.enable'],
                      content: v3.CupertinoSwitch(
                        value: _isBiometricAuthorized,
                        onChanged: (v) {
                          if (v != _isBiometricAuthorized) {
                            _updateBiometricAuth(v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
                child: CupertinoButton(
                  color: Theme.of(context).cardColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dic['delete'],
                          style: TextStyle(
                            color: Theme.of(context).errorColor,
                            fontFamily:
                                UI.getFontFamily('TitilliumWeb', context),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                  onPressed: () => _onDeleteAccount(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
