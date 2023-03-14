import 'package:app/common/components/jumpToLink.dart';
import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class WCSessionDetailPageParams {
  WCSessionDetailPageParams({this.version, this.topic, this.peerMeta});
  final int version;
  final String topic;
  final WCProposerMeta peerMeta;
}

class WCSessionDetailPage extends StatefulWidget {
  const WCSessionDetailPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/wc/session/detail';

  @override
  WCSessionDetailPageState createState() => WCSessionDetailPageState();
}

class WCSessionDetailPageState extends State<WCSessionDetailPage> {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final args =
        ModalRoute.of(context).settings.arguments as WCSessionDetailPageParams;

    return Observer(builder: (_) {
      final pairing = args.version == 1
          ? widget.service.store.account.walletConnectPairing
          : false;
      final callRequests = widget.service.store.account.wcCallRequests.toList();
      if (args.version == 1) {
        callRequests.retainWhere((e) => e.topic == null);
      } else {
        callRequests.retainWhere((e) => e.topic == args.topic);
      }

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
                          child: WCPairingSourceInfoDetail(args.peerMeta),
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
                                      onTap: () => widget.service.wc
                                          .handleWCCallRequest(context, e),
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
                        if (args.version == 1) {
                          widget.service.wc.disconnect();
                        } else {
                          widget.service.wc.disconnectV2(args.topic);
                        }

                        Navigator.popUntil(context, ModalRoute.withName('/'));
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
