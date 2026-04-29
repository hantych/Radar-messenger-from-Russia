import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/peer.dart';
import '../providers/app_provider.dart';
import '../widgets/radar_painter.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  void _openChat(Peer peer) {
    context.read<AppProvider>().setActiveChat(peer.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(peer: peer)),
    ).then((_) {
      if (mounted) {
        context.read<AppProvider>().setActiveChat(null);
      }
    });
  }

  Color _stateColor(PeerState s) {
    switch (s) {
      case PeerState.connected:
        return const Color(0xFF00FF41);
      case PeerState.connecting:
        return const Color(0xFFFFCC00);
      case PeerState.discovered:
        return const Color(0xFF66CCFF);
      case PeerState.disconnected:
        return const Color(0xFF555555);
    }
  }

  String _stateLabel(PeerState s) {
    switch (s) {
      case PeerState.connected:
        return '● ONLINE';
      case PeerState.connecting:
        return '◐ LINKING';
      case PeerState.discovered:
        return '○ FOUND';
      case PeerState.disconnected:
        return '· OFFLINE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final peers = provider.peerList
        .where((p) => p.state != PeerState.disconnected)
        .toList()
      ..sort((a, b) {
        // connected first, then connecting, then discovered
        return a.state.index.compareTo(b.state.index);
      });

    final connectedCount =
        peers.where((p) => p.state == PeerState.connected).length;

    return Scaffold(
      backgroundColor: const Color(0xFF080F08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            // Pulsing scan dot
            AnimatedBuilder(
              animation: _sweep,
              builder: (_, __) {
                final t =
                    (math.sin(_sweep.value * 2 * math.pi) + 1) / 2; // 0..1
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      const Color(0xFF003311),
                      const Color(0xFF00FF41),
                      t,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GHOST MESH',
                    style: TextStyle(
                      color: Color(0xFF00FF41),
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    '${provider.myName.toUpperCase()}  ·  $connectedCount/${peers.length} ONLINE',
                    style: const TextStyle(
                      color: Color(0xFF00A828),
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Color(0xFF00FF41), size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) {
                return CustomPaint(
                  painter: RadarPainter(
                    peers: peers,
                    sweepAngle: _sweep.value * 2 * math.pi,
                    myName: provider.myName,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          if (peers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: const Column(
                children: [
                  Text(
                    '◌  SCANNING…',
                    style: TextStyle(
                      color: Color(0xFF00FF41),
                      fontFamily: 'monospace',
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Make sure the other phone has Ghost Mesh open\nand both have Bluetooth + Location ON.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF00A828),
                      fontFamily: 'monospace',
                      fontSize: 10,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A0A),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF00FF41).withOpacity(0.25),
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: peers.length,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemBuilder: (context, i) =>
                    _peerTile(peers[i], provider),
              ),
            ),
        ],
      ),
    );
  }

  Widget _peerTile(Peer peer, AppProvider provider) {
    final color = _stateColor(peer.state);
    final isLive = peer.isConnected;

    final messages = provider.messagesFor(peer.id);
    final unread = messages.where((m) =>
        !m.isMine &&
        m.timestamp.isAfter(
          DateTime.now().subtract(const Duration(minutes: 5)),
        )).length;

    return GestureDetector(
      onTap: isLive ? () => _openChat(peer) : null,
      child: Opacity(
        opacity: isLive ? 1 : 0.55,
        child: Container(
          width: 130,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF0D1F0D),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _stateLabel(peer.state),
                          style: TextStyle(
                            color: color,
                            fontFamily: 'monospace',
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    peer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCCFFCC),
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (isLive)
                    Text(
                      'TAP TO CHAT',
                      style: TextStyle(
                        color: color.withOpacity(0.6),
                        fontFamily: 'monospace',
                        fontSize: 8,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
              if (unread > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF41),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Color(0xFF080F08),
                        fontFamily: 'monospace',
                        fontSize: 9,
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
}
