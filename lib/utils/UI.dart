import 'dart:async';
import 'dart:io';

import 'package:app/common/consts.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:update_app/update_app.dart';

class AppUI {
  static Future<void> alertWASM(
    BuildContext context,
    Function onCancel, {
    bool isImport = false,
  }) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String msg = dic['backup.error'];
    if (!isImport) {
      msg += dic['backup.error.2'];
    }
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Container(),
          content: Text(msg),
          actions: <Widget>[
            CupertinoButton(
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

  static Future<void> checkUpdate(BuildContext context, Map versions,
      {bool autoCheck = false}) async {
    if (versions == null || !Platform.isAndroid && !Platform.isIOS) return;
    String platform = Platform.isAndroid ? 'android' : 'ios';
    final Map dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    final int latestCode = versions[platform]['version-code'];
    final String latestBeta = versions[platform]['version-beta'];
    final int latestCodeBeta = versions[platform]['version-code-beta'];
    final int versionCodeMin = versions[platform]['version-code-min'];

    bool needUpdate = false;
    bool needExit = false;
    if (autoCheck) {
      if (latestCode > app_beta_version_code) {
        // new version found
        needUpdate = true;
        // app version lower than versionMin, force exit
        if (versionCodeMin > app_beta_version_code) {
          needExit = true;
        }
      } else {
        return;
      }
    } else {
      if (latestCodeBeta > app_beta_version_code) {
        // new version found
        needUpdate = true;
      }
    }

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        List versionInfo = versions[platform]['info']
            [I18n.of(context).locale.toString().contains('zh') ? 'zh' : 'en'];
        return CupertinoAlertDialog(
          title: Text('v$latestBeta'),
          content: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 8),
                child:
                    Text(needUpdate ? dic['update.up'] : dic['update.latest']),
              ),
              needUpdate
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: versionInfo
                          .map((e) => Text(
                                '- $e',
                                textAlign: TextAlign.left,
                              ))
                          .toList(),
                    )
                  : Container()
            ],
          ),
          actions: <Widget>[
            CupertinoButton(
              child: Text(I18n.of(context)
                  .getDic(i18n_full_dic_ui, 'common')['cancel']),
              onPressed: () {
                Navigator.of(context).pop();
                if (needUpdate && needExit) {
                  exit(0);
                }
              },
            ),
            CupertinoButton(
              child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
              onPressed: () async {
                Navigator.of(context).pop();
                if (!needUpdate) {
                  return;
                }
                if (Platform.isIOS) {
                  // go to ios download page
                  UI.launchURL('https://polkawallet.io/#download');
                } else if (Platform.isAndroid) {
                  // download apk
                  // START LISTENING FOR DOWNLOAD PROGRESS REPORTING EVENTS
                  try {
                    String url = versions['android']['url'];
                    UpdateApp.updateApp(url: url, appleId: "1520301768");
                  } catch (e) {
                    print('Failed to make OTA update. Details: $e');
                  }
                }
              },
            ),
          ],
        );
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
            return CupertinoAlertDialog(
              title: Text('metadata v$jsVersionLatest'),
              content: Text(I18n.of(context)
                  .getDic(i18n_full_dic_app, 'profile')['update.js.up']),
              actions: <Widget>[
                CupertinoButton(
                  child: Text(dic['cancel']),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    if (jsVersionMin != null && jsVersionApp < jsVersionMin) {
                      exit(0);
                    }
                  },
                ),
                CupertinoButton(
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

  static Future<void> updateJSCode(
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
        return CupertinoAlertDialog(
          title: Text(dic['update.download']),
          content: CupertinoActivityIndicator(),
        );
      },
    );
    final String code = await WalletApi.fetchPolkadotJSCode(network);
    print('downloaded jsCode for $network:');
    print(code);
    Navigator.of(context).pop();
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Container(),
          content: code == null
              ? Text(dic['update.error'])
              : Text(dicCommon['success']),
          actions: <Widget>[
            CupertinoButton(
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
  }

  static bool checkBalanceAndAlert(
      BuildContext context, BalanceData balance, BigInt amountNeeded) {
    if (Fmt.balanceInt(balance.availableBalance.toString()) <= amountNeeded) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(I18n.of(context)
                .getDic(i18n_full_dic_app, 'assets')['amount.low']),
            content: Container(),
            actions: <Widget>[
              CupertinoButton(
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
