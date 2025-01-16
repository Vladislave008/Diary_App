import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
//import 'package:namer_app/widgets/auth_form.dart';
import 'package:namer_app/providers/provider.dart';
import 'package:provider/provider.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({Key? key}) : super(key: key);

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final TextEditingController emailController = TextEditingController();

  void showSnackbar(String message) {
    final snackBar = SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: const Color.fromARGB(255, 255, 102, 0));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
        title: const Text('Восстановление пароля'),
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 80, 185, 247),
                const Color.fromARGB(255, 219, 81, 247),
              ],
            ),
          ),
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(160, 255, 255, 255),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          icon: Icon(Icons.mail_outline_rounded)),
                      onChanged: (value) {
                        setState(() {});
                      },
                      obscureText: false,
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: emailController.text.isEmpty
                          ? null
                          : () {
                              String email = emailController.text.trim();

                              firebaseService.resetUserPassword(
                                email: email,
                                context: Provider.of<ContextProvider>(context,
                                        listen: false)
                                    .context!,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 102, 0),
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Отправить письмо'),
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
