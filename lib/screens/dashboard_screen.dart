import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/co_pilot_service.dart';
import 'memory_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final TextEditingController _customInputController = TextEditingController();
  final ScrollController _transcriptScrollController = ScrollController();
  final ScrollController _interventionScrollController = ScrollController();
  
  String _activeMode = "Standard Mode";
  final List<String> _modes = ["Standard Mode", "Sales Mode", "Meeting Mode", "Interview Mode", "Business Calculator"];

  int _activeFeedTab = 0; // 0 for Live Audio, 1 for Whispers
  bool _simulatorExpanded = false;

  // Premade simulation triggers for instant demo
  final List<Map<String, String>> _demoTriggers = [
    {
      "label": "GST calculation (Hinglish)",
      "text": "total billing is 5000 plus 18 percent gst total kitna hoga?"
    },
    {
      "label": "Cost-per-lead (Hinglish)",
      "text": "20,000 rupees kharcha hua 418 leads ke liye toh cost kitna pada?"
    },
    {
      "label": "Factual Population (English)",
      "text": "do you know what is the current population of india?"
    },
    {
      "label": "Monthly Total leads (Bengali-English)",
      "text": "normally daily 50 leads ase, but Monday te 110 leads hole monthly total koto?"
    },
    {
      "label": "Casual Banter (Smart Silence)",
      "text": "haan bhai achha chal tea break pe chalte hain aur chai peete hain."
    }
  ];

  @override
  void dispose() {
    _customInputController.dispose();
    _transcriptScrollController.dispose();
    _interventionScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wsService = context.watch<CoPilotService>();
    
    // Auto scroll feeds when updated
    if (wsService.interventions.isNotEmpty) {
      _scrollToBottom(_interventionScrollController);
    }
    if (wsService.transcripts.isNotEmpty) {
      _scrollToBottom(_transcriptScrollController);
    }

    // Determine visualizer color and state
    Color visualizerColor = AppTheme.neuralGrey.withValues(alpha: 0.3);
    String listenerText = "Smart Silence Active";
    Widget visualizerWidget = Icon(Icons.mic_off_rounded, size: 48, color: AppTheme.neuralGrey.withValues(alpha: 0.4));
    
    if (wsService.isListening) {
      if (wsService.statusMessage.contains("Smart Silence")) {
        visualizerColor = AppTheme.neuralGrey.withValues(alpha: 0.5);
        listenerText = "Smart Silence Active";
        visualizerWidget = SpinKitDoubleBounce(color: visualizerColor, size: 85);
      } else if (wsService.interventions.isNotEmpty && 
                 wsService.interventions.last["query"] == wsService.transcripts.lastOrNull) {
        // AI actively speaking/intervening
        visualizerColor = AppTheme.primaryViolet;
        listenerText = "Whispering via TWS...";
        visualizerWidget = SpinKitRipple(color: visualizerColor, size: 100);
      } else {
        // Active ambient listening
        visualizerColor = AppTheme.accentTeal;
        listenerText = "Ambient Listening...";
        visualizerWidget = SpinKitWave(color: visualizerColor, size: 60, type: SpinKitWaveType.center);
      }
    }

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
                // 1. TOP HEADER & TWS PILLED BADGE
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SECOND BRAIN",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryViolet,
                              letterSpacing: 3,
                            ),
                          ),
                          Text(
                            "TWS Co-Pilot",
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      // Bluetooth Connection Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: AppTheme.glassDecoration(
                          borderColor: wsService.isConnected ? AppTheme.accentTeal : AppTheme.glassCardBorder,
                          bgColor: wsService.isConnected ? const Color(0x1F14B8A6) : AppTheme.glassCardBg
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              wsService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                              size: 16,
                              color: wsService.isConnected ? AppTheme.accentTeal : AppTheme.neuralGrey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              wsService.isConnected ? "TWS ROUTED" : "PHONE MIC",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: wsService.isConnected ? AppTheme.accentTeal : AppTheme.neuralGrey,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Color(0x1AFFFFFF), height: 1),

                // 2. LIVE COGNITIVE VISUALIZER RIPPLE
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: AppTheme.glassDecoration(),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 110,
                          child: Center(child: visualizerWidget),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          listenerText.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: visualizerColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          wsService.statusMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Active Listening Toggle Button
                        ElevatedButton.icon(
                          onPressed: () {
                            wsService.toggleListening();
                          },
                          icon: Icon(
                            wsService.isListening ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            color: Colors.white,
                          ),
                          label: Text(wsService.isListening ? "PAUSE OVERLAY" : "ACTIVATE LISTENING"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: wsService.isListening ? AppTheme.primaryViolet : AppTheme.accentTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // 3. MODE SELECTOR CAROUSEL
                SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _modes.length,
                    itemBuilder: (context, index) {
                      final mode = _modes[index];
                      final isSelected = _activeMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeMode = mode;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: AppTheme.glassDecoration(
                              borderColor: isSelected ? AppTheme.accentTeal : Colors.white12,
                              bgColor: isSelected ? const Color(0x1F14B8A6) : Colors.transparent,
                              borderRadius: 20
                            ),
                            child: Center(
                              child: Text(
                                mode,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : AppTheme.neuralGrey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 4. TRANSCRIPT & INTERVENTION SEGMENTED TAB PANEL
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _activeFeedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFeedTab == 0 ? AppTheme.accentTeal.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _activeFeedTab == 0 ? AppTheme.accentTeal : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hearing_rounded, size: 14, color: _activeFeedTab == 0 ? Colors.white : AppTheme.neuralGrey),
                            const SizedBox(width: 6),
                            Text(
                              "LIVE TRANSCRIPT",
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _activeFeedTab == 0 ? Colors.white : AppTheme.neuralGrey,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _activeFeedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFeedTab == 1 ? AppTheme.primaryViolet.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _activeFeedTab == 1 ? AppTheme.primaryViolet : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: _activeFeedTab == 1 ? Colors.white : AppTheme.neuralGrey),
                            const SizedBox(width: 6),
                            Text(
                              "AI WHISPERS (${wsService.interventions.length})",
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _activeFeedTab == 1 ? Colors.white : AppTheme.neuralGrey,
                                  letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _activeFeedTab == 0
                        ? Container(
                            key: const ValueKey("ambient_transcripts"),
                            padding: const EdgeInsets.all(12),
                            decoration: AppTheme.glassDecoration(borderColor: Colors.white10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "AMBIENT AUDIO FEED",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neuralGrey,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: wsService.transcripts.isEmpty
                                      ? Center(
                                          child: Text(
                                            "No audio heard. Speak or trigger simulation...",
                                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white30),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _transcriptScrollController,
                                          itemCount: wsService.transcripts.length,
                                          itemBuilder: (context, index) {
                                            final transcript = wsService.transcripts[index];
                                            final isTrigger = wsService.interventions.any((element) => element["query"] == transcript);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isTrigger ? AppTheme.primaryViolet.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isTrigger ? AppTheme.primaryViolet.withValues(alpha: 0.2) : Colors.white10,
                                                  ),
                                                ),
                                                child: Text(
                                                  "🗣️ \"$transcript\"",
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: isTrigger ? FontWeight.w600 : FontWeight.normal,
                                                    color: isTrigger ? AppTheme.accentTeal : Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            key: const ValueKey("ai_interventions"),
                            padding: const EdgeInsets.all(12),
                            decoration: AppTheme.glassDecoration(borderColor: AppTheme.glassCardBorder),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "AI COGNITIVE WHISPERS",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryViolet,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white24),
                                      onPressed: () {
                                        wsService.clearInterventions();
                                      },
                                      tooltip: "Clear Whispers",
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: wsService.interventions.isEmpty
                                      ? Center(
                                          child: Text(
                                            "AI is silent.\nIntervenes only on math, business, or facts.",
                                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white30),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _interventionScrollController,
                                          itemCount: wsService.interventions.length,
                                          itemBuilder: (context, index) {
                                            final item = wsService.interventions[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10.0),
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: AppTheme.glassDecoration(
                                                  borderColor: AppTheme.primaryViolet.withValues(alpha: 0.3),
                                                  bgColor: const Color(0x1F0F111E),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          (item["trigger_type"] ?? "Cognition").toUpperCase(),
                                                          style: GoogleFonts.jetBrainsMono(
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppTheme.primaryViolet,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${item["timestamp"] ?? ''}",
                                                          style: GoogleFonts.outfit(fontSize: 9, color: Colors.white30),
                                                        )
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "👂 Heard: \"${item["query"]}\"",
                                                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, fontStyle: FontStyle.italic),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.accentTeal),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            item["response"] ?? "",
                                                            style: GoogleFonts.outfit(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      "🧠 ${item["model"]} • Latency: ${item["latency"]}",
                                                      style: GoogleFonts.jetBrainsMono(fontSize: 8, color: Colors.white24),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // 5. INTERACTIVE CONSOLE FOR SIMULATION
                if (wsService.sttProvider == "Simulated")
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.glassDecoration(borderColor: Colors.white12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _simulatorExpanded = !_simulatorExpanded;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "COGNITIVE TEST ENGINE (SIMULATE SPEECH)",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentTeal,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Icon(
                                _simulatorExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                size: 16,
                                color: AppTheme.accentTeal,
                              ),
                            ],
                          ),
                        ),
                        if (_simulatorExpanded) ...[
                          const SizedBox(height: 8),
                          // Preset Scenario Badges
                          SizedBox(
                            height: 30,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _demoTriggers.length,
                              itemBuilder: (context, index) {
                                final demo = _demoTriggers[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ActionChip(
                                    label: Text(demo["label"]!, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                    backgroundColor: AppTheme.deepSpaceBlue,
                                    side: const BorderSide(color: Colors.white12),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!wsService.isListening) {
                                        wsService.toggleListening();
                                      }
                                      wsService.sendTranscript(demo["text"]!);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Manual Input row
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: _customInputController,
                                    decoration: const InputDecoration(
                                      hintText: "Speak customized Hinglish or Bengali math...",
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        if (!wsService.isListening) {
                                          wsService.toggleListening();
                                        }
                                        wsService.sendTranscript(val);
                                        _customInputController.clear();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  icon: const Icon(Icons.send_rounded, color: AppTheme.accentTeal),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.glassCardBg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    final text = _customInputController.text;
                                    if (text.trim().isNotEmpty) {
                                      if (!wsService.isListening) {
                                        wsService.toggleListening();
                                      }
                                      wsService.sendTranscript(text);
                                      _customInputController.clear();
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                
                
                // 6. BOTTOM NAVIGATION SIMULATED BAR
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.explore_outlined, color: AppTheme.accentTeal),
                        label: Text("DASHBOARD", style: GoogleFonts.outfit(color: AppTheme.accentTeal, fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MemoryScreen()),
                          );
                        },
                        icon: const Icon(Icons.psychology_outlined, color: AppTheme.neuralGrey),
                        label: Text("LEARNINGS", style: GoogleFonts.outfit(color: AppTheme.neuralGrey)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.tune_outlined, color: AppTheme.neuralGrey),
                        label: Text("TUNING", style: GoogleFonts.outfit(color: AppTheme.neuralGrey)),
                      ),
                    ],
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
