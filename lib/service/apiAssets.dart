import 'dart:convert';

import 'package:app/pages/assets/ethTransfer/ethTxConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/api/types/evmTxData.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ApiAssets {
  ApiAssets(this.apiRoot);

  final AppService apiRoot;

  Future<Map> updateTxs(int page) async {
    final acc = apiRoot.keyring.current;
    Map res = await apiRoot.subScan.fetchTransfersAsync(
      acc.address,
      page,
      network: apiRoot.plugin.basic.name == 'bifrost'
          ? 'bifrost-kusama'
          : apiRoot.plugin.basic.name,
    );

    if (page == 0) {
      apiRoot.store.assets.clearTxs();
    }
    // cache first page of txs
    await apiRoot.store.assets.addTxs(
      res,
      acc,
      apiRoot.plugin.basic.name,
      shouldCache: page == 0,
    );

    return res;
  }

  Future<List<EvmTxData>> updateEvmTxs(String tokenId) async {
    final address = apiRoot.keyringEVM.current.address;
    if (address == null) {
      return null;
    }
    final data = await WalletApi.getEvmTokenTxs(
        (apiRoot.plugin as PluginEvm).network, address,
        contractAddress: tokenId.startsWith('0x') ? tokenId : null);
    if (data != null && data['result'] != null) {
      print(data['result']);
      final list =
          (data['result'] as List).map((e) => EvmTxData.fromJson(e)).toList();
      apiRoot.store.assets.setEvmTxs(list, tokenId, address);
      return list;
    }
    return null;
  }

  Future<void> fetchMarketPrices(List<String> tokens) async {
    if (tokens == null) return;

    final res = await Future.wait([
      WalletApi.getTokenPrices(tokens),
      WalletApi.getTokenPriceFromSubScan(apiRoot.plugin.basic.name)
    ]);

    final Map<String, double> prices = {
      'KUSD': 1.0,
      'AUSD': 1.0,
      'USDT': 1.0,
    };
    if ((res[1] ?? {})['data'] != null) {
      final tokenData = res[1]['data']['detail'] as Map;
      prices.addAll({
        tokenData.keys.toList()[0]:
            double.tryParse(tokenData.values.toList()[0]['price'].toString())
      });
    }

    final serverPrice = Map<String, double>.from(res[0] ?? {});
    serverPrice.removeWhere((_, value) => value == 0);
    if (serverPrice.values.length > 0) {
      prices.addAll(serverPrice);
    }

    apiRoot.store.assets.setMarketPrices(prices);
  }

  Future<void> updateEvmGasParams(int gasLimit,
      {bool isFixedGas = true}) async {
    EvmGasParams gasParams;
    if (isFixedGas) {
      final gasPrice = await apiRoot.plugin.sdk.api.eth.keyring.getGasPrice();
      gasParams = EvmGasParams(
          gasLimit: gasLimit, gasPrice: Fmt.balanceDouble(gasPrice, 9));
    } else {
      gasParams = await apiRoot.plugin.sdk.api.eth.account
          .queryEthGasParams(gasLimit: gasLimit);
    }

    apiRoot.store.assets.setEvmGasParams(gasParams);
  }

  Future<Map> evmTransfer(
      EthTransferConfirmPageParams args, String pass, Map gasOptions) async {
    final token = args.contractAddress ?? args.tokenSymbol;
    final res = await apiRoot.plugin.sdk.api.eth.keyring.transfer(
        token: token,
        amount: args.amount,
        to: args.addressTo,
        sender: apiRoot.keyringEVM.current.address,
        pass: pass,
        gasOptions: gasOptions,
        onStatusChange: (res) {
          if (res['confirmNumber'] > -1) {
            (apiRoot.plugin as PluginEvm)
                .updateBalances(apiRoot.keyringEVM.current.toKeyPairData());
            (apiRoot.plugin as PluginEvm).updateBalanceNoneNativeTokensAll();

            apiRoot.store.assets.setPendingTx(
                apiRoot.keyringEVM.current.toKeyPairData(),
                EvmTxData(
                  hash: res['hash'],
                  contractAddress: args.contractAddress,
                  tokenSymbol: args.tokenSymbol,
                  tokenDecimal: (args.tokenDecimals ?? 18).toString(),
                  value:
                      Fmt.tokenInt(args.amount.toString(), args.tokenDecimals)
                          .toString(),
                  from: apiRoot.keyringEVM.current.address,
                  to: args.addressTo,
                  confirmations: res['confirmNumber'].toString(),
                ));

            updateEvmTxs(token);
          }
        });
    if (res != null && res['hash'] != null) {
      apiRoot.store.assets.setPendingTx(
          apiRoot.keyringEVM.current.toKeyPairData(),
          EvmTxData(
            hash: res['hash'],
            contractAddress: args.contractAddress,
            tokenSymbol: args.tokenSymbol,
            tokenDecimal: (args.tokenDecimals ?? 18).toString(),
            value: Fmt.tokenInt(args.amount.toString(), args.tokenDecimals)
                .toString(),
            from: apiRoot.keyringEVM.current.address,
            to: args.addressTo,
            confirmations: '-1',
          ));
    }
    return res;
  }
}
