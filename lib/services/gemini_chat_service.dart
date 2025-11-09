import 'dart:async';
import 'dart:developer';

import 'package:colorist_ui/colorist_ui.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/gemini.dart';

part 'gemini_chat_service.g.dart';

class GeminiChatService {
  GeminiChatService(this.ref);
  final Ref ref;

  Future<void> sendMessage(String message) async {
    final chatSession = await ref.read(chatSessionProvider.future);
    final chatStateNotifier = ref.read(chatStateProvider.notifier);
    final logStateNotifier = ref.read(logStateProvider.notifier);

    chatStateNotifier.addUserMessage(message);
    logStateNotifier.logUserText(message);
    final llmMessage = chatStateNotifier.createLlmMessage();
    try {
      log("message ${message}");
      final response = await chatSession.sendMessage(Content.text(message));

      final responseText = response.text;
      if (responseText != null) {
        logStateNotifier.logLlmText(responseText);
        chatStateNotifier.appendToMessage(llmMessage.id, responseText);
      }
    } catch (e, st) {
      logStateNotifier.logError(e, st: st);
      chatStateNotifier.appendToMessage(
        llmMessage.id,
        "\nI'm sorry, I encountered an error processing your request. "
        "Please try again.",
      );
    } finally {
      chatStateNotifier.finalizeMessage(llmMessage.id);
    }
  }
}

@Riverpod(keepAlive: true)
GeminiChatService geminiChatService(Ref ref) => GeminiChatService(ref);