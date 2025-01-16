//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/screens/auth_screen.dart';
import 'package:namer_app/screens/home_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:namer_app/providers/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ContextProvider(), // Создаем экземпляр вашего провайдера
      child: const MyApp(), // Оборачиваем ваше приложение в провайдер
    ),
  );
}

final GlobalKey<NavigatorState> kNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FirebaseService().onListenUser((user) {
      if (user == null) {
        Navigator.push(kNavigatorKey.currentContext!,
            MaterialPageRoute(builder: (_) => AuthScreen()));
      } else if (user.emailVerified) {
        Navigator.push(kNavigatorKey.currentContext!,
            MaterialPageRoute(builder: (_) => NavigationExample()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: kNavigatorKey,
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.red
          /*colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: Colors.amber, // Можно задать дополнительные цвета
        ),*/
          ),
      home: AuthScreen(),
    );
  }
}
