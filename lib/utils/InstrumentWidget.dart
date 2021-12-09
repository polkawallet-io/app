import 'package:app/utils/InstrumentItemWidget.dart';
import 'package:app/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      this.priceCurrency = 'USD'})
      : super(key: key);
  final List<InstrumentData> datas;
  final Function onSwitchChange;
  final Function onSwitchHideBalance;
  final bool hideBalance;
  final bool enabled;
  final String priceCurrency;
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
                  size: Size(MediaQuery.of(context).size.width - 122.w,
                      (MediaQuery.of(context).size.width - 122.w) / 294 * 168),
                ),
                Image.asset("assets/images/icon_instrument.png"),
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
                              color: Theme.of(context).textSelectionColor)),
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
                                color: Theme.of(context).textSelectionColor)),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 15.h),
                        child: GestureDetector(
                            onTap: widget.datas.length < 2 || !widget.enabled
                                ? null
                                : () {
                                    controller.switchAction();
                                  },
                            child: Container(
                              width: 46.w,
                              height: 46.w,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
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
                                    child: SvgPicture.asset(
                                        'assets/images/icon_instrument_1.svg'),
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
        widget.datas.length < 2
            ? Container(
                margin: EdgeInsets.only(bottom: 11),
              )
            : Container(
                margin: EdgeInsets.only(top: 4, bottom: 11),
                child: Text(widget.datas[getIndex()].prompt,
                    style: TextStyle(
                        fontFamily: "SF_Pro",
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).textSelectionColor)),
              ),
        Row(
          children: [
            ...widget.datas[getIndex()].items.reversed
                .map((e) => Expanded(
                        child: RoundedCard(
                      margin: EdgeInsets.symmetric(horizontal: 4.5.w),
                      padding:
                          EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10.w,
                                height: 10.w,
                                margin: EdgeInsets.only(right: 3.w),
                                decoration: BoxDecoration(
                                    color: e.color,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(10.w / 2))),
                              ),
                              Text(
                                e.name,
                                style: TextStyle(
                                    fontFamily: "TitilliumWeb",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Theme.of(context).textSelectionColor),
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
                                color: Theme.of(context).textSelectionColor),
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
