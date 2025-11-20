import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Contact Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  bool _processing = false;

  String _name = "";
  String _phone = "";

  Future<void> _pickImage(ImageSource source) async {
    await Permission.camera.request();
    await Permission.storage.request();

    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _name = "";
      _phone = "";
    });

    _runOCR();
  }

  Future<void> _runOCR() async {
    if (_image == null) return;

    setState(() => _processing = true);

    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(_image!.path);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      print("RAW OCR TEXT:\n$text");

      // -----------------------------
      // 1. Extract Phone Number (Indian format)
      // -----------------------------
      String extractPhone(String fullText) {
        final regex = RegExp(r'\b[6-9]\d{9}\b');   // Only valid IN numbers
        final match = regex.firstMatch(fullText);
        return match?.group(0) ?? "";
      }

      // -----------------------------
      // 2. Extract Name (first clean alphabetic line)
      // -----------------------------
      String extractName(String fullText) {
        final lines = fullText.split("\n");

        for (String line in lines) {
          line = line.trim();

          if (line.isEmpty) continue;
          if (line.toLowerCase().contains("contact")) continue;
          if (line.toLowerCase().contains("business")) continue;
          if (line.contains("@")) continue;
          if (RegExp(r'\d').hasMatch(line)) continue; // skip if contains digits

          // Accept only alphabet name with 2–4 words (First Last)
          if (RegExp(r"^[A-Za-z ]+$").hasMatch(line) && line.split(" ").length <= 4) {
            return line;
          }
        }
        return "";
      }

      // Use improved extraction
      final phone = extractPhone(text);
      final name = extractName(text);

      setState(() {
        _phone = phone;
        _name = name;
      });

    } catch (e) {
      print("OCR ERROR: $e");
    }

    await textRecognizer.close();
    setState(() => _processing = false);
  }


  Future<void> _saveContact() async {
    if (_name.isEmpty && _phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No data to save")));
      return;
    }

    if (!await FlutterContacts.requestPermission()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Permission denied")));
      return;
    }

    final newContact = Contact()
      ..name.first = _name
      ..phones = [Phone(_phone, label: PhoneLabel.mobile)];

    await newContact.insert();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Contact saved!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OCR Contact Saver"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 250),
              ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text("Gallery"),
                ),
              ],
            ),

            SizedBox(height: 20),

            if (_processing) CircularProgressIndicator(),

            if (!_processing && (_name.isNotEmpty || _phone.isNotEmpty))
              Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text("Name"),
                      subtitle: Text(_name.isEmpty ? "---" : _name),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.phone),
                      title: Text("Phone"),
                      subtitle: Text(_phone.isEmpty ? "---" : _phone),
                    ),
                  ),
                ],
              ),

            SizedBox(height: 20),

            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text("Save Contact"),
              onPressed:
              (_name.isEmpty && _phone.isEmpty) ? null : _saveContact,
            )
          ],
        ),
      ),
    );
  }
}
