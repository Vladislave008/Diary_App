import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FirebaseService {
  static final FirebaseService _singleton = FirebaseService._internal();

  factory FirebaseService() => _singleton;

  FirebaseService._internal();

  final auth = FirebaseAuth.instance;

  void onListenUser(void Function(User?)? doListen) {
    auth.authStateChanges().listen(doListen);
  }

  Future<String> onLogin({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      print(credential);
      User? user = credential.user;

      if (user != null) {
        if (user.emailVerified) {
          print('login');
          return 'login';
        } else if (user.emailVerified == false) {
          if (context.mounted) {
            try {
              await user.delete();
              print("User account deleted successfully.");
            } on FirebaseAuthException catch (e) {
              print("Failed to delete user account: $e");
            }
            showSnackbar(context,
                'Аккаунт не подтверждён. Создайте его заново и подтвердите.');
            return 'invalid_data';
          }
        }
      }

      return 'invalid_data';
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        if (email.isEmpty || password.isEmpty) {
          print('Empty field');
          showSnackbar(
            context,
            'Заполните все данные для авторизации',
          );
        } else if (e.code == 'invalid-credential') {
          print('invalid-credential');
          showSnackbar(context, 'Неверные данные аккаунта. Попробуйте ещё раз');
        } else if (e.code == 'user-not-found') {
          print('Нет пользователя с такой почтой');
          showSnackbar(context, 'Нет пользователя с такой почтой');
        } else if (e.code == 'wrong-password') {
          print('Пароль введён некорректно');
          showSnackbar(context, 'Пароль введён некорректно');
        } else if (e.code == 'invalid-email') {
          print('Адрес почты введён некорректно');
          showSnackbar(context, 'Адрес почты введён некорректно');
        } else if (e.code == 'too-many-requests') {
          print('too-many-requests');
          showSnackbar(context, 'Слишком много попыток. Попробуйте позже');
        }
      }
      return 'invalid_data'; // Неудачный вход
    }
  }

  void showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
        content: Text(message),
        duration: Duration(seconds: 5),
        backgroundColor: const Color.fromARGB(255, 255, 102, 0));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> resetUserPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent!");
      if (context.mounted) {
        showSnackbar(context, 'Письмо для сброса пароля отправлено на $email');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        print(e.code);
        switch (e.code) {
          case 'invalid-credential':
            print('invalid-credential');
            showSnackbar(
                context, 'Неверные данные аккаунта. Попробуйте ещё раз');
          case 'user-not-found':
            print('Нет пользователя с такой почтой');
            showSnackbar(context, 'Нет пользователя с такой почтой');
          case 'wrong-password':
            print('Пароль введён некорректно');
            showSnackbar(context, 'Пароль введён некорректно');
          case 'invalid-email':
            print('Адрес почты введён некорректно');
            showSnackbar(context, 'Адрес почты введён некорректно');
          case 'too-many-requests':
            print('Слишком много попыток');
            showSnackbar(context, 'Слишком много попыток. Попробуйте позже');
          default:
            print('Произошла ошибка: ${e.message}');
            showSnackbar(context, 'Произошла ошибка. Попробуйте еще раз.');
        }
      }
    } catch (e) {
      // Обработка других возможных исключений
      if (context.mounted) {
        print('Произошла ошибка: $e');
        showSnackbar(context, 'Произошла ошибка. Попробуйте еще раз.');
      }
    }
  }

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

  Future<String> onRegister({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    // Если поля пустые, сразу возвращаем 'empty_field'
    if (email.isEmpty || password.isEmpty) {
      print('Empty field');
      showSnackbar(context, 'Заполните все данные для авторизации');
      return 'empty_field';
    }

    try {
      // Попытка создать нового пользователя
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Отправка подтверждения электронной почты
      if (context.mounted) {
        showDialog<String>(
          context: context,
          barrierDismissible:
              false, // пользователи не могут закрыть диалог, пока идет отсчет
          builder: (BuildContext context) {
            int countdown = 100; // Общее время ожидания в секундах

            // Создаем таймер только один раз при создании диалога
            Timer? timer;

            return StatefulBuilder(
              builder: (context, setState) {
                // Запуск таймера только при первом построении
                timer ??= Timer.periodic(Duration(seconds: 1), (timer) {
                  if (countdown > 0) {
                    countdown--;
                    setState(() {}); // Обновить состояние диалога
                  } else {
                    timer.cancel();
                    Navigator.pop(
                        context); // Закрыть диалог по истечении времени
                  }
                });

                return AlertDialog(
                  title: const Text('Подтвердите аккаунт'),
                  content: Text(
                      'На вашу почту отправлено письмо для подтверждения аккаунта.\nОжидание подтверждения: $countdown секунд'),
                );
              },
            );
          },
        );
      }

      await credential.user?.sendEmailVerification();

      // Периодическая проверка подтверждения email
      bool isVerified = false;

      for (int i = 0; i < 25; i++) {
        // Проверяем 5 раз
        await Future.delayed(Duration(seconds: 5)); // Ждем 5 секунд
        isVerified = await checkEmailVerification(credential.user!);
        if (isVerified) {
          break;
        } // Если подтвержден, выходим из цикла
      }

      if (isVerified) {
        return 'verified';
      } else {
        if (context.mounted) {
          showSnackbar(
              context, 'Вы не подтвердили аккаунт. Попробуйте ещё раз.');
        }

        return 'not_verified';
      }
    } on FirebaseAuthException catch (e) {
      // Обработка различных ошибок FirebaseAuth
      if (context.mounted) {
        if (e.code == 'invalid-email') {
          print('The email provided is incorrect.');
          showSnackbar(context, 'Неправильный формат ввода почтового адреса');
        } else if (e.code == 'weak-password') {
          print('The password provided is too weak.');
          showSnackbar(context, 'Слишком простой пароль');
        } else if (e.code == 'email-already-in-use') {
          print('This email is already in use');
          showSnackbar(
              context, 'Этот адрес электронной почты уже зарегистрирован');
        }
      }
      print(e);

      return 'invalid_data'; // Возвращаем 'invalid_data' в случае ошибки
    } catch (e) {
      print(
          "Unexpected error: $e"); // Вывод ошибки в случае непредвиденного сбоя

      return 'not_verified'; // Возвращаем 'not_verified' в случае ошибок
    }
  }

  Future<String> logOut({required BuildContext context}) async {
    try {
      await auth.signOut();
      print('Sign Out Completed');
      return "log_out"; // Возвращаем строку подтверждения
    } catch (e) {
      print('Error signing out: $e');
      return "error"; // Возвращаем строку ошибки, если что-то пошло не так
    }
  }
}
