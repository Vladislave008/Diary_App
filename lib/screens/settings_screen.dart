import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/providers/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:namer_app/screens/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  int currentPageIndex = 0;

  int _current_notify_time_Value = 30;
  bool _switchOldPlansValue = false;
  bool isLoading = false;
  final SupabaseClient supabase = Supabase.instance.client;

  final FirebaseService firebaseService = FirebaseService();

  Future<void> fetchItems() async {
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      setState(() {});
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final response =
          await supabase.from('user_optional').select('plans_notify_time');
      setState(() {
        _current_notify_time_Value = int.parse(List<String>.from(
            response.map((tab) => tab['plans_notify_time'] as String))[0]);
      });
      final response1 =
          await supabase.from('user_optional').select('show_old_plans');
      setState(() {
        _switchOldPlansValue = List<bool>.from(
            response1.map((tab) => tab['show_old_plans'] as bool))[0];
      });
    } catch (e) {
      print('Ошибка $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка $e')),
        );
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> setNotifyTime(String time) async {
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      setState(() {});
      return;
    }

    try {
      await supabase
          .from('user_optional')
          .update({'plans_notify_time': time}).eq(
              'id', FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      print('Ошибка $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка $e')),
        );
      }
    }
    fetchItems();
  }

  Future<void> setOldPlans(bool value) async {
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      setState(() {});
      return;
    }

    try {
      await supabase.from('user_optional').update({'show_old_plans': value}).eq(
          'id', FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      print('Ошибка $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка $e')),
        );
      }
    }
    fetchItems();
  }

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
      appBar: AppBar(
        actions: isLoading
            ? [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  //color: const Color.fromARGB(255, 255, 115, 0),
                ),
              ]
            : [],
        title: const Text('Настройки'),
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
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
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          child: Center(
              child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(160, 255, 255, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: SwitchListTile(
                        title: Text('Показывать прошедшие планы'),
                        //subtitle: Text('Показывать/скрывать'),
                        value: _switchOldPlansValue,
                        onChanged: (bool value) {
                          setState(() {
                            setOldPlans(value);
                            _switchOldPlansValue = value;
                          });
                        },
                        secondary: Icon(Icons.history_rounded),
                      )),
                  SizedBox(height: 10),
                  Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(160, 255, 255, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Column(children: [
                        Text('Выделять ближайшие планы в течение:'),
                        SizedBox(height: 10),
                        SegmentedButton<int>(
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            textStyle:
                                WidgetStateProperty.resolveWith<TextStyle>(
                              (Set<WidgetState> states) {
                                return TextStyle(
                                  fontSize: 13, // Размер текста
                                );
                              },
                            ),
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.white60;
                                }
                                return Colors.transparent;
                              },
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                          ),
                          segments: [
                            ButtonSegment(value: 15, label: Text("15 мин")),
                            ButtonSegment(value: 30, label: Text("30 мин")),
                            ButtonSegment(value: 60, label: Text("1 ч")),
                            ButtonSegment(value: 120, label: Text("2 ч")),
                            ButtonSegment(value: -1, label: Text("Нет")),
                          ],
                          selected: {_current_notify_time_Value},
                          onSelectionChanged: (Set<int> newSelection) {
                            setState(() => _current_notify_time_Value =
                                newSelection.first);
                            setNotifyTime(
                                _current_notify_time_Value.toString());
                          },
                        )
                      ])),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(160, 255, 255, 255),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red, // Задаем цвет текста
                            ),
                            //onPressed: logOut,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Выйти из аккаунта'),
                                    content: Text(
                                        'Вы уверены, что хотите выйти из аккаунта?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Отмена'),
                                      ),
                                      TextButton(
                                        onPressed: logOut,
                                        child: Text(
                                          'Выйти',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text('Выйти'),
                          )
                        ]),
                  ),
                ]),
          ))),
    );
  }
}
