import 'dart:math';

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
              width: (MediaQuery.of(context).size.width - 32) / 3,
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
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: SimpleShadow(
        child: BottomAppBar(
          color: Color(0xFFE0DEDA),
          shape: CustomNotchedShape(context),
          child: SizedBox(height: 64, child: Row(children: children)),
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
        padding: EdgeInsets.only(top: 4, bottom: 4),
        onPressed: () => onPressed(item),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Icon(item.icon, color: active ? Color(0xfffed802) : style?.color),
          Container(
            width: 32,
            child: active ? item.iconActive : item.icon,
          ),
          Text(
            item.text,
            style: style?.copyWith(
                color: active
                    ? Theme.of(context).textSelectionTheme.selectionColor
                    : Color(0xFF9D9A98)),
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
              CentraNavBtn(
                onPressed: () => onPressed(item),
                active: active,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(3),
                    padding: EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
                        border: Border.all(
                            color: Color(!active ? 0xFFF4F2F0 : 0xFFBFBEBD),
                            width: 0.5),
                        gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
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
              ),
              const SizedBox(height: 5),
              Text(
                item.text,
                style: style?.copyWith(
                    color: active
                        ? Theme.of(context).textSelectionTheme.selectionColor
                        : Color(0xFF9D9A98)),
              ),
            ]));
  }
}

class CentraNavBtn extends StatefulWidget {
  CentraNavBtn({this.active, this.child, this.onPressed, Key key})
      : super(key: key);
  final bool active;
  Widget child;
  void Function() onPressed;

  @override
  _CentraNavBtnState createState() => _CentraNavBtnState();
}

class _CentraNavBtnState extends State<CentraNavBtn>
    with TickerProviderStateMixin {
  AnimationController controller;
  double animationNumber = 1;
  Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final buttonSize = 69.0;
    return GestureDetector(
        onTapUp: (tapUpDetails) {
          if (!widget.active) {
            this.controller = AnimationController(
                duration: const Duration(milliseconds: 800), vsync: this);
            animation = Tween(begin: 0.0, end: 1.0).animate(controller);
            animation.addListener(() {
              setState(() {
                animationNumber = animation.value;
              });
            });
            controller.forward();
          }
        },
        onTap: () => widget.onPressed(),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          child: FittedBox(
            child: FloatingActionButton(
                onPressed: null,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: Color(0xFF706C6A),
                    borderRadius:
                        BorderRadius.all(Radius.circular(buttonSize / 2)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x61000000),
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          spreadRadius: 1),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: buttonSize,
                        height: buttonSize,
                        child: CustomPaint(
                          painter: CircularProgressBar(
                              width: 3,
                              lineColor: [
                                Color(0xFFFF6732),
                                Color(0xFFFF9F7E),
                                Color(0xFFFF6732)
                              ],
                              progress: widget.active ? animationNumber : 0),
                        ),
                      ),
                      widget.child
                    ],
                  ),
                )),
          ),
        ));
  }
}

class CircularProgressBar extends CustomPainter {
  List<Color> lineColor;
  double width;
  double progress; //0-1
  double endAngle;

  CircularProgressBar({this.lineColor, this.width, this.progress = 1}) {
    this.endAngle = this.progress / 1 * 2 * pi;
  }
  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius =
        min(size.width / 2 - width / 2, size.height / 2 - width / 2);

    var paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = width;

    paint.shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      colors: lineColor,
      transform: GradientRotation(pi / 2),
    ).createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi / 2,
        endAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as CircularProgressBar).progress != this.progress;
  }
}

class CustomNotchedShape extends NotchedShape {
  final BuildContext context;
  const CustomNotchedShape(this.context);

  @override
  Path getOuterPath(Rect host, Rect guest) {
    const radius = 70.0;
    const lx = 40.0;
    const ly = 22;
    const bx = 25.0;
    const by = 40.0;
    var x = (MediaQuery.of(context).size.width - radius) / 2 - lx;
    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(x, host.top)
      // ..lineTo(x += lx, host.top - ly)
      ..quadraticBezierTo(x + bx, host.top, x += lx, host.top - ly)
      // ..lineTo(x += radius, host.top - ly)
      ..quadraticBezierTo(
          x + radius / 5, host.top - by, x += radius / 2, host.top - by)
      ..quadraticBezierTo(
          x + radius / 3.5, host.top - by, x += radius / 2, host.top - ly)
      // ..lineTo(x += lx, host.top)
      ..quadraticBezierTo((x += lx) - bx, host.top, x, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom);
  }
}
