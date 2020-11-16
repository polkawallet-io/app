import 'dart:async';
import 'dart:convert';

import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
// import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/cupertino.dart';

class ApiAccount {
  ApiAccount(this.apiRoot);

  final AppService apiRoot;

  final _biometricEnabledKey = 'biometric_enabled_';
  final _biometricPasswordKey = 'biometric_password_';

  Future<void> generateAccount() async {
    final mnemonic = await apiRoot.plugin.sdk.api.keyring.generateMnemonic();
    apiRoot.store.account.setNewAccountKey(mnemonic);
  }

  Future<KeyPairData> importAccount({
    KeyType keyType = KeyType.mnemonic,
    CryptoType cryptoType = CryptoType.sr25519,
    String derivePath = '',
  }) async {
    final acc = apiRoot.store.account.newAccount;
    final res = await apiRoot.plugin.sdk.api.keyring.importAccount(
      apiRoot.keyring,
      keyType: keyType,
      key: acc.key,
      name: acc.name,
      password: acc.password,
    );
    return res;
    // code = code.replaceAll(RegExp(r'\t|\n|\r'), '');
  }

  /// query address with account index
  // Future<List> queryAddressWithAccountIndex(String index) async {
  //   final res = await apiRoot.evalJavascript(
  //     'account.queryAddressWithAccountIndex("$index", ${store.settings.endpoint.ss58})',
  //     allowRepeat: true,
  //   );
  //   return res;
  // }

  // Future<void> changeCurrentAccount({
  //   String pubKey,
  //   bool fetchData = false,
  // }) async {
  //   String current = pubKey;
  //   if (pubKey == null) {
  //     if (store.account.accountListAll.length > 0) {
  //       current = store.account.accountListAll[0].pubKey;
  //     } else {
  //       current = '';
  //     }
  //   }
  //   store.account.setCurrentAccount(current);
  //
  //   // refresh balance
  //   store.assets.clearTxs();
  //   store.assets.loadAccountCache();
  //   if (fetchData) {
  //     webApi.assets.fetchBalance();
  //   }
  //   if (store.settings.endpoint.info == networkEndpointAcala.info) {
  //     store.acala.setTransferTxs([], reset: true);
  //     store.acala.loadCache();
  //   } else {
  //     // refresh user's staking info if network is kusama or polkadot
  //     store.staking.clearState();
  //     store.staking.loadAccountCache();
  //     if (fetchData) {
  //       webApi.staking.fetchAccountStaking();
  //     }
  //   }
  // }

  // Future<dynamic> checkAccountPassword(AccountData account, String pass) async {
  //   String pubKey = account.pubKey;
  //   print('checkpass: $pubKey, $pass');
  //   return apiRoot.evalJavascript(
  //     'account.checkPassword("$pubKey", "$pass")',
  //     allowRepeat: true,
  //   );
  // }

  void setBiometricEnabled(String pubKey) {
    apiRoot.store.storage.write(
        '$_biometricEnabledKey$pubKey', DateTime.now().millisecondsSinceEpoch);
  }

  void setBiometricDisabled(String pubKey) {
    apiRoot.store.storage.write('$_biometricEnabledKey$pubKey',
        DateTime.now().millisecondsSinceEpoch - SECONDS_OF_DAY * 7000);
  }

  bool getBiometricEnabled(String pubKey) {
    final timestamp =
        apiRoot.store.storage.read('$_biometricEnabledKey$pubKey');
    // we cache user's password with biometric for 7 days.
    if (timestamp != null &&
        timestamp + SECONDS_OF_DAY * 7000 >
            DateTime.now().millisecondsSinceEpoch) {
      return true;
    }
    return false;
  }

  // Future<BiometricStorageFile> getBiometricPassStoreFile(
  //   BuildContext context,
  //   String pubKey,
  // ) async {
  //   final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
  //   return BiometricStorage().getStorage(
  //     '$_biometricPasswordKey$pubKey',
  //     options:
  //         StorageFileInitOptions(authenticationValidityDurationSeconds: 30),
  //     androidPromptInfo: AndroidPromptInfo(
  //       title: dic['unlock.bio'],
  //       negativeButton: dic['cancel'],
  //     ),
  //   );
  // }

  // Future<List> fetchAddressIndex(List addresses) async {
  //   if (addresses == null || addresses.length == 0) {
  //     return [];
  //   }
  //   addresses
  //       .retainWhere((i) => !store.account.addressIndexMap.keys.contains(i));
  //   if (addresses.length == 0) {
  //     return [];
  //   }
  //
  //   var res = await apiRoot.evalJavascript(
  //     'account.getAccountIndex(${jsonEncode(addresses)})',
  //     allowRepeat: true,
  //   );
  //   store.account.setAddressIndex(res);
  //   return res;
  // }

  // Future<List> fetchAccountsIndex() async {
  //   final addresses =
  //       store.account.accountListAll.map((e) => e.address).toList();
  //   if (addresses == null || addresses.length == 0) {
  //     return [];
  //   }
  //
  //   var res = await apiRoot.evalJavascript(
  //     'account.getAccountIndex(${jsonEncode(addresses)})',
  //     allowRepeat: true,
  //   );
  //   store.account.setAccountsIndex(res);
  //   return res;
  // }

//   Future<String> checkDerivePath(
//       String seed, String path, String pairType) async {
//     String res = await apiRoot.evalJavascript(
//       'account.checkDerivePath("$seed", "$path", "$pairType")',
//       allowRepeat: true,
//     );
//     return res;
//   }
//
//   Future<Map> queryRecoverable(String address) async {
// //    address = "J4sW13h2HNerfxTzPGpLT66B3HVvuU32S6upxwSeFJQnAzg";
//     Map res = await apiRoot
//         .evalJavascript('api.query.recovery.recoverable("$address")');
//     if (res != null) {
//       res['address'] = address;
//     }
//     store.account.setAccountRecoveryInfo(res);
//
//     if (res != null && List.of(res['friends']).length > 0) {
//       getAddressIcons(res['friends']);
//     }
//     return res;
//   }
//
//   Future<List> queryRecoverableList(List<String> addresses) async {
//     List queries =
//         addresses.map((e) => 'api.query.recovery.recoverable("$e")').toList();
//     final List ls = await apiRoot.evalJavascript(
//       'Promise.all([${queries.join(',')}])',
//       allowRepeat: true,
//     );
//
//     List res = [];
//     ls.asMap().forEach((k, v) {
//       if (v != null) {
//         v['address'] = addresses[k];
//       }
//       res.add(v);
//     });
//
//     return res;
//   }
//
//   Future<List> queryActiveRecoveryAttempts(
//       String address, List<String> addressNew) async {
//     List queries = addressNew
//         .map((e) => 'api.query.recovery.activeRecoveries("$address", "$e")')
//         .toList();
//     final res = await apiRoot.evalJavascript(
//       'Promise.all([${queries.join(',')}])',
//       allowRepeat: true,
//     );
//     return res;
//   }
//
//   Future<List> queryActiveRecoveries(
//       List<String> addresses, String addressNew) async {
//     List queries = addresses
//         .map((e) => 'api.query.recovery.activeRecoveries("$e", "$addressNew")')
//         .toList();
//     final res = await apiRoot.evalJavascript(
//       'Promise.all([${queries.join(',')}])',
//       allowRepeat: true,
//     );
//     return res;
//   }
//
//   Future<List> queryRecoveryProxies(List<String> addresses) async {
//     List queries =
//         addresses.map((e) => 'api.query.recovery.proxy("$e")').toList();
//     final res = await apiRoot.evalJavascript(
//       'Promise.all([${queries.join(',')}])',
//       allowRepeat: true,
//     );
//     return res;
//   }

//   Future<Map> signAsync(String password) async {
//     final res = await apiRoot.evalJavascript('account.signAsync("$password")');
//     return res;
//   }
//
//   Future<Map> makeQrCode(Map txInfo, List params, {String rawParam}) async {
//     String param = rawParam != null ? rawParam : jsonEncode(params);
//     final Map res = await apiRoot.evalJavascript(
//       'account.makeTx(${jsonEncode(txInfo)}, $param)',
//       allowRepeat: true,
//     );
//     return res;
//   }
//
//   Future<Map> addSignatureAndSend(
//     String signed,
//     Map txInfo,
//     String pageTile,
//     String notificationTitle,
//   ) async {
//     final String address = store.account.currentAddress;
//     final Map res = await apiRoot.evalJavascript(
//       'account.addSignatureAndSend("$address", "$signed")',
//       allowRepeat: true,
//     );
//
//     if (res['hash'] != null) {
//       String hash = res['hash'];
//       NotificationPlugin.showNotification(
//         int.parse(hash.substring(0, 6)),
//         notificationTitle,
//         '$pageTile - ${txInfo['module']}.${txInfo['call']}',
//       );
//     }
//     return res;
//   }
//
//   Future<Map> signAsExtension(String password, Map args) async {
//     final String call = args['msgType'] == WalletExtensionSignPage.signTypeBytes
//         ? 'signBytesAsExtension'
//         : 'signTxAsExtension';
//     final res = await apiRoot.evalJavascript(
//       'account.$call("$password", ${jsonEncode(args['request'])})',
//       allowRepeat: true,
//     );
//     return res;
//   }
}
