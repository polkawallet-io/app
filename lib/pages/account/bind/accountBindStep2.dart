import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';

class AccountBindStep2 extends StatefulWidget {
  const AccountBindStep2(this.service, this.keyPairData, this.ethWalletData,
      {Key key})
      : super(key: key);
  final AppService service;
  final EthWalletData ethWalletData;
  final KeyPairData keyPairData;

  @override
  State<AccountBindStep2> createState() => _AccountBindStep2State();
}

class _AccountBindStep2State extends State<AccountBindStep2> {
  bool _submitting = false;

  void _confirmAction() async {
    final isAcala = (widget.service.plugin is PluginEvm &&
            (widget.service.plugin as PluginEvm).network ==
                para_chain_name_acala) ||
        widget.service.plugin.basic.name == para_chain_name_acala;

    final password = await widget.service.account
        .getEvmPassword(context, widget.ethWalletData);

    if (password == null) return;
    setState(() {
      _submitting = true;
    });
    Map res = await widget.service.account.evmSignMessage(
        isAcala ? metamask_acala_params : metamask_karura_params,
        widget.keyPairData.pubKey,
        widget.ethWalletData.address,
        password);

    if (res['success'] == false) {
      showCupertinoDialog(
          context: context,
          builder: (_) {
            return PolkawalletAlertDialog(
              type: DialogType.warn,
              title: Text('bad.warn'),
              content: Text(res['error']),
              actions: [
                PolkawalletActionSheetAction(
                  child: Text('ok'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    } else {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAcala = (widget.service.plugin is PluginEvm &&
            (widget.service.plugin as PluginEvm).network ==
                para_chain_name_acala) ||
        widget.service.plugin.basic.name == para_chain_name_acala;

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 1.0,
            spreadRadius: 0.0,
            offset: Offset(
              0.0,
              -2.0,
            ),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 1.0,
                  spreadRadius: 0,
                  offset: Offset(
                    0.0,
                    1.0,
                  ),
                )
              ],
            ),
            child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context).disabledColor,
                            size: 18,
                          )),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text("Create Claim signature",
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    )
                  ],
                )),
          ),
          Expanded(
              child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 39, bottom: 32),
                  child: Image.asset(
                    "assets/images/complete_ecosystem.png",
                    width: 213,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            "Address",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )),
                      Text(
                        widget.ethWalletData.address,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      Padding(
                          padding: const EdgeInsets.only(bottom: 5, top: 21),
                          child: Text(
                            "Message",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )),
                      Padding(
                          padding: const EdgeInsets.only(bottom: 21),
                          child: Text(
                            "Welcome to ${isAcala ? "Acala" : "Karura"} EVM+!",
                            style: Theme.of(context).textTheme.headline5,
                          )),
                      Text(
                        "Click “sign” to continue \nThis signature will cost 0 gas",
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      Padding(
                          padding: const EdgeInsets.only(bottom: 5, top: 21),
                          child: Text(
                            "Substrate Address",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )),
                      Text(
                        Fmt.address(widget.keyPairData.address),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: Button(
                  title: "Cancel",
                  isBlueBg: false,
                  style: Theme.of(context).textTheme.button?.copyWith(
                      color: UI.isDarkTheme(context)
                          ? Theme.of(context).textTheme.button?.color
                          : Theme.of(context).textTheme.headline1?.color),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
                Container(
                  width: 38,
                ),
                Expanded(
                    child: Button(
                  submitting: _submitting,
                  title: "Comfirm",
                  onPressed: () => _confirmAction(),
                ))
              ],
            ),
          )
        ],
      ),
    );
  }
}
