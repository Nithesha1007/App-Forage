import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AiChatService — Google Gemini 1.5 Flash (free tier)
// Free: 15 req/min · 1M tokens/day · no credit card needed
//
// ONLY this file changes — ChatProvider and AiChatScreen are untouched.
// ══════════════════════════════════════════════════════════════════════════════

class AiChatService {
  GenerativeModel? _model;
  ChatSession?     _chat;

  static const String _systemPrompt = '''
You are AppForge AI, a helpful assistant built into a no-code mobile app builder called AppForge.

Help users build their mobile apps. You can answer questions about:
- Adding and configuring widgets (Text, Button, Image, Input, Card, Icon, Divider, App Bar, Nav Bar, etc.)
- Setting up screens and navigation between them
- Configuring the backend (Firestore database tables, authentication methods)
- Binding data from the database to widgets
- Customizing themes, colors, and fonts
- Previewing and publishing their app
- Firebase and Firestore concepts as they relate to app building
- General mobile app design and UX advice

Keep answers concise, practical, and beginner-friendly.
Use numbered steps when explaining a process.
If asked something unrelated to app building, politely redirect back to AppForge.
Be encouraging and supportive.
''';

  // ── Lazy init — only creates model on first use ───────────────────────────
  void _init() {
    if (_model != null) return;
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model:  'gemini-2.5-flash',   // free tier
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature:     0.7,
        maxOutputTokens: 600,
      ),
      systemInstruction: Content.system(_systemPrompt),
    );
    // Persistent session so AI remembers conversation history
    _chat = _model!.startChat();
  }

  // ── getResponse is now async — ChatProvider awaits it ────────────────────
  Future<String> getResponse(String userMessage) async {
    try {
      _init();
      final response = await _chat!.sendMessage(
        Content.text(userMessage),
      );
      return response.text?.trim() ??
          'Sorry, I could not generate a response. Please try again.';
    } on GenerativeAIException catch (e) {
      return _handleError(e.message);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Reset conversation history ────────────────────────────────────────────
  void resetChat() {
    _model = null;
    _chat  = null;
  }

  String _handleError(String msg) {
    if (msg.contains('API_KEY') || msg.contains('api key')) {
      return '⚠️ API key missing. Add GEMINI_API_KEY to your .env file.';
    }
    if (msg.contains('RESOURCE_EXHAUSTED') || msg.contains('quota')) {
      return '⏳ Free quota reached. Please wait a minute and try again.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return '📡 No internet connection. Please check your network.';
    }
    return 'Error: $msg';
  }
}
