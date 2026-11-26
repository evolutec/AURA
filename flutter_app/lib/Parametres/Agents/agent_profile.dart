class AgentProfile {
  final String id;
  final String name;
  final String avatar;
  final String systemPrompt;
  final List<String> quickPrompts;

  const AgentProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.systemPrompt,
    this.quickPrompts = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'systemPrompt': systemPrompt,
    'quickPrompts': quickPrompts,
  };

  factory AgentProfile.fromJson(Map<String, dynamic> json) => AgentProfile(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    avatar: json['avatar']?.toString() ?? 'assistant',
    systemPrompt: json['systemPrompt']?.toString() ?? '',
    quickPrompts: (json['quickPrompts'] as List<dynamic>? ?? const [])
        .map((prompt) => prompt.toString())
        .toList(),
  );

  static const defaults = [
    AgentProfile(
      id: 'ask',
      name: 'Ask',
      avatar: 'assistant',
      systemPrompt: 'You are a helpful general-purpose assistant.',
      quickPrompts: ['Explain this clearly', 'Summarize this'],
    ),
    AgentProfile(
      id: 'code',
      name: 'Code',
      avatar: 'code',
      systemPrompt: 'You are a precise programming assistant. Provide working code and explain important decisions.',
      quickPrompts: ['Review this code', 'Help me debug this'],
    ),
    AgentProfile(
      id: 'review',
      name: 'Review',
      avatar: 'review',
      systemPrompt: 'You are a careful reviewer. Identify risks, errors, and concrete improvements.',
      quickPrompts: ['Review this proposal', 'Find potential issues'],
    ),
  ];
}
