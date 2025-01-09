import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
//import 'package:namer_app/widgets/auth_form.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({Key? key}) : super(key: key);

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  bool isLogin = false;
  final FirebaseService firebaseService = FirebaseService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void showSnackbar(message) {
    final snackBar = SnackBar(
        content: Text(message),
        duration: Duration(seconds: 5),
        backgroundColor: Theme.of(context).primaryColor);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Восстановление пароля'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    obscureText: false),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    String email = emailController.text.trim();
                    if (email.isEmpty) {
                      print('empty_field');
                      showSnackbar('Введите свой адрес электронной почты');
                    } else {
                      firebaseService.resetUserPassword(email);
                      showSnackbar('Сообщение отправлено вам на почту');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text('Отправить письмо'),
                ),
              ],
            ),
          )),
    );
  }
}
