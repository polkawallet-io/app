import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:rive/rive.dart';

class AccountBindSuccess extends StatefulWidget {
  const AccountBindSuccess({Key key}) : super(key: key);
  static const String route = '/account/accountBind/success';

  @override
  State<AccountBindSuccess> createState() => _AccountBindSuccessState();
}

class _AccountBindSuccessState extends State<AccountBindSuccess> {
  RiveAnimationController _controller;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = OneShotAnimation(
      'Animation 1',
      autoplay: false,
      onStop: () => setState(() => _isPlaying = false),
      onStart: () => setState(() => _isPlaying = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context).settings?.arguments as Map;
    final EthWalletData ethWalletData = arg != null ? arg['ethAccount'] : null;
    final dicPublic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return PluginScaffold(
      appBar: const PluginAppBar(
        title: Text("EVM+"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                  visible: ethWalletData != null,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      dicPublic['evm.bind.success'],
                      style: Theme.of(context)
                          .textTheme
                          .headline4
                          .copyWith(color: Colors.white),
                    ),
                  )),
              Visibility(
                  visible: ethWalletData != null,
                  child: PluginAddressFormItem(
                      account: ethWalletData?.toKeyPairData(),
                      label: dicPublic['evm.bound'])),
            ],
          ),
          Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                  onTap: () => _isPlaying ? null : _controller.isActive = true,
                  child: Stack(
                    children: [
                      Container(
                        height: 96,
                        width: 310,
                        margin: const EdgeInsets.only(top: 365),
                        child: const RiveAnimation.asset(
                          'assets/images/streamer_card.riv',
                          fit: BoxFit.none,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 365),
                        width: 308,
                        height: 94,
                        alignment: Alignment.center,
                        child: Text(
                          dicPublic['evm.more.features'],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline3.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ))),
          Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
                onTap: () => _isPlaying ? null : _controller.isActive = true,
                child: SizedBox(
                  height: 380,
                  width: 110,
                  child: RiveAnimation.asset(
                    'assets/images/small_rocket.riv',
                    fit: BoxFit.fitWidth,
                    animations:
                        _controller.isActive ? const ['Animation 1'] : [],
                    controllers: [_controller],
                  ),
                )),
          ),
        ]),
      ),
    );
  }
}
