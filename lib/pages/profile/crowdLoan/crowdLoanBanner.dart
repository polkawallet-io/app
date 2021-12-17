import 'package:app/pages/profile/crowdLoan/crowdLoanPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KarCrowdLoanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    final cardColor = Theme.of(context).cardColor;
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        GestureDetector(
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        Image.asset('assets/images/public/banner_kar_plo.png'),
                  )
                ],
              ),
              Container(
                constraints: BoxConstraints(maxHeight: fullWidth / 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: fullWidth / 3 + 24,
                      alignment: Alignment.centerLeft,
                      height: 32,
                      margin: EdgeInsets.only(left: 16, top: 24.h, right: 8.w),
                      // child: Image.asset(
                      //     'assets/images/public/kar_logo.png'),
                      child: SvgPicture.asset(
                          'assets/images/public/kusama_logo.svg'),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 24, top: 6.h),
                      child: Text(
                        'Parachain Auction',
                        style: TextStyle(
                            color: cardColor,
                            height: 0.9,
                            fontSize: 21,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          onTap: () => Navigator.of(context).pushNamed(CrowdLoanPage.route),
        ),
      ],
    );
  }
}
