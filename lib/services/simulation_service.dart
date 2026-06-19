import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

// Conditional import for Windows Win32 API
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

import '../models/message.dart';
import '../models/settings.dart';
import '../models/history_item.dart';

class SimulationService {
  static const MethodChannel _channel = MethodChannel('com.chatsimulator.chat_simulator_pro/automation');

  final Uuid _uuid = const Uuid();
  bool _isCancelled = false;
  Timer? _countdownTimer;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    _countdownTimer?.cancel();
  }

  // Starts the simulation session
  Future<void> run({
    required List<Message> messages,
    required ProjectSettings settings,
    required Function(String log, String type) onLog,
    required Function(int secondsRemaining) onCountdown,
    required Function(HistoryItem sentItem) onMessageSent,
    required Function() onFinished,
    String? customChatAppUrl, // Optional URL scheme for mobile launch
  }) async {
    _isCancelled = false;
    final sessionId = _uuid.v4().substring(0, 8);

    onLog('Session $sessionId started.', 'info');

    // 1. Countdown Phase
    int countdown = settings.countdown;
    if (countdown > 0) {
      onLog('Starting countdown of $countdown seconds. Switch to target chat input now!', 'warning');
      while (countdown > 0) {
        if (_isCancelled) {
          onLog('Session cancelled during countdown.', 'error');
          onFinished();
          return;
        }
        onCountdown(countdown);
        await Future.delayed(const Duration(seconds: 1));
        countdown--;
      }
    }
    onCountdown(0);
    onLog('Countdown finished. Starting message simulation.', 'success');

    // 2. Message Transmission Phase
    for (int i = 0; i < messages.length; i++) {
      if (_isCancelled) {
        onLog('Session cancelled by user.', 'error');
        onFinished();
        return;
      }

      final message = messages[i];
      onLog('Preparing message ${i + 1}/${messages.length}...', 'info');

      try {
        if (Platform.isWindows) {
          await _sendOnWindows(message.message, settings, onLog);
        } else if (Platform.isAndroid || Platform.isIOS) {
          await _sendOnMobile(message.message, customChatAppUrl, onLog);
        } else {
          // Fallback/Web: copy to clipboard
          await Clipboard.setData(ClipboardData(text: message.message));
          onLog('Copied to clipboard (platform fallback).', 'success');
        }

        // Create and record history item
        final historyItem = HistoryItem(
          id: _uuid.v4(),
          message: message.message,
          timestamp: DateTime.now(),
          sessionId: sessionId,
          status: 'Sent',
        );
        onMessageSent(historyItem);
        onLog('Message "${message.message.substring(0, min(message.message.length, 25))}..." sent successfully.', 'success');

      } catch (e) {
        onLog('Failed to send message: $e', 'error');
      }

      // Inter-message delay (only if not the last message)
      if (i < messages.length - 1) {
        final delayMs = _getInterMessageDelay(settings);
        onLog('Waiting ${delayMs ~/ 1000}s before next message.', 'info');
        
        int waited = 0;
        while (waited < delayMs) {
          if (_isCancelled) {
            onLog('Session cancelled during delay.', 'error');
            onFinished();
            return;
          }
          await Future.delayed(const Duration(milliseconds: 200));
          waited += 200;
        }
      }
    }

    onLog('Session $sessionId ended successfully.', 'success');
    onFinished();
  }

  // Windows Specific Implementation using win32
  Future<void> _sendOnWindows(
    String message,
    ProjectSettings settings,
    Function(String, String) onLog,
  ) async {
    final mode = settings.sendingMode.toLowerCase();

    if (mode == 'instant') {
      onLog('Instant mode: Pasting message using clipboard.', 'info');
      // 1. Copy message to clipboard
      await Clipboard.setData(ClipboardData(text: message));
      await Future.delayed(const Duration(milliseconds: 50)); // let clipboard register

      // 2. Press Ctrl + V
      _simulateCtrlV();
      await Future.delayed(const Duration(milliseconds: 50)); // wait for paste operation

      // 3. Press Enter to send
      _simulateEnter();
      await Future.delayed(const Duration(milliseconds: 100)); // wait for message to send
    } else {
      // Human or Fast Mode (character-by-character typing)
      onLog('Typing mode: sending keystrokes character-by-character.', 'info');
      final isHuman = mode == 'human';
      final baseDelay = isHuman ? settings.typingSpeed : 10; // human uses setting, fast uses 10ms

      for (int i = 0; i < message.length; i++) {
        if (_isCancelled) return;

        final char = message[i];

        // Simulate random typos in Human Mode (1% chance if length > 5)
        if (isHuman && i > 3 && i < message.length - 1 && Random().nextDouble() < 0.01) {
          final typoChar = String.fromCharCode(char.codeUnitAt(0) + (Random().nextBool() ? 1 : -1));
          _simulateUnicodeKey(typoChar.codeUnitAt(0));
          await Future.delayed(Duration(milliseconds: baseDelay + Random().nextInt(50)));
          
          // Backspace to correct
          _simulateBackspace();
          await Future.delayed(Duration(milliseconds: baseDelay + Random().nextInt(50)));
        }

        // Type correct character
        _simulateUnicodeKey(char.codeUnitAt(0));

        // Variable delay
        final delay = isHuman 
            ? baseDelay + Random().nextInt(100) // random offset
            : baseDelay; // constant small delay
        await Future.delayed(Duration(milliseconds: delay));
      }

      // Press Enter to send after typing finishes
      await Future.delayed(const Duration(milliseconds: 150));
      _simulateEnter();
    }
  }

  // Mobile Specific Implementation
  Future<void> _sendOnMobile(
    String message,
    String? customChatAppUrl,
    Function(String, String) onLog,
  ) async {
    bool accessibilityEnabled = false;
    if (Platform.isAndroid) {
      try {
        accessibilityEnabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
      } catch (e) {
        onLog('[DEBUG] Error checking accessibility status: $e', 'warning');
      }
    }

    if (accessibilityEnabled) {
      onLog('Universal Automation Accessibility Service is ACTIVE. Queueing text injection.', 'info');
      try {
        await _channel.invokeMethod('simulateType', {'text': message});
        onLog('Message successfully queued for auto-typing. Switch to your chat app and tap the message text box!', 'success');
        return; // Return immediately to avoid opening the sharing intent/link.
      } catch (e) {
        onLog('[DEBUG] Error sending text to accessibility service: $e', 'warning');
      }
    }

    final launched = await _launchUrlWithFallbacks(
      message: message,
      customChatAppUrl: customChatAppUrl,
      onLog: onLog,
    );

    if (!launched) {
      // 2. Only copy to clipboard as fallback if app launch failed and accessibility is not enabled
      await Clipboard.setData(ClipboardData(text: message));
      onLog('Message copied to clipboard (launch fallback).', 'success');
    }
  }

  // Robust URL launcher with prioritised fallbacks and logging
  Future<bool> _launchUrlWithFallbacks({
    required String message,
    required String? customChatAppUrl,
    required Function(String, String) onLog,
  }) async {
    final List<String> urlsToTry = [];
    
    final isCustomWhatsApp = customChatAppUrl != null && 
        (customChatAppUrl.contains('whatsapp') || customChatAppUrl.contains('wa.me'));
        
    final isCustomEmpty = customChatAppUrl == null || customChatAppUrl.trim().isEmpty;

    if (isCustomWhatsApp || isCustomEmpty) {
      // If user specified a custom WhatsApp URL, try it first
      if (customChatAppUrl != null && customChatAppUrl.isNotEmpty) {
        urlsToTry.add(customChatAppUrl);
      }
      
      // Default priority fallbacks:
      // 1. https://api.whatsapp.com/send?text={text}
      // 2. https://wa.me/?text={text}
      // 3. whatsapp://send?text={text}
      final defaultList = [
        'https://api.whatsapp.com/send?text={text}',
        'https://wa.me/?text={text}',
        'whatsapp://send?text={text}',
      ];
      for (var fallback in defaultList) {
        if (!urlsToTry.contains(fallback)) {
          urlsToTry.add(fallback);
        }
      }
    } else {
      // User entered a non-WhatsApp custom scheme
      urlsToTry.add(customChatAppUrl);
    }

    bool launched = false;
    for (int i = 0; i < urlsToTry.length; i++) {
      final pattern = urlsToTry[i];
      final encodedText = Uri.encodeComponent(message);
      final formattedUrl = pattern.replaceAll('{text}', encodedText);
      
      onLog('[DEBUG] Generated URL: $pattern', 'info');
      onLog('[DEBUG] URL encoded result: $formattedUrl', 'info');
      
      final uri = Uri.parse(formattedUrl);
      
      try {
        onLog('Checking if URL can be launched...', 'info');
        final canLaunch = await canLaunchUrl(uri);
        onLog('[DEBUG] canLaunchUrl result: $canLaunch', 'info');
        
        onLog('Launching URL...', 'info');
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        onLog('[DEBUG] launchUrl result: $launched', 'info');
        
        if (launched) {
          onLog('WhatsApp launched successfully.', 'success');
          return true;
        }
      } catch (e, stackTrace) {
        onLog('Error launching URL: $e', 'warning');
        onLog('[DEBUG] Exception stack trace:\n$stackTrace', 'warning');
      }
      
      onLog('Failed to launch URL: $formattedUrl', 'warning');
      if (i < urlsToTry.length - 1) {
        onLog('Trying next fallback URL...', 'info');
      }
    }
    
    return false;
  }

  // Mobile prefill test runner called from settings
  Future<Map<String, dynamic>> testWhatsAppPrefill({
    required Function(String, String) onLog,
  }) async {
    final testMessage = "Hello World WhatsApp Prefill Test - ${DateTime.now().minute}:${DateTime.now().second}";
    onLog('Starting WhatsApp prefill test...', 'info');
    
    final success = await _launchUrlWithFallbacks(
      message: testMessage,
      customChatAppUrl: null, // Force default fallback list
      onLog: onLog,
    );
    
    if (success) {
      return {
        'success': true,
        'message': 'WhatsApp launched successfully.',
      };
    } else {
      return {
        'success': false,
        'message': 'All WhatsApp prefill variants failed to launch.',
      };
    }
  }

  // Calculate random/minimal delays between consecutive messages
  int _getInterMessageDelay(ProjectSettings settings) {
    final mode = settings.sendingMode.toLowerCase();
    if (mode == 'instant') {
      return 150; // Minimal delay between instant messages (150ms)
    } else if (mode == 'fast') {
      return 800; // 0.8s delay between fast messages
    } else {
      // Human mode: Use the inter-message delay setting, with a small random offset (+/- 20%) to keep it organic
      final baseDelayMs = settings.interMessageDelay * 1000;
      final maxOffset = baseDelayMs ~/ 5;
      final offset = maxOffset > 0 ? Random().nextInt(maxOffset) - (maxOffset ~/ 2) : 0;
      return max(500, baseDelayMs + offset);
    }
  }

  // Win32 keyboard utility functions
  void _sendKey(int wVk, {bool keyUp = false}) {
    if (!Platform.isWindows) return;

    final input = calloc<win32.INPUT>();
    input.ref.type = win32.INPUT_KEYBOARD;
    input.ref.ki.wVk = wVk;
    input.ref.ki.wScan = 0;
    input.ref.ki.dwFlags = keyUp ? win32.KEYEVENTF_KEYUP : 0;
    input.ref.ki.time = 0;
    input.ref.ki.dwExtraInfo = 0;

    win32.SendInput(1, input, sizeOf<win32.INPUT>());
    calloc.free(input);
  }

  void _simulateUnicodeKey(int charCode) {
    if (!Platform.isWindows) return;

    final input = calloc<win32.INPUT>();
    input.ref.type = win32.INPUT_KEYBOARD;
    input.ref.ki.wVk = 0;
    input.ref.ki.wScan = charCode;
    input.ref.ki.dwFlags = win32.KEYEVENTF_UNICODE;
    input.ref.ki.time = 0;
    input.ref.ki.dwExtraInfo = 0;

    win32.SendInput(1, input, sizeOf<win32.INPUT>());

    // Key up
    input.ref.ki.dwFlags = win32.KEYEVENTF_UNICODE | win32.KEYEVENTF_KEYUP;
    win32.SendInput(1, input, sizeOf<win32.INPUT>());

    calloc.free(input);
  }

  void _simulateCtrlV() {
    // Press Ctrl (0x11)
    _sendKey(0x11, keyUp: false);
    // Press V (0x56)
    _sendKey(0x56, keyUp: false);
    // Release V
    _sendKey(0x56, keyUp: true);
    // Release Ctrl
    _sendKey(0x11, keyUp: true);
  }

  void _simulateEnter() {
    // VK_RETURN = 0x0D
    _sendKey(0x0D, keyUp: false);
    _sendKey(0x0D, keyUp: true);
  }

  void _simulateBackspace() {
    // VK_BACK = 0x08
    _sendKey(0x08, keyUp: false);
    _sendKey(0x08, keyUp: true);
  }
}
