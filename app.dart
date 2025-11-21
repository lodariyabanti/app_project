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
      theme: ThemeData(primarySwatch: Colors.deepPurple),
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

  // -------------------------------
  // PICK IMAGE
  // -------------------------------
  Future<void> _pickImage(ImageSource source) async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();

    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _name = "";
      _phone = "";
    });

    _runOCR();
  }

  // -------------------------------------------------
  // ⭐ IMPROVED OCR PROCESSING
  // -------------------------------------------------
  Future<void> _runOCR() async {
    if (_image == null) return;
    setState(() => _processing = true);

    final recognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(_image!.path);

    try {
      final RecognizedText textData = await recognizer.processImage(inputImage);
      final fullText = textData.text;

      print("\n------ RAW TEXT ------\n$fullText\n");

      // -------------------------------------------------
      // ✔ Extract Phone (Strong Regex)
      // -------------------------------------------------
      String extractPhone(String text) {
        final regex = RegExp(
            r'(\+91[\s\-]?)?[6-9]\d{9}', // +91 or normal 10 digit
            multiLine: true);

        final match = regex.firstMatch(text);
        if (match != null) {
          return match.group(0)!
              .replaceAll(RegExp(r'\s+|\-'), '')
              .replaceAll("+91", "");
        }
        return "";
      }

      // -------------------------------------------------
      // ✔ Extract Name (Smart Filtering)
      // -------------------------------------------------
      String extractName(String text) {
        List<String> lines = text.split("\n");

        for (String line in lines) {
          line = line.trim();

          if (line.isEmpty) continue;
          if (line.length < 3) continue;
          if (line.contains("@")) continue;
          if (RegExp(r'\d').hasMatch(line)) continue;
          if (line.toLowerCase().contains("mr") ||
              line.toLowerCase().contains("ms") ||
              line.toLowerCase().contains("profile") ||
              line.toLowerCase().contains("contact") ||
              line.toLowerCase().contains("information") ||
              line.toLowerCase().contains("business")) continue;

          // Only allow alphabetic names (2–4 words)
          if (RegExp(r"^[A-Za-z ]+$").hasMatch(line)) {
            int wordCount = line.split(" ").length;
            if (wordCount >= 2 && wordCount <= 4) {
              return line;
            }
          }
        }

        return "";
      }

      final phone = extractPhone(fullText);
      final name = extractName(fullText);

      setState(() {
        _phone = phone;
        _name = name;
      });

    } catch (e) {
      print("OCR ERROR: $e");
    }

    await recognizer.close();
    setState(() => _processing = false);
  }

  // -------------------------------------------------
  // SAVE CONTACT
  // -------------------------------------------------
  Future<void> _saveContact() async {
    if (_name.isEmpty && _phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No valid data found")));
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

  // -------------------------------------------------
  // UI
  // -------------------------------------------------
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

            if (_processing)
              CircularProgressIndicator(),

            if (!_processing)
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
              onPressed: (_name.isEmpty && _phone.isEmpty)
                  ? null
                  : _saveContact,
            )
          ],
        ),
      ),
    );
  }
}
