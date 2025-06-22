import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namer_app/screens/home_screen.dart';

class ConfirmLetterScreen extends StatefulWidget {
  @override
  State<ConfirmLetterScreen> createState() => _ComfirmLetterScreenState();
}

class _ComfirmLetterScreenState extends State<ConfirmLetterScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final auth = FirebaseAuth.instance;
  int countdown = 60;
  bool countdown_going = false;
  bool done = false;
  Future<bool> checkEmailVerification(User user) async {
    // Обновляем состояние пользователя
    await user.reload();

    // Получаем обновленного пользователя
    User? updatedUser = FirebaseAuth.instance.currentUser;

    // Проверяем, подтвержден ли email
    if (updatedUser != null && updatedUser.emailVerified) {
      print("Email is verified.");
      return true; // Возвращаем true, если email подтвержден
    } else {
      print("Email is not verified yet.");

      return false; // Возвращаем false, если email не подтвержден
    }
  }

  Future<void> sendConfirmLetter(
      {required BuildContext context,
      required String email,
      required String password}) async {
    if (email.isEmpty || email.isEmpty) {
      print('Empty field');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Введите данные аккаунта')),
        );
      }
    }
    User? updatedUser = FirebaseAuth.instance.currentUser;
    if (updatedUser != null && updatedUser.emailVerified) {
      print("Email is verified.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Этот аккаунт уже подтвержден')),
        );
      }
    } else if (updatedUser != null && !updatedUser.emailVerified) {
      try {
        final credential = await auth.signInWithEmailAndPassword(
            email: email, password: password);
        print(credential);

        await credential.user?.sendEmailVerification();
        bool isVerified = false;
        setState(() {
          countdown_going = true;
        });
        for (int i = 0; i < 60; i++) {
          await Future.delayed(Duration(seconds: 1));
          setState(() {
            countdown--;
          });

          isVerified = await checkEmailVerification(credential.user!);
          if (isVerified) {
            setState(() {
              countdown_going = false;
              done = true;
            });
            if (context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NavigationExample(),
              ));
            }
            break;
          }
        }

        if (!isVerified) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Вы не подтвердили аккаунт. Попробуйте ещё раз.')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        print(e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Неверные данные аккаунта')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
        title: const Text('Подтверждение аккаунта'),
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
                  children: countdown_going
                      ? [
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
                          TextFormField(
                            onChanged: (value) {
                              setState(() {});
                            },
                            controller: passwordController,
                            decoration: InputDecoration(
                              icon: Icon(Icons.lock_outline_rounded),
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible =
                                        !_isPasswordVisible; // Меняем видимость пароля
                                  });
                                },
                              ),
                            ),
                            obscureText:
                                !_isPasswordVisible, // Устанавливаем видимость пароля
                          ),
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: emailController.text.isEmpty ||
                                    passwordController.text.isEmpty
                                ? null
                                : () {
                                    String email = emailController.text.trim();
                                    String password =
                                        passwordController.text.trim();
                                    sendConfirmLetter(
                                        context: context,
                                        email: email,
                                        password: password);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 102, 0),
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: const Text('Отправить письмо'),
                          ),
                          Text(
                              'Письмо отправлено на вашу почту. Ожидание подтверждения: $countdown секунд')
                        ]
                      : done
                          ? [
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
                              TextFormField(
                                onChanged: (value) {
                                  setState(() {});
                                },
                                controller: passwordController,
                                decoration: InputDecoration(
                                  icon: Icon(Icons.lock_outline_rounded),
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible; // Меняем видимость пароля
                                      });
                                    },
                                  ),
                                ),
                                obscureText:
                                    !_isPasswordVisible, // Устанавливаем видимость пароля
                              ),
                              const SizedBox(height: 20.0),
                              ElevatedButton(
                                onPressed: emailController.text.isEmpty ||
                                        passwordController.text.isEmpty
                                    ? null
                                    : () {
                                        String email =
                                            emailController.text.trim();
                                        String password =
                                            passwordController.text.trim();
                                        sendConfirmLetter(
                                            context: context,
                                            email: email,
                                            password: password);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 102, 0),
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                child: const Text('Отправить письмо'),
                              ),
                              Text('Подтверждение получено, подождите..')
                            ]
                          : [
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
                              TextFormField(
                                onChanged: (value) {
                                  setState(() {});
                                },
                                controller: passwordController,
                                decoration: InputDecoration(
                                  icon: Icon(Icons.lock_outline_rounded),
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible; // Меняем видимость пароля
                                      });
                                    },
                                  ),
                                ),
                                obscureText:
                                    !_isPasswordVisible, // Устанавливаем видимость пароля
                              ),
                              const SizedBox(height: 20.0),
                              ElevatedButton(
                                onPressed: emailController.text.isEmpty ||
                                        passwordController.text.isEmpty
                                    ? null
                                    : () {
                                        String email =
                                            emailController.text.trim();
                                        String password =
                                            passwordController.text.trim();
                                        sendConfirmLetter(
                                            context: context,
                                            email: email,
                                            password: password);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 102, 0),
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
