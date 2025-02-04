import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TabsPage extends StatefulWidget {
  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  List<String> tabs = [];
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

      print('Данные из базы: $response');
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
        title: isSelectionMode
            ? Text('Выбрано: ${selectedIndices.length}')
            : Text('Мои Списки'),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete),
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
                          child: Text('Удалить'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Название Списка'),
            ),
          ),
          ElevatedButton(
            onPressed: addTab,
            child: Text('Добавить Список'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(tabs[index]),
                  onTap: () {
                    if (isSelectionMode) {
                      toggleSelection(index);
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
                                      child: Text('Удалить'),
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
