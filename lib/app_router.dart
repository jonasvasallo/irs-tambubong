import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/navigation_menu.dart';
import 'package:irs_capstone/pages/home_page.dart';
import 'package:irs_capstone/pages/login_page.dart';
import 'package:irs_capstone/pages/signup_page.dart';
import 'package:irs_capstone/pages/verify_phone_page.dart';

class AppRouter {
  AppRouter._();

  static String initR = "/auth/login";

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _rootNavigatorHome =
      GlobalKey<NavigatorState>(debugLabel: "shellHome");
  static final _rootNavigatorCart =
      GlobalKey<NavigatorState>(debugLabel: "shellCart");
  static final _rootNavigatorNotif =
      GlobalKey<NavigatorState>(debugLabel: "shellNotif");
  static final _rootNavigatorProfile =
      GlobalKey<NavigatorState>(debugLabel: "shellProfile");

  static GoRouter router = GoRouter(
    initialLocation: "/login",
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignupPage(),
      ),
      GoRoute(
        path: '/verify/:verificationId/:phoneNumber',
        builder: (context, state) => VerifyPhonePage(
            verificationId: state.pathParameters["verificationId"]!,
            phoneNumber: state.pathParameters["phoneNumber"]!),
      ),
      StatefulShellRoute.indexedStack(
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _rootNavigatorHome,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => HomePage(),
              ),
            ],
          ),
        ],
        builder: (context, state, navigationShell) => NavigationMenu(
          navigationShell: navigationShell,
        ),
      ),
    ],
  );

  // static final GoRouter router = GoRouter(
  //   initialLocation: initR,
  //   navigatorKey: _rootNavigatorKey,
  //   routes: <RouteBase>[
  //     GoRoute(
  //       builder: (context, state) {
  //         return Container();
  //       },
  //       path: '/auth',
  //       routes: [
  //         GoRoute(
  //           path: 'login',
  //           builder: (context, state) => LoginPage(),
  //         ),
  //         GoRoute(
  //           path: 'signup',
  //           builder: (context, state) => SignupPage(),
  //         ),
  //       ],
  //     ),
  // StatefulShellRoute.indexedStack(
  //   branches: <StatefulShellBranch>[
  //     StatefulShellBranch(
  //       navigatorKey: _rootNavigatorHome,
  //       routes: [
  //         GoRoute(
  //           path: "/home",
  //           name: "Home",
  //           builder: (context, state) => HomePage(
  //             key: state.pageKey,
  //           ),
  //           routes: [],
  //         ),
  //       ],
  //     ),
  // StatefulShellBranch(
  //   navigatorKey: _rootNavigatorCart,
  //   routes: [
  //     GoRoute(
  //       path: "/cart",
  //       name: "Cart",
  //       builder: (context, state) => CartPage(
  //         key: state.pageKey,
  //       ),
  //       routes: [
  //         GoRoute(
  //           path: "checkout",
  //           name: "Checkout",
  //           builder: (context, state) => CheckoutPage(
  //             key: state.pageKey,
  //           ),
  //         ),
  //       ],
  //     ),
  //   ],
  // ),
  // StatefulShellBranch(
  //   navigatorKey: _rootNavigatorNotif,
  //   routes: [
  //     GoRoute(
  //       path: "/notif",
  //       name: "Notifications",
  //       builder: (context, state) => NotificationPage(
  //         key: state.pageKey,
  //       ),
  //     ),
  //   ],
  // ),
  // StatefulShellBranch(
  //   navigatorKey: _rootNavigatorProfile,
  //   routes: [
  //     GoRoute(
  //       path: "/profile",
  //       name: "Main Profile",
  //       builder: (context, state) => MainProfilePage(
  //         key: state.pageKey,
  //       ),
  //       routes: [
  //         GoRoute(
  //           path: "orders",
  //           name: "Orders",
  //           builder: (context, state) => OrdersPage(
  //             key: state.pageKey,
  //           ),
  //         ),
  //       ],
  //     ),
  //   ],
  // ),
  //   ],
  //   builder: (context, state, navigationShell) => NavigationMenu(
  //     navigationShell: navigationShell,
  //   ),
  // ),
  //   ],
  // );
}
