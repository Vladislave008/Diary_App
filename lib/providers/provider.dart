import 'package:flutter/material.dart';

class ContextProvider with ChangeNotifier {
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
    notifyListeners();
  }

  BuildContext? get context => _context;
}