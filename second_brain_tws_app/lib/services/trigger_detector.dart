import 'dart:math';

class TriggerResult {
  final bool shouldRespond;
  final String triggerType;
  final double confidence;
  final String extractedQuery;

  TriggerResult({
    required this.shouldRespond,
    required this.triggerType,
    required this.confidence,
    required this.extractedQuery,
  });
}

class TriggerDetector {
  // Math & Calculation Regex Patterns (Eng, Hindi, Beng, Hinglish)
  final List<RegExp> _mathPatterns = [
    RegExp(r'\b(plus|minus|multiplied|divided|times|into|divided by|percentage|percent|gst|tax|interest|margin|profit|loss)\b', caseSensitive: false),
    RegExp(r'\b(jama|ghata|guna|bhaag|pratishat|munafa|nuksan|faida|ghata)\b', caseSensitive: false),
    RegExp(r'\b(jog|biyog|gun|bhag|shothkorashotkora|labh|khoti|lokshan)\b', caseSensitive: false),
    RegExp(r'\b(leads?|cr|lakhs?|rupees?|rs|kharcha|cost|expenses?|revenue|margin|pricing|invoice|billing|filings?|gst|total)\b', caseSensitive: false),
    RegExp(r'\b(taka|khoroch|hisab|leads?|total|monthly|monthly total|hisab)\b', caseSensitive: false),
    RegExp(r'\b\d+\s*(plus|minus|into|times|\+|\-|\*|\/|divided|multiply|divided by|divided)\s*\d+\b', caseSensitive: false),
    RegExp(r'\b\d+\s*leads?\s*(\bke\s*liye\b|\bfor\b|\bte\b)\b', caseSensitive: false),
    RegExp(r'\b(gst|percentage|percent|margin)\b\s*(\bkitna\b|\bhow\s*much\b|\bkateto\b)\b', caseSensitive: false)
  ];

  // Factual & Informational Regex Patterns (Who, What, Where, Population, etc.)
  final List<RegExp> _factualPatterns = [
    RegExp(r'\b(population|capital|gdp|founder|ceo|president|prime minister|governor|hq|headquarters|area|distance|speed|size|height)\b', caseSensitive: false),
    RegExp(r'\b(abadi|jansankhya|rajdhani|sthapna|malik|bazar|market cap|founder|population)\b', caseSensitive: false),
    RegExp(r'\b(jonoshonkhya|rajdhani|malik|founder|gdp)\b', caseSensitive: false),
    RegExp(r'\b(who is|what is|where is|how many|how much|kitna hai|kitna hota hai|koto|koto ache|koto holo)\b', caseSensitive: false)
  ];

  // Comparison Patterns
  final List<RegExp> _comparisonPatterns = [
    RegExp(r'\b(compare|versus|vs|better than|cheaper|expensive|difference between|farther|closer|larger|smaller)\b', caseSensitive: false),
    RegExp(r'\b(tulna|farq|bhalo|shosta|dami|beshi|kom|tufan)\b', caseSensitive: false)
  ];

  // Greetings / Casual chit chat filter
  final List<RegExp> _noisePatterns = [
    RegExp(r'\b(hello|hi|hey|good morning|how are you|whats up|chal chai peete|haan haan|chalo chalo|thik hai|thik ache|okay|yes|no|bye|see you|good night)\b', caseSensitive: false)
  ];

  TriggerResult analyze(String text) {
    final textClean = text.toLowerCase().trim();
    if (textClean.isEmpty) {
      return TriggerResult(shouldRespond: false, triggerType: "none", confidence: 0.0, extractedQuery: "");
    }

    // Digit count
    final digitMatches = RegExp(r'\b\d+\b').allMatches(textClean);
    final digitCount = digitMatches.length;

    // Check Math/Calculation
    int mathMatches = 0;
    for (var pattern in _mathPatterns) {
      if (pattern.hasMatch(textClean)) {
        mathMatches++;
      }
    }

    // Check Facts
    int factMatches = 0;
    for (var pattern in _factualPatterns) {
      if (pattern.hasMatch(textClean)) {
        factMatches++;
      }
    }

    // Check Comparisons
    int compMatches = 0;
    for (var pattern in _comparisonPatterns) {
      if (pattern.hasMatch(textClean)) {
        compMatches++;
      }
    }

    bool shouldRespond = false;
    String triggerType = "none";
    double confidence = 0.0;

    if ((mathMatches > 0 && digitCount >= 1) || (mathMatches >= 2)) {
      shouldRespond = true;
      triggerType = "math";
      confidence = min(0.6 + (0.1 * mathMatches) + (0.1 * digitCount), 1.0);
    } else if (factMatches > 0) {
      shouldRespond = true;
      triggerType = "fact";
      confidence = min(0.55 + (0.15 * factMatches), 1.0);
    } else if (compMatches > 0) {
      shouldRespond = true;
      triggerType = "comparison";
      confidence = min(0.5 + (0.2 * compMatches), 1.0);
    }

    // Smart Silence Ignore greetings unless accompanied by math/facts
    if (shouldRespond) {
      int noiseMatches = 0;
      for (var pattern in _noisePatterns) {
        if (pattern.hasMatch(textClean)) {
          noiseMatches++;
        }
      }
      if (noiseMatches > 1 && mathMatches == 0 && factMatches == 0) {
        shouldRespond = false;
        triggerType = "none";
        confidence = 0.1;
      }
    }

    return TriggerResult(
      shouldRespond: shouldRespond,
      triggerType: triggerType,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      extractedQuery: shouldRespond ? text.trim() : "",
    );
  }
}
