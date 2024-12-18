import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FileBrowser(),
    );
  }
}

class FileBrowser extends StatefulWidget {
  const FileBrowser({super.key});

  @override
  _FileBrowserState createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  List<FileSystemEntity> _files = [];
  final String _path = '/storage/emulated/0/MIUI/sound_recorder/call_rec';
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadFiles();
  }

  Future<void> _requestPermissionAndLoadFiles() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      _loadFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required')),
      );
    }
  }

  void _loadFiles() {
    try {
      Directory directory = Directory(_path);
      List<FileSystemEntity> files = directory
          .listSync()
          .where((file) => file.path.endsWith('.mp3'))
          .toList();
      setState(() {
        _files = files;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _playAudio(String filePath) async {
    if (_isPlaying && _currentlyPlaying == filePath) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.stop(); // Stop any currently playing audio
      await _audioPlayer.play(DeviceFileSource(filePath));
      setState(() {
        _isPlaying = true;
        _currentlyPlaying = filePath;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Player')),
      body: _files.isEmpty
          ? const Center(child: Text('No MP3 files found'))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                FileSystemEntity file = _files[index];
                String fileName = file.path.split('/').last;
                return ListTile(
                  title: Text(fileName),
                  subtitle: Text(file.path),
                  leading: Icon(
                    Icons.audiotrack,
                    color: _isPlaying && _currentlyPlaying == file.path
                        ? Colors.green
                        : Colors.grey,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _isPlaying && _currentlyPlaying == file.path
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () => _playAudio(file.path),
                  ),
                );
              },
            ),
    );
  }
}
