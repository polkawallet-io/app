import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:rive/rive.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class BridgeChainSelector extends StatelessWidget {
  const BridgeChainSelector(
      {Key key,
      this.chainFromAll,
      this.chainToMap,
      this.from,
      this.to,
      this.loading,
      this.connecting = false,
      this.toConnecting = false,
      this.chainsInfo,
      this.onChanged})
      : super(key: key);

  final List<String> chainFromAll;
  final Map<String, Set<String>> chainToMap;
  final bool loading;
  final bool connecting;
  final bool toConnecting;
  final String from;
  final String to;
  final Map<String, BridgeChainData> chainsInfo;
  final Function(String, String) onChanged;

  void _switch() {
    if (!chainFromAll.contains(to)) return;
    if (!chainToMap[to].toList().contains(from)) return;
    onChanged(to, from);
  }

  void _selectFrom(BuildContext context) {
    _selectChain(context, 0, chainFromAll);
  }

  void _selectTo(BuildContext context) {
    _selectChain(context, 1, chainToMap[from].toList());
  }

  Future<void> _selectChain(
      BuildContext context, int index, List<String> options) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final current = index == 0 ? from : to;
    final crossChainIcons = Map<String, Widget>.from(chainsInfo?.map((k, v) =>
        MapEntry(
            k,
            v.icon.contains('.svg')
                ? SvgPicture.network(v.icon)
                : Image.network(v.icon))));
    Navigator.of(context).push(BridgePopupRoute(
      title: index == 0 ? dic['bridge.from'] : dic['bridge.to'],
      child: ChainSelectorList(
        selected: current,
        options: options,
        crossChainIcons: crossChainIcons,
        chainsInfo: chainsInfo,
        onSelect: (chain) {
          Navigator.of(context).pop();
          if (chain != current) {
            if (index == 0) {
              onChanged(
                  chain,
                  chainToMap[chain].contains(to)
                      ? to
                      : chainToMap[chain].toList().first);
            } else {
              onChanged(from, chain);
            }
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    BridgeChainData fromData = chainsInfo != null ? chainsInfo[from] : null;
    BridgeChainData toData = chainsInfo != null ? chainsInfo[to] : null;

    return Container(
        width: double.infinity,
        height: 140.h,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.24),
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: Padding(
          padding:
              EdgeInsets.only(left: 30.w, right: 30.w, top: 0, bottom: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24.h,
                    child: Text(
                      dic['bridge.from'],
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Titillium Web Bold',
                        fontSize: 16.sp,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                      onTap: chainFromAll != null && chainFromAll.isNotEmpty
                          ? () => _selectFrom(context)
                          : null,
                      child: Container(
                        width: 112.w,
                        height: 100.h,
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8)),
                            color: Color(0xFF404142)),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              child: fromData == null
                                  ? Align(
                                      child: SizedBox(
                                          height: 40.w,
                                          width: 40.w,
                                          child: Stack(
                                            children: [
                                              SkeletonLoader(
                                                builder: Container(
                                                  height: 40.w,
                                                  width: 40.w,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF6F6F6F),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.w),
                                                  ),
                                                ),
                                                items: 1,
                                                period:
                                                    const Duration(seconds: 2),
                                                highlightColor:
                                                    const Color(0xFF404142),
                                                baseColor:
                                                    const Color(0xFF6F6F6F),
                                                direction:
                                                    SkeletonDirection.ltr,
                                              ),
                                              Align(
                                                child: Container(
                                                  height: 20.w,
                                                  width: 20.w,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF404142),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.w),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )),
                                    )
                                  : fromData.icon.contains("svg")
                                      ? SvgPicture.network(fromData.icon,
                                          height: 40.w,
                                          width: 40.w,
                                          color: connecting
                                              ? Colors.black.withOpacity(0.5)
                                              : null,
                                          colorBlendMode: BlendMode.srcIn)
                                      : Image.network(fromData.icon,
                                          height: 40.w,
                                          width: 40.w,
                                          color: connecting
                                              ? Colors.black.withOpacity(0.5)
                                              : null,
                                          colorBlendMode: BlendMode.srcATop),
                            ),
                            Container(
                                height: 22.h,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                    color: Color(0xff2e2f30),
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8))),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: fromData == null
                                          ? SizedBox(
                                              height: 10.w,
                                              width: 52.w,
                                              child: SkeletonLoader(
                                                builder: Container(
                                                  height: 10.w,
                                                  width: 52.w,
                                                  color:
                                                      const Color(0xFF6F6F6F),
                                                ),
                                                items: 1,
                                                period:
                                                    const Duration(seconds: 2),
                                                highlightColor:
                                                    const Color(0xFF404142),
                                                baseColor:
                                                    const Color(0xFF6F6F6F),
                                                direction:
                                                    SkeletonDirection.ltr,
                                              ),
                                            )
                                          : Text(
                                              fromData?.display ?? '',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.normal,
                                                  fontFamily:
                                                      'Titillium Web Regular'),
                                            ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Visibility(
                                          visible: connecting,
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(left: 4),
                                            width: 14,
                                            height: 14,
                                            child: const RiveAnimation.asset(
                                              'assets/images/loading.riv',
                                              fit: BoxFit.none,
                                            ),
                                          )),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: SvgPicture.asset(
                                            "packages/polkawallet_ui/assets/images/triangle_bottom.svg",
                                            width: 12.w,
                                            color: const Color(0xFFFF7849),
                                          )),
                                    ),
                                  ],
                                ))
                          ],
                        ),
                      ))
                ],
              ),
              GestureDetector(
                onTap: () => _switch(),
                child: Container(
                  margin: EdgeInsets.only(top: 16.h),
                  child: Image.asset("assets/images/icon_bridge_swap.png",
                      width: 36.w),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24.h,
                    child: Text(
                      dic['bridge.to'],
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Titillium Web Bold',
                        fontSize: 16.sp,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                      onTap: to != null ? () => _selectTo(context) : null,
                      child: Container(
                        width: 112.w,
                        height: 100.h,
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8)),
                            color: Color(0xFF404142)),
                        child: Column(
                          children: [
                            Expanded(
                                child: Container(
                                    child: toData == null
                                        ? Align(
                                            child: SizedBox(
                                                height: 40.w,
                                                width: 40.w,
                                                child: Stack(
                                                  children: [
                                                    SkeletonLoader(
                                                      builder: Container(
                                                        height: 40.w,
                                                        width: 40.w,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFF6F6F6F),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.w),
                                                        ),
                                                      ),
                                                      items: 1,
                                                      period: const Duration(
                                                          seconds: 2),
                                                      highlightColor:
                                                          const Color(
                                                              0xFF404142),
                                                      baseColor: const Color(
                                                          0xFF6F6F6F),
                                                      direction:
                                                          SkeletonDirection.ltr,
                                                    ),
                                                    Align(
                                                      child: Container(
                                                        height: 20.w,
                                                        width: 20.w,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFF404142),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.w),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                )),
                                          )
                                        : toData.icon.contains("svg")
                                            ? SvgPicture.network(toData.icon,
                                                height: 40.w,
                                                width: 40.w,
                                                color: toConnecting
                                                    ? Colors.black
                                                        .withOpacity(0.5)
                                                    : null,
                                                colorBlendMode: BlendMode.srcIn)
                                            : Image.network(toData.icon,
                                                height: 40.w,
                                                width: 40.w,
                                                color: toConnecting
                                                    ? Colors.black
                                                        .withOpacity(0.5)
                                                    : null,
                                                colorBlendMode:
                                                    BlendMode.srcATop))),
                            Container(
                              height: 22.h,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                  color: Color(0xff2e2f30),
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8))),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: toData == null
                                        ? SizedBox(
                                            height: 10.w,
                                            width: 52.w,
                                            child: SkeletonLoader(
                                              builder: Container(
                                                height: 10.w,
                                                width: 52.w,
                                                color: const Color(0xFF6F6F6F),
                                              ),
                                              items: 1,
                                              period:
                                                  const Duration(seconds: 2),
                                              highlightColor:
                                                  const Color(0xFF404142),
                                              baseColor:
                                                  const Color(0xFF6F6F6F),
                                              direction: SkeletonDirection.ltr,
                                            ),
                                          )
                                        : Text(
                                            toData != null
                                                ? toData.display
                                                : '',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.normal,
                                                fontFamily:
                                                    'Titillium Web Regular'),
                                          ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Visibility(
                                        visible: toConnecting,
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          width: 14,
                                          height: 14,
                                          child: const RiveAnimation.asset(
                                            'assets/images/loading.riv',
                                            fit: BoxFit.none,
                                          ),
                                        )),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: SvgPicture.asset(
                                          "packages/polkawallet_ui/assets/images/triangle_bottom.svg",
                                          width: 12.w,
                                          color: const Color(0xFFFF7849),
                                        )),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ))
                ],
              )
            ],
          ),
        ));
  }
}

class BridgePopupRoute<T> extends PopupRoute<T> {
  @override
  Color get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(seconds: 0);

  final Color backgroundViewColor;

  /// default value: [Alignment.center]
  final Alignment alignment;

  /// child
  final Widget child;

  /// child
  final String title;

  /// backgroundView Tap action default dismiss
  final Function onClick;

  BridgePopupRoute(
      {this.backgroundViewColor,
      this.alignment = Alignment.center,
      this.onClick,
      this.child,
      this.title});

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        child: Stack(
          children: [
            Container(
              width: screenSize.width,
              height: screenSize.height,
              color: backgroundViewColor ?? Colors.white.withOpacity(0.3),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: screenSize.width - 56.w,
                  height: 420.h,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF212224)),
                  child: Column(
                    children: [
                      Padding(
                          padding: EdgeInsets.only(
                              left: 20.w, right: 4.w, top: 8.h, bottom: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title ?? "",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18.sp,
                                    height: 1.5,
                                    fontFamily: 'Titillium Web SemiBold'),
                              ),
                              IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20.w,
                                  ))
                            ],
                          )),
                      Expanded(
                          child: Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: child))
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          if (onClick != null) {
            onClick();
          }
        },
      ),
    );
  }
}

class ChainSelectorList extends StatefulWidget {
  const ChainSelectorList(
      {this.options,
      this.crossChainIcons,
      this.chainsInfo,
      this.selected,
      this.onSelect,
      Key key})
      : super(key: key);

  final List<String> options;
  final Map<String, Widget> crossChainIcons;
  final Map<String, BridgeChainData> chainsInfo;
  final String selected;
  final Function(String) onSelect;
  @override
  State<ChainSelectorList> createState() => _ChainSelectorListState();
}

class _ChainSelectorListState extends State<ChainSelectorList> {
  final TextEditingController searchCtl = TextEditingController();
  final FocusNode focusNode = FocusNode();
  List<String> searchList = [];

  @override
  void initState() {
    super.initState();
    searchList = widget.options;
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return Column(children: [
      Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
          alignment: Alignment.center,
          height: 40,
          child: Stack(
            children: [
              Align(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFF424447)),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextField(
                  focusNode: focusNode,
                  controller: searchCtl,
                  onChanged: (value) {
                    var list = widget.options
                        .where((element) => element
                            .toUpperCase()
                            .contains(searchCtl.text.toUpperCase()))
                        .toList();
                    if (searchCtl.text.isEmpty) {
                      list = widget.options;
                    }
                    setState(() {
                      searchList = list;
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  textInputAction: TextInputAction.search,
                  maxLines: 1,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(left: 8, right: 30),
                    hintText: dic['bridge.search.chain'],
                    hintStyle: TextStyle(
                        fontFamily: 'Titillium Web Light',
                        fontWeight: FontWeight.w300,
                        fontSize: UI.getTextSize(14, context),
                        color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Icon(
                      Icons.search,
                      size: 24,
                      color: Color(0xFF979797),
                    )),
              )
            ],
          )),
      Expanded(
          child: ListView(
        children: searchList.map((i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0x24FFFFFF)),
                foregroundDecoration: i == widget.selected
                    ? BoxDecoration(
                        color: const Color(0xFFFF7849).withOpacity(0.09),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFF7849),
                        ))
                    : null,
                child: ListTile(
                  selected: i == widget.selected,
                  title: CurrencyWithIcon(
                    widget.chainsInfo[i].display ?? '',
                    TokenIcon(i, widget.crossChainIcons),
                    textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Titillium Web SemiBold'),
                  ),
                  onTap: () {
                    widget.onSelect(i);
                  },
                )),
          );
        }).toList(),
      ))
    ]);
  }
}
