import 'package:app/pages/profile/crowdLoan/crowdLoanPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';

class KarCrowdLoanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Image.asset('assets/images/public/banner_kar_plo.png',
          width: double.infinity, fit: BoxFit.contain),
      onTap: () => Navigator.of(context).pushNamed(CrowdLoanPage.route),
    );
  }
}

class ACACrowdLoanBanner extends StatelessWidget {
  ACACrowdLoanBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Image.asset(
        'assets/images/public/banner_aca_plo.png',
        width: double.infinity,
        fit: BoxFit.contain,
      ),
      onTap: () => Navigator.of(context).pushNamed(CrowdLoanPage.route),
    );
  }
}

class GeneralCrowdLoanBanner extends StatelessWidget {
  const GeneralCrowdLoanBanner(this.image, this.url, {Key key})
      : super(key: key);

  final String image;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Image.asset(image, width: double.infinity, fit: BoxFit.contain),
      onTap: () => Navigator.of(context).pushNamed(
        DAppWrapperPage.route,
        arguments: url,
      ),
    );
  }
}
