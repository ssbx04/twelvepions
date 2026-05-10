import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_endpoints.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentToken;
  Timer? _reconnectTimer;

  Future<void> connect(String token) async {
    _currentToken = token;
    _reconnectTimer?.cancel();

    if (_isConnected) return;

    try {
      final wsUrl = Uri.parse('${ApiEndpoints.wsUrl}?token=$token');
      debugPrint('🔌 Connexion WS à $wsUrl...');
      
      _channel = WebSocketChannel.connect(wsUrl);
      
      _subscription = _channel?.stream.listen(
        (data) {
          if (!_isConnected) {
            _isConnected = true;
            debugPrint('🟢 WS Connecté');
          }
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(json);
          } catch (e) {
            debugPrint('⚠️ Erreur parsing JSON WS: $e');
          }
        },
        onError: (error) {
          debugPrint('🔴 WS Erreur: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('⚪ WS Déconnecté');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('🔴 Erreur initialisation WS: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_currentToken == null) return; // Déconnexion volontaire
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnected && _currentToken != null) {
        debugPrint('🔄 Tentative de reconnexion WS...');
        connect(_currentToken!);
      }
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      debugPrint('⚠️ Impossible d\'envoyer (WS déconnecté): $data');
    }
  }

  void disconnect() {
    _currentToken = null;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    debugPrint('🔌 WS Fermé (volontaire)');
  }
}
