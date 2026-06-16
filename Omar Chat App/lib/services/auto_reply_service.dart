/// Generates context-aware auto-replies for simulated incoming messages.
class AutoReplyService {
  String generateReply(
    String userMessage, {
    String? senderName,
    String? mentionedName,
    String messageType = 'text',
  }) {
    if (messageType == 'voice') {
      return generateVoiceReply(userMessage);
    }
    final directed = mentionedName != null ? _messageForMention(userMessage, mentionedName) : userMessage;
    final lower = directed.toLowerCase().trim();

    if (_matchesAny(lower, ['hello', 'hi ', ' hi', 'hey', 'good morning', 'good evening', 'salam'])) {
      return "Hello! How are you doing today?";
    }
    if (_matchesAny(lower, ['how are you', 'how r u', 'how\'s it going', 'what\'s up', 'sup'])) {
      return "I'm doing great, thanks for asking! How about you?";
    }
    if (_matchesAny(lower, ['thank', 'thanks', 'thx', 'appreciate'])) {
      return "You're welcome! Happy to help. 😊";
    }
    if (_matchesAny(lower, ['bye', 'goodbye', 'see you', 'talk later', 'good night'])) {
      return "Goodbye! Talk to you soon.";
    }
    if (_matchesAny(lower, ['meeting', 'schedule', 'appointment'])) {
      return "Sure, I'll be there. What time works best for you?";
    }
    if (_matchesAny(lower, ['help', 'assist', 'support', 'problem', 'issue', 'stuck'])) {
      return "Of course! Tell me more about what you need and I'll do my best to help.";
    }
    if (_matchesAny(lower, ['project', 'task', 'deadline', 'report', 'assignment'])) {
      return "Got it. I'll review the details and get back to you shortly.";
    }
    if (_matchesAny(lower, ['yes', 'sure', 'okay', 'ok', 'agreed', 'sounds good'])) {
      return "Perfect! Let me know if you need anything else.";
    }
    if (_matchesAny(lower, ['no', 'not now', 'can\'t', 'cannot', 'busy'])) {
      return "No problem, we can discuss this later when you're free.";
    }
    if (lower.contains('?')) {
      if (_matchesAny(lower, ['when', 'what time'])) {
        return "Let me check my schedule and confirm the time with you.";
      }
      if (_matchesAny(lower, ['where', 'location'])) {
        return "I'll send you the location details in a moment.";
      }
      if (_matchesAny(lower, ['who', 'which'])) {
        return "Good question — I'll find out and let you know.";
      }
      return "That's a great question. Let me think about it and get back to you.";
    }
    if (_matchesAny(lower, ['love', 'great', 'awesome', 'excellent', 'amazing', 'nice'])) {
      return "Glad to hear that! 😊";
    }
    if (_matchesAny(lower, ['sorry', 'apologize', 'my bad'])) {
      return "No worries at all, it happens!";
    }

    return "Got your message. I'll get back to you soon!";
  }

  /// Contextual text shown alongside a simulated voice reply.
  String generateVoiceReply(String userMessage) {
    final lower = userMessage.toLowerCase().trim();
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return "Hi! I heard your voice note — great to hear from you!";
    }
    if (lower.contains('meeting') || lower.contains('schedule')) {
      return "Got your voice about the meeting — I'll confirm the time shortly.";
    }
    if (lower.contains('?')) {
      return "Good question in your voice note — let me think and reply.";
    }
    if (lower.contains('thank')) {
      return "You're welcome! Happy I could help.";
    }
    return "Thanks for the voice message! I listened and I'll follow up soon.";
  }

  /// Uses the text after @Name when present so group replies match the mention.
  String _messageForMention(String message, String name) {
    final pattern = RegExp('@${RegExp.escape(name)}\\s*(.*)', caseSensitive: false);
    final match = pattern.firstMatch(message);
    if (match != null) {
      final rest = match.group(1)?.trim();
      if (rest != null && rest.isNotEmpty) return rest;
    }
    return message;
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
