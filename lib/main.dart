import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(RepairAIApp());

class RepairAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepairAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late CameraDescription firstCamera;
  String _videoUrl = '';

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    await _controller.initialize();
    setState(() {});
  }

  Future<void> fetchYouTubeLinks(String query) async {
    final apiKey = 'YOUR_YOUTUBE_API_KEY';
    final response = await http.get(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$query&key=$apiKey'
          as Uri,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final videoLinks = data['items']
          .map((item) =>
              'https://www.youtube.com/watch?v=${item['id']['videoId']}')
          .toList();
      setState(() {
        _videoUrl =
            videoLinks.isNotEmpty ? videoLinks.first : 'No videos found';
      });
    } else {
      throw Exception('Failed to load YouTube videos');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('RepairAI'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: CameraPreview(_controller),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final image = await _controller.takePicture();
                    // Yapay Zeka entegrasyonu ile burada image.path kullanarak analiz yapabilirsiniz
                    await fetchYouTubeLinks('how to repair ' +
                        'item'); // item yerine analiz sonucu yazılacak
                  } catch (e) {
                    print(e);
                  }
                },
                child: Text('Fotoğraf Çek ve Tamir Önerileri Al'),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Text(
                  _videoUrl.isNotEmpty
                      ? _videoUrl
                      : 'Tamir önerileri burada görünecek.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
