import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'face_capture_screen.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildImageSection('ID Photo', context, true),
            const SizedBox(height: 30),
            _buildImageSection('Selfie Photo', context, false),
            const SizedBox(height: 40),
            _buildVerifyButton(context),
            const SizedBox(height: 30),
            _buildResultSection(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String title, BuildContext context, bool isId) {
    final appState = Provider.of<AppState>(context);
    final imageFile = isId ? appState.idImage : appState.selfieImage;

    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: imageFile == null
              ? const Center(child: Icon(Icons.photo, size: 50))
              : Image.file(imageFile, fit: BoxFit.cover),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImageButton(Icons.camera_alt, 'Camera', isId, true, context),
            const SizedBox(width: 10),
            _buildImageButton(Icons.photo_library, 'Gallery', isId, false, context),
          ],
        ),
      ],
    );
  }

  Widget _buildImageButton(IconData icon, String label, bool isId, bool isCamera, BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () => _pickImage(isId, isCamera, context),
    );
  }

  Future<void> _pickImage(bool isId, bool isCamera, BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if(isId) {
      final source = isCamera ? ImageSource.camera : ImageSource.gallery;
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked != null) {
        appState.setIdImage(File(picked.path));
      }
    }else{
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => FaceDetectionScreen()));
      if(result != null){
        appState.setSelfieImage(File(result));
      }
    }
  }

  Widget _buildVerifyButton(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return appState.isLoading
        ? const CircularProgressIndicator()
        : SizedBox(
        width: double.infinity,
        child: ElevatedButton(
        style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    onPressed: appState.idImage == null || appState.selfieImage == null
    ? null
        : () => appState.verifyFaces(),
    child: const Text('VERIFY FACES', style: TextStyle(fontSize: 18)),
    ),);
  }

  Widget _buildResultSection(BuildContext context) {
    final result = Provider.of<AppState>(context).result;
    if (result == null) return Container();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: result['verified'] ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            result['verified'] ? '✅ VERIFIED' : '❌ NOT VERIFIED',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: result['verified'] ? Colors.green : Colors.red),
          ),
          const SizedBox(height: 15),
          Text('Similarity: ${result['similarity']?.toStringAsFixed(2) ?? 'N/A'}%',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          if (result['distance'] != null)
            Text('Distance: ${result['distance']?.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: Provider.of<AppState>(context, listen: false).reset,
            child: const Text('NEW VERIFICATION'),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}