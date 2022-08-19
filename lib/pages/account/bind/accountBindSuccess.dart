import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

class AccountBindSuccess extends StatelessWidget {
  const AccountBindSuccess({Key key}) : super(key: key);
  static const String route = '/account/accountBind/success';
  @override
  Widget build(BuildContext context) {
    final EthWalletData ethWalletData =
        (ModalRoute.of(context).settings.arguments as Map)['ethAccount'];
    return PluginScaffold(
        appBar: const PluginAppBar(
          title: Text("EVM+"),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    "You have bound your EVM account successfully!",
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        .copyWith(color: Colors.white),
                  ),
                ),
                PluginAddressFormItem(
                    account: ethWalletData.toKeyPairData(),
                    label: "Bound Account"),
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 160),
                          width: 310,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFFF6D37).withOpacity(0.24),
                                    const Color(0xFFFF6D37).withOpacity(0.1),
                                    const Color(0xFFF57D49).withOpacity(0.94),
                                  ])),
                          child: Container(
                            width: 308,
                            height: 94,
                            decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                                color: Color(0xFF36383A)),
                            alignment: Alignment.center,
                            child: Text(
                              "Stay tuned for more features \ncoming !",
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Center(
                          child: Image.asset(
                        'assets/images/evm_bind_success.png',
                        width: 107,
                        height: 173,
                      )),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
