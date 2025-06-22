import 'dart:io';
import 'package:bohpiai/aimodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<_ChatMessage> messages = [];
  bool isTyping = false;
  XFile? selectedImage;

  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: YOUR_API_KEY,
  );

  final List<String> faqQuestions = [
    "Is the information about both image and text fake or real",
  ];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add(_ChatMessage(
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      isTyping = true;
    });
    textController.clear();
    scrollToBottom();

    final prompt = """
Detect DEEPFAKES and Fake news: $text 
Analyze this news post for truthfulness. It include a text description. For this task:

If got image, do image Integrity: Determine if the image is real, AI-generated, photoshopped, or digitally manipulated using forensic techniques.
If dont have image, ignore this part.
Text Veracity: Analyze the accompanying news text to detect fake or misleading claims.

Cross-Reference:
- (If no image ignore this parts)Perform a reverse image search to find original uses of this image online.
- Search for books, news sources, or articles related to the described event/person/place.
- Check if the text accurately describes what's shown or referenced.

Return the following:
- Real/Fake probability (% Real)
- Authenticity verdict: Real / Possibly Fake / Fake
- Key mismatch or confirmation notes.


""";

    final List<Content> aiInputs = [];
    if (selectedImage != null) {
      final imageBytes = await selectedImage!.readAsBytes();
      final mimetype = selectedImage!.mimeType ?? 'image/jpeg';
      aiInputs.add(Content.multi([
        TextPart(prompt),
        DataPart(mimetype, imageBytes),
      ]));
    } else {
      aiInputs.add(Content.text(prompt));
    }

    String aiResponse = '';
    final response = model.generateContentStream(aiInputs);
    await for (final chunk in response) {
      if (chunk.text != null) {
        setState(() {
          aiResponse += chunk.text!;
        });
        scrollToBottom();
      }
    }

    setState(() {
      messages.add(_ChatMessage(
        text: aiResponse.trim(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
      isTyping = false;
    });
    scrollToBottom();
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

//bold
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

  void pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        selectedImage = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NEWSCLEAR',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[200],
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            onPressed: () => pickImage(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModelPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(File(selectedImage!.path), height: 150),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: faqQuestions
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(q),
                            onPressed: () => sendMessage(q),
                            backgroundColor: Colors.yellow[100],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    final msg = messages[index];
                    //ui
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                    );
//ui
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: SpinKitThreeBounce(
                          color: Colors.grey,
                          size: 20.0,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      onSubmitted: sendMessage,
                      decoration: InputDecoration(
                        hintText: "Enter your query...",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => sendMessage(textController.text),
                    icon: const Icon(Icons.send, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
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
