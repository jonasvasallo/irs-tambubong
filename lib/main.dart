import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:irs_capstone/app_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/resident/pages/home/home_page.dart';
import 'package:irs_capstone/resident/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:irs_capstone/firebase_options.dart';
import 'package:irs_capstone/core/utilities.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: Utilities.messengerKey,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      title: 'Tambubong IRS',
      theme: ThemeData(
        colorScheme: ColorScheme.light(primary: accentColor),
        useMaterial3: true,
        buttonTheme: ButtonThemeData(
          buttonColor: accentColor,
        ),
        primaryColorLight: accentColor,
        primaryColor: accentColor,
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: majorText,
          ),
        ),
      ),

      // home: StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, snapshot) {
      //     if (snapshot.hasData) {
      //       return HomePage();
      //     } else {
      //       return LoginPage();
      //     }
      //   },
      // ),
    );
  }
}
