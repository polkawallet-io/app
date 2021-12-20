import 'package:app/utils/InstrumentItemWidget.dart';
import 'package:app/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

export 'package:app/utils/InstrumentItemWidget.dart';

class InstrumentWidget extends StatefulWidget {
  InstrumentWidget(this.datas,
      {Key key,
      @required this.onSwitchChange,
      @required this.onSwitchHideBalance,
      this.hideBalance = false,
      this.enabled = false,
      this.priceCurrency = 'USD',
      this.switchDefi = false,
      this.gradienColors})
      : super(key: key);
  final List<InstrumentData> datas;
  final Function onSwitchChange;
  final Function onSwitchHideBalance;
  final bool hideBalance;
  final bool enabled;
  final String priceCurrency;
  final bool switchDefi;
  final List<Color> gradienColors;
  @override
  _InstrumentWidgetState createState() => _InstrumentWidgetState();
}

class _InstrumentWidgetState extends State<InstrumentWidget> {
  InstrumentItemWidgetController controller = InstrumentItemWidgetController();
  int index = 0;

  @override
  void initState() {
    // print("initState");
    WidgetsBinding.instance
        .addPostFrameCallback((_) => controller.switchAction(isOnClick: false));
    // TODO: implement initState
    super.initState();
  }

  int getIndex() {
    return index >= widget.datas.length ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - (16.w + 11.w + 34.w) * 2;
    return Column(
      children: [
        Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            margin: EdgeInsets.symmetric(horizontal: 34.w),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                InstrumentItemWidget(
                  controller: controller,
                  onChanged: (index, isOnClick) {
                    if (isOnClick) {
                      widget.onSwitchChange();
                    }
                    setState(() {
                      this.index = index;
                    });
                  },
                  datas: widget.datas,
                  initializeIndex: getIndex(),
                  size: Size(width, width / 249 * 168),
                ),
                Container(
                    width: width,
                    height: width / 249 * 168,
                    child: Image.asset(
                      "assets/images/icon_instrument.png",
                      fit: BoxFit.fill,
                    )),
                Container(
                  child: Column(
                    children: [
                      Text(
                          widget.datas[getIndex()].title.length > 0
                              ? "${widget.datas[getIndex()].title}:"
                              : "",
                          style: TextStyle(
                              fontFamily: "TitilliumWeb",
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context)
                                  .textSelectionTheme
                                  .selectionColor)),
                      GestureDetector(
                        onTap: () {
                          widget.onSwitchHideBalance();
                        },
                        child: Text(
                            widget.hideBalance
                                ? "******"
                                : "${Utils.currencySymbol(widget.priceCurrency)}${Fmt.priceFloor(widget.datas[getIndex()].sumValue, lengthMax: widget.datas[getIndex()].lengthMax)}",
                            style: TextStyle(
                                fontFamily: "SF_Pro",
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textSelectionTheme
                                    .selectionColor)),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 15.h),
                        child: GestureDetector(
                            onTap: widget.switchDefi && widget.enabled
                                ? () {
                                    controller.switchAction();
                                  }
                                : null,
                            child: Container(
                              width: 46.w,
                              height: 46.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: widget.gradienColors ??
                                        [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context).hoverColor
                                        ]),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(46.w / 2)),
                              ),
                              // child: Center(
                              child: Center(
                                  child: Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(40.w / 2)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Color(0x4F000000),
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          spreadRadius: 0),
                                    ],
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [
                                          0.0,
                                          1.0
                                        ],
                                        colors: [
                                          Color(0xFFFFFAF1),
                                          Color(0xFFB1ADA7),
                                        ])),
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    width: 22.w,
                                    height: 15.w,
                                    child: Image.asset(
                                        'assets/images/icon_instrument_1.png'),
                                  ),
                                ),
                              )),
                              // ),
                            )),
                      )
                    ],
                  ),
                )
              ],
            )),
        !widget.switchDefi
            ? Container(
                margin: EdgeInsets.only(bottom: 8),
              )
            : Container(
                margin: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(widget.datas[getIndex()].prompt,
                    style: TextStyle(
                        fontFamily: "SF_Pro",
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .textSelectionTheme
                            .selectionColor)),
              ),
        Row(
          children: [
            ...widget.datas[getIndex()].items.reversed
                .map((e) => Expanded(
                        child: RoundedCard(
                      margin: EdgeInsets.symmetric(horizontal: 4.5.w),
                      padding:
                          EdgeInsets.symmetric(horizontal: 11.w, vertical: 3.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                    color: e.color,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(10 / 2))),
                              ),
                              Text(
                                e.name,
                                style: TextStyle(
                                    fontFamily: "TitilliumWeb",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .textSelectionTheme
                                        .selectionColor),
                              )
                            ],
                          ),
                          Text(
                            widget.hideBalance
                                ? "******"
                                : "${Utils.currencySymbol(widget.priceCurrency)}${Fmt.priceFloor(e.value, lengthMax: widget.datas[getIndex()].lengthMax)}",
                            style: TextStyle(
                                fontFamily: "TitilliumWeb",
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context)
                                    .textSelectionTheme
                                    .selectionColor),
                          )
                        ],
                      ),
                    )))
                .toList(),
          ],
        )
      ],
    );
  }
}
