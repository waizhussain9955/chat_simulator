import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_logo.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({Key? key}) : super(key: key);

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xff0d1117),
            border: Border(bottom: BorderSide(color: Color(0xff1f242c), width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: DarkEmeraldTheme.primaryColor,
            labelColor: DarkEmeraldTheme.primaryColor,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'USER MANUAL & GUIDE'),
              Tab(text: 'PRIVACY POLICY'),
            ],
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGuideTab(),
              _buildPrivacyTab(),
            ],
          ),
        ),
      ],
    );
  }

  // GUIDE TAB
  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Introduction
          _buildHeroSection(),
          const SizedBox(height: 24),

          // Flowchart Timeline
          _buildSectionHeader('How It Works (Simulation Flow)'),
          const SizedBox(height: 12),
          _buildFlowchartTimeline(),
          const SizedBox(height: 24),

          // Step 1: Android Accessibility Setup
          _buildSectionHeader('1. Enable Android Accessibility Service'),
          const SizedBox(height: 12),
          _buildAccessibilitySetupCard(),
          const SizedBox(height: 24),

          // Step 2: Sideloading Restricted Settings
          _buildSectionHeader('2. Sideloading "Restricted Settings" Fix'),
          const SizedBox(height: 12),
          _buildRestrictedSettingsCard(),
          const SizedBox(height: 24),

          // Step 3: Message Library & Data Formats
          _buildSectionHeader('3. Message Management & Imports (JSON/CSV/TXT)'),
          const SizedBox(height: 12),
          _buildDataFormatsCard(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return GlassCard(
      child: Row(
        children: [
          const AppLogo(size: 64),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Chat Simulator Pro Guide',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Follow these guidelines to configure and start injecting messages automatically into any messaging client on your device.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFlowchartTimeline() {
    return GlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return isNarrow 
              ? Column(
                  children: [
                    _buildFlowStep('1', 'Select Messages', 'Select single/multiple messages from the Library.', Icons.check_box),
                    _buildArrow(vertical: true),
                    _buildFlowStep('2', 'Start Simulation', 'Simulate begins with a configured countdown timer.', Icons.play_arrow),
                    _buildArrow(vertical: true),
                    _buildFlowStep('3', 'Switch Chat App', 'Switch manually to WhatsApp, Telegram, etc.', Icons.swap_horiz),
                    _buildArrow(vertical: true),
                    _buildFlowStep('4', 'Focus Text Field', 'Tap the target message text field / box.', Icons.touch_app),
                    _buildArrow(vertical: true),
                    _buildFlowStep('5', 'Sent Automatically', 'Service types and presses the send button!', Icons.send),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildFlowStep('1', 'Select', 'Choose messages.', Icons.check_box)),
                    _buildArrow(),
                    Expanded(child: _buildFlowStep('2', 'Start', 'Trigger timer.', Icons.play_arrow)),
                    _buildArrow(),
                    Expanded(child: _buildFlowStep('3', 'Switch', 'Open chat app.', Icons.swap_horiz)),
                    _buildArrow(),
                    Expanded(child: _buildFlowStep('4', 'Focus', 'Tap text box.', Icons.touch_app)),
                    _buildArrow(),
                    Expanded(child: _buildFlowStep('5', 'Sent', 'Auto types & sends.', Icons.send)),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildFlowStep(String num, String title, String desc, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xff1f242c),
          foregroundColor: DarkEmeraldTheme.primaryColor,
          child: Icon(icon, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          '$num. $title',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildArrow({bool vertical = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: vertical ? 12.0 : 0.0),
      child: Icon(
        vertical ? Icons.arrow_downward : Icons.arrow_forward,
        color: const Color(0xff30363d),
        size: 20,
      ),
    );
  }

  Widget _buildAccessibilitySetupCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Roman Urdu Instruction (Aasan Lafzon mein):',
            style: TextStyle(fontWeight: FontWeight.bold, color: DarkEmeraldTheme.primaryColor, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            '1. Settings page par ja kar "ENABLE ACCESSIBILITY SERVICE" par click karein.\n'
            '2. Aapke phone ki Accessibility screen open ho gi.\n'
            '3. "Installed Services" (ya Downloaded Apps) par tap karein.\n'
            '4. List mein se "Chat Simulator Pro" par click karke toggle switch "ON" kar dein.\n'
            '5. App mein wapas aayein, status "ACTIVE" ho jaye ga.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
          const Divider(color: Color(0xff30363d), height: 24),
          
          const Text(
            'Visual Path Map:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Beautiful visual mockup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff0d1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff30363d)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMockSettingRow(Icons.settings, 'System Settings', 'Accessibility Options'),
                _buildMockArrowDown(),
                _buildMockSettingRow(Icons.accessibility, 'Accessibility', 'Vision, Hearing, Installed Services'),
                _buildMockArrowDown(),
                _buildMockSettingRow(Icons.download, 'Installed Services / Downloaded Apps', 'Manage extensions'),
                _buildMockArrowDown(),
                _buildMockSettingRow(Icons.offline_bolt, 'Chat Simulator Pro', 'OFF (Tap to change)', showSwitch: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMockSettingRow(IconData icon, String title, String subtitle, {bool showSwitch = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff30363d), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: DarkEmeraldTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 10)),
              ],
            ),
          ),
          if (showSwitch)
            Switch(
              value: false,
              onChanged: (_) {},
              activeColor: DarkEmeraldTheme.primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildMockArrowDown() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Center(
        child: Icon(Icons.keyboard_arrow_down, color: Colors.white30, size: 16),
      ),
    );
  }

  Widget _buildRestrictedSettingsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Sideloaded / Sourced APK Security (Android 13 & 14+):',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'Android 13 aur 14+ par jab aap direct APK install karte hain, toh Android security restrictions ki wajah se accessibility service option disable/greyed out ho sakta hai. Isay active karne ka tareeqa ye hai:',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            '1. Phone ki settings mein ja kar **Apps** (ya App Management) par click karein.\n'
            '2. **Chat Simulator Pro** (ya chat_simulator_pro) app select karein.\n'
            '3. Top-right corner mein teen vertical dots **(⋮)** par click karein.\n'
            '4. **"Allow restricted settings"** (ya scale authorization) par tap karein.\n'
            '5. Phone lock ka password ya fingerprint scan enter karein.\n'
            '6. Ab wapas Accessibility panel mein jayein, option enabled ho chuka hoga.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDataFormatsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bulk Upload / Import Formats:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can instantly upload bulk messages using CSV, JSON, or TXT file formats. Ensure your files match these exact structures:',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _buildCodeFormatBlock(
            'JSON Template (.json)',
            '[\n'
            '  {\n'
            '    "message": "Hello Client! This is a test message.",\n'
            '    "category": "Clients",\n'
            '    "isFavorite": true\n'
            '  },\n'
            '  {\n'
            '    "message": "Hey friend, how are you?",\n'
            '    "category": "Friends",\n'
            '    "isFavorite": false\n'
            '  }\n'
            ']',
          ),
          const SizedBox(height: 12),
          _buildCodeFormatBlock(
            'CSV Template (.csv)',
            'message,category,isFavorite\n'
            '"Hello Client! This is a test message.","Clients",true\n'
            '"Hey friend, how are you?","Friends",false',
          ),
          const SizedBox(height: 12),
          _buildCodeFormatBlock(
            'TXT Template (.txt)',
            'Hello Client! This is a test message. (Lines represent individual messages. Defaults to "Custom" category.)\n'
            'Hey friend, how are you?',
          ),
        ],
      ),
    );
  }

  Widget _buildCodeFormatBlock(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff0d1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff30363d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xff161b22),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70)),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xffcfcfcf)),
            ),
          )
        ],
      ),
    );
  }

  // PRIVACY POLICY TAB
  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy Policy & Data Protection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Last Updated: June 20, 2026',
            style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          _buildPrivacyPolicyCard(),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '1. 100% Offline & Local Storage',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'Chat Simulator Pro performs all database actions directly on your physical hardware. We use Hive local database boxes to store your project profiles, message libraries, and send history. None of this data is ever synced, sent, or uploaded to any remote servers.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
          Divider(color: Color(0xff30363d), height: 32),
          
          Text(
            '2. Accessibility Permission Usage',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'Our custom Accessibility Service is strictly used to facilitate character typing simulation and automated send button trigger events. It operates entirely locally on your device. It does not monitor other app behaviors, read keystrokes outside active window simulation, or collect/transmit keyboard inputs.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
          Divider(color: Color(0xff30363d), height: 32),

          Text(
            '3. Zero Telemetry or Third-party SDKs',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'The application runs without any cloud infrastructure, authentication handlers, or diagnostic tracking metrics (like Firebase Analytics). We have zero insight into how many messages you send, what you write, or which applications you target.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
          Divider(color: Color(0xff30363d), height: 32),

          Text(
            '4. Safe Sandboxing & Export Control',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'Your exported CSV, JSON, and text templates are written only to the local download path or folder path explicitly designated by you via file selector dialogs. We recommend securing your device backups using system-level storage encryption.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
