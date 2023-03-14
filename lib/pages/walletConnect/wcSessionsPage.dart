import 'package:app/pages/walletConnect/wcSessionDetailPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/ethSignRequestInfo.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

class WCSessionsPage extends StatelessWidget {
  const WCSessionsPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/wc/session';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Observer(builder: (_) {
      final sessionCount = service.store.account.wcV2Sessions.length;

      return Scaffold(
        appBar: AppBar(
            title: Image.asset('assets/images/wallet_connect_banner.png',
                height: 20),
            centerTitle: true,
            leading: BackBtn()),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
                itemCount: service.store.account.wcSessionURI != null
                    ? sessionCount + 2
                    : sessionCount + 1,
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        dic['wc.session'],
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    );
                  }
                  if (index == 1 &&
                      service.store.account.wcSessionURI != null) {
                    return GestureDetector(
                      child: RoundedCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: WCPairingSourceInfo(
                            service.store.account.wcSession,
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16)),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                            WCSessionDetailPage.route,
                            arguments: WCSessionDetailPageParams(
                                version: 1,
                                topic: '',
                                peerMeta: service.store.account.wcSession));
                      },
                    );
                  }
                  final i = service.store.account.wcSessionURI != null
                      ? index - 2
                      : index - 1;
                  return GestureDetector(
                    child: RoundedCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: WCPairingSourceInfo(
                          service.store.account.wcV2Sessions[i].peerMeta,
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16)),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(WCSessionDetailPage.route,
                          arguments: WCSessionDetailPageParams(
                              version: 2,
                              topic:
                                  service.store.account.wcV2Sessions[i].topic,
                              peerMeta: service
                                  .store.account.wcV2Sessions[i].peerMeta));
                    },
                  );
                }),
          ),
        ),
      );
    });
  }
}
