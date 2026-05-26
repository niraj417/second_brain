import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/co_pilot_service.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  @override
  Widget build(BuildContext context) {
    final coPilot = context.watch<CoPilotService>();
    final memory = coPilot.memoryProfile;

    // Pull directly from on-device local memory profile!
    final String preferredLang = memory["user_preferences"]?["preferred_language"] ?? "Hinglish/Bengali-Mixed";
    
    final Map<dynamic, dynamic> metricsMap = memory["business_profile"]?["recurring_metrics"] ?? {};
    final Map<String, String> metrics = metricsMap.map((key, value) => MapEntry(key.toString(), value.toString()));
    
    final List<dynamic> clients = memory["business_profile"]?["recurring_clients"] ?? [];
    final List<dynamic> facts = memory["extracted_facts"] ?? [];

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
                // Header Row
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
                        "Second Brain Learnings",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Glowing Active Pulse to indicate serverless health
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "ON-DEVICE SECURE",
                            style: GoogleFonts.jetbrainsMono(fontSize: 8, color: AppTheme.accentTeal, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const Divider(color: Color(0x1AFFFFFF), height: 1),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    children: [
                      // A. DYNAMIC PROFILE SUMMARY CARD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassDecoration(borderColor: AppTheme.accentTeal.withOpacity(0.3)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: AppTheme.accentTeal, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "DYNAMIC USER PROFILE",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentTeal,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Language preference:", style: GoogleFonts.outfit(color: AppTheme.neuralGrey)),
                                Text(preferredLang, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Last Calculated CPL:", style: GoogleFonts.outfit(color: AppTheme.neuralGrey)),
                                Text(metrics["last_calculated_cpl"] ?? "₹47.85 (Simulated)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Common Tax Rate:", style: GoogleFonts.outfit(color: AppTheme.neuralGrey)),
                                Text(metrics["common_gst_rate"] ?? "18%", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Recognized Clients:",
                              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neuralGrey),
                            ),
                            const SizedBox(height: 6),
                            clients.isEmpty
                                ? Text("No clients recorded yet.", style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24))
                                : Wrap(
                                    spacing: 6,
                                    children: clients.map((c) => Chip(
                                      label: Text(c.toString(), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                      backgroundColor: AppTheme.obsidianBlack,
                                      side: BorderSide(color: AppTheme.glassCardBorder.withOpacity(0.3)),
                                      padding: EdgeInsets.zero,
                                    )).toList(),
                                  )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // B. LEARNED FACTS LIST
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "LONG-TERM MEMORY REGISTRY",
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryViolet,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "${facts.length} facts logged",
                            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neuralGrey),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      facts.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassDecoration(borderColor: Colors.white10),
                              child: Center(
                                child: Text(
                                  "Long term memory is currently clear.\nInterventions populate learnings.",
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white30),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: facts.length,
                              itemBuilder: (context, index) {
                                final factItem = facts[index];
                                final int id = factItem["id"] ?? index;
                                final String factText = factItem["fact"] ?? "";
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: AppTheme.glassDecoration(borderColor: Colors.white10),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.lens_blur_rounded, color: AppTheme.primaryViolet, size: 16),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            factText,
                                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white30),
                                          onPressed: () {
                                            coPilot.deleteFact(id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Memory pruned successfully.")),
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 30),

                      // C. DATA PRIVACY CONTROL CARD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassDecoration(borderColor: AppTheme.softCrimson.withOpacity(0.3)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.security_rounded, color: AppTheme.softCrimson, size: 20),
                                const SizedBox(width: 8),
                                  Text(
                                    "SECURITY & ENCRYPTION",
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.softCrimson,
                                      letterSpacing: 2,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your conversation analysis and business profiles are stored strictly inside private, localized on-device caches. No backend or corporate cloud sees your transcripts.",
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Purge Entire Memory?"),
                                    content: const Text("This completely wipes all dynamic business stats, client arrays, and preference indices. This action is irreversible."),
                                    actions: [
                                      TextButton(
                                        child: const Text("CANCEL"),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(foregroundColor: AppTheme.softCrimson),
                                        onPressed: () {
                                          coPilot.clearAllMemory();
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("All memory registries purged.")),
                                          );
                                        },
                                        child: const Text("PURGE ALL DATA"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.softCrimson,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("PURGE CO-PILOT DYNAMIC MEMORY"),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
