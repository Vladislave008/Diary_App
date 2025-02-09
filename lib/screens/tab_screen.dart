import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namer_app/screens/tab_content_page.dart';

class TabsPage extends StatefulWidget {
  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  List<String> tabs = [];
  List<DateTime> tabs_dates = [];
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

  final TextEditingController _nameController = TextEditingController();
  Set<int> selectedIndices = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    fetchTabs();
  }

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> fetchTabs() async {
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      return;
    }
    try {
      final response = await supabase
          .from('tabs')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid);

      //print('Данные из базы: $response');
      setState(() {
        tabs = List<String>.from(response.map((tab) => tab['name'] as String));
      });
    } catch (e) {
      print('Ошибка при загрузке списков: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке списков: $e')),
        );
      }
    }

    try {
      final response = await supabase
          .from('tabs')
          .select('created_at')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid);

      //print('Данные из базы: $response');
      setState(() {
        tabs_dates = List<DateTime>.from(
          response.map((tab) {
            final createdAt = tab['created_at'];
            if (createdAt != null) {
              try {
                return DateTime.parse(createdAt as String);
              } catch (e) {
                print('Ошибка при преобразовании даты: $e');
                return DateTime
                    .now(); // Возвращаем текущую дату как значение по умолчанию
              }
            } else {
              return DateTime
                  .now(); // Возвращаем текущую дату как значение по умолчанию
            }
          }),
        );
      });
    } catch (e) {
      print('Ошибка при загрузке списков: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке списков: $e')),
        );
      }
    }
  }

  Future<void> addTab() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите название списка')),
      );
      return;
    }
    if (_nameController.text[0] == ' ') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Название списка не может быть пустым или начинаться с пробела')),
      );
      return;
    }
    if (tabs.contains(_nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Такая вкладка уже существует')),
      );
      return;
    }

    try {
      await supabase.from('tabs').insert([
        {
          'name': _nameController.text,
          'user_id': FirebaseAuth.instance.currentUser!.uid
        }
      ]);
      _nameController.clear();
      await fetchTabs();
    } catch (e) {
      print('Ошибка при добавлении списка: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении списка: $e')),
        );
      }
    }
  }

  Future<void> deleteTab(String tabName) async {
    print('delete tab ${tabName}');
    try {
      await supabase
          .from('tabs')
          .delete()
          .eq('name', tabName)
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid);

      await supabase
          .from('tabs_items')
          .delete()
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('parent_tab', tabName);

      await fetchTabs();
    } catch (e) {
      print('Ошибка при удалении таба: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении таба: $e')),
      );
    }
  }

  Future<void> deleteSelectedTabs() async {
    try {
      for (int index in selectedIndices) {
        await supabase
            .from('tabs')
            .delete()
            .eq('name', tabs[index])
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid);

        await supabase
            .from('tabs_items')
            .delete()
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('parent_tab', tabs[index]);
      }
      await fetchTabs();
      setState(() {
        selectedIndices.clear();
        isSelectionMode = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
        title: isSelectionMode
            ? Text('Выбрано: ${selectedIndices.length}')
            : Text('Мои Списки'),
        actions: [],
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
                      title: Text('Удалить выбранные списки'),
                      content: Text(
                          'Вы уверены, что хотите удалить все выбранные списки?'),
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
                            await deleteSelectedTabs(); // Удалить выбранные списки
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
            children: [
              //SizedBox(height: 10),

              Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(160, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название Списка',
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                        ),
                        color: Color.fromARGB(220, 36, 182, 0),
                        onPressed: _nameController.text.isEmpty ||
                                _nameController.text[0] == ' '
                            ? null
                            : addTab,
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
                    maxLength: 40,
                  )),
              SizedBox(height: 10),
              /*ElevatedButton(
            onPressed:
                _nameController.text.isEmpty || _nameController.text[0] == ' '
                    ? null
                    : addTab,
            child: Text('Добавить Список'),
          ),*/
              Expanded(
                child: ListView.builder(
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    if (tabs_dates.isEmpty || index >= tabs_dates.length) {
                      return SizedBox
                          .shrink(); // Возвращаем пустой виджет, если данных нет
                    }
                    String monthIndexStr =
                        tabs_dates[index].toLocal().toString().substring(5, 7);
                    String date =
                        tabs_dates[index].toLocal().toString().substring(8, 10);
                    if (date[0] == '0') {
                      date = date.substring(1, 2);
                    }
                    String year =
                        tabs_dates[index].toLocal().toString().substring(0, 4);
                    int monthIndex = int.parse(monthIndexStr) - 1;
                    String monthName = months[monthIndex];
                    return Container(
                      decoration: BoxDecoration(
                        color:
                            selectedIndices.contains(index) && isSelectionMode
                                ? Color.fromARGB(255, 245, 163, 163)
                                : Color.fromARGB(160, 255, 255, 255),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      margin: const EdgeInsets.only(bottom: 10.0),
                      child: ListTile(
                        title: Text(
                          tabs[index],
                          //style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Создано $date $monthName $year'),
                        onTap: () {
                          if (isSelectionMode) {
                            toggleSelection(index);
                          } else {
                            if (context.mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    TabContentPage(tabName: tabs[index]),
                              ));
                            }
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            isSelectionMode = true;
                            toggleSelection(index);
                          });
                        },
                        trailing: isSelectionMode
                            ? Checkbox(
                                activeColor:
                                    const Color.fromARGB(255, 236, 37, 23),
                                value: selectedIndices.contains(index),
                                onChanged: (value) {
                                  toggleSelection(index);
                                },
                              )
                            : IconButton(
                                icon: Icon(Icons.delete_outline_outlined),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Удалить Список'),
                                        content: Text(
                                            'Вы уверены, что хотите удалить список ${tabs[index]}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Закрыть диалог
                                            },
                                            child: Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context)
                                                  .pop(); // Закрыть диалог
                                              await deleteTab(
                                                  tabs[index]); // Удалить таб
                                            },
                                            child: Text(
                                              'Удалить',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
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
    _nameController.dispose();
    super.dispose();
  }
}
