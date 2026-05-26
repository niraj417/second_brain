import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryManager {
  final String _prefKey = "second_brain_local_memory";
  
  Map<String, dynamic> _memory = {
    "business_profile": {
      "business_type": "Unknown",
      "pricing_structure": {},
      "lead_history": [],
      "recurring_clients": [],
      "recurring_metrics": <String, dynamic>{}
    },
    "user_preferences": {
      "preferred_language": "Hinglish",
      "speaking_style": "Super concise",
      "commonly_discussed_topics": []
    },
    "extracted_facts": [] // list of {"id": int, "fact": str, "keywords": list}
  };

  Map<String, dynamic> get memoryProfile => _memory;

  Future<void> loadMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKey);
      if (savedJson != null) {
        final Map<String, dynamic> loaded = jsonDecode(savedJson);
        // Safely merge values into template schema
        for (var key in _memory.keys) {
          if (loaded.containsKey(key)) {
            if (_memory[key] is Map && loaded[key] is Map) {
              (_memory[key] as Map).addAll(loaded[key]);
            } else {
              _memory[key] = loaded[key];
            }
          }
        }
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> saveMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_memory));
    } catch (e) {
      //
    }
  }

  List<String> _extractKeywords(String text) {
    final stopWords = {
      "is", "the", "a", "an", "and", "or", "but", "to", "for", "in", "on", "at", 
      "hai", "kitna", "kya", "toh", "ko", "ke", "liye", "hua", "eta", "koto", "holo"
    };
    final regex = RegExp(r"\b[a-zA-Z0-9\-\u0900-\u097F\u0980-\u09FF]+\b");
    final List<String> words = regex.allMatches(text.toLowerCase()).map((m) => m.group(0)!).toList();
    
    return words
        .where((w) => !stopWords.contains(w) && w.length > 2)
        .toSet()
        .toList();
  }

  Future<void> learnFromInteraction(String query, String response) async {
    final queryClean = query.toLowerCase();
    
    // 1. Detect lead costs / conversions using keyword proximity
    final numberMatches = RegExp(r'\b\d+\b').allMatches(queryClean).map((m) => int.parse(m.group(0)!)).toList();
    if (numberMatches.length >= 2) {
      bool hasLeads = queryClean.contains(RegExp(r'\b(lead|leads)\b'));
      bool hasMoney = queryClean.contains(RegExp(r'\b(rupee|rupees|rs|kharcha|cost|expens|spent|taka)\b'));
      
      if (hasLeads && hasMoney) {
        final num1 = numberMatches[0];
        final num2 = numberMatches[1];
        
        final leadIdx = queryClean.indexOf("lead");
        final dist1 = (queryClean.indexOf(num1.toString()) - leadIdx).abs();
        final dist2 = (queryClean.indexOf(num2.toString()) - leadIdx).abs();
        
        final leads = dist1 < dist2 ? num1 : num2;
        final cost = leads == num1 ? num2 : num1;
        
        if (leads > 0) {
          final double cpl = double.parse((cost / leads).toStringAsFixed(2));
          
          final List history = _memory["business_profile"]["lead_history"] ?? [];
          history.add({
            "leads": leads,
            "total_cost": cost,
            "cost_per_lead": cpl
          });
          _memory["business_profile"]["lead_history"] = history;
          
          final Map<String, dynamic> recMetrics = Map<String, dynamic>.from(_memory["business_profile"]["recurring_metrics"] ?? {});
          recMetrics["last_calculated_cpl"] = "₹$cpl";
          _memory["business_profile"]["recurring_metrics"] = recMetrics;
          
          await addExtractedFact("Calculated lead cost: $leads leads for ₹$cost (CPL: ₹$cpl)");
        }
      }
    }

    // 2. GST Calculations
    final gstMatch = RegExp(r'(\d+)\s*%\s*gst|gst\s*(\d+)\s*%').firstMatch(queryClean);
    if (gstMatch != null) {
      final rate = gstMatch.group(1) ?? gstMatch.group(2) ?? "18";
      final Map<String, dynamic> recMetrics = Map<String, dynamic>.from(_memory["business_profile"]["recurring_metrics"] ?? {});
      recMetrics["common_gst_rate"] = "$rate%";
      _memory["business_profile"]["recurring_metrics"] = recMetrics;
      await addExtractedFact("User frequently calculates GST at $rate%");
    }

    // 3. Client references
    final clientMatch = RegExp(r'\b(?:client|customer|party)\s+([a-zA-Z\s]+)\b').firstMatch(queryClean);
    if (clientMatch != null) {
      final clientName = clientMatch.group(1)!.trim();
      final List clients = _memory["business_profile"]["recurring_clients"] ?? [];
      if (!clients.contains(clientName)) {
        clients.add(clientName);
        _memory["business_profile"]["recurring_clients"] = clients;
        await addExtractedFact("Interacted with client/party: $clientName");
      }
    }

    // 4. Topics detection
    if (queryClean.contains("llp") || queryClean.contains("filing")) {
      final List topics = _memory["user_preferences"]["commonly_discussed_topics"] ?? [];
      if (!topics.contains("LLP & Corporate Filings")) {
        topics.add("LLP & Corporate Filings");
        _memory["user_preferences"]["commonly_discussed_topics"] = topics;
      }
    }

    // 5. Preferred language tracking
    if (["kitna", "kya", "hua", "sab", "toh", "pada"].any((h) => queryClean.contains(h))) {
      _memory["user_preferences"]["preferred_language"] = "Hinglish";
    } else if (["koto", "holo", "khoroch", "ache", "bhalo"].any((b) => queryClean.contains(b))) {
      _memory["user_preferences"]["preferred_language"] = "Benglish (Bengali-English)";
    }

    await saveMemory();
  }

  Future<void> addExtractedFact(String fact) async {
    final List factsList = _memory["extracted_facts"] ?? [];
    
    // Check duplicates
    for (var item in factsList) {
      if (item["fact"].toString().toLowerCase() == fact.toLowerCase()) {
        return;
      }
    }

    final int factId = factsList.length + 1;
    final keywords = _extractKeywords(fact);
    factsList.add({
      "id": factId,
      "fact": fact,
      "keywords": keywords
    });
    
    _memory["extracted_facts"] = factsList;
    await saveMemory();
  }

  String retrieveContext(String query) {
    final queryKeywords = _extractKeywords(query);
    if (queryKeywords.isEmpty) return "";

    final List factsList = _memory["extracted_facts"] ?? [];
    final List<Map<String, dynamic>> matches = [];
    
    for (var item in factsList) {
      final itemKeywords = List<String>.from(item["keywords"] ?? []);
      final overlap = queryKeywords.where((k) => itemKeywords.contains(k)).toList();
      if (overlap.isNotEmpty) {
        matches.add({
          "overlapCount": overlap.length,
          "fact": item["fact"]
        });
      }
    }

    // Sort by overlapCount descending
    matches.sort((a, b) => (b["overlapCount"] as int).compareTo(a["overlapCount"] as int));
    final topMatches = matches.take(3).map((m) => m["fact"].toString()).toList();

    final Map<String, dynamic> businessProfile = _memory["business_profile"] ?? {};
    final Map recMetrics = businessProfile["recurring_metrics"] ?? {};
    final List clients = businessProfile["recurring_clients"] ?? [];
    
    final List<String> contextParts = [];
    if (topMatches.isNotEmpty) {
      contextParts.add("Relevant memories:\n${topMatches.map((f) => "- $f").join("\n")}");
    }

    final List<String> profileParts = [];
    if (recMetrics.isNotEmpty) {
      profileParts.add(recMetrics.entries.map((e) => "${e.key}: ${e.value}").join(", "));
    }
    if (clients.isNotEmpty) {
      profileParts.add("Clients: ${clients.join(', ')}");
    }

    if (profileParts.isNotEmpty) {
      contextParts.add("Business Stats Context: ${profileParts.join("; ")}");
    }

    return contextParts.isNotEmpty ? contextParts.join("\n\n") : "";
  }

  Future<bool> deleteFact(int factId) async {
    final List factsList = _memory["extracted_facts"] ?? [];
    final originalLen = factsList.length;
    
    factsList.removeWhere((f) => f["id"] == factId);
    
    if (factsList.length < originalLen) {
      _memory["extracted_facts"] = factsList;
      await saveMemory();
      return true;
    }
    return false;
  }

  Future<void> clearAll() async {
    _memory = {
      "business_profile": {
        "business_type": "Unknown",
        "pricing_structure": {},
        "lead_history": [],
        "recurring_clients": [],
        "recurring_metrics": <String, dynamic>{}
      },
      "user_preferences": {
        "preferred_language": "Hinglish",
        "speaking_style": "Super concise",
        "commonly_discussed_topics": []
      },
      "extracted_facts": []
    };
    await saveMemory();
  }
}
