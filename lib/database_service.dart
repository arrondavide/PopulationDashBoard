import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSegments(String segmentType) async {
    final response = await _supabase
        .from('Segments')
        .select()
        .eq('segment_type', segmentType);
    return response;
  }

  Future<void> addSegment(Map<String, dynamic> segmentData) async {
    await _supabase.from('Segments').insert(segmentData);
  }

  Future<void> updateSegment(
      int segmentId, Map<String, dynamic> segmentData) async {
    await _supabase
        .from('Segments')
        .update(segmentData)
        .eq('segment_id', segmentId);
  }

  // Add more methods for other CRUD operations and tables as needed
}
