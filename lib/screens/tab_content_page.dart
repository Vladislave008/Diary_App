import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class TabContentPage extends StatefulWidget {
  final String tabName;

  TabContentPage({required this.tabName});

  @override
  _TabContentPageState createState() => _TabContentPageState();
}

class _TabContentPageState extends State<TabContentPage> {
  List<dynamic> items = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }
    final response = await http
        .get(Uri.parse('http://172.25.0.7:8000/items/?owner_id=${user.uid}'));

    if (response.statusCode == 200) {
      setState(() {
        var jsonResponse = json.decode(response.body);
        items = jsonResponse
            .where((item) => item['tab_name'] == widget.tabName)
            .toList();
      });
    } else {
      throw Exception('Ошибка загрузки данных');
    }
  }

  Future<void> _createItem(String text) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }
    final response = await http.post(
      Uri.parse('http://172.25.0.7:8000/items/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({
        'text': text,
        'owner_id': user.uid, // Укажите ID владельца
        'tab_name': widget.tabName, // Указываем tab_name
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // При успехе обновляем список элементов
      _fetchItems();
      _controller.clear(); // Очищаем текстовое поле
    } else {
      throw Exception('Не удалось создать элемент');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tabName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]['text']),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Введите текст',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _createItem(_controller.text);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
