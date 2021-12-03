import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:simple_shadow/simple_shadow.dart';

class BottomBarScaffold extends StatefulWidget {
  BottomBarScaffold(
      {@required this.body,
      @required this.pages,
      @required this.tabIndex,
      @required this.onChanged,
      Key key})
      : super(key: key);
  final Widget body;
  final List<HomeNavItem> pages;
  final Function(int) onChanged;
  final int tabIndex;

  @override
  _BottomBarScaffoldState createState() => _BottomBarScaffoldState();
}

class _BottomBarScaffoldState extends State<BottomBarScaffold> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    final centralIndex = widget.pages.length ~/ 2;
    for (int i = 0; i < widget.pages.length; i++) {
      if (i == centralIndex) {
        children.insert(
            i,
            Container(
              width: 70,
              height: 70,
            ));
      } else {
        children.add(NavItem(widget.pages[i], i == widget.tabIndex, (item) {
          setState(() {
            final index =
                widget.pages.indexWhere((element) => element.text == item.text);
            widget.onChanged(index);
          });
        }));
      }
    }
    return Scaffold(
      body: widget.body,
      bottomNavigationBar: SimpleShadow(
        child: BottomAppBar(
          color: Color(0xFFE3DED8),
          shape: CustomNotchedShape(context),
          child: SizedBox(height: 66, child: Row(children: children)),
        ),
        opacity: 0.7, // Default: 0.5
        color: Color(0x66000000), // Default: Black
        offset: Offset(0, -1), // Default: Offset(2, 2)
        sigma: 4, // Default: 2
      ),
      floatingActionButton: CentralNavItem(
          widget.pages[centralIndex], centralIndex == widget.tabIndex, (item) {
        widget.onChanged(centralIndex);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class NavItem extends StatelessWidget {
  final HomeNavItem item;
  final bool active;
  final void Function(HomeNavItem) onPressed;

  const NavItem(this.item, this.active, this.onPressed);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.caption;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => onPressed(item),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Icon(item.icon, color: active ? Color(0xfffed802) : style?.color),
          Container(
            width: 24,
            height: 26,
            child: active ? item.iconActive : item.icon,
          ),
          const SizedBox(height: 2),
          Text(
            item.text,
            style: style?.copyWith(color: active ? Colors.black87 : null),
          )
        ]),
      ),
    );
  }
}

class CentralNavItem extends StatelessWidget {
  CentralNavItem(this.item, this.active, this.onPressed);

  final HomeNavItem item;
  final bool active;
  final void Function(HomeNavItem) onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.caption;
    return Container(
        margin: EdgeInsets.only(top: 30),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                  onPressed: () => onPressed(item),
                  child: Container(
                    width: 69,
                    height: 69,
                    decoration: BoxDecoration(
                      color: Color(0xFF706C6A),
                      borderRadius: BorderRadius.all(Radius.circular(69.0 / 2)),
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x61000000),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            spreadRadius: 1),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0 / 2)),
                            border: Border.all(
                                color: Color(!active ? 0xFFF4F2F0 : 0xFFBFBEBD),
                                width: 0.5),
                            gradient: LinearGradient(
                                //渐变位置
                                begin: Alignment.topRight, //右上
                                end: Alignment.bottomLeft, //左下
                                stops: [
                                  0.0,
                                  1.0
                                ],
                                colors: [
                                  Color(!active ? 0xFFEEECE8 : 0xFF807D78),
                                  Color(!active ? 0xFFB0ACA6 : 0xFFB0ACA6),
                                ])),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            child: active ? item.iconActive : item.icon,
                          ),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Text(
                item.text,
                style: style?.copyWith(color: active ? Colors.black87 : null),
              ),
            ]));
  }
}

class CustomNotchedShape extends NotchedShape {
  final BuildContext context;
  const CustomNotchedShape(this.context);

  @override
  Path getOuterPath(Rect host, Rect guest) {
    const radius = 60.0;
    const lx = 25.0;
    const ly = 19;
    const bx = 12.0;
    const by = 50.0;
    var x = (MediaQuery.of(context).size.width - radius) / 2 - lx;
    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(x, host.top)
      // ..lineTo(x += lx, host.top - ly)
      ..quadraticBezierTo(x + bx, host.top, x += lx, host.top - ly)
      // ..lineTo(x += radius, host.top - ly)
      ..quadraticBezierTo(
          x + radius / 2, host.top - by, x += radius, host.top - ly)
      // ..lineTo(x += lx, host.top)
      ..quadraticBezierTo((x += lx) - bx, host.top, x, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom);
  }
}
