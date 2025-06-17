import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:namer_app/screens/home_screen.dart';

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
  final TextEditingController _newnameController = TextEditingController();

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

  Future<void> updateItem(String itemName) async {
    if (_newnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите текст')),
      );
      return;
    }
    if (_newnameController.text[0] == ' ') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Название не может быть пустым или начинаться с пробела')),
      );
      return;
    }
    if (items.contains(_newnameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Такая вкладка уже существует')),
      );
      return;
    }

    try {
      await supabase
          .from('tabs_items')
          .update({'name': _newnameController.text})
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('name', itemName)
          .eq('parent_tab', widget.tabName);

      _newnameController.clear();
      await _fetchItems();
      print('Tab updated successfully');
    } catch (e) {
      print('Error updating tab: $e');
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
        actions: [
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
              SizedBox(height: 10),
              Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  //padding: EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(160, 255, 255, 255),
                      border: OutlineInputBorder(),
                      labelText: 'Введите текст',
                      suffixIcon: AbsorbPointer(
                          absorbing: _nameController.text.isEmpty,
                          child: AnimatedOpacity(
                            opacity:
                                _nameController.text.isNotEmpty ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 400),
                            child: IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: Color.fromARGB(255, 32, 190, 0),
                                size: 35,
                              ),
                              onPressed: () {
                                _createItem(_nameController.text);
                              },
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          )),
                      /*suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                        ),
                        
                        onPressed: () {
                          _createItem(_nameController.text);
                        },
                      ),*/
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
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
                            } else {
                              setState(() {
                                _newnameController.text = items[index];
                              });
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Обновить запись'),
                                    content: TextField(
                                      controller: _newnameController,
                                      decoration: InputDecoration(
                                        labelText: 'Новое название',
                                      ),
                                      onChanged: (text) {
                                        setState(() {});
                                      },
                                      maxLength: 40,
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
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          await updateItem(items[index]);
                                          setState(() {
                                            _newnameController.clear();
                                          });
                                        },
                                        child: Text(
                                          'Готово',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                              ;
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
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined),
                                        onPressed: () {
                                          setState(() {
                                            _newnameController.text =
                                                items[index];
                                          });
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text('Обновить запись'),
                                                content: TextField(
                                                  controller:
                                                      _newnameController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Новое название',
                                                  ),
                                                  onChanged: (text) {
                                                    setState(() {});
                                                  },
                                                  maxLength: 40,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        _newnameController
                                                            .clear();
                                                      });
                                                    },
                                                    child: Text(
                                                      'Отмена',
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                      await updateItem(
                                                          items[index]);
                                                      setState(() {
                                                        _newnameController
                                                            .clear();
                                                      });
                                                    },
                                                    child: Text(
                                                      'Готово',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon:
                                            Icon(Icons.delete_outline_outlined),
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
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('Отмена'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      deleteItem(items[index]);
                                                      Navigator.of(context)
                                                          .pop();
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
                                      )
                                    ]),
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
