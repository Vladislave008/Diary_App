import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:namer_app/firebase_service.dart';
import 'package:namer_app/screens/notes_screen.dart';
import 'package:namer_app/screens/home_screen.dart';

class NoteContentPage extends StatefulWidget {
  final String NoteName;

  NoteContentPage({required this.NoteName});

  @override
  State<NoteContentPage> createState() => _NoteContentPageState();
}

class _NoteContentPageState extends State<NoteContentPage> {
  final FirebaseService firebaseService = FirebaseService();
  final SupabaseClient supabase = Supabase.instance.client;
  List<String> notes = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.NoteName.contains('-*-*-*--')) {
      _nameController.text = '';
    } else {
      _nameController.text = widget.NoteName;
    }
  }

  Future<void> updateNote() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите текст')),
      );
      return;
    }
    if (_nameController.text[0] == ' ') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Текст не может быть пустым или начинаться с пробела')),
      );
      return;
    }

    try {
      final response = await supabase
          .from('notes')
          .select('name')
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid);

      setState(() {
        notes =
            List<String>.from(response.map((note) => note['name'] as String));
      });
    } catch (e) {
      print('error');
    }

    if (notes.contains(_nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Такая заметка уже существует')),
      );
      return;
    }

    try {
      print(_nameController.text);
      await supabase
          .from('notes')
          .update({'name': _nameController.text})
          .eq('user_id', FirebaseAuth.instance.currentUser!.uid)
          .eq('name', widget.NoteName);
    } catch (e) {
      print('Error updating note: $e');
    }

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => NotesScreen(),
      ));
    }
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
                builder: (context) => NotesScreen(),
              ));
            }
          },
        ),
        backgroundColor: const Color.fromARGB(110, 168, 195, 212),
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
      floatingActionButton: _nameController.text.isEmpty ||
              _nameController.text[0] == ' ' ||
              _nameController.text == widget.NoteName
          ? null
          : FloatingActionButton(
              onPressed: updateNote,
              backgroundColor: const Color.fromARGB(255, 32, 190, 0),
              foregroundColor: Colors.white,
              child: Icon(Icons.done_rounded),
            ),
      body: Container(
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
          child: Column(children: [
            Expanded(
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(160, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _nameController,
                      minLines: null,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        labelText: null,
                        icon: null,
                        prefixIcon: null,
                      ),
                      onChanged: (text) {
                        setState(() {});
                      },
                    )))
          ])),
    );
  }
}
