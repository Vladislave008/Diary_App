import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ItemList extends StatefulWidget {
  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  List<Item> items = [];
  TextEditingController textController = TextEditingController();
  bool isLoading = false;

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://172.25.0.7:8000/items/?owner_id=${user.uid}'), // Получаем элементы только для текущего пользователя
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((item) => Item.fromJson(item)).toList();
        });
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print('Error fetching items: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addItem(String text) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('http://172.25.0.7:8000/items/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'text': text,
          'owner_id': user.uid,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        fetchItems();
        textController.clear();
      } else {
        print('Failed to add item: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to add item');
      }
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Enter text',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            addItem(textController.text);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(items[index].text),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class Item {
  final int id;
  final String text;

  Item({required this.id, required this.text});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      text: json['text'],
    );
  }
}
