import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';

class AccountBindStep3 extends StatefulWidget {
  const AccountBindStep3(this.service, this.isPlugin, this.signMessage,
      this.keyPairData, this.ethWalletData, this.onNext,
      {Key key})
      : super(key: key);
  final AppService service;
  final Map signMessage;
  final Function onNext;
  final bool isPlugin;
  final EthWalletData ethWalletData;
  final KeyPairData keyPairData;

  @override
  State<AccountBindStep3> createState() => _AccountBindStep3State();
}

class _AccountBindStep3State extends State<AccountBindStep3> {
  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.headline4?.copyWith(
        fontWeight: FontWeight.bold,
        color: widget.isPlugin
            ? Colors.white
            : Theme.of(context).textTheme.headline4?.color);

    final dicPublic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return Padding(
        padding: const EdgeInsets.only(top: 33),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Substrate ${dicPublic['auction.address']}",
                  style: labelStyle),
              AddressFormItem(
                widget.keyPairData,
                isDarkTheme: widget.isPlugin,
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text("Evm ${dicPublic['auction.address']}",
                      style: labelStyle)),
              AddressFormItem(
                widget.ethWalletData,
                isDarkTheme: widget.isPlugin,
              ),
              Padding(
                  padding: const EdgeInsets.only(bottom: 5, top: 21),
                  child: Text(
                    "Signature",
                    style: labelStyle,
                  )),
              Text(
                widget.signMessage['signature'],
                style: Theme.of(context).textTheme.headline5.copyWith(
                    color: widget.isPlugin
                        ? Colors.white
                        : Theme.of(context).textTheme.headline5?.color),
              ),
            ],
          )),
          SafeArea(
              minimum: const EdgeInsets.only(bottom: 24),
              child: Button(
                title: dicPublic['evm.bind'],
                isDarkTheme: widget.isPlugin,
                style: Theme.of(context).textTheme.button.copyWith(
                    color: widget.isPlugin
                        ? const Color(0xFF121212)
                        : Theme.of(context).textTheme.button.color),
                onPressed: () => widget.onNext(),
              ))
        ]));
  }
}
