class Achievement {
  final String id;
  final String title;
  final String description;
  final IconType icon;
  final double progress;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon = IconType.trophy,
    this.progress = 0.0,
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      icon: _parseIconType(json['icon'] as String? ?? 'trophy'),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isUnlocked: json['unlocked'] as bool? ?? false,
    );
  }

  static IconType _parseIconType(String value) {
    switch (value) {
      case 'star':
        return IconType.star;
      case 'brain':
        return IconType.brain;
      case 'lock':
        return IconType.lock;
      default:
        return IconType.trophy;
    }
  }
}

enum IconType { trophy, star, brain, lock }
