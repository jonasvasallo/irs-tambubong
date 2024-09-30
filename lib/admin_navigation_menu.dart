import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:irs_app/constants.dart";

class AdminNavigationMenu extends StatefulWidget {
  const AdminNavigationMenu({Key? key, required this.navigationShell})
      : super(key: key);

  final StatefulNavigationShell navigationShell;

  @override
  State<AdminNavigationMenu> createState() => _AdminNavigationMenuState();
}

class _AdminNavigationMenuState extends State<AdminNavigationMenu> {
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
              Icons.report,
              color: majorText,
            ),
            label: "Emergencies",
          ),
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
