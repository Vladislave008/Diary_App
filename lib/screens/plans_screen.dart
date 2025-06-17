import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:namer_app/screens/home_screen.dart';
import 'package:namer_app/screens/settings_screen.dart';

class PlansPage extends StatefulWidget {
  final DateTime Date;

  PlansPage({required this.Date});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<String> plans = [];
  List<String> times = [];
  List<String> old_plans = [];
  List<String> old_times = [];
  bool switchvalue = true;
  bool isLoading = false;
  bool noTime = false;
  bool _showOldPlans = false;
  int time_to_highlite = 30;

  final TextEditingController _newnameController = TextEditingController();
  DateTime _time = DateTime.now();

  List<String> months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  String title = '';
  String date_cur = '';
  Set<int> selectedIndices = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    print(DateTime.now());
    print(widget.Date);
    date_cur = widget.Date.toLocal().toString().substring(0, 11);
    String monthIndexStr = widget.Date.toLocal().toString().substring(5, 7);
    String date = widget.Date.toLocal().toString().substring(8, 11);
    if (date[0] == '0') {
      date = date.substring(1, 2);
    }
    String year = widget.Date.toLocal().toString().substring(0, 4);
    int monthIndex = int.parse(monthIndexStr) - 1;
    String monthName = months[monthIndex];

    title = '$date$monthName $year';

    super.initState();
    fetchPlans();
  }

  final SupabaseClient supabase = Supabase.instance.client;

  void sortLists() {
    if (plans.length != 0) {
      List<String> plans_new = [plans[0]];
      List<String> times_new = [times[0]];

      for (int i = 1; i < times.length; i++) {
        if (times[i] == ' ') {
          times_new.insert(times_new.length, times[i]);
          plans_new.insert(plans_new.length, plans[i]);
        } else {
          int flag = 0;
          for (int j = 0; j < times_new.length; j++) {
            if (times_new[j] == ' ' && flag == 0) {
              times_new.insert(j, times[i]);
              plans_new.insert(j, plans[i]);
              flag = 1;
            }

            if (times_new[j] != ' ' && flag == 0) {
              int time_cur = int.parse(times[i].substring(0, 2)) * 60 +
                  int.parse(times[i].substring(
                    3,
                  ));
              int time_to_compare =
                  int.parse(times_new[j].substring(0, 2)) * 60 +
                      int.parse(times_new[j].substring(
                        3,
                      ));

              if (time_cur < time_to_compare) {
                times_new.insert(j, times[i]);
                plans_new.insert(j, plans[i]);
                flag = 1;
              }
            }
          }

          if (flag == 0) {
            times_new.insert(times_new.length, times[i]);
            plans_new.insert(plans_new.length, plans[i]);
            flag = 1;
          }
        }
      }
      setState(() {
        times = times_new;
        plans = plans_new;
        times_new = [];
        plans_new = [];
        old_plans = [];
        old_times = [];
      });

      int month = int.parse(widget.Date.toLocal().toString().substring(5, 7));
      int day = int.parse(widget.Date.toLocal().toString().substring(8, 10));
      int year = int.parse(widget.Date.toLocal().toString().substring(0, 4));
      int year_cur = DateTime.now().year;
      int month_cur = DateTime.now().month;
      int day_cur = DateTime.now().day;

      for (int i = 0; i < plans.length; i++) {
        if ((year > year_cur) ||
            (year == year_cur && month > month_cur) ||
            (year == year_cur && month == month_cur && day > day_cur)) {
          times_new.insert(times_new.length, times[i]);
          plans_new.insert(plans_new.length, plans[i]);
        } else if (((year < year_cur) ||
                (year == year_cur && month < month_cur) ||
                (year == year_cur && month == month_cur && day < day_cur)) &&
            (times[i] != ' ' || plans[i] != ' ')) {
        } else if (times[i] == ' ') {
          times_new.insert(times_new.length, times[i]);
          plans_new.insert(plans_new.length, plans[i]);
        } else if ((int.parse(times[i].substring(0, 2)) * 60 +
                int.parse(times[i].substring(
                  3,
                ))) >=
            (DateTime.now().hour * 60 + DateTime.now().minute)) {
          times_new.insert(times_new.length, times[i]);
          plans_new.insert(plans_new.length, plans[i]);
        } else {
          old_times.insert(times_new.length, times[i]);
          old_plans.insert(plans_new.length, plans[i]);
        }
      }

      setState(() {
        if (_showOldPlans) {
          times = old_times + times_new;
          plans = old_plans + plans_new;
          times_new = [];
          plans_new = [];
        } else {
          times = times_new;
          plans = plans_new;

          times_new = [];
          plans_new = [];
          old_plans = [];
          old_times = [];
        }
      });
    }
  }

  Future<void> fetchPlans() async {
    setState(() {
      isLoading = true;
    });
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response =
          await supabase.from('user_optional').select('plans_notify_time');
      setState(() {
        time_to_highlite = int.parse(List<String>.from(
            response.map((tab) => tab['plans_notify_time'] as String))[0]);
      });
      final response1 =
          await supabase.from('user_optional').select('show_old_plans');
      setState(() {
        _showOldPlans = List<bool>.from(
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

    try {
      final response = await supabase
          .from('plans')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('date', widget.Date.toLocal().toString().substring(0, 11));

      setState(() {
        plans = List<String>.from(response.map((tab) => tab['name'] as String));
      });

      final response2 = await supabase
          .from('plans')
          .select('time')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('date', widget.Date.toLocal().toString().substring(0, 11));

      setState(() {
        times =
            List<String>.from(response2.map((tab) => tab['time'] as String));
      });
    } catch (e) {
      print('Ошибка при загрузке списков: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке списков: $e')),
        );
      }
    }
    sortLists();
    setState(() {
      isLoading = false;
    });
    print(plans);
    print(times);
  }

  Future<void> addPlan() async {
    if (plans.contains(' ')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Уже существует пустой план')),
        );
      }
      print('Уже существует пустой план');
      return;
    }
    try {
      await supabase.from('plans').insert([
        {
          'name': ' ',
          'user_id': FirebaseAuth.instance.currentUser!.uid,
          'date': widget.Date.toLocal().toString().substring(0, 11)
        }
      ]);

      await fetchPlans();
    } catch (e) {
      print('Ошибка при добавлении списка: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении списка: $e')),
        );
      }
    }
  }

  Future<void> updatePlan(String tabName) async {
    if (_newnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите название списка')),
      );
      return;
    }
    if (_newnameController.text[0] == ' ') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Название списка не может быть пустым или начинаться с пробела')),
      );
      return;
    }
    if (plans.contains(_newnameController.text) &&
        _newnameController.text != tabName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Такая вкладка уже существует')),
      );
      return;
    }

    try {
      if (noTime) {
        await supabase
            .from('plans')
            .update({'name': _newnameController.text, 'time': ' '})
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('name', tabName)
            .eq('date', widget.Date.toLocal().toString().substring(0, 11));
      } else if (noTime == false) {
        await supabase
            .from('plans')
            .update(
                {'name': _newnameController.text, 'time': formatTime(_time)})
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('name', tabName)
            .eq('date', widget.Date.toLocal().toString().substring(0, 11));
      }

      _newnameController.clear();
      await fetchPlans();
      print('Tabupdated successfully');
    } catch (e) {
      print('Error updating tab: $e');
    }
  }

  Future<void> deletePlan(String tabName) async {
    print('delete tab $tabName');
    try {
      await supabase
          .from('plans')
          .delete()
          .eq('name', tabName)
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('date', widget.Date.toLocal().toString().substring(0, 11));

      await fetchPlans();
    } catch (e) {
      print('Ошибка при удалении таба: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении таба: $e')),
      );
    }
  }

  Future<void> deleteSelectedPlans() async {
    setState(() {
      isSelectionMode = false;
    });
    try {
      for (int index in selectedIndices) {
        await supabase
            .from('plans')
            .delete()
            .eq('name', plans[index])
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('date', widget.Date.toLocal().toString().substring(0, 11));
      }

      setState(() {
        selectedIndices.clear();
        isSelectionMode = false;
      });
      await fetchPlans();
    } catch (e) {
      print('Ошибка при удалении табов: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении табов: $e')),
      );
    }
  }

  void toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
      if (selectedIndices.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  bool checkHighlight(String time) {
    if (date_cur == DateTime.now().toLocal().toString().substring(0, 11)) {
      if (time != ' ') {
        if ((int.parse(time.substring(0, 2)) * 60 +
                        int.parse(time.substring(
                          3,
                        ))) -
                    (DateTime.now().hour * 60 + DateTime.now().minute) <=
                time_to_highlite &&
            (int.parse(time.substring(0, 2)) * 60 +
                        int.parse(time.substring(
                          3,
                        ))) -
                    (DateTime.now().hour * 60 + DateTime.now().minute) >
                0) {
          return true;
        }
      }
    }
    return false;
  }

  String formatTime(DateTime time) {
    String hours = time.hour.toString().padLeft(2, '0');
    String minutes = time.minute.toString().padLeft(2, '0');
    return "$hours:$minutes";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NavigationExample(),
              ));
            }
          },
        ),
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
        title: isSelectionMode
            ? Text('Выбрано: ${selectedIndices.length}')
            : Text(title),
        actions: isLoading
            ? [
                CircularProgressIndicator(
                  strokeWidth: 3,

                  //color: const Color.fromARGB(255, 255, 115, 0),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SettingsScreen(),
                      ));
                    }
                  },
                ),
                IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => NavigationExample(),
                        ));
                      }
                    },
                    icon: Icon(Icons.home_rounded)),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SettingsScreen(),
                      ));
                    }
                  },
                ),
                IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => NavigationExample(),
                        ));
                      }
                    },
                    icon: Icon(Icons.home_rounded))
              ],
      ),
      floatingActionButton: isSelectionMode
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 245, 46, 46),
              foregroundColor: Colors.white,
              child: Icon(Icons.delete_outline_outlined),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Удалить выбранные планы'),
                      content: Text(
                          'Вы уверены, что хотите удалить все выбранные планы?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Закрыть диалог
                          },
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Закрыть диалог
                            await deleteSelectedPlans(); // Удалить выбранные списки
                          },
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            )
          : null,
      body: Container(
          padding: const EdgeInsets.all(10.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //SizedBox(height: 10),

              Container(
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Color.fromARGB(160, 255, 255, 255),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  //color: Color.fromARGB(255, 212, 94, 15),
                  onPressed: addPlan,
                ),
              ),
              SizedBox(height: 10),
              /*ElevatedButton(
            onPressed:
                _nameController.text.isEmpty || _nameController.text[0] == ' '
                    ? null
                    : addPlan,
            child: Text('Добавить план'),
          ),*/
              Expanded(
                child: ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    if (plans.isEmpty ||
                        index >= plans.length ||
                        times.isEmpty ||
                        index >= times.length) {
                      isLoading = false;

                      return SizedBox
                          .shrink(); // Возвращаем пустой виджет, если данных нет
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color:
                            selectedIndices.contains(index) && isSelectionMode
                                ? Color.fromARGB(255, 245, 163, 163)
                                : checkHighlight(times[index])
                                    ? Color.fromARGB(200, 250, 207, 188)
                                    : Color.fromARGB(160, 255, 255, 255),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      margin: const EdgeInsets.only(bottom: 10.0),
                      child: ListTile(
                          minVerticalPadding: 5,
                          title: Text(
                            plans[index],
                          ),
                          subtitle: times[index] == ' '
                              ? null
                              : (old_plans.contains(plans[index]))
                                  ? IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .stretch, // Растягиваем по высоте
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(times[index]),
                                          ),
                                          SizedBox(
                                            width: 7,
                                          ),
                                          Container(
                                            padding: EdgeInsets.only(
                                                right: 5, left: 5),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Color.fromARGB(
                                                    97, 255, 255, 255)),
                                            child: Text('время прошло'),
                                          )
                                        ],
                                      ),
                                    )
                                  : checkHighlight(times[index])
                                      ? IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .stretch, // Растягиваем по высоте
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(times[index]),
                                              ),
                                              SizedBox(
                                                width: 7,
                                              ),
                                              Container(
                                                padding: EdgeInsets.only(
                                                    right: 5, left: 5),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: Color.fromARGB(
                                                        97, 255, 255, 255)),
                                                child: Text('скоро'),
                                              )
                                            ],
                                          ),
                                        )
                                      : Text(times[index]),
                          onTap: () {
                            if (times[index] == ' ') {
                              setState(() {
                                switchvalue = false;
                                noTime = true;
                                _time = DateTime.now();
                              });
                            } else if (times[index] != ' ') {
                              setState(() {
                                String t = times[index];
                                switchvalue = true;
                                noTime = false;
                                _time = DateTime.parse("2023-10-05T$t:00.123Z");
                              });
                            }
                            if (isSelectionMode) {
                              toggleSelection(index);
                            } else {
                              setState(() {
                                if (plans[index] == ' ') {
                                  _newnameController.clear();
                                } else {
                                  _newnameController.text = plans[index];
                                }
                              });
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return AlertDialog(
                                        title: Text('Обновить план'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: _newnameController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Новое название плана',
                                                ),
                                                onChanged: (text) {
                                                  setState(() {});
                                                },
                                                maxLength: 60,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TimePickerSpinner(
                                                    spacing: 0,
                                                    itemHeight: 40,
                                                    normalTextStyle:
                                                        const TextStyle(
                                                      fontSize: 25,
                                                      color: Colors.grey,
                                                    ),
                                                    highlightedTextStyle:
                                                        TextStyle(
                                                      fontSize: 25,
                                                      color: noTime
                                                          ? Colors.grey
                                                          : Colors.black,
                                                    ),
                                                    time: _time,
                                                    onTimeChange: (time) {
                                                      setState(() {
                                                        _time =
                                                            time; // Форматируем время
                                                      });
                                                    },
                                                  ),
                                                  // Switch
                                                  Switch(
                                                    value: switchvalue,
                                                    onChanged: (bool value) {
                                                      setState(() {
                                                        switchvalue = value;
                                                        noTime = !value;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              setState(() {
                                                _newnameController.clear();
                                              });
                                            },
                                            child: Text(
                                              'Отмена',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await updatePlan(plans[index]);
                                              setState(() {
                                                _newnameController.clear();
                                              });
                                            },
                                            child: Text('Готово'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              isSelectionMode = true;
                              toggleSelection(index);
                            });
                          },
                          trailing: isSelectionMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                      Checkbox(
                                        activeColor: const Color.fromARGB(
                                            255, 236, 37, 23),
                                        value: selectedIndices.contains(index),
                                        onChanged: (value) {
                                          toggleSelection(index);
                                        },
                                      )
                                    ])
                              : checkHighlight(times[index])
                                  ? Icon(Icons.query_builder_rounded,
                                      color: const Color.fromARGB(
                                          255, 226, 69, 58))
                                  : null),
                    );
                  },
                ),
              ),
            ],
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
