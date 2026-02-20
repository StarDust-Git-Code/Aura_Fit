import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ble_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aura Fit Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              Provider.of<BleProvider>(context, listen: false).disconnect();
              Navigator.pop(context); // Go back to scan screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Section: Massive BPM
            Expanded(
              flex: 2,
              child: Center(
                child: Consumer<BleProvider>(
                  builder: (context, provider, child) {
                    // Update pulse speed based on BPM? (Optional enhancement)
                    return ScaleTransition(
                      scale: _pulseAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${provider.bpm}",
                            style: GoogleFonts.outfit(
                              fontSize: 120,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonCyan,
                              shadows: [
                                Shadow(
                                  color: AppTheme.neonCyan.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "BPM",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Middle Section: Vitals Grid
            Expanded(
              flex: 2,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // Stress Card
                  _buildGlassCard(
                    context,
                    child: Consumer<BleProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularPercentIndicator(
                              radius: 40.0,
                              lineWidth: 8.0,
                              percent: provider.stressLevel / 100,
                              center: Text(
                                "${provider.stressLevel.toInt()}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              progressColor: AppTheme.vibrantPurple,
                              backgroundColor: Colors.grey[800]!,
                              circularStrokeCap: CircularStrokeCap.round,
                              animation: true,
                              animateFromLastPercent: true,
                            ),
                            const SizedBox(height: 8),
                            Text("Stress", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        );
                      },
                    ),
                  ),

                  // Anxiety Card
                  _buildGlassCard(
                    context,
                    child: Consumer<BleProvider>(
                      builder: (context, provider, child) {
                        Color statusColor;
                        switch (provider.anxietyStatus) {
                          case "CALM":
                            statusColor = Colors.greenAccent;
                            break;
                          case "ELEVATED":
                            statusColor = Colors.orangeAccent;
                            break;
                          case "HIGH":
                            statusColor = Colors.redAccent;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              provider.anxietyStatus,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                shadows: [
                                  Shadow(
                                    color: statusColor.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Anxiety", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Section: RAW Data Chart
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.only(top: 16, right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Consumer<BleProvider>(
                  builder: (context, provider, child) {
                    if (provider.rawHistory.isEmpty) {
                      return const Center(child: Text("Waiting for data..."));
                    }

                    return LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 100,
                        minY: provider.rawHistory.reduce((a, b) => a < b ? a : b) - 100,
                        maxY: provider.rawHistory.reduce((a, b) => a > b ? a : b) + 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: provider.rawHistory
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            gradient: const LinearGradient(
                              colors: [AppTheme.neonCyan, AppTheme.vibrantPurple],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.neonCyan.withValues(alpha: 0.2),
                                  AppTheme.vibrantPurple.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Recommendation Card
            Consumer<BleProvider>(
              builder: (context, provider, child) {
                if (provider.recommendation.isEmpty) return const SizedBox.shrink();

                Color cardColor;
                IconData cardIcon;
                switch (provider.anxietyStatus) {
                  case "CALM":
                    cardColor = Colors.greenAccent;
                    cardIcon = Icons.favorite;
                    break;
                  case "ELEVATED":
                    cardColor = Colors.orangeAccent;
                    cardIcon = Icons.warning_amber_rounded;
                    break;
                  default: // HIGH
                    cardColor = Colors.redAccent;
                    cardIcon = Icons.emergency;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(cardIcon, color: cardColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.recommendation,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.8), // Glass-like background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
