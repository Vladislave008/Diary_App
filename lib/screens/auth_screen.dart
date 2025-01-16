import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/screens/reset_password_screen.dart';
import 'package:namer_app/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namer_app/widgets/auth_form.dart';
import 'package:namer_app/widgets/reg_form.dart';
import 'package:namer_app/providers/provider.dart';
import 'package:provider/provider.dart';

// test_of_git_push
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final FirebaseService firebaseService = FirebaseService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ContextProvider>(context, listen: false).setContext(context);

    //Size size = MediaQuery.of(context).size;
    //double height = size.height;
    //double width = size.width;

    void showSnackbar(BuildContext context, String message) {
      final snackBar = SnackBar(
          content: Text(message),
          duration: Duration(seconds: 5),
          backgroundColor: const Color.fromARGB(220, 255, 102, 0));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    void onAuth() async {
      String loginSuccess = await firebaseService.onLogin(
        context: Provider.of<ContextProvider>(context, listen: false).context!,
        email: emailController.text,
        password: passwordController.text,
      );
      if (loginSuccess == 'login') {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          if (context.mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => NavigationExample(),
            ));
          }
        }
      }
    }

    bool checkEmail(String email) {
      String allowedChars =
          "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#%&'*+/=?^_`@.{|}~-";
      bool isValid = true;
      for (int i = 0; i < email.length; i++) {
        if (!allowedChars.contains(email[i])) {
          isValid = false;
          break;
        }
      }
      if (!email.contains('@') ||
          email.indexOf('@') == 0 ||
          email.indexOf('@') == email.length - 1) {
        isValid = false;
      }
      return isValid;
    }

    void onReg() async {
      if (checkEmail(emailController.text)) {
        if (passwordController.text == passwordConfirmController.text) {
          print("Passwords match, attempting registration...");

          final localContext =
              Provider.of<ContextProvider>(context, listen: false).context!;

          String registrationSuccess = await firebaseService.onRegister(
            context: localContext,
            email: emailController.text,
            password: passwordController.text,
          );

          if (registrationSuccess == 'verified') {
            User? user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              if (context.mounted) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => NavigationExample(),
                ));
              }
            } else {
              print("User is null after registration.");
            }
          } else if (registrationSuccess == 'not_verified') {
            print("Registration failed. Deleting user account...");
            User? user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              try {
                await user.delete(); // Удаляем аккаунт пользователя
                print("User account deleted successfully.");
              } on FirebaseAuthException catch (e) {
                print("Failed to delete user account: $e");
              }
            } else {
              print("No user to delete.");
            }
          } else if (registrationSuccess == 'invalid_data') {
            print("Registration failed. Invalid data provided.");
          }
        } else {
          print("Passwords don't match");
          showSnackbar(context, 'Пароли не совпадают. Попробуйте ещё раз.');
        }
      } else {
        showSnackbar(context,
            'Некорректный формат почтового адреса. Попробуйте ещё раз.');
      }
    }

    final buttonText = isLogin ? 'Войти' : 'Создать аккаунт';

    String logRegButtonText =
        isLogin ? 'Ещё нет аккаунта? Создайте его' : 'Уже есть аккаунт? Войти';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(159, 207, 234, 250),
        title: Text(buttonText),
        //title: isLogin ? Text('Войти в аккаунт') : Text('Создать аккаунт'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Вопросы',
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Аутентификация пользователя'),
                content: const Text(
                    'При создании аккаунта лучше использовать реальные почтовые адреса, иначе будет утрачена возможность восстанавливать утерянные пароли'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'OK'),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 80, 185, 247),
                const Color.fromARGB(255, 219, 81, 247)
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: (isLogin
                        ? [
                            Container(
                              child: AuthForm(
                                authButtonText: buttonText,
                                onAuth: onAuth,
                                emailController: emailController,
                                passwordController: passwordController,
                              ),
                            ),
                            Container(
                                child: Column(children: [
                              TextButton(
                                child: Text(logRegButtonText),
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                  });
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        ResetScreen(), // Создание экземпляра ResetScreen
                                  ));
                                },
                                child: Text('Не помню пароль'),
                              ),
                            ])),
                          ]
                        : [
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                                child: RegForm(
                              authButtonText: buttonText,
                              onAuth: onReg,
                              emailController: emailController,
                              passwordController: passwordController,
                              passwordConfirmController:
                                  passwordConfirmController,
                            )),
                            Container(
                                child: Column(children: [
                              TextButton(
                                child: Text(logRegButtonText),
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                  });
                                },
                              ),
                            ])),
                          ]))),
          ))),
    );
  }
}
