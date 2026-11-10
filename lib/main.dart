import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/universee_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniverSeeApp());
}

class UniverSeeApp extends StatelessWidget {
  const UniverSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniverSee Assistance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFFF97316),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),
      home: const QuickSupportPage(),
    );
  }
}

class QuickSupportPage extends StatefulWidget {
  const QuickSupportPage({super.key});

  @override
  State<QuickSupportPage> createState() => _QuickSupportPageState();
}

class _QuickSupportPageState extends State<QuickSupportPage> {
  final UniverSeeService _service = UniverSeeService();
  String _id = '--- --- ---';
  String _pin = '----';
  ConnectionStateEnum _state = ConnectionStateEnum.disconnected;
  String _statusLog = '';

  @override
  void initState() {
    super.initState();
    _service.onCredentialsChange = (id, pin) {
      if (mounted) setState(() { _id = id; _pin = pin; });
    };
    _service.onStateChange = (state) {
      if (mounted) setState(() { _state = state; });
    };
    _service.onLog = (log) {
      if (mounted) setState(() { _statusLog = log; });
    };
    _service.init();
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: _id));
    Fluttertoast.showToast(
      msg: 'Identifiant copié !',
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
    );
  }

  void _copyPin() {
    Clipboard.setData(ClipboardData(text: _pin));
    Fluttertoast.showToast(
      msg: 'Code PIN copié !',
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
    );
  }

  void _toggleSharing() async {
    if (_state == ConnectionStateEnum.inSession) {
      _service.stopScreenSharing();
    } else {
      await _service.startScreenSharing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInSession = _state == ConnectionStateEnum.inSession;
    final bool isReady = _state == ConnectionStateEnum.ready;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Header & Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.write != null ? null : Border.all(color: const Color(0xFFF97316).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.screen_share, color: Color(0xFFF97316), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'UniverSee',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Universal Move Assistance',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isInSession
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : (isReady
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : Colors.redAccent.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isInSession
                        ? const Color(0xFF10B981)
                        : (isReady ? const Color(0xFF10B981).withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInSession || isReady ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isInSession
                          ? 'Session active avec le technicien'
                          : (isReady ? 'Prêt pour la connexion' : 'Connexion au serveur...'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isInSession || isReady ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Credentials Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363D)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Support ID
                    const Text(
                      'VOTRE IDENTIFIANT D\'ASSISTANCE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _copyId,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _id,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                fontFamily: 'monospace',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy, size: 20, color: Color(0xFFF97316)),
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Color(0xFF30363D), height: 32),

                    // Security PIN
                    const Text(
                      'CODE PIN TEMPORAIRE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _copyPin,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF30363D)),
                            ),
                            child: Text(
                              _pin,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 5.0,
                                fontFamily: 'monospace',
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.grey, size: 22),
                          onPressed: () => _service.regeneratePin(),
                          tooltip: 'Générer un nouveau PIN',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status log or message
              if (_statusLog.isNotEmpty)
                Text(
                  _statusLog,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

              const Spacer(),

              // Big Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _toggleSharing,
                  icon: Icon(
                    isInSession ? Icons.stop_circle : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    isInSession ? 'Arrêter le partage' : 'Démarrer le partage d\'écran',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInSession ? Colors.redAccent : const Color(0xFFF97316),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Security Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Chiffrement direct P2P • Universal Move Tech',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
