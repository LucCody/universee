import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStateEnum {
  disconnected,
  connecting,
  ready,
  inSession
}

class UniverSeeService {
  static final UniverSeeService _instance = UniverSeeService._internal();
  factory UniverSeeService() => _instance;
  UniverSeeService._internal();

  WebSocketChannel? _channel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCDataChannel? _dataChannel;

  String supportId = '';
  String securityPin = '';
  ConnectionStateEnum state = ConnectionStateEnum.disconnected;

  Function(ConnectionStateEnum state)? onStateChange;
  Function(String id, String pin)? onCredentialsChange;
  Function(String message)? onLog;

  final String signalingUrl = 'wss://universalmove.tech/universee-ws';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    supportId = prefs.getString('universee_id') ?? '';
    if (supportId.isEmpty) {
      supportId = _generateRandomId();
      await prefs.setString('universee_id', supportId);
    }
    securityPin = _generateRandomPin();
    onCredentialsChange?.call(supportId, securityPin);

    connectSignaling();
  }

  void regeneratePin() {
    securityPin = _generateRandomPin();
    onCredentialsChange?.call(supportId, securityPin);
    // Re-register with new PIN
    _send({
      'type': 'register_host',
      'id': supportId,
      'pin': securityPin,
      'os': Platform.operatingSystem,
      'name': 'UniverSee Client ()',
    });
  }

  String _generateRandomId() {
    final rnd = Random();
    final part1 = 100 + rnd.nextInt(900);
    final part2 = 100 + rnd.nextInt(900);
    final part3 = 100 + rnd.nextInt(900);
    return '\ \ \';
  }

  String _generateRandomPin() {
    final rnd = Random();
    return (1000 + rnd.nextInt(9000)).toString();
  }

  void connectSignaling() {
    try {
      _updateState(ConnectionStateEnum.connecting);
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(signalingUrl));

      _channel!.stream.listen(
        (data) => _handleSignalingMessage(data),
        onDone: () {
          _updateState(ConnectionStateEnum.disconnected);
          // Auto reconnect after 5s
          Future.delayed(const Duration(seconds: 5), () {
            if (state == ConnectionStateEnum.disconnected) {
              connectSignaling();
            }
          });
        },
        onError: (err) {
          onLog?.call('Erreur WebSocket: \');
          _updateState(ConnectionStateEnum.disconnected);
        },
      );

      // Register host
      _send({
        'type': 'register_host',
        'id': supportId,
        'pin': securityPin,
        'os': Platform.operatingSystem,
        'name': 'UniverSee Client ()',
      });
    } catch (e) {
      _updateState(ConnectionStateEnum.disconnected);
      onLog?.call('Erreur connexion: \');
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _updateState(ConnectionStateEnum newState) {
    state = newState;
    onStateChange?.call(state);
  }

  Future<void> _handleSignalingMessage(dynamic raw) async {
    try {
      final msg = jsonDecode(raw.toString());
      final type = msg['type'];

      switch (type) {
        case 'registered':
          _updateState(ConnectionStateEnum.ready);
          onLog?.call('Connecté au serveur UniverSee Relay.');
          break;

        case 'agent_connected':
          onLog?.call('Technicien Universal Move connecté ! Préparation de l écran...');
          break;

        case 'webrtc_offer':
          await _handleOffer(msg['sdp']);
          break;

        case 'webrtc_ice':
          if (_peerConnection != null && msg['candidate'] != null) {
            final c = msg['candidate'];
            await _peerConnection!.addCandidate(
              RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
            );
          }
          break;

        case 'agent_disconnected':
        case 'session_ended_by_agent':
          stopScreenSharing();
          _updateState(ConnectionStateEnum.ready);
          regeneratePin();
          onLog?.call('Session terminée par le technicien.');
          break;
      }
    } catch (e) {
      onLog?.call('Erreur message: \');
    }
  }

  Future<void> _handleOffer(String sdp) async {
    try {
      final config = {
        'iceServers': [
          {'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']}
        ]
      };

      _peerConnection = await createPeerConnection(config);

      // ICE candidates
      _peerConnection!.onIceCandidate = (candidate) {
        _send({
          'type': 'webrtc_ice',
          'candidate': candidate.toMap(),
        });
      };

      // DataChannel
      _peerConnection!.onDataChannel = (channel) {
        _dataChannel = channel;
        _dataChannel!.onMessage = (message) {
          _handleDataChannelMessage(message.text);
        };
      };

      // Set Remote Description
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp, 'offer'),
      );

      // Start screen capture if not already started
      if (_localStream == null) {
        await startScreenSharing();
      }

      // Add local stream tracks to peer
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          _peerConnection!.addTrack(track, _localStream!);
        }
      }

      // Create Answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _send({
        'type': 'webrtc_answer',
        'sdp': answer.sdp,
      });

      _updateState(ConnectionStateEnum.inSession);
      onLog?.call('Partage d écran en direct avec le technicien.');
    } catch (e) {
      onLog?.call('Erreur WebRTC Offer: \');
    }
  }

  Future<bool> startScreenSharing() async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        }
      };

      _localStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      _updateState(ConnectionStateEnum.inSession);
      return true;
    } catch (e) {
      onLog?.call('Permission de capture d écran refusée: \');
      return false;
    }
  }

  void stopScreenSharing() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _peerConnection?.close();
    _peerConnection = null;

    _dataChannel?.close();
    _dataChannel = null;

    _updateState(ConnectionStateEnum.ready);
  }

  void _handleDataChannelMessage(String raw) {
    try {
      final msg = jsonDecode(raw);
      // Remote control events: mouse_move, tap, android_nav, clipboard
      onLog?.call('Action reçue: \');
    } catch (e) {
      // Ignored
    }
  }

  void dispose() {
    stopScreenSharing();
    _channel?.sink.close();
  }
}
