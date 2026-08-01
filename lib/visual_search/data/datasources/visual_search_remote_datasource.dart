import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hopscotch/api/api_service.dart';

class VisualSearchRemoteDataSource {
  final ApiService _apiService;
  
  VisualSearchRemoteDataSource(this._apiService);
  
  /// Upload image using multipart/form-data and perform AI Visual Search
  Future<Map<String, dynamic>> searchWithImage(File imageFile) async {
    print('[VISUAL_SEARCH] 📸 Uploading image for AI Visual Search...');
    print('[VISUAL_SEARCH] 📸 Path: ${imageFile.path}');
    print('[VISUAL_SEARCH] 📸 Size: ${await imageFile.length()} bytes');
    
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      print('[VISUAL_SEARCH] 🌐 Calling backend endpoint: /api/v1/mobile/search/visual');
      final apiStartTime = DateTime.now();
      
      final response = await _apiService.post(
        '/api/v1/mobile/search/visual',
        data: formData,
      );
      
      final apiTime = DateTime.now().difference(apiStartTime).inMilliseconds;
      print('[VISUAL_SEARCH] ⏱️ API call completed in ${apiTime}ms');
      print('[VISUAL_SEARCH] 📊 Status code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data as Map<String, dynamic>;
        final data = (body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>
            : body;

        print('[VISUAL_SEARCH] ✅ Visual search successful');
        print('[VISUAL_SEARCH] 📦 Exact matches: ${data['exactMatches']?.length ?? 0}');
        print('[VISUAL_SEARCH] 📦 Similar matches: ${data['similarMatches']?.length ?? 0}');
        print('[VISUAL_SEARCH] 🏷️ Attributes: ${data['extractedAttributes']}');
        
        return data;
      } else {
        print('[VISUAL_SEARCH] ❌ API returned non-200 status: ${response.statusCode}');
        throw Exception('Failed to perform visual search (HTTP ${response.statusCode})');
      }
    } on DioException catch (e) {
      print('[VISUAL_SEARCH] ❌ DioException: ${e.message}');
      print('[VISUAL_SEARCH] ❌ Response: ${e.response?.data}');
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network failure during visual search';
      throw Exception(msg);
    } catch (e) {
      print('[VISUAL_SEARCH] ❌ Error during visual search: $e');
      throw Exception('Visual search failed: $e');
    }
  }
  
  /// Get visual search query by ID
  Future<Map<String, dynamic>> getQuery(String queryId) async {
    try {
      final response = await _apiService.get('/api/visual-search/$queryId');
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        return (body['data'] as Map<String, dynamic>?) ?? body;
      }
      throw Exception('Failed to get query');
    } catch (e) {
      throw Exception('Error getting query: $e');
    }
  }
  
  /// Get visual search history
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _apiService.get('/api/visual-search/history');
      if (response.statusCode == 200) {
        final body = response.data;
        final list = (body is Map && body['data'] is List) ? body['data'] as List : (body as List);
        return list.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to get history');
    } catch (e) {
      throw Exception('Error getting history: $e');
    }
  }
  
  /// Delete visual search query
  Future<void> deleteQuery(String queryId) async {
    try {
      await _apiService.delete('/api/visual-search/$queryId');
    } catch (e) {
      throw Exception('Error deleting query: $e');
    }
  }
}
