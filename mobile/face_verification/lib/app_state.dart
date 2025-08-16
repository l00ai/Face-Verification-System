import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class AppState extends ChangeNotifier {
  File? _idImage;
  File? _selfieImage;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  File? get idImage => _idImage;
  File? get selfieImage => _selfieImage;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get result => _result;

  void setIdImage(File image) {
    _idImage = image;
    notifyListeners();
  }

  void setSelfieImage(File image) {
    _selfieImage = image;
    notifyListeners();
  }

  Future<void> verifyFaces() async {
    if (_idImage == null || _selfieImage == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // API call implementation
      final uploadUrl = "http://192.236.162.28:5050/verify-face";

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add image file
      var id_card = await http.MultipartFile.fromPath(
        'id_card',  // Field name on server
        _idImage!.path,
        filename: basename(_idImage!.path),
      );


      var selfie = await http.MultipartFile.fromPath(
        'selfie',  // Field name on server
        _selfieImage!.path,
        filename: basename(_selfieImage!.path),
      );

      request.files.add(id_card);
      request.files.add(selfie);

      var response = await request.send();

      // Get response
      if (response.statusCode == 200) {
        print('Uploaded!');
        final responseData = await response.stream.bytesToString();
        log("----------");
        log(responseData);
        log("----------");
        _result = jsonDecode(responseData);
      } else {
        print('Upload failed with status: ${response.statusCode}');
      }

    } catch (e) {
      log(e.toString());
      _isLoading = false;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _idImage = null;
    _selfieImage = null;
    _result = null;
    notifyListeners();
  }
}