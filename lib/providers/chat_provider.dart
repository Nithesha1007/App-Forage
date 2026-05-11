import 'package:flutter/material.dart';
import '../services/ai_chat_service.dart';

enum ChatStatus { idle, thinking }

// ── ChatMessage model (unchanged) ─────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// ChatProvider
// Only change: sendMessage now awaits _service.getResponse() (real Gemini AI)
// instead of calling the old synchronous rule-based getResponse().
// Everything else — getters, clearHistory, clearNewSuggestion — is identical.
// ══════════════════════════════════════════════════════════════════════════════
class ChatProvider extends ChangeNotifier {
  final AiChatService _service = AiChatService();

  final List<ChatMessage> _messages = [];
  ChatStatus _status = ChatStatus.idle;
  bool _hasNewSuggestion = false;

  // ── Getters (unchanged) ───────────────────────────────────────────────────
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatStatus get status => _status;
  bool get isThinking => _status == ChatStatus.thinking;
  bool get hasNewSuggestion => _hasNewSuggestion;
  bool get isEmpty => _messages.isEmpty;

  // ── Welcome message (unchanged) ───────────────────────────────────────────
  ChatProvider() {
    _addBotMessage(
      '👋 Hi! I\'m your AppForge AI assistant.\n\n'
      'I can help you:\n'
      '• Add and customize widgets\n'
      '• Set up your Firebase database\n'
      '• Bind data to your UI\n'
      '• Publish your app\n\n'
      'What would you like to build today?',
    );
  }

  // ── Send user message — NOW calls real Gemini AI ──────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user bubble immediately
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _status = ChatStatus.thinking; // shows typing indicator in UI
    notifyListeners();

    // 2. ✅ Real Gemini response (async, replaces fake delay + rule-based)
    final response = await _service.getResponse(text.trim());

    // 3. Add AI reply bubble
    _addBotMessage(response);
    _status = ChatStatus.idle;
    _hasNewSuggestion = true;
    notifyListeners();
  }

  // ── Quick reply shortcut (unchanged) ─────────────────────────────────────
  Future<void> sendQuickReply(String text) => sendMessage(text);

  // ── Mark suggestions read (unchanged) ────────────────────────────────────
  void clearNewSuggestion() {
    _hasNewSuggestion = false;
    notifyListeners();
  }

  // ── Clear history — also resets Gemini conversation context ──────────────
  void clearHistory() {
    _messages.clear();
    _hasNewSuggestion = false;
    _service.resetChat(); // ← fresh Gemini session too
    _addBotMessage('Chat cleared! How can I help you?');
    notifyListeners();
  }

  // ── Internal helper (unchanged) ───────────────────────────────────────────
  void _addBotMessage(String text) {
    _messages.add(
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
}
