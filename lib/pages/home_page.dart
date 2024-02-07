import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Authenticated"),
            FilledButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();

                context.go('/login');
              },
              child: Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
