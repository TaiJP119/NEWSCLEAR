// import 'dart:io';

// import 'package:bohpiai/backend_service.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class ModelPage extends StatefulWidget {
//   const ModelPage({super.key});

//   @override
//   State<ModelPage> createState() => _ModelPageState();
// }

// class _ModelPageState extends State<ModelPage> {
//   final _txt = TextEditingController();
//   final _picker = ImagePicker();
//   File? _image;
//   Map<String, dynamic>? _result;
//   bool _busy = false;

//   Future<void> _pick(ImageSource src) async {
//     final picked = await _picker.pickImage(source: src, maxWidth: 1024);
//     if (picked != null) {
//       setState(() => _image = File(picked.path));
//     }
//   }

//   Future<void> _submit() async {
//     setState(() {
//       _busy = true;
//       _result = null;
//     });
//     try {
//       final res = await BackendService.predictMultimodal(
//         text: _txt.text.isNotEmpty ? _txt.text : null,
//         imageFile: _image,
//       );
//       setState(() => _result = res);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() => _busy = false);
//     }
//   }

//   @override
//   void dispose() {
//     _txt.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(title: const Text('Fake-News Detector')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // ----- text input -------------------------------------------------
//             TextField(
//               controller: _txt,
//               maxLines: 5,
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//                 labelText: 'Enter text (optional)',
//               ),
//             ),
//             const SizedBox(height: 16),

//             const SizedBox(height: 24),
//             // ----- submit button ----------------------------------------------
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton.icon(
//                 icon: const Icon(Icons.send),
//                 label: const Text('Predict'),
//                 onPressed: _busy ? null : _submit,
//               ),
//             ),
//             const SizedBox(height: 24),
//             // ----- result area ------------------------------------------------
//             if (_busy)
//               const CircularProgressIndicator()
//             else if (_result != null)
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       if (_result!['text_label'] != null)
//                         _buildRow(
//                           'Text',
//                           _result!['text_label'],
//                           _result!['text_prob'],
//                           theme,
//                         ),
//                       if (_result!['img_label'] != null)
//                         _buildRow(
//                           'Image',
//                           _result!['img_label'],
//                           _result!['img_prob'],
//                           theme,
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRow(
//     String src,
//     String label,
//     num prob,
//     ThemeData theme,
//   ) {
//     final isTrue = label == 'true';
//     final color = isTrue ? Colors.green : Colors.red;
//     final icon = isTrue ? Icons.check_circle : Icons.warning;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '$src Prediction',
//                   style: theme.textTheme.titleMedium,
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Chip(
//                       label: Text(
//                         label.toUpperCase(),
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                       backgroundColor: color,
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 4, horizontal: 10),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Confidence: ${(prob).toStringAsFixed(6)}%',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
