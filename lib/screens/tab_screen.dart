import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tab_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namer_app/screens/tab_content_page.dart';

class TabsPage extends StatefulWidget {
  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  List<MyTab> tabs = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTabs();
  }

  Future<void> fetchTabs() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    final response = await http
        .get(Uri.parse('http://172.25.0.7:8000/tabs?owner_id=${user.uid}'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      setState(() {
        tabs = jsonResponse.map((tab) => MyTab.fromJson(tab)).toList();
      });
    } else {
      throw Exception('Failed to load tabs');
    }
  }

  Future<void> addTab() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    // Получаем текст имени таба
    String tabName = _nameController.text.trim();

    // Проверяем на пустое имя
    if (tabName.isEmpty) {
      // Отображаем сообщение об ошибке
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ошибка'),
            content: Text('Имя таба не может быть пустым.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрыть диалог
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Проверяем на существующее имя таба
    bool tabExists = tabs.any((tab) => tab.name == tabName);
    if (tabExists) {
      // Отображаем сообщение об ошибке
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ошибка'),
            content: Text('Таб с таким именем уже существует.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрыть диалог
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Если все проверки пройдены, выполняем запрос на добавление таба
    final response = await http.post(
      Uri.parse('http://172.25.0.7:8000/tabs/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': tabName,
        'owner_id': user.uid,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      fetchTabs();
      _nameController.clear();
    } else {
      throw Exception('Failed to add tab');
    }
  }

  Future<void> deleteTab(String tabName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    final response = await http.delete(
      Uri.parse('http://172.25.0.7:8000/tabs/${tabName}?owner_id=${user.uid}'),
    );

    if (response.statusCode == 204) {
      fetchTabs();
    } else {
      throw Exception('Failed to delete tab');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Tab Name'),
            ),
          ),
          ElevatedButton(
            onPressed: addTab,
            child: Text('Add Tab'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(tabs[index].name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TabContentPage(tabName: tabs[index].name),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Функция для удаления таба
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Tab'),
                            content: Text(
                                'Are you sure you want to delete this tab?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Закрыть диалог
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  deleteTab(tabs[index].name); // Удалить таб
                                  Navigator.of(context).pop(); // Закрыть диалог
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
