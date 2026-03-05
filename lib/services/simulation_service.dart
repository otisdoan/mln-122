import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/simulation_model.dart';

class SimulationService {
  static final _client = Supabase.instance.client;

  static Future<SimulationModel?> getLatest(String userId) async {
    final data = await _client
        .from('simulations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return SimulationModel.fromJson(data);
  }

  static Future<SimulationModel> save(SimulationModel sim) async {
    final data = await _client
        .from('simulations')
        .insert(sim.toJson())
        .select()
        .single();
    return SimulationModel.fromJson(data);
  }

  static Future<void> update(SimulationModel sim) async {
    await _client.from('simulations').update(sim.toJson()).eq('id', sim.id);
  }

  static Future<List<SimulationModel>> getHistory(String userId) async {
    final data = await _client
        .from('simulations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return (data as List).map((e) => SimulationModel.fromJson(e)).toList();
  }
}
