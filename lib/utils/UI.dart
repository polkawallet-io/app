import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:app/common/consts.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:update_app/update_app.dart';

class AppUI {
  static Future<void> alertWASM(
    BuildContext context,
    Function onCancel, {
    bool isImport = false,
    String errorMsg,
  }) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String msg = dic['backup.error'];
    if (!isImport) {
      msg += dic['backup.error.2'];
    }
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PolkawalletAlertDialog(
          type: DialogType.warn,
          title: Container(),
          content: Text(errorMsg ?? msg),
          actions: <Widget>[
            PolkawalletActionSheetAction(
              child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> checkUpdate(
      BuildContext context, Map versions, BuildTargets buildTarget,
      {bool autoCheck = false}) async {
    if (versions == null || !Platform.isAndroid && !Platform.isIOS) return;
    String platform = Platform.isAndroid ? 'android' : 'ios';

    final int latestCode = versions[platform]['version-code'];
    final String latestBeta = versions[platform]['version-beta'];
    final int latestCodeBeta = versions[platform]['version-code-beta'];
    final int latestCodeStore = versions[platform]['version-code-store'];
    final int versionCodeMin = versions[platform]['version-code-min'];

    bool needUpdate = false;
    if ((autoCheck ? latestCode : latestCodeBeta) >
        await Utils.getBuildNumber()) {
      // new version found
      if (Platform.isAndroid && buildTarget == BuildTargets.playStore) {
        needUpdate = (latestCodeStore) > await Utils.getBuildNumber();
        if (!needUpdate && autoCheck) return;
      } else {
        needUpdate = true;
      }
    } else {
      if (autoCheck) return;
    }

    final Map dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final showLatestBeta =
        needUpdate ? latestBeta : await Utils.getAppVersion();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        List versionInfo = versions[platform]['info']
            [I18n.of(context).locale.toString().contains('zh') ? 'zh' : 'en'];
        return WillPopScope(
            onWillPop: () async {
              if (needUpdate && versionCodeMin > await Utils.getBuildNumber()) {
                exit(0);
              }
              return true;
            },
            child: Container(
                margin: EdgeInsets.only(left: 48, right: 48),
                padding: EdgeInsets.only(bottom: 50),
                child: Center(
                    child: Stack(
                  alignment: AlignmentDirectional.topCenter,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: needUpdate ? 105 : 106),
                        width: double.infinity,
                        height: (MediaQuery.of(context).size.width - 96) /
                            294 *
                            (needUpdate ? 421 : 298),
                        child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(60),
                                topRight: Radius.circular(60),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20)),
                            child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  padding: EdgeInsets.only(
                                      top: needUpdate ? 92 : 69,
                                      bottom: 20,
                                      left: 19,
                                      right: 19),
                                  width: double.infinity,
                                  height:
                                      (MediaQuery.of(context).size.width - 96) /
                                          294 *
                                          (needUpdate ? 421 : 298),
                                  decoration: BoxDecoration(
                                    color: needUpdate || UI.isDarkTheme(context)
                                        ? Colors.transparent
                                        : Colors.white,
                                    gradient:
                                        needUpdate || UI.isDarkTheme(context)
                                            ? null
                                            : LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                stops: [0.03, 0.3],
                                                colors: [
                                                  Color(0xFFFDF1EB),
                                                  Color(0xFFFFFFFF),
                                                ],
                                              ),
                                    image: needUpdate
                                        ? DecorationImage(
                                            image: AssetImage(
                                                "assets/images/update_app_bg${UI.isDarkTheme(context) ? "_dark" : ""}.png"))
                                        : UI.isDarkTheme(context)
                                            ? DecorationImage(
                                                image: AssetImage(
                                                    "assets/images/update_app_bg2_dark.png"))
                                            : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'V ${showLatestBeta.split("-")[0]}',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3
                                            ?.copyWith(
                                                fontSize: UI.getTextSize(
                                                    28, context)),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(bottom: 24),
                                          child: Text(
                                            '- ${showLatestBeta.split("-")[1]}',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4
                                                ?.copyWith(
                                                    fontSize: UI.getTextSize(
                                                        18, context)),
                                          )),
                                      Expanded(
                                          child: needUpdate
                                              ? SingleChildScrollView(
                                                  child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: versionInfo
                                                      .map((e) => Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  bottom: 12,
                                                                  left: 14),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                width: 10,
                                                                height: 10,
                                                                margin: EdgeInsets
                                                                    .only(
                                                                        top: 5),
                                                                decoration: BoxDecoration(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .toggleableActiveColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            5)),
                                                              ),
                                                              Expanded(
                                                                  child: Padding(
                                                                      padding: EdgeInsets.only(left: 9),
                                                                      child: Text(
                                                                        e,
                                                                        textAlign:
                                                                            TextAlign.left,
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline4,
                                                                      ))),
                                                            ],
                                                          )))
                                                      .toList(),
                                                ))
                                              : Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 12, left: 14),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        dic['update.latest'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headline4
                                                            ?.copyWith(
                                                                height: 1.7),
                                                      ),
                                                    ],
                                                  ))),
                                      Visibility(
                                          visible: needUpdate,
                                          child: Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                dic['update.up'],
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6
                                                    ?.copyWith(
                                                        fontSize:
                                                            UI.getTextSize(
                                                                14, context)),
                                              ))),
                                      GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            if (!needUpdate) {
                                              return;
                                            }
                                            if (Platform.isIOS) {
                                              // go to ios download page
                                              UI.launchURL(versions[platform]
                                                  ['store-url']);
                                            } else if (Platform.isAndroid) {
                                              if (buildTarget ==
                                                  BuildTargets.playStore) {
                                                // go to google play page
                                                UI.launchURL(versions[platform]
                                                    ['store-url']);
                                                return;
                                              }
                                              // download apk
                                              // START LISTENING FOR DOWNLOAD PROGRESS REPORTING EVENTS
                                              try {
                                                UpdateApp.updateApp(
                                                    url: versions['android']
                                                        ['url'],
                                                    appleId: "1520301768");
                                                showCupertinoDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext ctx) {
                                                      return PolkawalletAlertDialog(
                                                        title: Text(dic[
                                                            'update.download']),
                                                        content: Text(dic[
                                                            'update.download.check']),
                                                        actions: [
                                                          PolkawalletActionSheetAction(
                                                            child: Text(I18n.of(
                                                                    context)
                                                                .getDic(
                                                                    i18n_full_dic_ui,
                                                                    'common')['ok']),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        ctx)
                                                                    .pop(),
                                                          ),
                                                        ],
                                                      );
                                                    });
                                              } catch (e) {
                                                print(
                                                    'Failed to make OTA update. Details: $e');
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 45, vertical: 7),
                                            decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .toggleableActiveColor,
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: Text(
                                              needUpdate
                                                  ? dic['update.now']
                                                  : I18n.of(context).getDic(
                                                      i18n_full_dic_ui,
                                                      'common')['ok'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .button,
                                            ),
                                          ))
                                    ],
                                  ),
                                )))),
                    Image.asset(
                      "assets/images/update_app_icon${needUpdate ? '' : '2'}.png",
                      width: needUpdate ? 116 : 200,
                    ),
                    GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          if (needUpdate &&
                              versionCodeMin > await Utils.getBuildNumber()) {
                            exit(0);
                          }
                        },
                        child: Container(
                            margin: EdgeInsets.only(
                                top: 134, left: needUpdate ? 212 : 230),
                            child: Image.asset(
                                "assets/images/update_app_delete.png",
                                width: 24))),
                  ],
                ))));
      },
    );
  }

  static Future<bool> checkJSCodeUpdate(
    BuildContext context,
    GetStorage jsStorage,
    int jsVersionApp,
    jsVersionLatest,
    jsVersionMin,
    String network,
  ) async {
    if (jsVersionLatest != null) {
      if (jsVersionLatest > jsVersionApp) {
        final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
        final bool isOk = await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return PolkawalletAlertDialog(
              title: Text('metadata v$jsVersionLatest'),
              content: Text(I18n.of(context)
                  .getDic(i18n_full_dic_app, 'profile')['update.js.up']),
              actions: <Widget>[
                PolkawalletActionSheetAction(
                  child: Text(dic['cancel']),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    if (jsVersionMin != null && jsVersionApp < jsVersionMin) {
                      exit(0);
                    }
                  },
                ),
                PolkawalletActionSheetAction(
                  isDefaultAction: true,
                  child: Text(dic['ok']),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
        return isOk;
      }
    }
    return false;
  }

  static Future<bool> updateJSCode(
    BuildContext context,
    GetStorage jsStorage,
    String network,
    int version,
  ) async {
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PolkawalletAlertDialog(
          title: Text(dic['update.download']),
          content: CupertinoActivityIndicator(),
        );
      },
    );
    final String code = await WalletApi.fetchPolkadotJSCode(network);
    print('downloaded jsCode for $network:');
    Navigator.of(context).pop();
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PolkawalletAlertDialog(
          title: Container(),
          content: code == null
              ? Text(dic['update.error'])
              : Text(dicCommon['success']),
          actions: <Widget>[
            PolkawalletActionSheetAction(
              child: Text(dicCommon['ok']),
              onPressed: () {
                if (code != null) {
                  WalletApi.setPolkadotJSCode(
                      jsStorage, network, code, version);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return code != null;
  }

  static bool checkBalanceAndAlert(
      BuildContext context, BalanceData balance, BigInt amountNeeded) {
    if (Fmt.balanceInt(balance.availableBalance.toString()) <= amountNeeded) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return PolkawalletAlertDialog(
            title: Text(I18n.of(context)
                .getDic(i18n_full_dic_app, 'assets')['amount.low']),
            content: Container(),
            actions: <Widget>[
              PolkawalletActionSheetAction(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return false;
    } else {
      return true;
    }
  }
}
