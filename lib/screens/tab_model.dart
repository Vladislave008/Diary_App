class MyTab {
  final int id;
  final String name;

  MyTab({required this.id, required this.name});

  factory MyTab.fromJson(Map<String, dynamic> json) {
    return MyTab(
      id: json['id'],
      name: json['name'],
    );
  }
}
