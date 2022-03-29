import 'package:app/common/consts.dart';
import 'package:app/pages/profile/aboutPage.dart';
import 'package:app/pages/profile/account/accountManagePage.dart';
import 'package:app/pages/profile/communityPage.dart';
import 'package:app/pages/profile/contacts/contactPage.dart';
import 'package:app/pages/profile/contacts/contactsPage.dart';
import 'package:app/pages/profile/message/messagePage.dart';
import 'package:app/pages/profile/recovery/recoveryProofPage.dart';
import 'package:app/pages/profile/recovery/recoverySettingPage.dart';
import 'package:app/pages/profile/recovery/recoveryStatePage.dart';
import 'package:app/pages/profile/settings/remoteNodeListPage.dart';
import 'package:app/pages/profile/settings/settingsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage(this.service, this.connectedNode);

  final AppService service;
  final NetworkParams connectedNode;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  KeyPairData _currentAccount;

  Future<void> _manageAccount() async {
    if (widget.service.keyring.current.observation ?? false) {
      await Navigator.pushNamed(context, ContactPage.route,
          arguments: widget.service.keyring.current);
    } else {
      await Navigator.pushNamed(context, AccountManagePage.route);
    }
    setState(() {
      _currentAccount = widget.service.keyring.current;
    });
  }

  void _showRecoveryMenu(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(dic['recovery.make']),
            onPressed: () {
              Navigator.of(context).popAndPushNamed(RecoverySettingPage.route);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(dic['recovery.init']),
            onPressed: () {
              Navigator.of(context).popAndPushNamed(RecoveryStatePage.route);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(dic['recovery.help']),
            onPressed: () {
              Navigator.of(context).popAndPushNamed(RecoveryProofPage.route);
            },
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final Color grey = Theme.of(context).unselectedWidgetColor;
    final acc = widget.service.keyring.current;
    final primaryColor = Theme.of(context).primaryColor;

    final labelStyle = Theme.of(context).textTheme.headline4;
    final blue = Theme.of(context).toggleableActiveColor;
    final iconGrey = Color(0xFFCECECE);
    final pagePadding = 16.w;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['title']),
        centerTitle: true,
        elevation: 0.0,
        actions: [
          Center(child: Observer(builder: (_) {
            return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(MessagePage.route);
                },
                child: Container(
                  width: 32.h,
                  height: 32.h,
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              "packages/polkawallet_ui/assets/images/icon_bg_grey.png"),
                          fit: BoxFit.fill)),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                          width: double.infinity,
                          height: double.infinity,
                          padding: EdgeInsets.only(right: 1, bottom: 1),
                          child: Image.asset("assets/images/message.png",
                              width: 24.h)),
                      Visibility(
                          visible: widget.service.store.settings
                                      .communityUnreadNumber +
                                  widget.service.store.settings
                                      .systemUnreadNumber >
                              0,
                          child: Container(
                            width: 9.h,
                            height: 9.h,
                            margin: EdgeInsets.only(right: 1, top: 1),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.5.h),
                                color: Theme.of(context).errorColor),
                          ))
                    ],
                  ),
                ));
          }))
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: RoundedCard(
                    margin: EdgeInsets.fromLTRB(
                        pagePadding, 4.h, pagePadding, 16.h),
                    padding: EdgeInsets.fromLTRB(24.w, 16.h, 0, 16.h),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 8.w),
                              child: AddressIcon(acc.address,
                                  svg: acc.icon, size: 60.w),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    child: Text(UI.accountName(context, acc),
                                        style: TextStyle(
                                            color: Color(0xFF565554),
                                            fontSize: 20,
                                            fontFamily: 'TitilliumWeb',
                                            fontWeight: FontWeight.w600)),
                                    onTap: _manageAccount,
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Fmt.address(acc.address) ?? '',
                                        style: TextStyle(
                                            fontSize: 16, color: grey),
                                      ),
                                      GestureDetector(
                                          child: Container(
                                            padding: EdgeInsets.fromLTRB(
                                                4.w, 2.h, 8.w, 0),
                                            child: SvgPicture.asset(
                                              'assets/images/qr.svg',
                                              color: blue,
                                              width: 24.w,
                                            ),
                                          ),
                                          onTap: () => Navigator.pushNamed(
                                              context, AccountQrCodePage.route))
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(16.w),
                              child: Image.asset(
                                  'assets/images/icons/arrow_forward.png',
                                  width: 30.w),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: _manageAccount),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 6.h),
                child: SettingsPageListItem(
                  leading: Image.asset(
                    'assets/images/icons/address_book.png',
                    width: 24.w,
                  ),
                  label: dic['contact'],
                  onTap: () async {
                    await Navigator.of(context).pushNamed(ContactsPage.route);
                    setState(() {
                      _currentAccount = widget.service.keyring.current;
                    });
                  },
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 6.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      leading: Image.asset(
                        'assets/images/icons/preference.png',
                        width: 24.w,
                      ),
                      label: dic['setting'],
                      onTap: () =>
                          Navigator.of(context).pushNamed(SettingsPage.route),
                    ),
                    Divider(),
                    SettingsPageListItem(
                      leading: Image.asset(
                        'assets/images/icons/remote_node.png',
                        width: 24.w,
                      ),
                      label: dic['setting.node'],
                      content: widget.connectedNode == null
                          ? CupertinoActivityIndicator(radius: 8)
                          : null,
                      onTap: () => Navigator.of(context)
                          .pushNamed(RemoteNodeListPage.route),
                    )
                  ],
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 6.h),
                child: Column(
                  children: [
                    widget.service.plugin.basic.name ==
                                para_chain_name_karura ||
                            widget.service.plugin.basic.name ==
                                para_chain_name_acala
                        ? Column(
                            children: [
                              SettingsPageListItem(
                                leading: Image.asset(
                                  'assets/images/icons/community.png',
                                  width: 24.w,
                                ),
                                label: dic['community'],
                                onTap: () => Navigator.of(context)
                                    .pushNamed(CommunityPage.route),
                              ),
                              Divider()
                            ],
                          )
                        : Container(),
                    SettingsPageListItem(
                      leading: Image.asset(
                        'assets/images/icons/guide.png',
                        width: 24.w,
                      ),
                      label: dic['guide'],
                      onTap: () =>
                          UI.launchURL('https://wiki.polkawallet.app/'),
                    )
                  ],
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 16.h),
                padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 6.h),
                child: SettingsPageListItem(
                  leading: Image.asset(
                    'assets/images/icons/about.png',
                    width: 24.w,
                  ),
                  label: dic['about'],
                  onTap: () => Navigator.of(context).pushNamed(AboutPage.route),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPageListItem extends StatelessWidget {
  SettingsPageListItem(
      {this.leading, this.label, this.subtitle, this.content, this.onTap});
  final Widget leading;
  final String label;
  final String subtitle;
  final Widget content;
  final Function onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Visibility(
            visible: leading != null,
            child: Container(
              padding: EdgeInsets.all(4.r),
              child: leading,
              decoration: BoxDecoration(
                  color: Color(0xFFCECECE),
                  borderRadius: BorderRadius.all(Radius.circular(8.r))),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 8.w, right: 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.headline4),
                  subtitle != null
                      ? Text(subtitle,
                          style: Theme.of(context).textTheme.headline6)
                      : Container(),
                ],
              ),
            ),
          ),
          Visibility(
            visible: content != null,
            child: content ?? Container(),
          ),
          onTap != null
              ? Image.asset('assets/images/icons/arrow_forward.png',
                  width: 24.w)
              : Container(width: 1),
        ],
      ),
      onTap: onTap,
    );
  }
}
