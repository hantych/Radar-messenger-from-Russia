import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'radar_screen.dart';

/// Pre-flight check screen.
/// Goes through every requirement step-by-step, lets the user fix each one,
/// and only proceeds to the radar when everything is green.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _starting = false;

  // Each requirement state
  _ReqState _platformOk = _ReqState.unknown;
  _ReqState _location = _ReqState.unknown;
  _ReqState _locationService = _ReqState.unknown;
  _ReqState _bluetooth = _ReqState.unknown;
  _ReqState _bluetoothService = _ReqState.unknown;
  _ReqState _nearby = _ReqState.unknown;
  _ReqState _notifications = _ReqState.unknown;

  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runChecks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user comes back from system settings — re-run checks automatically.
    if (state == AppLifecycleState.resumed) {
      _runChecks();
    }
  }

  bool get _allOk =>
      _platformOk == _ReqState.ok &&
      _location == _ReqState.ok &&
      _locationService == _ReqState.ok &&
      _bluetooth == _ReqState.ok &&
      _bluetoothService == _ReqState.ok &&
      _nearby == _ReqState.ok &&
      _notifications == _ReqState.ok;

  Future<void> _runChecks() async {
    setState(() => _checking = true);

    // Platform check
    if (!Platform.isAndroid) {
      setState(() {
        _platformOk = _ReqState.fail;
        _checking = false;
      });
      return;
    }
    _platformOk = _ReqState.ok;

    // Location permission (both fine and when-in-use, we just need one granted)
    final locFine = await Permission.location.status;
    final locWhenInUse = await Permission.locationWhenInUse.status;
    _location = (locFine.isGranted ||
            locFine.isLimited ||
            locWhenInUse.isGranted ||
            locWhenInUse.isLimited)
        ? _ReqState.ok
        : _ReqState.fail;

    // Location service ON in system?
    final locSvc = await Permission.location.serviceStatus;
    _locationService = locSvc.isEnabled ? _ReqState.ok : _ReqState.fail;

    // Bluetooth permissions (Android 12+)
    final btScan = await Permission.bluetoothScan.status;
    final btAdv = await Permission.bluetoothAdvertise.status;
    final btCon = await Permission.bluetoothConnect.status;
    _bluetooth = (btScan.isGranted && btAdv.isGranted && btCon.isGranted)
        ? _ReqState.ok
        : _ReqState.fail;

    // Bluetooth service ON?
    final btSvc = await Permission.bluetooth.serviceStatus;
    _bluetoothService = btSvc.isEnabled ? _ReqState.ok : _ReqState.fail;

    // Nearby Wi-Fi (Android 13+)
    final nearby = await Permission.nearbyWifiDevices.status;
    _nearby = (nearby.isGranted || nearby.isLimited || nearby.isDenied)
        // 'denied' counts as ok because the OS may not actually require it on
        // older Android — Nearby Connections will fall back gracefully.
        ? _ReqState.ok
        : _ReqState.fail;
    // …but if it's permanentlyDenied that's a real fail
    if (nearby.isPermanentlyDenied) _nearby = _ReqState.fail;

    // Notifications
    final notif = await Permission.notification.status;
    _notifications = (notif.isGranted || notif.isLimited || notif.isDenied)
        ? _ReqState.ok
        : _ReqState.fail;
    if (notif.isPermanentlyDenied) _notifications = _ReqState.fail;

    setState(() => _checking = false);
  }

  Future<void> _requestLocation() async {
    await Permission.location.request();
    await Permission.locationWhenInUse.request();
    await _runChecks();
  }

  Future<void> _requestBluetooth() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetooth,
    ].request();
    await _runChecks();
  }

  Future<void> _requestNearby() async {
    await Permission.nearbyWifiDevices.request();
    await _runChecks();
  }

  Future<void> _requestNotifications() async {
    await Permission.notification.request();
    await _runChecks();
  }

  Future<void> _enableBluetooth() async {
    try {
      await Nearby().enableBluetooth();
    } catch (_) {}
    await _runChecks();
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    await context.read<AppProvider>().init();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RadarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking && _platformOk == _ReqState.unknown) {
      return _splash();
    }

    if (!Platform.isAndroid) {
      return _errorScreen('This app currently runs on Android only.');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080F08),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '◎',
                    style: TextStyle(color: Color(0xFF00FF41), fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GHOST MESH',
                        style: TextStyle(
                          color: Color(0xFF00FF41),
                          fontFamily: 'monospace',
                          fontSize: 18,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PRE-FLIGHT CHECK',
                        style: TextStyle(
                          color: const Color(0xFF00FF41).withOpacity(0.6),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _check(
                      label: 'Location permission',
                      state: _location,
                      hint: 'Required so Bluetooth scanning works',
                      onFix: _requestLocation,
                      fixLabel: 'Grant',
                    ),
                    _check(
                      label: 'Location service (GPS)',
                      state: _locationService,
                      hint: 'Swipe down from top → turn on Location',
                      onFix: _runChecks,
                      fixLabel: 'I turned it on',
                    ),
                    _check(
                      label: 'Bluetooth permission',
                      state: _bluetooth,
                      hint: 'Scan, advertise, connect to nearby phones',
                      onFix: _requestBluetooth,
                      fixLabel: 'Grant',
                    ),
                    _check(
                      label: 'Bluetooth service',
                      state: _bluetoothService,
                      hint: 'Bluetooth must be turned on',
                      onFix: _enableBluetooth,
                      fixLabel: 'Turn on',
                    ),
                    _check(
                      label: 'Nearby Wi-Fi devices',
                      state: _nearby,
                      hint: 'For faster peer-to-peer transfer',
                      onFix: _requestNearby,
                      fixLabel: 'Grant',
                    ),
                    _check(
                      label: 'Notifications',
                      state: _notifications,
                      hint: 'Get notified when a peer messages you',
                      onFix: _requestNotifications,
                      fixLabel: 'Grant',
                    ),
                  ],
                ),
              ),
              if (!_allOk)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFCC00).withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'XIAOMI / HUAWEI USERS',
                        style: TextStyle(
                          color: Color(0xFFFFCC00),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'If "Grant" buttons do nothing, open app\nsettings manually and turn on every\npermission.',
                        style: TextStyle(
                          color: const Color(0xFFFFCC00).withOpacity(0.85),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _openSettings,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFFCC00),
                          ),
                          child: const Text(
                            'OPEN APP SETTINGS',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allOk
                        ? const Color(0xFF1A4A1A)
                        : const Color(0xFF1A1A1A),
                    foregroundColor: _allOk
                        ? const Color(0xFF00FF41)
                        : const Color(0xFF555555),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: _allOk
                            ? const Color(0xFF00FF41)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  onPressed: _allOk && !_starting ? _start : null,
                  child: _starting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FF41),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _allOk ? 'ENTER MESH ▶' : 'FIX ISSUES ABOVE',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _check({
    required String label,
    required _ReqState state,
    required String hint,
    required VoidCallback onFix,
    required String fixLabel,
  }) {
    Color color;
    IconData icon;
    switch (state) {
      case _ReqState.ok:
        color = const Color(0xFF00FF41);
        icon = Icons.check_circle;
        break;
      case _ReqState.fail:
        color = const Color(0xFFFF5544);
        icon = Icons.cancel;
        break;
      case _ReqState.unknown:
        color = const Color(0xFF555555);
        icon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A0A),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFCCFFCC),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: TextStyle(
                    color: const Color(0xFF66CC66).withOpacity(0.8),
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (state != _ReqState.ok) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onFix,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFCC00),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                fixLabel.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _splash() {
    return Scaffold(
      backgroundColor: const Color(0xFF080F08),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '◎',
              style: TextStyle(color: Color(0xFF00FF41), fontSize: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'GHOST MESH',
              style: TextStyle(
                color: Color(0xFF00FF41),
                fontFamily: 'monospace',
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Color(0xFF00FF41),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorScreen(String msg) => Scaffold(
        backgroundColor: const Color(0xFF080F08),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF5544),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}

enum _ReqState { unknown, ok, fail }
