import 'package:flutter/material.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/screens/home_screen.dart';
import 'package:namer_app/screens/note_content_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int currentPageIndex = 0;

  List<String> notes_pinned = [];
  List<String> notes_not_pinned = [];
  List<String> notes = [];

  List<bool> pins = [];
  List<bool> pins_pinned = [];
  List<bool> pins_not_pinned = [];

  Set<int> selectedIndices = {};
  bool isSelectionMode = false;
  bool isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _newnameController = TextEditingController();

  final FirebaseService firebaseService = FirebaseService();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> _navigateToNoteContentPage(String NoteName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NoteContentPage(NoteName: NoteName)),
    );

    fetchNotes();
  }

  Future<void> fetchNotes() async {
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
      final response1 = await supabase
          .from('notes')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('pin', true);

      setState(() {
        notes_pinned =
            List<String>.from(response1.map((note) => note['name'] as String));
      });

      final response2 = await supabase
          .from('notes')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('pin', false);

      setState(() {
        notes_not_pinned =
            List<String>.from(response2.map((note) => note['name'] as String));
      });
    } catch (e) {
      print('Ошибка при загрузке списков: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке списков: $e')),
        );
      }
    }

    setState(() {
      notes =
          notes_pinned.reversed.toList() + notes_not_pinned.reversed.toList();
    });

    try {
      final response1 = await supabase
          .from('notes')
          .select('pin')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('pin', true);

      setState(() {
        pins_pinned =
            List<bool>.from(response1.map((note) => note['pin'] as bool));
      });

      final response2 = await supabase
          .from('notes')
          .select('pin')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('pin', false);

      setState(() {
        pins_not_pinned =
            List<bool>.from(response2.map((note) => note['pin'] as bool));
      });
    } catch (e) {
      print('Ошибка при загрузке списков: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке списков: $e')),
        );
      }
    }
    setState(() {
      pins = pins_pinned.reversed.toList() + pins_not_pinned.reversed.toList();
      isLoading = false;
    });
  }

  Future<void> addNote() async {
    try {
      String now = '-*-*-*--' + DateTime.now().toLocal().toString();

      await supabase.from('notes').insert([
        {'name': now, 'user_id': FirebaseAuth.instance.currentUser!.uid}
      ]);

      _nameController.clear();
      await fetchNotes();
    } catch (e) {
      print(_nameController.text);
      print(FirebaseAuth.instance.currentUser!.uid);
      print('Ошибка при добавлении заметки: $e ');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении заметки: $e')),
        );
      }
    }
  }

  Future<void> pinNote(int index) async {
    if (pins[index] == false) {
      try {
        await supabase
            .from('notes')
            .update({'pin': true})
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('name', notes[index]);

        //await fetchNotes();
        print('Tabupdated successfully');
      } catch (e) {
        print('Error updating tab: $e');
      }
    } else if (pins[index] == true) {
      try {
        await supabase
            .from('notes')
            .update({'pin': false})
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
            .eq('name', notes[index]);

        await fetchNotes();
        print('Tabupdated successfully');
      } catch (e) {
        print('Error updating tab: $e');
      }
    }
    await fetchNotes();
  }

  Future<void> updateNote(String noteName) async {
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
    if (notes.contains(_newnameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Такая вкладка уже существует')),
      );
      return;
    }

    try {
      await supabase
          .from('notes')
          .update({'name': _newnameController.text})
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('name', noteName);

      _newnameController.clear();
      await fetchNotes();
      print('Tabupdated successfully');
    } catch (e) {
      print('Error updating tab: $e');
    }
  }

  Future<void> deleteSelectedNotes() async {
    try {
      for (int index in selectedIndices) {
        await supabase
            .from('notes')
            .delete()
            .eq('name', notes[index])
            .eq('user_id', FirebaseAuth.instance.currentUser!.uid);
      }
      await fetchNotes();
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
            : Text('Заметки'),
        actions: isLoading == true
            ? [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  //color: const Color.fromARGB(255, 255, 115, 0),
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
                      title: Text('Удалить выбранные заметки'),
                      content: Text(
                          'Вы уверены, что хотите удалить все выбранные заметки?'),
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
                            await deleteSelectedNotes(); // Удалить выбранные списки
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
          : FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 245, 136, 46),
              foregroundColor: Colors.white,
              onPressed: addNote,
              child: Icon(Icons.add_rounded),
            ),
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
              Expanded(
                child: ListView.builder(
                  itemCount: (notes.length / 2).ceil(),
                  itemBuilder: (context, index) {
                    if (notes.isEmpty || index >= notes.length) {
                      isLoading = false;

                      return SizedBox
                          .shrink(); // Возвращаем пустой виджет, если данных нет
                    }
                    int firstIndex = index * 2;

                    int secondIndex = firstIndex + 1;

                    String name1 = ' ';
                    String name2 = ' ';

                    if (firstIndex < notes.length) {
                      if (notes[firstIndex].contains('-*-*-*--')) {
                        name1 = '';
                      } else if (notes[firstIndex].length > 25) {
                        name1 = notes[firstIndex].substring(0, 19) + '...';
                      } else if (notes[firstIndex].length <= 25) {
                        name1 = notes[firstIndex];
                      }
                    }

                    if (secondIndex < notes.length) {
                      if (notes[secondIndex].contains('-*-*-*--')) {
                        name2 = '';
                      } else if (notes[secondIndex].length > 25) {
                        name2 = notes[secondIndex].substring(0, 19) + '...';
                      } else if (notes[secondIndex].length <= 25) {
                        name2 = notes[secondIndex];
                      }
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedIndices.contains(firstIndex) &&
                                      isSelectionMode
                                  ? Color.fromARGB(255, 245, 163, 163)
                                  : Color.fromARGB(160, 255, 255, 255),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            margin: EdgeInsets.all(8.0),
                            height: 100,
                            child: ListTile(
                              trailing: IconButton(
                                icon: Icon(
                                    pins[firstIndex]
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: pins[firstIndex]
                                        ? const Color.fromARGB(255, 238, 143, 0)
                                        : null),
                                selectedIcon: Icon(Icons.star_rounded),
                                onPressed: () {
                                  pinNote(firstIndex);
                                },
                              ),
                              title: Text(name1),
                              onLongPress: () {
                                setState(() {
                                  isSelectionMode = true;
                                  toggleSelection(firstIndex);
                                });
                              },
                              onTap: () {
                                if (isSelectionMode) {
                                  toggleSelection(firstIndex);
                                } else {
                                  _navigateToNoteContentPage(notes[firstIndex]);
                                }
                              },
                            ),
                          ),
                        ),
                        if (secondIndex < notes.length)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedIndices.contains(secondIndex) &&
                                        isSelectionMode
                                    ? Color.fromARGB(255, 245, 163, 163)
                                    : Color.fromARGB(160, 255, 255, 255),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: EdgeInsets.all(8.0),
                              height: 100,
                              child: ListTile(
                                trailing: IconButton(
                                  icon: Icon(
                                      pins[secondIndex]
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: pins[secondIndex]
                                          ? const Color.fromARGB(
                                              255, 238, 143, 0)
                                          : null),
                                  selectedIcon: Icon(Icons.star_rounded),
                                  onPressed: () {
                                    pinNote(secondIndex);
                                  },
                                ),
                                title: Text(name2),
                                onLongPress: () {
                                  setState(() {
                                    isSelectionMode = true;
                                    toggleSelection(secondIndex);
                                  });
                                },
                                onTap: () {
                                  if (isSelectionMode) {
                                    toggleSelection(secondIndex);
                                  } else {
                                    _navigateToNoteContentPage(
                                        notes[secondIndex]);
                                  }
                                },
                              ),
                            ),
                          ),
                        if (secondIndex >= notes.length)
                          Expanded(
                            child: Container(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          )),
    );
  }
}
