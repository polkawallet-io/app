import 'package:flutter/material.dart';

class InstrumentItemWidget extends StatefulWidget {
  final List<InstrumentData> datas;
  int initializeIndex;
  final Size size;
  InstrumentItemWidgetController controller;
  Function(int, bool isOnClick) onChanged;
  InstrumentItemWidget(
      {Key key,
      @required this.controller,
      @required this.datas,
      @required this.size,
      this.onChanged,
      this.initializeIndex = 0})
      : super(key: key);

  @override
  _InstrumentItemWidgetState createState() => _InstrumentItemWidgetState();
}

class _InstrumentItemWidgetState extends State<InstrumentItemWidget>
    with TickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();

  Animation<double> animation;
  double animationNumber = 1;
  AnimationController controller;

  bool isSwitching = false;

  @override
  void initState() {
    widget.controller.bindAction(({bool isOnClick}) {
      _switchAction(isOnClick: isOnClick ?? true);
    });
    super.initState();
  }

  dispose() {
    controller?.dispose();
    super.dispose();
  }

  _switchAction({isOnClick = true}) {
    if (!isOnClick &&
        widget.datas.length > 1 &&
        widget.datas[1].sumValue == 0 &&
        widget.datas[1].items.length > 0) {
      widget.initializeIndex = widget.initializeIndex + 1 >= widget.datas.length
          ? 0
          : widget.initializeIndex + 1;
      if (widget.onChanged != null) {
        widget.onChanged(widget.initializeIndex, isOnClick);
      }
      return;
    }
    if (isSwitching || !mounted) return;
    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    final CurvedAnimation curve =
        CurvedAnimation(parent: controller, curve: Curves.easeIn);
    animation = Tween(begin: 1.0, end: 0.0).animate(curve)
      ..addListener(() {
        setState(() {
          isSwitching = true;
          animationNumber = animation.value;
          // the state that has changed here is the animation object’s value
        });
      })
      ..addStatusListener((state) {
        //当动画在开始处停止再次从头开始执行动画
        if (state == AnimationStatus.completed) {
          setState(() {
            isSwitching = false;
            this.animationNumber = 1;
            widget.initializeIndex =
                widget.initializeIndex + 1 >= widget.datas.length
                    ? 0
                    : widget.initializeIndex + 1;
            if (widget.onChanged != null) {
              widget.onChanged(widget.initializeIndex, isOnClick);
            }
          });
        }
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _containerKey,
      children: buildItems(),
    );
  }

  List<Widget> buildItems() {
    if (widget.datas[widget.initializeIndex].sumValue == 0 &&
        widget.datas[widget.initializeIndex].items.length > 0) {
      return [Container()];
    }
    final List<Widget> currentWidgets = [];
    final List<Widget> widgets = [];
    for (int j = 0; j < widget.datas.length; j++) {
      double angle = 0;
      for (int i = 0; i < widget.datas[j].items.length; i++) {
        if (i > 0) {
          angle += -3.85 *
              widget.datas[j].items[i - 1].value /
              widget.datas[j].sumValue;
        }
        if (double.parse(widget.datas[j].items[i].value
                .toStringAsFixed(widget.datas[j].lengthMax)) >
            0) {
          var angleValue = j == widget.initializeIndex
              ? (angle * animationNumber + 2.4 * (1 - animationNumber))
              : (-3.9 * animationNumber + angle * (1 - animationNumber));
          (j == widget.initializeIndex ? currentWidgets : widgets).add(
              angleValue < -2.45
                  ? ClipRect(
                      child: Align(
                          widthFactor: 0.5,
                          alignment: Alignment.centerLeft,
                          child: buildItem(
                              angleValue, widget.datas[j].items[i].iconName)))
                  : buildItem(angleValue, widget.datas[j].items[i].iconName));
        }
      }
    }
    currentWidgets.addAll(widgets);
    return currentWidgets.length > 0 ? currentWidgets : [Container()];
  }

  Widget buildItem(double angleValue, String iconName) {
    return ClipRect(
        child: Align(
            widthFactor: 1,
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: angleValue,
              alignment: Alignment.bottomCenter,
              origin: Offset(0, -(44 / 167) * widget.size.height),
              child: Container(
                child: Image.asset(
                  iconName,
                  fit: BoxFit.fill,
                ),
                width: widget.size.width,
                height: widget.size.height,
              ),
            )));
  }
}

class InstrumentItemWidgetController {
  Function({bool isOnClick}) switchAction;

  void bindAction(Function({bool isOnClick}) switchAction) {
    this.switchAction = switchAction;
  }
}

class InstrumentItemData {
  final Color color;
  final String iconName;
  final String name;
  final double value;

  InstrumentItemData(this.color, this.name, this.value, this.iconName);
}

class InstrumentData {
  final double sumValue;
  final int lengthMax;
  final String title;
  List<InstrumentItemData> items;

  InstrumentData(this.sumValue, this.items,
      {this.lengthMax = 2, this.title = ""});
}
