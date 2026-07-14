import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hopscotch/api/api_service.dart';

class VisualSearchRemoteDataSource {
  final ApiService _apiService;
  
  VisualSearchRemoteDataSource(this._apiService);
  
  /// Upload image and perform visual search
  Future<Map<String, dynamic>> searchWithImage(File imageFile) async {
    print('[VISUAL_SEARCH] 📸 Starting visual search with image...');
    print('[VISUAL_SEARCH] 📸 Image path: ${imageFile.path}');
    print('[VISUAL_SEARCH] 📸 Image size: ${await imageFile.length()} bytes');
    
    try {
      // Convert image to base64
      final startTime = DateTime.now();
      print('[VISUAL_SEARCH] 🔄 Converting image to base64...');
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${const Base64Encoder().convert(imageBytes)}';
      final conversionTime = DateTime.now().difference(startTime).inMilliseconds;
      print('[VISUAL_SEARCH] ✅ Base64 conversion completed in ${conversionTime}ms');
      print('[VISUAL_SEARCH] 📏 Base64 length: ${base64Image.length} characters');
      
      print('[VISUAL_SEARCH] 🌐 Calling backend API: /api/visual-search/search');
      final apiStartTime = DateTime.now();
      
      final response = await _apiService.post(
        '/api/visual-search/search',
        data: {
          'imageUrl': base64Image,
        },
      );
      
      final apiTime = DateTime.now().difference(apiStartTime).inMilliseconds;
      print('[VISUAL_SEARCH] ⏱️ API call completed in ${apiTime}ms');
      print('[VISUAL_SEARCH] 📊 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('[VISUAL_SEARCH] ✅ Search successful');
        print('[VISUAL_SEARCH] 📦 Match count: ${data['matches']?.length ?? 0}');
        print('[VISUAL_SEARCH] 📦 Similar suggestions: ${data['similarSuggestions']?.length ?? 0}');
        print('[VISUAL_SEARCH] 📊 Confidence: ${data['confidence']}');
        print('[VISUAL_SEARCH] 🏷️ Extracted data: ${data['extractedData']}');
        return data;
      } else {
        print('[VISUAL_SEARCH] ❌ API returned non-200 status: ${response.statusCode}');
        throw Exception('Failed to perform visual search: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[VISUAL_SEARCH] ❌ DioException: ${e.message}');
      print('[VISUAL_SEARCH] ❌ Error type: ${e.type}');
      print('[VISUAL_SEARCH] ❌ Error response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('[VISUAL_SEARCH] ❌ Unexpected error: $e');
      throw Exception('Error during visual search: $e');
    }
  }
  
  /// Get visual search query by ID
  Future<Map<String, dynamic>> getQuery(String queryId) async {
    print('[VISUAL_SEARCH] 🔍 Fetching query details for queryId: $queryId');
    
    try {
      final response = await _apiService.get('/api/visual-search/query/$queryId');
      
      if (response.statusCode == 200) {
        print('[VISUAL_SEARCH] ✅ Query retrieved successfully');
        return response.data as Map<String, dynamic>;
      } else {
        print('[VISUAL_SEARCH] ❌ Failed to get query: ${response.statusCode}');
        throw Exception('Failed to get query: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[VISUAL_SEARCH] ❌ Network error getting query: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('[VISUAL_SEARCH] ❌ Error getting query: $e');
      throw Exception('Error getting query: $e');
    }
  }
  
  /// Get visual search history
  Future<List<Map<String, dynamic>>> getHistory() async {
    print('[VISUAL_SEARCH] 📜 Fetching visual search history');
    
    try {
      final response = await _apiService.get('/api/visual-search/history');
      
      if (response.statusCode == 200) {
        final history = (response.data as List).cast<Map<String, dynamic>>();
        print('[VISUAL_SEARCH] ✅ History retrieved: ${history.length} records');
        return history;
      } else {
        print('[VISUAL_SEARCH] ❌ Failed to get history: ${response.statusCode}');
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[VISUAL_SEARCH] ❌ Network error getting history: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('[VISUAL_SEARCH] ❌ Error getting history: $e');
      throw Exception('Error getting history: $e');
    }
  }
  
  /// Delete visual search query
  Future<void> deleteQuery(String queryId) async {
    print('[VISUAL_SEARCH] 🗑️ Deleting query: $queryId');
    
    try {
      final response = await _apiService.delete('/api/visual-search/query/$queryId');
      
      if (response.statusCode == 200) {
        print('[VISUAL_SEARCH] ✅ Query deleted successfully');
      } else {
        print('[VISUAL_SEARCH] ❌ Failed to delete query: ${response.statusCode}');
        throw Exception('Failed to delete query: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[VISUAL_SEARCH] ❌ Network error deleting query: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('[VISUAL_SEARCH] ❌ Error deleting query: $e');
      throw Exception('Error deleting query: $e');
    }
  }
}
