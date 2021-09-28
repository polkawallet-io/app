import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/plugin/index.dart';

class PluginDisabled {
  PluginDisabled(this.name, this.icon, this.pluginType);
  final String name;
  final Widget icon;
  final PluginType pluginType;
}
