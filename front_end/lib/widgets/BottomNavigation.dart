import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/screen/authentication/home.dart';
import 'package:paddy_rice/screen/profileManagement/profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class BottomNavigationRoute extends StatefulWidget {
  final int page;

  const BottomNavigationRoute({this.page = 0});
  @override
  _BottomNavigationRouteState createState() => _BottomNavigationRouteState();
}

class _BottomNavigationRouteState extends State<BottomNavigationRoute> {
  int _selectedTab = 0;

  final List<Widget> _pages = [
    HomeRoute(),
    ProfileRoute(),
  ];
  @override
  void initState() {
    super.initState();
    _selectedTab = widget.page;
  }

  void _changeTab(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => _changeTab(index),
        selectedItemColor: iconcolor,
        backgroundColor: fill_color,
        unselectedItemColor: unnecessary_colors,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: S.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: S.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
