//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/screens/settings_screen.dart';
//import 'package:namer_app/screens/test_screen.dart';
import 'package:namer_app/screens/tab_screen.dart';
import 'package:namer_app/screens/notes_screen.dart';
import 'package:namer_app/screens/plans_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<String> plans = [];
  List<String> times = [];
  List<String> ids = [];

  String plan_to_show = '';
  String plan_time_to_show = '';

  bool switchvalue = true;
  bool isLoading = false;
  bool noTime = false;
  int nules = 0;

  final SupabaseClient supabase = Supabase.instance.client;

  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    fetchPlans();
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
      final response = await supabase.from('user_optional').select('id');
      setState(() {
        ids = List<String>.from(response.map((tab) => tab['id'] as String));
      });
    } catch (e) {
      print('Ошибка при загрузке списков: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке списков: $e')),
        );
      }
    }

    if (!(ids.contains(FirebaseAuth.instance.currentUser!.uid))) {
      try {
        await supabase.from('user_optional').insert([
          {
            'id': FirebaseAuth.instance.currentUser!.uid,
          }
        ]);
      } catch (e) {
        print('Ошибка при добавлении писка: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при добавлении списка: $e')),
          );
        }
      }
    }
    try {
      final response = await supabase
          .from('plans')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('date', DateTime.now().toLocal().toString().substring(0, 11));

      setState(() {
        plans = List<String>.from(response.map((tab) => tab['name'] as String));
      });

      final response2 = await supabase
          .from('plans')
          .select('time')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('date', DateTime.now().toLocal().toString().substring(0, 11));

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
      });

      for (int i = 0; i < plans.length; i++) {
        if (times[i] == ' ') {
          times_new.insert(times_new.length, times[i]);
          plans_new.insert(plans_new.length, plans[i]);
        } else if ((int.parse(times[i].substring(0, 2)) * 60 +
                int.parse(times[i].substring(
                  3,
                ))) >=
            (DateTime.now().hour * 60 + DateTime.now().minute)) {
          times_new.insert(times_new.length, times[i]);
          plans_new.insert(plans_new.length, plans[i]);
        }
      }
      setState(() {
        times = times_new;
        plans = plans_new;

        times_new = [];
        plans_new = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Diary App'),
          backgroundColor: const Color.fromARGB(110, 168, 195, 212),
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
                  )
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
                  )
                ]),
      drawer: Drawer(
        child: Center(
          child: Container(
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
              //padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    //padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color.fromARGB(110, 168, 195, 212)),
                    child: Image.asset(
                      'assets/images/bar_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                if (context.mounted) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => TabsPage(),
                                  ));
                                }
                              },
                              icon: Icon(Icons.format_list_numbered),
                              label: const Text('Мои Списки'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (context.mounted) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => NotesScreen(),
                                  ));
                                }
                              },
                              icon: Icon(Icons.event_note),
                              label: const Text('Заметки'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _closeDrawer,
                              icon: Icon(Icons.close),
                              label: const Text('Закрыть меню'),
                            )
                          ])),
                ],
              )),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 248, 149, 83),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.messenger_sharp),
            ),
            label: 'Messages',
          ),
        ],
      ),
      body: <Widget>[
        /// Home page
        Container(
          //shadowColor: Colors.transparent,
          //margin: const EdgeInsets.all(8.0),
          padding: EdgeInsets.all(10),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(160, 255, 255, 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Week',
                    CalendarFormat.twoWeeks: 'Month',
                    CalendarFormat.week: '2 weeks'
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PlansPage(Date: selectedDay),
                      ));
                    }
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
                child: IntrinsicWidth(
                    child: Row(
              children: [
                Expanded(
                  // Равномерно распределяет пространство
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(160, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        /*onTap: () {
                                              if (isSelectionMode) {
                                                toggleSelection(firstIndex);
                                              } else {
                                                _navigateToNoteContentPage(
                                                    notes[firstIndex]);
                                              }
                                            },
                                            onLongPress: () {
                                              setState(() {
                                                isSelectionMode = true;
                                                toggleSelection(firstIndex);
                                              });
                                            },*/
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [Colors.black, Colors.transparent],
                              stops: [0.7, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: ListTile(
                                //leading: Icon(Icons.alarm),
                                /* trailing: plans.length == 0 || plan_to_show == ' '
                        ? null
                        : Text(
                            'Планы на сегодня',
                            style: TextStyle(fontSize: 13),
                          ),*/
                                onTap: () {
                                  if (context.mounted) {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) =>
                                          PlansPage(Date: DateTime.now()),
                                    ));
                                  }
                                },
                                subtitle: times.length == 0
                                    ? null
                                    : times[0] == ' '
                                        ? null
                                        : Text(times[0]),
                                title: plans.length == 0
                                    ? SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text('Нет планов'))
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(plans[0]))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(160, 255, 255, 255),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('')),
                ),
              ],
            ))),
            SizedBox(height: 10),
            Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(160, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                    leading: Icon(Icons.alarm),
                    /* trailing: plans.length == 0 || plan_to_show == ' '
                        ? null
                        : Text(
                            'Планы на сегодня',
                            style: TextStyle(fontSize: 13),
                          ),*/
                    onTap: () {
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PlansPage(Date: DateTime.now()),
                        ));
                      }
                    },
                    subtitle: times.length == 0
                        ? null
                        : times[0] == ' '
                            ? null
                            : Text(times[0]),
                    title: plans.length == 0
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text('Нет планов на сегодня'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(plans[0])))),
          ]),
        ),
        Container(
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
          //shadowColor: Colors.transparent,
          //margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'Second',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ),

        /// Notifications page

        Container(
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
          //shadowColor: Colors.transparent,
          //margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'Third',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ][currentPageIndex],
    );
  }
}
