import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/plugin/index.dart';

import 'package:polkawallet_sdk/api/types/networkParams.dart';

class NodeSelectPage extends StatefulWidget {
  NodeSelectPage(
      this.service, this.plugins, this.changeNetwork, this.changeNode,
      {Key key})
      : super(key: key);

  final List<PolkawalletPlugin> plugins;
  final AppService service;
  final Future<void> Function(NetworkParams) changeNode;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  static final String route = '/nodeSelect';

  @override
  _NodeSelectPageState createState() => _NodeSelectPageState();
}

class _NodeSelectPageState extends State<NodeSelectPage> {
  int expansionIndex = -1;

  @override
  void initState() {
    super.initState();
    expansionIndex = widget.plugins.indexWhere(
        (element) => element.basic.name == widget.service.plugin.basic.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.of(context)
              .getDic(i18n_full_dic_app, 'profile')['setting.network.node']),
          centerTitle: true,
        ),
        body: Container(
          child: ListView.separated(
            itemCount: widget.plugins.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                child: NodeSelectItem(
                    widget.service,
                    widget.plugins[index],
                    index == expansionIndex,
                    widget.changeNetwork,
                    widget.changeNode),
                onTap: index == expansionIndex
                    ? null
                    : () {
                        setState(() {
                          expansionIndex = index;
                        });
                      },
              );
            },
            separatorBuilder: (BuildContext context, int index) => Divider(),
          ),
        ));
  }
}

class NodeSelectItem extends StatelessWidget {
  NodeSelectItem(this.service, this.plugin, this.isExpansion,
      this.changeNetwork, this.changeNode,
      {Key key})
      : super(key: key);
  PolkawalletPlugin plugin;
  bool isExpansion = false;
  final AppService service;
  final Future<void> Function(NetworkParams) changeNode;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      color: Colors.transparent,
      child: Column(
        children: [
          ListTile(
            leading: SizedBox(child: plugin.basic.icon, height: 28, width: 28),
            title: Text(plugin.basic.name),
            trailing: isExpansion
                ? Icon(
                    Icons.check_circle,
                    color: plugin.basic.primaryColor,
                  )
                : Container(width: 8),
            onTap: isExpansion ? () {} : null,
          ),
          Visibility(
            visible: isExpansion,
            child: Column(
              children: [
                Divider(),
                ListView.builder(
                    padding: EdgeInsets.only(left: 30),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: plugin.nodeList.length,
                    itemBuilder: (context, index) {
                      final isCurrent =
                          service.plugin.sdk.api.connectedNode?.endpoint ==
                              plugin.nodeList[index].endpoint;
                      return ListTile(
                        title: Text(plugin.nodeList[index].name),
                        subtitle: Text(plugin.nodeList[index].endpoint),
                        trailing: Container(
                          width: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                  visible: isCurrent,
                                  child: Icon(Icons.check_circle,
                                      color: Colors.lightGreen, size: 18)),
                              Icon(Icons.arrow_forward_ios, size: 18)
                            ],
                          ),
                        ),
                        onTap: () {
                          if (isCurrent) {
                            Navigator.of(context).pop();
                            return;
                          }
                          changeNetwork(plugin);
                          changeNode(plugin.nodeList[index]);
                          Navigator.of(context).pop();
                        },
                      );
                    })
              ],
            ),
          )
        ],
      ),
    );
  }
}
