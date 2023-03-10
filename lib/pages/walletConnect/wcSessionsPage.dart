import 'package:app/common/components/jumpToLink.dart';
import 'package:app/pages/walletConnect/dotRequestSignPage.dart';
import 'package:app/pages/walletConnect/ethRequestSignPage.dart';
import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class WCSessionsPage extends StatefulWidget {
  const WCSessionsPage(this.service);
  final AppService service;

  static const String route = '/wc/session';

  @override
  _WCSessionsPageState createState() => _WCSessionsPageState();
}

class _WCSessionsPageState extends State<WCSessionsPage> {
  Future<void> _handleWCCallRequest(WCCallRequestData payload) async {
    if (widget.service.plugin is PluginEvm) {
      Navigator.of(context).pushNamed(EthRequestSignPage.route,
          arguments: EthRequestSignPageParams(
              payload, Uri.parse(widget.service.store.account.wcSession.url)));
    } else {
      Navigator.of(context).pushNamed(DotRequestSignPage.route,
          arguments: DotRequestSignPageParams(
              payload, Uri.parse(widget.service.store.account.wcSession.url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Observer(builder: (_) {
      final session = widget.service.store.account.wcSession;
      final pairing = widget.service.store.account.walletConnectPairing;
      final callRequests = widget.service.store.account.wcCallRequests;

      final originUri = widget.service.store.account.wcSession != null
          ? Uri.parse(widget.service.store.account.wcSession.url)
          : null;
      return Scaffold(
        appBar: AppBar(
            title: Image.asset('assets/images/wallet_connect_banner.png',
                height: 20),
            centerTitle: true,
            leading: BackBtn()),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            dic['wc.connect'],
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: WCPairingSourceInfoDetail(session),
                        ),
                        Visibility(
                          visible: callRequests.isNotEmpty,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                                child: Text(dic['wc.calls']),
                              ),
                              RoundedCard(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: callRequests.map((e) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(e.params[0].value),
                                      trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14),
                                      onTap: () => _handleWCCallRequest(e),
                                    );
                                  }).toList(),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    )),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      pairing
                          ? const PluginLoadingWidget()
                          : const Icon(
                              Icons.check_circle,
                              color: Colors.lightGreen,
                            ),
                      Text(dic[pairing ? 'wc.connecting' : 'wc.connected'])
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 24, bottom: pairing ? 24 : 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          JumpToLink(
                            'https://walletconnect.com/',
                            text: dic['wc.service'],
                            color: Theme.of(context).disabledColor,
                          ),
                        ]),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Button(
                      title: pairing
                          ? I18n.of(context)
                              .getDic(i18n_full_dic_ui, 'common')['cancel']
                          : dic['wc.disconnect'],
                      onPressed: () {
                        widget.service.wc.disconnect();

                        Navigator.of(context).pop();
                      },
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    });
  }
}
