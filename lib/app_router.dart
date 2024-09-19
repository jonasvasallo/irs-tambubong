import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/navigation_menu.dart';
import 'package:irs_app/resident/mfa_phone_page.dart';
import 'package:irs_app/resident/mfa_page.dart';
import 'package:irs_app/resident/pages/forgot_password_page.dart';
import 'package:irs_app/resident/pages/home/add_incident_page.dart';
import 'package:irs_app/resident/pages/home/home_page.dart';
import 'package:irs_app/resident/pages/home/incident_chatroom_page.dart';
import 'package:irs_app/resident/pages/home/incident_details_page.dart';
import 'package:irs_app/resident/pages/news/news_details_page.dart';
import 'package:irs_app/resident/pages/notifications/notification_detail_page.dart';
import 'package:irs_app/resident/pages/notifications/notification_page.dart';
import 'package:irs_app/resident/pages/profile/help/CaseDetailsPage.dart';
import 'package:irs_app/resident/pages/profile/help/HelpPage.dart';
import 'package:irs_app/resident/pages/profile/incidents/user_emergency_history_page.dart';
import 'package:irs_app/resident/pages/profile/incidents/user_emergency_review_page.dart';
import 'package:irs_app/resident/pages/profile/incidents/user_incident_history_page.dart';
import 'package:irs_app/resident/pages/profile/incidents/user_incident_review_page.dart';
import 'package:irs_app/resident/pages/tos_page.dart';
import 'package:irs_app/resident/password_expiration_page.dart';
import 'package:irs_app/tanod/pages/history/tanod_response_details_page.dart';
import 'package:irs_app/tanod/pages/history/tanod_response_history_page.dart';
import 'package:irs_app/tanod/pages/profile/tanod_change_email_page.dart';
import 'package:irs_app/tanod/pages/profile/tanod_change_phone_page.dart';
import 'package:irs_app/tanod/pages/profile/tanod_emergency_details_page.dart';
import 'package:irs_app/tanod/pages/profile/tanod_update_profile_page.dart';
import 'package:irs_app/resident/pages/home/witness_page.dart';
import 'package:irs_app/resident/pages/login_page.dart';
import 'package:irs_app/resident/pages/news/news_page.dart';
import 'package:irs_app/resident/pages/profile/complaint/complaint_page.dart';
import 'package:irs_app/resident/pages/profile/complaint/known_complaint_page.dart';
import 'package:irs_app/resident/pages/profile/complaint/unknown_complaint_page.dart';
import 'package:irs_app/resident/pages/profile/update_profile/change_email_page.dart';
import 'package:irs_app/resident/pages/profile/update_profile/change_password_page.dart';
import 'package:irs_app/resident/pages/profile/update_profile/change_phone_page.dart';
import 'package:irs_app/resident/pages/profile/update_profile/update_profile_page.dart';
import 'package:irs_app/resident/pages/profile/incidents/user_incidents_page.dart';
import 'package:irs_app/resident/pages/profile/update_profile/verify_change_page.dart';
import 'package:irs_app/resident/pages/reports/reports_page.dart';
import 'package:irs_app/resident/pages/signup_page.dart';
import 'package:irs_app/resident/pages/sos/ongoing_sos_page.dart';
import 'package:irs_app/resident/pages/sos/sos_page.dart';
import 'package:irs_app/resident/pages/verify_phone_page.dart';
import 'package:irs_app/resident/pages/profile/profile_page.dart';
import 'package:irs_app/tanod/pages/tanod_emergency_chatroom_page.dart';
import 'package:irs_app/tanod/pages/tanod_home_page.dart';
import 'package:irs_app/tanod/pages/tanod_incident_details_page.dart';
import 'package:irs_app/tanod/pages/tanod_profile_page.dart';
import 'package:irs_app/tanod/pages/tanod_respond_page.dart';

class AppRouter {
  AppRouter._();

  static String initR = "/home";

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _rootNavigatorHome =
      GlobalKey<NavigatorState>(debugLabel: "shellHome");
  static final _rootNavigatorNotifications =
      GlobalKey<NavigatorState>(debugLabel: "shellNotifications");
  static final _rootNavigatorSOS =
      GlobalKey<NavigatorState>(debugLabel: "shellSOS");
  static final _rootNavigatorNews =
      GlobalKey<NavigatorState>(debugLabel: "shellNews");
  static final _rootNavigatorProfile =
      GlobalKey<NavigatorState>(debugLabel: "shellProfile");

  static final _rootNavigatorTanodHome =
      GlobalKey<NavigatorState>(debugLabel: "shellTanodHome");

  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) async {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final currentUser = _auth.currentUser;

      if (currentUser == null &&
          state.uri.path != '/login' &&
          state.uri.path != '/signup' &&
          state.uri.path != '/signup/tos' &&
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
        routes: [
          GoRoute(path: 'tos', builder: (context, state) => TosPage(),)
        ]
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/password-expired',
        builder: (context, state) => PasswordExpirationPage(),
      ),
      GoRoute(
        path: '/mfa',
        builder: (context, state) => MfaPage(),
        routes: [
          GoRoute(
            path: 'phone/:id',
            builder: (context, state) => MfaPhonePage(
              id: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
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
            navigatorKey: _rootNavigatorTanodHome,
            routes: [
              GoRoute(
                path: '/tanod_home',
                name: "Tanod Home",
                builder: (context, state) => TanodHomePage(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => TanodProfilePage(),
                    routes: [
                      GoRoute(
                        path: 'update',
                        builder: (context, state) => TanodUpdateProfilePage(),
                        routes: [
                          GoRoute(
                            path: 'email/:email',
                            builder: (context, state) => TanodChangeEmailPage(
                                email: state.pathParameters['email']!),
                          ),
                          GoRoute(
                            path: 'phone',
                            builder: (context, state) => TanodChangePhonePage(),
                          ),
                          GoRoute(
                            path: 'change-auth/:type',
                            builder: (context, state) => VerifyChangePage(
                                type: state.pathParameters["type"]!),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'response-history',
                    builder: (context, state) => TanodResponseHistoryPage(),
                    routes: [
                      GoRoute(
                        path: 'details/:id/:type',
                        builder: (context, state) => TanodResponseDetailsPage(
                          id: state.pathParameters['id']!,
                          type: state.pathParameters['type']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'incident-details/:id',
                    name: "Tanod Incident Details",
                    builder: (context, state) => TanodIncidentDetailsPage(
                      id: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'incident-chatroom/:id',
                        builder: (context, state) => IncidentChatroomPage(
                          id: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path:
                            'respond/:incidentId/:latitude/:longitude', // Changed capture group name from 'id' to 'incidentId'
                        builder: (context, state) => TanodRespondPage(
                          id: state.pathParameters[
                              'incidentId']!, // Updated to use 'incidentId'
                          latitude:
                              double.parse(state.pathParameters['latitude']!)
                                  .toDouble(),
                          longitude:
                              double.parse(state.pathParameters['longitude']!)
                                  .toDouble(),
                          type: "incident",
                        ),
                        routes: [
                          GoRoute(
                            path: 'chatroom/:id',
                            builder: (context, state) => IncidentChatroomPage(
                              id: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: "emergency-details/:id",
                    builder: (context, state) => TanodEmergencyDetailsPage(
                      id: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'emergency-chatroom/:id',
                        builder: (context, state) => TanodEmergencyChatroomPage(
                          id: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path:
                            'respond/:emergencyId/:latitude/:longitude', // Changed capture group name from 'id' to 'incidentId'
                        builder: (context, state) => TanodRespondPage(
                          id: state.pathParameters[
                              'emergencyId']!, // Updated to use 'incidentId'
                          latitude:
                              double.parse(state.pathParameters['latitude']!)
                                  .toDouble(),
                          longitude:
                              double.parse(state.pathParameters['longitude']!)
                                  .toDouble(),
                          type: "emergency",
                        ),
                        routes: [
                          GoRoute(
                            path: 'chatroom/:id',
                            builder: (context, state) =>
                                TanodEmergencyChatroomPage(
                              id: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ],
        builder: (context, state, navigationShell) => Scaffold(
          body: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: navigationShell,
          ),
        ),
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
                    path: 'add-incident',
                    builder: (context, state) => AddIncidentPage(),
                  ),
                  GoRoute(
                    path: 'incident/:id',
                    builder: (context, state) => IncidentDetailsPage(
                        id: state.pathParameters['id'] ?? ''),
                    routes: [
                      GoRoute(
                        path: 'chatroom/:id',
                        builder: (context, state) => IncidentChatroomPage(
                            id: state.pathParameters['id'] ?? ''),
                      ),
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
            navigatorKey: _rootNavigatorNotifications,
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => NotificationPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        NotificationDetailPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorSOS,
            routes: [
              GoRoute(
                path: '/sos',
                builder: (context, state) => SosPage(),
                routes: [
                  GoRoute(
                    path: 'ongoing/:id',
                    builder: (context, state) => OngoingSosPage(
                      id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorNews,
            routes: [
              GoRoute(
                  path: '/news',
                  builder: (context, state) => NewsPage(),
                  routes: [
                    GoRoute(
                      path: 'details/:id',
                      builder: (context, state) => NewsDetailsPage(
                        id: state.pathParameters['id']!,
                      ),
                    ),
                  ]),
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
                  GoRoute(
                      path: 'incidents',
                      builder: (context, state) => UserIncidentsPage(),
                      routes: [
                        GoRoute(
                            path: ':id',
                            builder: (context, state) =>
                                UserIncidentHistoryPage(
                                  id: state.pathParameters['id']!,
                                ),
                            routes: [
                              GoRoute(
                                path: 'review/:id',
                                builder: (context, state) =>
                                    UserIncidentReviewPage(
                                  id: state.pathParameters['id']!,
                                ),
                              ),
                            ]),
                        GoRoute(
                            path: 'emergency/:id',
                            builder: (context, state) =>
                                UserEmergencyHistoryPage(
                                  id: state.pathParameters['id']!,
                                ),
                            routes: [
                              GoRoute(
                                path: 'review/:id',
                                builder: (context, state) =>
                                    UserEmergencyReviewPage(
                                        id: state.pathParameters['id']!),
                              )
                            ]),
                      ]),
                  GoRoute(
                    path: 'complaint',
                    builder: (context, state) => ComplaintPage(),
                    routes: [
                      GoRoute(
                        path: 'known',
                        builder: (context, state) => KnownComplaintPage(),
                      ),
                      GoRoute(
                        path: 'unknown',
                        builder: (context, state) => UnknownComplaintPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => HelpPage(),
                    routes: [
                      GoRoute(
                        path: 'details/:id',
                        builder: (context, state) =>
                            CaseDetailsPage(id: state.pathParameters['id']!),
                      ),
                    ],
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
