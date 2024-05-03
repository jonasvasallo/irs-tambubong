import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:irs_capstone/constants.dart";

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({Key? key, required this.navigationShell})
      : super(key: key);

  final StatefulNavigationShell navigationShell;

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int nav_index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        indicatorColor: Color(0xFF4FADC0),
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 80,
        elevation: 0,
        selectedIndex: nav_index,
        onDestinationSelected: (value) {
          setState(() {
            nav_index = value;
          });
          goToBranch(nav_index);
        },
        destinations: [
          NavigationDestination(
              icon: Icon(
                Icons.home,
                color: majorText,
              ),
              label: "Home"),
          NavigationDestination(
            icon: Icon(
              Icons.notifications_active,
              color: majorText,
            ),
            label: "Reports",
          ),
          NavigationDestination(
            icon: Icon(
              Icons.sos_rounded,
              color: Colors.red,
            ),
            label: "SOS",
          ),
          NavigationDestination(
              icon: Icon(
                Icons.campaign_rounded,
                color: majorText,
              ),
              label: "News"),
          NavigationDestination(
              icon: Icon(
                Icons.person,
                color: majorText,
              ),
              label: "Profile"),
        ],
      ),
    );
  }

  void goToBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
