import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/navigation_menu.dart';
import 'package:irs_capstone/pages/forgot_password_page.dart';
import 'package:irs_capstone/pages/home/home_page.dart';
import 'package:irs_capstone/pages/home/incident_details_page.dart';
import 'package:irs_capstone/pages/home/witness_page.dart';
import 'package:irs_capstone/pages/login_page.dart';
import 'package:irs_capstone/pages/profile/change_email_page.dart';
import 'package:irs_capstone/pages/profile/change_password_page.dart';
import 'package:irs_capstone/pages/profile/change_phone_page.dart';
import 'package:irs_capstone/pages/profile/update_profile_page.dart';
import 'package:irs_capstone/pages/profile/verify_change_page.dart';
import 'package:irs_capstone/pages/signup_page.dart';
import 'package:irs_capstone/pages/verify_phone_page.dart';
import 'package:irs_capstone/pages/profile/profile_page.dart';

class AppRouter {
  AppRouter._();

  static String initR = "/home";

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _rootNavigatorHome =
      GlobalKey<NavigatorState>(debugLabel: "shellHome");
  static final _rootNavigatorReports =
      GlobalKey<NavigatorState>(debugLabel: "shellReports");
  static final _rootNavigatorSOS =
      GlobalKey<NavigatorState>(debugLabel: "shellSOS");
  static final _rootNavigatorNotifications =
      GlobalKey<NavigatorState>(debugLabel: "shellNotifications");
  static final _rootNavigatorProfile =
      GlobalKey<NavigatorState>(debugLabel: "shellProfile");

  static GoRouter router = GoRouter(
    redirect: (context, state) async {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final currentUser = _auth.currentUser;

      if (currentUser == null &&
          state.uri.path != '/login' &&
          state.uri.path != '/signup' &&
          state.uri.path != '/forgot-password') {
        return '/login';
      }
    },
    initialLocation: initR,
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
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordPage(),
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
                builder: (context, state) => HomePage(
                  key: state.pageKey,
                ),
                routes: [
                  GoRoute(
                    path: 'incident/:id',
                    builder: (context, state) => IncidentDetailsPage(
                        id: state.pathParameters['id'] ?? ''),
                    routes: [
                      GoRoute(
                        path: 'witness/:id',
                        builder: (context, state) =>
                            WitnessPage(id: state.pathParameters['id'] ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorReports,
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => Scaffold(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorSOS,
            routes: [
              GoRoute(
                path: '/sos',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: Text("SOS"),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorNotifications,
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => Scaffold(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'update',
                    builder: (context, state) => UpdateProfilePage(),
                    routes: [
                      GoRoute(
                        path: 'email/:email',
                        builder: (context, state) => ChangeEmailPage(
                            email: state.pathParameters['email']!),
                      ),
                      GoRoute(
                        path: 'phone',
                        builder: (context, state) => ChangePhonePage(),
                      ),
                      GoRoute(
                        path: 'change-auth/:type',
                        builder: (context, state) => VerifyChangePage(
                            type: state.pathParameters["type"]!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) => ChangePasswordPage(),
                  ),
                ],
              ),
              GoRoute(
                path: '/profile/:reload', // Parameterized route
                builder: (context, state) {
                  final String reloadParam =
                      state.pathParameters['reload'] ?? '';
                  final bool reload = reloadParam.toLowerCase() == 'true';
                  return ProfilePage(reload: reload);
                },
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
