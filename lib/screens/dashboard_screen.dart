import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';
import '../models/message.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Calculate metrics
    final totalMessages = provider.messages.length;
    final totalSessions = provider.history.map((h) => h.sessionId).toSet().length;
    
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayMessages = provider.history.where((h) {
      final dateStr = DateFormat('yyyy-MM-dd').format(h.timestamp);
      return dateStr == todayStr;
    }).length;

    final lastActivityStr = provider.history.isNotEmpty
        ? DateFormat('MM/dd HH:mm').format(provider.history.first.timestamp)
        : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 600 ? 2 : 4;
              final childAspectRatio = width < 600 ? 1.3 : 1.5;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCard(
                    context,
                    'Total Messages',
                    totalMessages.toString(),
                    Icons.message,
                    DarkEmeraldTheme.primaryColor,
                  ),
                  _buildStatCard(
                    context,
                    'Total Sessions',
                    totalSessions.toString(),
                    Icons.history,
                    Colors.blueAccent,
                  ),
                  _buildStatCard(
                    context,
                    'Today\'s Sent',
                    todayMessages.toString(),
                    Icons.today,
                    Colors.amberAccent,
                  ),
                  _buildStatCard(
                    context,
                    'Last Activity',
                    lastActivityStr,
                    Icons.bolt,
                    Colors.purpleAccent,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Main Section: Chart + Quick Send
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart area
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message Frequency (Last 7 Days)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      height: 300,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, right: 16, left: 8),
                        child: _buildChart(provider),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sidebar: Quick Run (only for wider screens)
              if (MediaQuery.of(context).size.width > 950) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Start Simulator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickStartPanel(context, provider),
                    ],
                  ),
                ),
              ]
            ],
          ),
          
          // Show Quick Send at the bottom for smaller screen widths
          if (MediaQuery.of(context).size.width <= 950) ...[
            const SizedBox(height: 32),
            const Text(
              'Quick Start Simulator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickStartPanel(context, provider),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Activity Chart
  Widget _buildChart(AppProvider provider) {
    final List<DateTime> pastDays = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });

    final Map<String, int> counts = {};
    for (var d in pastDays) {
      counts[DateFormat('yyyy-MM-dd').format(d)] = 0;
    }

    for (var h in provider.history) {
      final dateStr = DateFormat('yyyy-MM-dd').format(h.timestamp);
      if (counts.containsKey(dateStr)) {
        counts[dateStr] = counts[dateStr]! + 1;
      }
    }

    final double maxVal = counts.values.isEmpty 
        ? 5 
        : counts.values.reduce(max).toDouble();
    final double maxY = maxVal == 0 ? 5 : maxVal + (maxVal * 0.2).roundToDouble();

    int index = 0;
    final barGroups = pastDays.map((d) {
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      final count = counts[dateStr] ?? 0;
      final group = BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: DarkEmeraldTheme.primaryColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: const Color(0xff1f242c),
            ),
          )
        ],
      );
      index++;
      return group;
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xff161b22),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = pastDays[group.x];
              final dateName = DateFormat('MMM dd').format(date);
              return BarTooltipItem(
                '$dateName\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: '${rod.toY.toInt()} Sent',
                    style: const TextStyle(color: DarkEmeraldTheme.primaryColor),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int idx = value.toInt();
                if (idx >= 0 && idx < pastDays.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(pastDays[idx]),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value % 2 == 0 || value == maxVal) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // Quick Start Simulation Panel
  Widget _buildQuickStartPanel(BuildContext context, AppProvider provider) {
    if (provider.messages.isEmpty) {
      return GlassCard(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.library_books, color: Colors.white24, size: 48),
              SizedBox(height: 12),
              Text(
                'No messages in library.',
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                'Go to Library to add some.',
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setState) {
        // Find favorite messages or take first 5
        final List<Message> quickList = provider.messages.where((m) => m.isFavorite).toList();
        final displayList = quickList.isNotEmpty 
            ? quickList 
            : provider.messages.sublist(0, min(5, provider.messages.length));

        return GlassCard(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select messages to send:',
                style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final msg = displayList[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xff0d1117),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff30363d)),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          msg.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          msg.category,
                          style: const TextStyle(color: DarkEmeraldTheme.primaryColor, fontSize: 10),
                        ),
                        trailing: msg.isFavorite
                            ? const Icon(Icons.star, color: Colors.amber, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: provider.isRunning
                    ? null
                    : () {
                        provider.startSimulation(displayList);
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(provider.isRunning ? 'RUNNING...' : 'SIMULATE THESE (${displayList.length})'),
              )
            ],
          ),
        );
      },
    );
  }
}
