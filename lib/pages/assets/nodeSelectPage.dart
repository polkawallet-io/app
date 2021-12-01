import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/plugin/index.dart';

import 'package:polkawallet_sdk/api/types/networkParams.dart';

class NodeSelectPage extends StatefulWidget {
  NodeSelectPage(this.service, this.plugins, this.changeNetwork,
      this.changeNode, this.checkJSCodeUpdate,
      {Key key})
      : super(key: key);

  final List<PolkawalletPlugin> plugins;
  final AppService service;
  final Future<void> Function(NetworkParams) changeNode;
  final Future<void> Function(String) changeNetwork;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;

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
    return Container(
      child: ListView.separated(
        itemCount: widget.plugins.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: NodeSelectItem(
                widget.service,
                widget.plugins[index],
                index == expansionIndex,
                widget.changeNetwork,
                widget.changeNode,
                widget.checkJSCodeUpdate),
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
    );
  }
}

class NodeSelectItem extends StatelessWidget {
  NodeSelectItem(this.service, this.plugin, this.isExpansion,
      this.changeNetwork, this.changeNode, this.checkJSCodeUpdate,
      {Key key})
      : super(key: key);
  PolkawalletPlugin plugin;
  bool isExpansion = false;
  final AppService service;
  final Future<void> Function(NetworkParams) changeNode;
  final Future<void> Function(String) changeNetwork;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;

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
          isExpansion
              ? Column(
                  children: [
                    Divider(),
                    Container(
                      margin: EdgeInsets.only(left: 30),
                      child: Column(
                        children: [
                          ...plugin.nodeList.map((e) {
                            return ListTile(
                              title: Text(e.name),
                              subtitle: Text(e.endpoint),
                              trailing: Container(
                                width: 48,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Visibility(
                                        visible: service.plugin.sdk.api
                                                .connectedNode?.endpoint ==
                                            e.endpoint,
                                        child: Icon(Icons.check_circle,
                                            color: Colors.lightGreen,
                                            size: 18)),
                                    Icon(Icons.arrow_forward_ios, size: 18)
                                  ],
                                ),
                              ),
                              onTap: () {
                                if (service.plugin.sdk.api.connectedNode
                                        ?.endpoint ==
                                    e.endpoint) {
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (service.plugin.basic.name !=
                                    plugin.basic.name) {
                                  changeNetwork(plugin.basic.name);
                                  checkJSCodeUpdate(plugin);
                                }
                                changeNode(e);
                                Navigator.of(context).pop();
                              },
                            );
                          }).toList()
                        ],
                      ),
                    )
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}
