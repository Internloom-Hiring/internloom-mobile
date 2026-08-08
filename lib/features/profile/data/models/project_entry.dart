import 'package:uuid/uuid.dart';

/// One entry inside the `projects` column. That column is a plain
/// `text` field in the real schema (not jsonb), so a `List<ProjectEntry>`
/// is JSON-encoded to a string before saving and decoded back on load
/// — see ProfileService's (de)serialization. This model itself is
/// unaffected by that; it's still structured (title, description,
/// link) the same way the requirements doc's Section 2.2 describes.
class ProjectEntry {
  final String id;
  String title;
  String description;
  String link;

  ProjectEntry({
    String? id,
    required this.title,
    this.description = '',
    this.link = '',
  }) : id = id ?? const Uuid().v4();

  factory ProjectEntry.blank() => ProjectEntry(title: '', description: '', link: '');

  factory ProjectEntry.fromMap(Map<String, dynamic> map) => ProjectEntry(
        id: map['id'] as String?,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        link: map['link'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'link': link,
      };

  bool get isComplete => title.trim().isNotEmpty;
}
