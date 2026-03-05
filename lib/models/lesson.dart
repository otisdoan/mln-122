class Lesson {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool isLocked;
  final String content;
  final String formula;
  final String duration;
  final int orderIndex;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.isLocked = false,
    this.content = '',
    this.formula = '',
    this.duration = '',
    this.orderIndex = 0,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'book',
      isLocked: json['is_locked'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'is_locked': isLocked,
      'content': content,
      'formula': formula,
      'order_index': orderIndex,
    };
  }
}
