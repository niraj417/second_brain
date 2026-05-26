import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'trigger_detector.dart';
import 'memory_manager.dart';
import 'task_router.dart';

class CoPilotService extends ChangeNotifier {
  // Core Local Engines
  final TriggerDetector _detector = TriggerDetector();
  final MemoryManager _memoryManager = MemoryManager();
  final TaskRouter _router = TaskRouter();

  // State Variables
  bool _isConnected = true; // Always active in direct serverless API mode!
  String _statusMessage = "Cognitive assistance ready.";
  
  final List<Map<String, dynamic>> _interventions = [];
  final List<String> _transcripts = [];
  
  // Persistent Settings
  String _openRouterKey = "";
  String _selectedModel = "google/gemini-2.0-flash-exp:free";
  double _sensitivity = 0.5;
  String _sttProvider = "Simulated";
  
  bool _isListening = false;
  
  // Dynamic OpenRouter Model Pools
  List<Map<String, String>> _dynamicModels = [];
  bool _isFetchingModels = false;
  
  // Getters
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  List<Map<String, dynamic>> get interventions => _interventions;
  List<String> get transcripts => _transcripts;
  String get openRouterKey => _openRouterKey;
  String get selectedModel => _selectedModel;
  double get sensitivity => _sensitivity;
  String get sttProvider => _sttProvider;
  bool get isListening => _isListening;
  
  List<Map<String, String>> get dynamicModels => _dynamicModels;
  bool get isFetchingModels => _isFetchingModels;
  
  // Access memory profile directly
  Map<String, dynamic> get memoryProfile => _memoryManager.memoryProfile;

  CoPilotService() {
    _initService();
  }

  Future<void> _initService() async {
    // 1. Boot up memory registry
    await _memoryManager.loadMemory();
    
    // 2. Load configurations
    final prefs = await SharedPreferences.getInstance();
    _openRouterKey = prefs.getString("openrouter_key") ?? "";
    _selectedModel = prefs.getString("selected_model") ?? "google/gemini-2.0-flash-exp:free";
    _sensitivity = prefs.getDouble("sensitivity") ?? 0.5;
    _sttProvider = prefs.getString("stt_provider") ?? "Simulated";
    
    _statusMessage = "Neural Link Active (Serverless Mode)";
    notifyListeners();

    if (_openRouterKey.isNotEmpty) {
      fetchOpenRouterModels();
    }
  }

  Future<void> fetchOpenRouterModels() async {
    if (_openRouterKey.isEmpty) return;
    
    _isFetchingModels = true;
    _statusMessage = "Fetching latest OpenRouter model catalogs...";
    notifyListeners();

    try {
      final firstKey = _openRouterKey.split(",").first.trim();
      final url = Uri.parse("https://openrouter.ai/api/v1/models");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $firstKey",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey("data")) {
          final List data = body["data"];
          _dynamicModels = data.map<Map<String, String>>((m) {
            final id = m["id"]?.toString() ?? "";
            final name = m["name"]?.toString() ?? id;
            final promptVal = m["pricing"]?["prompt"] ?? "0";
            final compVal = m["pricing"]?["completion"] ?? "0";
            
            double promptPrice = double.tryParse(promptVal.toString()) ?? 0.0;
            double compPrice = double.tryParse(compVal.toString()) ?? 0.0;
            
            String priceStr = promptPrice == 0 && compPrice == 0
                ? "Free Tier Model"
                : "Prompt: \$${(promptPrice * 1000000).toStringAsFixed(2)}/M • Completion: \$${(compPrice * 1000000).toStringAsFixed(2)}/M";

            return {
              "id": id,
              "name": name,
              "desc": priceStr,
            };
          }).toList();

          // Sort so free models appear at the top
          _dynamicModels.sort((a, b) {
            final aFree = a["desc"]!.contains("Free");
            final bFree = b["desc"]!.contains("Free");
            if (aFree && !bFree) return -1;
            if (!aFree && bFree) return 1;
            return a["name"]!.toLowerCase().compareTo(b["name"]!.toLowerCase());
          });
          
          _statusMessage = "Loaded ${_dynamicModels.length} models directly from OpenRouter.";
        }
      } else {
        _statusMessage = "OpenRouter catalog retrieval error: Status ${response.statusCode}";
      }
    } catch (e) {
      _statusMessage = "Offline Catalog: Dynamic OpenRouter list loading bypassed.";
    } finally {
      _isFetchingModels = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings({
    String? key,
    String? model,
    double? sens,
    String? stt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool keyChanged = false;
    
    if (key != null) {
      keyChanged = _openRouterKey != key;
      _openRouterKey = key;
      await prefs.setString("openrouter_key", key);
    }
    if (model != null) {
      _selectedModel = model;
      await prefs.setString("selected_model", model);
    }
    if (sens != null) {
      _sensitivity = sens;
      await prefs.setDouble("sensitivity", sens);
    }
    if (stt != null) {
      _sttProvider = stt;
      await prefs.setString("stt_provider", stt);
    }
    
    notifyListeners();

    if (keyChanged && _openRouterKey.isNotEmpty) {
      fetchOpenRouterModels();
    }
  }

  void toggleListening() {
    _isListening = !_isListening;
    if (_isListening) {
      _statusMessage = "Continuous overlay active...";
    } else {
      _statusMessage = "Cognitive assistance paused.";
    }
    notifyListeners();
  }

  // Receives transcript segments directly from mic / simulation pad
  Future<void> sendTranscript(String text) async {
    if (text.trim().isEmpty) return;

    _transcripts.add(text);
    if (_transcripts.length > 50) _transcripts.removeAt(0);
    notifyListeners();

    if (!_isListening) return;

    // 1. Scan transcript locally on-device for triggers
    final analysis = _detector.analyze(text);
    
    // Sensitivity threshold mapping
    final double threshold = 0.9 - (_sensitivity * 0.6);

    if (analysis.shouldRespond && analysis.confidence >= threshold) {
      _statusMessage = "Whisper co-pilot triggered...";
      notifyListeners();

      // 2. Retrieve local memory context
      final context = _memoryManager.retrieveContext(text);

      // 3. Directly solve via OpenRouter with key cycling or local mock fallback
      final result = await _router.routeAndSolve(
        query: text,
        triggerType: analysis.triggerType,
        apiKeyPool: _openRouterKey,
        customModel: _selectedModel,
        memoryContext: context,
      );

      if (result.success) {
        // 4. Update the on-device memory profile based on this transaction
        await _memoryManager.learnFromInteraction(text, result.response);

        // Add the whisper intervention
        _interventions.add({
          "trigger_type": analysis.triggerType,
          "confidence": analysis.confidence,
          "query": text,
          "response": result.response,
          "model": result.modelUsed,
          "latency": result.latency,
          "timestamp": DateTime.now().toLocal().toString().substring(11, 16)
        });
        
        if (_interventions.length > 50) _interventions.removeAt(0);
        _statusMessage = "Whisper delivered to TWS.";
      } else {
        _statusMessage = "API Exception: Key depleted.";
        _interventions.add({
          "trigger_type": "Juggling Error",
          "confidence": 0.0,
          "query": text,
          "response": result.response,
          "model": result.modelUsed,
          "latency": result.latency,
          "timestamp": DateTime.now().toLocal().toString().substring(11, 16)
        });
      }
    } else {
      // Smart Silence logs greeting segment
      _statusMessage = "Smart Silence: Everyday chatter filtered on-device.";
    }
    notifyListeners();
  }

  Future<void> deleteFact(int factId) async {
    final success = await _memoryManager.deleteFact(factId);
    if (success) {
      notifyListeners();
    }
  }

  Future<void> clearAllMemory() async {
    await _memoryManager.clearAll();
    notifyListeners();
  }

  void clearInterventions() {
    _interventions.clear();
    notifyListeners();
  }
}
