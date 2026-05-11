import 'widget_model.dart';

class AppScreen {
  final String id;
  String name;
  List<WidgetModel> widgets;
  AppScreen({required this.id, required this.name, this.widgets = const []});
  factory AppScreen.fromMap(Map<String, dynamic> m) => AppScreen(
    id: m['id'] ?? '',
    name: m['name'] ?? 'Screen',
    widgets: (m['widgets'] as List? ?? [])
        .map((w) => WidgetModel.fromMap(w))
        .toList(),
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'widgets': widgets.map((w) => w.toMap()).toList(),
  };
}
