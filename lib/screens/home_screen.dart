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

    int mini_hour = 1000;
    int mini_minute = 1000;
    nules = 0;

    for (int i = 0; i < plans.length; i++) {
      if (times[i] == ' ' || plans[i] == ' ') {
        nules++;
      } else if (int.parse(times[i].substring(0, 2)) < DateTime.now().hour ||
          (int.parse(times[i].substring(0, 2)) == DateTime.now().hour &&
              int.parse(times[i].substring(
                    3,
                  )) <
                  DateTime.now().minute)) {
        nules++;
      } else if (int.parse(times[i].substring(0, 2)) < mini_hour ||
          (int.parse(times[i].substring(0, 2)) == mini_hour &&
              int.parse(times[i].substring(
                    3,
                  )) <
                  mini_minute)) {
        mini_hour = int.parse(times[i].substring(0, 2));
        mini_minute = int.parse(times[i].substring(
          3,
        ));
        plan_time_to_show = times[i];
        plan_to_show = plans[i];
      }
      ;
    }
    print(nules);

    if (nules == plans.length && plans.length != 0) {
      plan_time_to_show = times[0];
      plan_to_show = plans[0];
      /*
      if (plan_to_show.length > 22) {
        plan_to_show = plan_to_show.substring(0, 20) + '...';
      }*/
    }

    setState(() {
      isLoading = false;
    });
    print(plans);
    print(times);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Diary App'),
          backgroundColor: const Color.fromARGB(110, 168, 195, 212),
          actions: <Widget>[
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(160, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                    leading: Icon(Icons.alarm),
                    trailing: plans.length == 0 || plan_to_show == ' '
                        ? null
                        : Text(
                            'Планы на сегодня',
                            style: TextStyle(fontSize: 13),
                          ),
                    onTap: () {
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PlansPage(Date: DateTime.now()),
                        ));
                      }
                    },
                    subtitle: plans.length == 0 || plan_to_show == ' '
                        ? null
                        : Text(plan_time_to_show),
                    title: plans.length == 0 || plan_to_show == ' '
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text('Нет планов на сегодня'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(plan_to_show)))),
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
