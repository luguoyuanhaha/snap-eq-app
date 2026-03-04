import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '拍照解方程',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  final varCtl = TextEditingController(text: "x");
  File? img;
  String out = "拍照后点击识别并求解";
  bool loading = false;

  final String apiBase = "http://192.168.10.10:8000";

  Future<void> takePhoto() async {
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x != null) setState(() => img = File(x.path));
  }

  Future<void> solveFromImage() async {
    if (img == null) return;
    setState(() => loading = true);
    try {
      final req = http.MultipartRequest("POST", Uri.parse("$apiBase/solve_from_image"));
      req.fields["variable"] = varCtl.text.trim().isEmpty ? "x" : varCtl.text.trim();
      req.files.add(await http.MultipartFile.fromPath("file", img!.path));
      final res = await req.send();
      final txt = await res.stream.bytesToString();
      final j = jsonDecode(txt);

      if (j["success"] == true) {
        setState(() {
          out = "方程：${j["equation"]}\n解：${(j["solutions"] as List).join(", ")}";
        });
      } else {
        setState(() => out = "失败：${j["error"]}");
      }
    } catch (e) {
      setState(() => out = "异常：$e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("拍照解方程")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: img == null
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: const Text("暂无照片"),
                    )
                  : Image.file(img!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: varCtl,
              decoration: const InputDecoration(
                labelText: "求解变量（默认 x）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : takePhoto,
                    child: const Text("拍照"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : solveFromImage,
                    child: const Text("识别并求解"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading) const CircularProgressIndicator(),
            if (!loading) SelectableText(out),
          ],
        ),
      ),
    );
  }
}
