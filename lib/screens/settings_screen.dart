import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/co_pilot_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, String>> _models = [
    {
      "id": "google/gemini-2.0-flash-exp:free",
      "name": "Gemini 2.0 Flash (Fast / Recommended)",
      "desc": "Ultra-low latency calculation & fact retrieval."
    },
    {
      "id": "meta-llama/llama-3.3-70b-instruct:free",
      "name": "Llama 3.3 70B (High Reasoning)",
      "desc": "Highly reliable open weights model."
    },
    {
      "id": "anthropic/claude-3.5-sonnet",
      "name": "Claude 3.5 Sonnet (Premium Reasoning)",
      "desc": "Top-tier intelligence for complex business logic."
    },
    {
      "id": "deepseek/deepseek-r1",
      "name": "DeepSeek R1 (Deep Thinking)",
      "desc": "Thorough logic and chain-of-thought mathematical proofing."
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomSettings();
  }

  void _loadCustomSettings() {
    final coPilot = context.read<CoPilotService>();
    _apiKeyController.text = coPilot.openRouterKey;
  }

  Future<void> _saveCustomSettings() async {
    final coPilot = context.read<CoPilotService>();
    
    // Save locally
    await coPilot.updateSettings(
      key: _apiKeyController.text,
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tuning profiles saved successfully.")),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coPilot = context.watch<CoPilotService>();

    // Calculate dynamic/fallback pool and filter list based on search bar
    final pool = coPilot.dynamicModels.isNotEmpty ? coPilot.dynamicModels : _models;
    final searchQuery = _searchController.text.toLowerCase();
    final filteredPool = pool.where((m) {
      final name = m["name"]!.toLowerCase();
      final id = m["id"]!.toLowerCase();
      return name.contains(searchQuery) || id.contains(searchQuery);
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.deepSpaceBlue, AppTheme.obsidianBlack],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "System Co-Pilot Tuning",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0x1AFFFFFF), height: 1),
                const SizedBox(height: 16),

                // Settings List
                Expanded(
                  child: ListView(
                    children: [
                      // 1. OPENROUTER CONFIGURATION
                      Text(
                        "INTELLIGENCE ROUTING ACCESS",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "OpenRouter API Key(s)",
                          hintText: "sk-or-v1-key1, sk-or-v1-key2",
                          prefixIcon: Icon(Icons.key_rounded, color: AppTheme.primaryViolet),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Separate multiple API keys with commas. The system will automatically cycle through keys to juggle credits seamlessly on rates or limits!",
                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neuralGrey),
                      ),
                      const SizedBox(height: 24),

                      // 1.5 SPEECH DETECTION ENGINE
                      Text(
                        "SPEECH DETECTION ENGINE",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: AppTheme.glassDecoration(borderColor: Colors.white10),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: coPilot.sttProvider,
                            isExpanded: true,
                            dropdownColor: AppTheme.deepSpaceBlue,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                            items: ["Simulated", "WhisperFlow", "Local SDK"].map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val == "WhisperFlow" 
                                    ? "WhisperFlow (High-Fidelity Cloud STT)" 
                                    : val == "Local SDK" 
                                        ? "Local On-Device SDK (Fallback)" 
                                        : "Simulated Overlay (Testing)"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                coPilot.updateSettings(stt: val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. MODEL ROUTER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "DYNAMICAL MODEL SELECTION",
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryViolet,
                              letterSpacing: 2,
                            ),
                          ),
                          if (coPilot.openRouterKey.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                coPilot.fetchOpenRouterModels();
                              },
                              icon: const Icon(Icons.sync_rounded, size: 12, color: AppTheme.accentTeal),
                              label: Text(
                                "FETCH CATALOG",
                                style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.accentTeal, fontWeight: FontWeight.bold),
                              ),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            )
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Search Bar for models
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: "Filter through OpenRouter models...",
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.accentTeal),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      if (coPilot.isFetchingModels)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(color: AppTheme.accentTeal),
                          ),
                        )
                      else if (filteredPool.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassDecoration(borderColor: Colors.white10),
                          child: Center(
                            child: Text(
                              "No matching models found.",
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white30),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 250,
                          child: Container(
                            decoration: AppTheme.glassDecoration(borderColor: Colors.white10),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListView.builder(
                              itemCount: filteredPool.length,
                              itemBuilder: (context, index) {
                                final model = filteredPool[index];
                                final isSelected = coPilot.selectedModel == model["id"];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    model["name"]!,
                                    style: GoogleFonts.outfit(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                      color: isSelected ? AppTheme.accentTeal : Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    model["desc"]!,
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neuralGrey),
                                  ),
                                  leading: Radio<String>(
                                    value: model["id"]!,
                                    // ignore: deprecated_member_use
                                    groupValue: coPilot.selectedModel,
                                    activeColor: AppTheme.accentTeal,
                                    // ignore: deprecated_member_use
                                    onChanged: (val) {
                                      coPilot.updateSettings(model: val);
                                    },
                                  ),
                                  onTap: () {
                                    coPilot.updateSettings(model: model["id"]);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // 3. SENSITIVITY CONTROLLER
                      Text(
                        "SMART TRIGGER SENSITIVITY: ${(coPilot.sensitivity * 100).toInt()}%",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      Slider(
                        value: coPilot.sensitivity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: "${(coPilot.sensitivity * 100).toInt()}%",
                        onChanged: (val) {
                          coPilot.updateSettings(sens: val);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Silent (Trigger only solid math)", style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.neuralGrey)),
                          Text("Talkative", style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.neuralGrey)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 4. SERVERLESS INFORMATION CARD
                      Text(
                        "COGNITIVE ARCHITECTURE STATUS",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassDecoration(borderColor: AppTheme.accentTeal.withValues(alpha: 0.3)),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done_rounded, color: AppTheme.accentTeal, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Serverless On-Device Mode Active",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "No separate backend servers required. Calculation solvers, trigger matched loops, and user profiles operate 100% on-device.",
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neuralGrey),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Save Changes Pill
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ElevatedButton(
                    onPressed: _saveCustomSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("APPLY & SAVE TUNING PROFILE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
