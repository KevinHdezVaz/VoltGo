import 'package:flutter/material.dart';
import 'package:wisetrack_app/ui/IntroPage/OnboardingScreenOne.dart';
import 'package:wisetrack_app/ui/IntroPage/OnboardingScreenThree.dart';
import 'package:wisetrack_app/ui/IntroPage/OnboardingScreenTwo.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  _OnboardingWrapperState createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          OnboardingScreenOne(pageController: _pageController),
          OnboardingscreenTwo(pageController: _pageController),
          OnboardingscreenThree(pageController: _pageController),
        ],
      ),
    );
  }
}
