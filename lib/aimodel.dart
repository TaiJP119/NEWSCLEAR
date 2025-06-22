import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:bohpiai/backend_service.dart';

// model
class ModelPage extends StatefulWidget {
  const ModelPage({super.key});

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  final _txt = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<_ChatMessage> messages = [];

  Map<String, dynamic>? _result;
  bool _busy = false;

  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: YOUR_API_KEY,
  );

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final res = await BackendService.predictMultimodal(
        text: _txt.text.isNotEmpty ? _txt.text : null,
      );
      setState(() => _result = res);

      final textLabel = res['text_label'];
      final textProb = ((res['text_prob'] ?? 0.0) * 100).toStringAsFixed(6);

      await sendMessage(textLabel, textProb);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> sendMessage(String label, String prob) async {
    final showedMessageUi =
        "My trained model for news identification has outputs of Prediction: $label and confidence: $prob%. Refer to both of the outputs above, analyze this news post for truthfulness.\nText Veracity: Analyze the accompanying news text to detect fake or misleading claims.";

    final prompt = """
${_txt.text}
$showedMessageUi

Cross-Reference:
- Search for books, news sources, or articles related to the described event/person/place.
- Check if the text accurately describes what's shown or referenced.

Return the following:
- Real/Fake probability (% Real)
- Authenticity verdict: Real / Possibly Fake / Fake
- Key mismatch or confirmation notes.
""";

    messages.add(_ChatMessage(
      text: showedMessageUi,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    setState(() {});

    String aiResponse = '';
    final response = model.generateContentStream([Content.text(prompt)]);
    await for (final chunk in response) {
      if (chunk.text != null) {
        aiResponse += chunk.text!;
        setState(() {
          if (messages.isEmpty || messages.last.isUser) {
            messages.add(_ChatMessage(
              text: chunk.text!,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          } else {
            messages[messages.length - 1] = _ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            );
          }
        });
        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  RichText _formatRichText(String text) {
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: const TextStyle(fontWeight: FontWeight.normal),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: const TextStyle(fontWeight: FontWeight.normal),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: spans,
      ),
    );
  }

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text('', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[200],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _txt,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enter text (optional)',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text('Predict'),
                            onPressed: _busy ? null : _submit,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_busy)
                          const Center(child: CircularProgressIndicator())
                        else if (_result != null)
                          // Card(
                          //   elevation: 2,
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(16),
                          //     child: Column(
                          //       children: [
                          //         if (_result!['text_label'] != null)
                          //           _buildRow('Text', _result!['text_label'],
                          //               _result!['text_prob'], theme),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 16),
                        ...messages.map((msg) => Align(
                              alignment: msg.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: msg.isUser
                                      ? Colors.yellow[200]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: msg.isUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(0),
                                    bottomRight: msg.isUser
                                        ? const Radius.circular(0)
                                        : const Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _formatRichText(msg.text),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String src,
    String label,
    num prob,
    ThemeData theme,
  ) {
    final isTrue = label == 'true';
    final color = isTrue ? Colors.green : Colors.red;
    final icon = isTrue ? Icons.check_circle : Icons.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$src Prediction',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        label.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 10),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confidence: ${(prob * 100).toStringAsFixed(6)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
