import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
flimport 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(RepairAIApp(camera: firstCamera));
}

class RepairAIApp extends StatelessWidget {
  final CameraDescription camera;

  RepairAIApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepairAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(camera: camera),
    );
  }
}

class HomePage extends StatefulWidget {
  final CameraDescription camera;

  HomePage({required this.camera});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String _videoUrl = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> fetchYouTubeLinks(String query) async {
    final apiKey = 'AIzaSyD7tJLEs6Et5jagyn5EZWZEVLZNDDKrse4';
    final response = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$query&key=$apiKey'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('RepairAI'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();

                    setState(() {
                      _isProcessing = true;
                    });

                    // Yapay Zeka entegrasyonu ile burada image.path kullanarak analiz yapabilirsiniz
                    await fetchYouTubeLinks(
                        'how to repair item'); // item yerine analiz sonucu yazılacak

                    setState(() {
                      _isProcessing = false;
                    });
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
              child: _isProcessing
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
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
