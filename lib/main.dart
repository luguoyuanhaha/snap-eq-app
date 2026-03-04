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

// TODO: 改成你的后端地址，例如 http://192.168.31.20:8000
final String apiBase = "http://YOUR_SERVER_IP:8000";

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
out = "方程：<span class="katex"><span class="katex-mathml"><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mrow><mi>j</mi><mo stretchy="false">[</mo><mi mathvariant="normal">&quot;</mi><mi>e</mi><mi>q</mi><mi>u</mi><mi>a</mi><mi>t</mi><mi>i</mi><mi>o</mi><mi>n</mi><mi mathvariant="normal">&quot;</mi><mo stretchy="false">]</mo></mrow><mstyle mathcolor="#cc0000"><mtext>\n</mtext></mstyle><mtext>解：</mtext></mrow><annotation encoding="application/x-tex">{j[&quot;equation&quot;]}\n解：</annotation></semantics></math></span><span class="katex-html" aria-hidden="true"><span class="base"><span class="strut" style="height:1em;vertical-align:-0.25em;"></span><span class="mord"><span class="mord mathnormal" style="margin-right:0.05724em;">j</span><span class="mopen">[</span><span class="mord">&quot;</span><span class="mord mathnormal">e</span><span class="mord mathnormal" style="margin-right:0.03588em;">q</span><span class="mord mathnormal">u</span><span class="mord mathnormal">a</span><span class="mord mathnormal">t</span><span class="mord mathnormal">i</span><span class="mord mathnormal">o</span><span class="mord mathnormal">n</span><span class="mord">&quot;</span><span class="mclose">]</span></span><span class="mord text" style="color:#cc0000;"><span class="mord" style="color:#cc0000;">\n</span></span><span class="mord cjk_fallback">解：</span></span></span></span>{(j["solutions"] as List).join(", ")}";
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
