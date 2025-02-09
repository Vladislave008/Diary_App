import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TabContentPage extends StatefulWidget {
  final String tabName;
  TabContentPage({required this.tabName});

  @override
  State<TabContentPage> createState() => _TabContentPageState();
}

class _TabContentPageState extends State<TabContentPage> {
  List<dynamic> items = [];

  Set<int> selectedIndices = {};

  bool isSelectionMode = false;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _fetchItems() async {
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      return;
    }
    try {
      final response = await supabase
          .from('tabs_items')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('parent_tab', widget.tabName);

      //print('Данные из базы: $response');
      setState(() {
        items =
            List<String>.from(response.map((item) => item['name'] as String));
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

  Future<void> _createItem(String text) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите название')),
      );
      return;
    }
    if (_nameController.text[0] == ' ') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Название не может быть пустым или начинаться с пробела')),
      );
      return;
    }
    if (items.contains(_nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Такая вкладка уже существует')),
      );
      return;
    }

    try {
      await supabase.from('tabs_items').insert([
        {
          'name': _nameController.text,
          'user_id': FirebaseAuth.instance.currentUser!.uid,
          'parent_tab': widget.tabName
        }
      ]);
      _nameController.clear();
      await _fetchItems();
    } catch (e) {
      print('Ошибка при добавлении: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении: $e')),
        );
      }
    }
  }

  Future<void> deleteItem(String itemName) async {
    print('delete tab ${widget.tabName}');
    try {
      await supabase
          .from('tabs_items')
          .delete()
          .eq('name', itemName)
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('parent_tab', widget.tabName);

      await _fetchItems();
    } catch (e) {
      print('Ошибка при удалении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  Future<void> deleteSelectedItems() async {
    try {
      for (int index in selectedIndices) {
        await supabase
            .from('tabs_items')
            .delete()
            .eq('name', items[index])
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('parent_tab', widget.tabName);
      }

      await _fetchItems();
      setState(() {
        selectedIndices.clear();
        isSelectionMode = false;
      });
    } catch (e) {
      print('Ошибка при удалении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
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
    print(items);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
        title: isSelectionMode
            ? Text('Выбрано: ${selectedIndices.length}')
            : Text(widget.tabName),
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
                      title: Text('Удалить выбранные элементы'),
                      content: Text(
                          'Вы уверены, что хотите удалить все выбранные элементы?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await deleteSelectedItems();
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
              Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(160, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Введите текст',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            _createItem(_nameController.text);
                          }
                        },
                      ),
                    ),
                    maxLength: 40,
                  )),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
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
                          title: Text(items[index]),
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
                                  activeColor:
                                      const Color.fromARGB(255, 236, 37, 23),
                                  value: selectedIndices.contains(index),
                                  onChanged: (value) {
                                    toggleSelection(index);
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Удалить запись'),
                                          content: Text(
                                              'Вы уверены, что хотите удалить эту запись?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                deleteItem(items[index]);
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'Удалить',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                        ));
                  },
                ),
              ),
              /*Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Введите текст',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          _createItem(_nameController.text);
                        }
                      },
                    ),
                  ),
                  maxLength: 40,
                ),
              ),*/
            ],
          )),
    );
  }
}
