class MessageTemplate {
  final int? id;
  final String title;
  final String content;
  final String type; // 'telegram' yoki 'sms'

  MessageTemplate({
    this.id,
    required this.title,
    required this.content,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'content': content, 'type': type};
  }

  factory MessageTemplate.fromMap(Map<String, dynamic> map) {
    return MessageTemplate(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      type: map['type'],
    );
  }
}
