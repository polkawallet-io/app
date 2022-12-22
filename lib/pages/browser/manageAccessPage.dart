import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ManageWebAccessPage extends StatelessWidget {
  const ManageWebAccessPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/browser/access';

  void _onChange(String url, bool auth) {
    service.store.settings
        .updateDAppAuth(url, auth: auth, isEvm: service.plugin is PluginEvm);
  }

  void _onDelete(BuildContext context, String url) async {
    final confirmed = await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PolkawalletAlertDialog(
          title: Text(
              '${I18n.of(context).getDic(i18n_full_dic_app, "public")["hub.browser.confirm"]} $url ?'),
          actions: [
            CupertinoButton(
                child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel'],
                  style: const TextStyle(color: Colors.black54),
                ),
                onPressed: () => Navigator.of(context).pop(false)),
            CupertinoButton(
                child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok'],
                  style: const TextStyle(color: PluginColorsDark.primary),
                ),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );
    if (confirmed) {
      service.store.settings
          .updateDAppAuth(url, auth: null, isEvm: service.plugin is PluginEvm);
    }
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['hub.browser.access']),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          final state = service.store.settings.websiteAccess;
          final list = state.keys.toList();
          return ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(list[i],
                              style: const TextStyle(color: Colors.white))),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Text(
                          dic['hub.browser.access.${state[list[i]]}'],
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      v3.CupertinoSwitch(
                        value: state[list[i]],
                        onChanged: (auth) => _onChange(list[i], auth),
                      ),
                      IconButton(
                          onPressed: () => _onDelete(context, list[i]),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: PluginColorsDark.primary,
                          ))
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}
