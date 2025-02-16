//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/screens/settings_screen.dart';
//import 'package:namer_app/screens/test_screen.dart';
import 'package:namer_app/screens/tab_screen.dart';
import 'package:namer_app/screens/notes_screen.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  void _closeDrawer() {
    Navigator.of(context).pop();
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
                              icon: Icon(Icons.format_list_numbered),
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
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'First',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
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
