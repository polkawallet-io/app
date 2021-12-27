import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/plugin/index.dart';

import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class NodeSelectPage extends StatefulWidget {
  NodeSelectPage(this.service, this.plugins, this.changeNetwork, {Key key})
      : super(key: key);

  final List<PolkawalletPlugin> plugins;
  final AppService service;
  final Future<void> Function(String, {NetworkParams node}) changeNetwork;

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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 7.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              color: Color(0xFFF0ECE6),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4.0,
                  spreadRadius: 0.0,
                  offset: Offset(
                    0.0,
                    2.0,
                  ),
                )
              ],
            ),
            height: 48.h,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                      I18n.of(context).getDic(
                          i18n_full_dic_app, 'assets')["v3.changeNetwork"],
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.w),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).disabledColor,
                          size: 15,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: widget.plugins.length,
                  itemBuilder: (context, index) {
                    return NodeSelectItem(
                        widget.service,
                        widget.plugins[index],
                        index == expansionIndex,
                        widget.changeNetwork, (itemIndex) {
                      if (itemIndex != expansionIndex) {
                        setState(() {
                          expansionIndex = itemIndex;
                        });
                      }
                    }, index);
                  }))
        ],
      ),
    );
  }
}

class NodeSelectItem extends StatelessWidget {
  NodeSelectItem(this.service, this.plugin, this.isExpansion,
      this.changeNetwork, this.networkOnTap, this.index,
      {Key key})
      : super(key: key);
  PolkawalletPlugin plugin;
  bool isExpansion = false;
  int index = 0;
  final AppService service;
  final Future<void> Function(String, {NetworkParams node}) changeNetwork;
  final Function(int) networkOnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          PluginItemWidget(
            leading:
                SizedBox(child: plugin.basic.icon, height: 42.w, width: 42.w),
            spacing: 11.w,
            bgColor: Theme.of(context).cardColor,
            title: Text(
                "${plugin.basic.name[0].toUpperCase()}${plugin.basic.name.substring(1)}",
                style: Theme.of(context).textTheme.headline4.copyWith(
                    fontWeight: FontWeight.w600, fontFamily: "SF_Pro")),
            isSelect: isExpansion,
            onTap: () {
              networkOnTap(index);
            },
          ),
          isExpansion
              ? Column(
                  children: [
                    Column(
                      children: [
                        ...plugin.nodeList.map((e) {
                          return NodeItemWidget(
                            title: Text(e.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    .copyWith(color: Color(0xFF040404))),
                            subtitle: Text(e.endpoint,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    .copyWith(
                                        color: Color(0xFF7E7D7B),
                                        fontWeight: FontWeight.w300)),
                            bgColor: Theme.of(context).cardColor,
                            isSelect: service
                                    .plugin.sdk.api.connectedNode?.endpoint ==
                                e.endpoint,
                            onTap: () {
                              if (service
                                      .plugin.sdk.api.connectedNode?.endpoint ==
                                  e.endpoint) {
                                Navigator.of(context).pop();
                                return;
                              }
                              changeNetwork(plugin.basic.name, node: e);
                              Navigator.of(context).pop();
                            },
                          );
                        }).toList()
                      ],
                    ),
                  ],
                )
              : Container(
                  height: 0,
                ),
        ],
      ),
    );
  }
}

class PluginItemWidget extends StatefulWidget {
  PluginItemWidget(
      {Key key,
      this.leading,
      this.title,
      this.spacing,
      this.onTap,
      this.isSelect,
      this.bgColor})
      : super(key: key);
  Widget leading;
  Widget title;
  double spacing;
  bool isSelect = false;
  Color bgColor;
  Function() onTap;

  @override
  _PluginItemWidgetState createState() => _PluginItemWidgetState();
}

class _PluginItemWidgetState extends State<PluginItemWidget> {
  bool isTapDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (tapDownDetails) {
        setState(() {
          isTapDown = true;
        });
      },
      onTapCancel: () {
        setState(() {
          isTapDown = false;
        });
      },
      onTapUp: (tapUpDetails) {
        setState(() {
          isTapDown = false;
        });
      },
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
            color: widget.bgColor,
            gradient: widget.isSelect || isTapDown
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 1.0],
                    colors: [Color(0xFFE3DED8), Color(0xFFF0ECE6)])
                : null),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                children: [
                  widget.leading,
                  Container(
                    width: widget.spacing,
                  ),
                  widget.title,
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 0),
                child: Divider(
                  height: 1,
                ))
          ],
        ),
      ),
    );
  }
}

class NodeItemWidget extends StatefulWidget {
  NodeItemWidget(
      {Key key,
      this.title,
      this.subtitle,
      this.onTap,
      this.bgColor,
      this.isSelect})
      : super(key: key);
  Widget title;
  Widget subtitle;
  Color bgColor;
  Function() onTap;
  bool isSelect = false;

  @override
  _NodeItemWidgetState createState() => _NodeItemWidgetState();
}

class _NodeItemWidgetState extends State<NodeItemWidget> {
  bool isTapDown = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (tapDownDetails) {
        setState(() {
          isTapDown = true;
        });
      },
      onTapCancel: () {
        setState(() {
          isTapDown = false;
        });
      },
      onTapUp: (tapUpDetails) {
        setState(() {
          isTapDown = false;
        });
      },
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
            color: widget.bgColor,
            image: isTapDown
                ? DecorationImage(
                    image:
                        AssetImage("assets/images/nodeItem_bg_onTapDown.png"),
                    fit: BoxFit.fill)
                : null),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 0, 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.title,
                      widget.subtitle,
                    ],
                  )),
                  Image.asset(
                    "assets/images/${widget.isSelect ? "icon_circle_select.png" : isTapDown ? "icon_circle_onTapDown.png" : "icon_circle_unselect.png"}",
                    fit: BoxFit.contain,
                    width: 16.w,
                  )
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 0),
                child: Divider(
                  height: 1,
                ))
          ],
        ),
      ),
    );
  }
}
