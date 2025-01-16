import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/providers/provider.dart';
import 'package:provider/provider.dart';
import 'package:namer_app/screens/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int currentPageIndex = 0;
  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  final FirebaseService firebaseService = FirebaseService();
  @override
  Widget build(BuildContext context) {
    Future<void> logOut() async {
      String loginSuccess = await firebaseService.logOut(
          context:
              Provider.of<ContextProvider>(context, listen: false).context!);
      if (loginSuccess == 'log_out') {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => AuthScreen()),
            (Route<dynamic> route) => false, // Удаляем все предыдущие маршруты
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      drawer: Drawer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('This is the Drawer'),
              ElevatedButton(
                onPressed: _closeDrawer,
                child: const Text('Close Drawer'),
              ),
            ],
          ),
        ),
      ),
      body:

          /// Home page
          ElevatedButton(
        onPressed: logOut,
        child: const Text('Log Out'),
      ),

      /// Notifications page
    );
  }
}
