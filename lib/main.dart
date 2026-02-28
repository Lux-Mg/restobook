import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Transición suave con fade para todas las pantallas
PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UsuarioActual.cargarSesion();
  // READ: cargar todas las reservas desde SQLite al arrancar
  reservas = await ReservasDB.getReservas();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RestoBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          primary: const Color(0xFF0B6E4F),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyMedium: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2D2D2D)),
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF2D2D2D)),
          titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
          titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0B6E4F),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B6E4F),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B6E4F), width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0B6E4F),
          unselectedItemColor: Colors.grey[500],
          elevation: 12,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      locale: const Locale('ru', 'RU'),
      home: const SplashScreen(),
    );
  }
}

// ─── USUARIO GLOBAL ───────────────────────────────────────────────────────────
class UsuarioActual {
  static String nombre = '';
  static String telegramId = '';

  static Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    nombre = prefs.getString('nombre') ?? '';
    telegramId = prefs.getString('telegramId') ?? '';
  }

  static Future<void> guardarSesion(String nom, String tgId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nom);
    await prefs.setString('telegramId', tgId);
    nombre = nom;
    telegramId = tgId;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nombre');
    await prefs.remove('telegramId');
    nombre = '';
    telegramId = '';
  }
}

// ─── RESTAURANTES ─────────────────────────────────────────────────────────────
final List<Map<String, String>> restaurantes = [
  {
    'nombre': 'Ресторан Дон Лучо',
    'foto': 'assets/images/rest1.webp',
    'telefono': '+7 (391) 252-73-60',
    'direccion': 'пр. Мира, 10, Красноярск',
    'horario': '10:00 – 23:00 (Пн–Вс)',
    'descripcion':
        'Изысканная латиноамериканская кухня в сердце города. Уютная атмосфера, живая музыка и авторские коктейли — идеальное место для особых вечеров.',
  },
  {
    'nombre': 'Ресторан Los Amigos',
    'foto': 'assets/images/rest2.webp',
    'telefono': '+7 (391) 252-73-61',
    'direccion': 'ул. Ленина, 7, Красноярск',
    'horario': '11:00 – 00:00 (Пн–Вс)',
    'descripcion':
        'Семейный ресторан с тёплой атмосферой и традиционными блюдами мексиканской и испанской кухни. Здесь каждый гость чувствует себя как дома.',
  },
  {
    'nombre': 'Ресторан Picante!',
    'foto': 'assets/images/rest3.webp',
    'telefono': '+7 (391) 252-73-62',
    'direccion': 'ул. Карла Маркса, 49, Красноярск',
    'horario': '12:00 – 01:00 (Пн–Вс)',
    'descripcion':
        'Острые и пикантные блюда со всего мира. Идеально для любителей ярких вкусов и необычных сочетаний. Каждое блюдо — это маленькое приключение.',
  },
];

// Coordenadas reales en Красноярск para cada restaurante
final Map<String, LatLng> restaurantCoords = {
  'Ресторан Дон Лучо': const LatLng(56.0159, 92.8684),
  'Ресторан Los Amigos': const LatLng(56.0100, 92.8531),
  'Ресторан Picante!': const LatLng(56.0230, 92.8750),
};

final Map<String, String> menuImages = {
  'Ресторан Дон Лучо': 'assets/images/menu1.jpg',
  'Ресторан Los Amigos': 'assets/images/menu2.jpg',
  'Ресторан Picante!': 'assets/images/menu3.webp',
};

// ─── MODELO RESERVA ───────────────────────────────────────────────────────────
class Reserva {
  int? localId;            // Clave primaria SQLite (asignada por la BD)
  final String restaurante;
  final String fecha;
  final String hora;
  final String horaFin;
  final int personas;
  final String comentario;
  final String telefono;
  String estado;
  String? id;              // ID del backend Railway

  Reserva({
    this.localId,
    required this.restaurante,
    required this.fecha,
    required this.hora,
    required this.horaFin,
    required this.personas,
    this.comentario = '',
    this.telefono = '',
    this.estado = 'Ожидает подтверждения',
    this.id,
  });

  // Convierte la reserva a Map para INSERT/UPDATE en SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'restaurante': restaurante,
      'fecha': fecha,
      'hora': hora,
      'horaFin': horaFin,
      'personas': personas,
      'comentario': comentario,
      'telefono': telefono,
      'estado': estado,
      'backendId': id,
    };
    if (localId != null) map['localId'] = localId;
    return map;
  }

  // Crea una Reserva desde una fila de SQLite
  factory Reserva.fromMap(Map<String, dynamic> map) => Reserva(
        localId: map['localId'] as int?,
        restaurante: map['restaurante'] as String,
        fecha: map['fecha'] as String,
        hora: map['hora'] as String,
        horaFin: (map['horaFin'] as String?) ?? '',
        personas: map['personas'] as int,
        comentario: (map['comentario'] as String?) ?? '',
        telefono: (map['telefono'] as String?) ?? '',
        estado: (map['estado'] as String?) ?? 'Ожидает подтверждения',
        id: map['backendId'] as String?,
      );
}

List<Reserva> reservas = [];

// ─── BASE DE DATOS LOCAL (SQLite) ─────────────────────────────────────────────
class ReservasDB {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'restobook.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reservas (
            localId     INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurante TEXT    NOT NULL,
            fecha       TEXT    NOT NULL,
            hora        TEXT    NOT NULL,
            horaFin     TEXT    NOT NULL,
            personas    INTEGER NOT NULL,
            comentario  TEXT    DEFAULT '',
            telefono    TEXT    DEFAULT '',
            estado      TEXT    NOT NULL,
            backendId   TEXT
          )
        ''');
      },
    );
  }

  // ── CREATE ── Inserta una reserva y devuelve su localId asignado
  static Future<int> insertReserva(Reserva r) async {
    final db = await _database;
    return db.insert('reservas', r.toMap());
  }

  // ── READ ── Obtiene todas las reservas ordenadas por fecha de creación
  static Future<List<Reserva>> getReservas() async {
    final db = await _database;
    final maps = await db.query('reservas', orderBy: 'localId ASC');
    return maps.map(Reserva.fromMap).toList();
  }

  // ── UPDATE ── Actualiza el estado de una reserva
  static Future<void> updateEstado(int localId, String estado) async {
    final db = await _database;
    await db.update(
      'reservas',
      {'estado': estado},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  // ── UPDATE ── Guarda el backendId cuando el servidor responde
  static Future<void> updateBackendId(int localId, String backendId) async {
    final db = await _database;
    await db.update(
      'reservas',
      {'backendId': backendId},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  // ── DELETE ── Elimina permanentemente una reserva de la base de datos
  static Future<void> deleteReserva(int localId) async {
    final db = await _database;
    await db.delete(
      'reservas',
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }
}

// ─── SPLASH SCREEN ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        _fadeRoute(
          UsuarioActual.nombre.isNotEmpty
              ? const MainScreen()
              : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B6E4F),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'RestoBook',
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Бронирование столиков',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  final String botUsername = 'RestobkBot';

  Future<void> _loginWithTelegram(BuildContext context) async {
    final List<Uri> urls = [
      Uri.parse('tg://resolve?domain=$botUsername&start=login'),
      Uri.parse('tg://resolve?domain=$botUsername'),
      Uri.parse('https://t.me/$botUsername?start=login'),
    ];

    for (final url in urls) {
      try {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          if (context.mounted) {
            Navigator.push(
              context,
              _fadeRoute(const OtpScreen()),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Falló $url: $e');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir Telegram. Verifica que esté instalado.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // ── Header rojo con logo ──────────────────────────────
          Expanded(
            flex: 45,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0B6E4F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'RestoBook',
                      style: GoogleFonts.poppins(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Бронирование столиков',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Área de login ─────────────────────────────────────
          Expanded(
            flex: 55,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добро пожаловать!',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Войдите, чтобы забронировать\nстолик в любимом ресторане',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _loginWithTelegram(context),
                      icon: const Icon(Icons.telegram, size: 26, color: Colors.white),
                      label: Text(
                        'Войти через Telegram',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088CC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OTP SCREEN ───────────────────────────────────────────────────────────────
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  bool _ignorarClipboard = false;

  static const String botApiUrl = 'https://web-production-86f86.up.railway.app/verify';

  @override
  void initState() {
    super.initState();
    _focusNodes[0].addListener(() {
      if (_focusNodes[0].hasFocus && !_ignorarClipboard) _checkClipboard();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final texto = data!.text!.trim();
      if (texto.length == 6 && RegExp(r'^\d{6}$').hasMatch(texto)) {
        _pegarCodigo(texto);
      }
    }
  }

  void _pegarCodigo(String codigo) {
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = codigo[i];
    }
    _focusNodes[5].requestFocus();
    setState(() => _errorMessage = null);
    _verificarCodigo();
  }

  String get _codigoCompleto => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value)) {
      _pegarCodigo(value);
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _errorMessage = null);
    if (_codigoCompleto.length == 6) _verificarCodigo();
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoCompleto;
    if (codigo.length < 6) {
      setState(() => _errorMessage = 'Введите все 6 цифр');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(botApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': codigo}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          // Guardar sesión para no pedir código al minimizar
          await UsuarioActual.guardarSesion(
            data['name'] ?? '',
            data['telegram_id'] ?? '',
          );

          Navigator.pushAndRemoveUntil(
            context,
            _fadeRoute(const MainScreen()),
            (route) => false,
          );
        } else {
          setState(() => _errorMessage = 'Неверный или просроченный код');
          _limpiarCampos();
        }
      } else {
        setState(() => _errorMessage = 'Ошибка сервера. Попробуйте ещё раз.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Нет соединения с сервером');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _limpiarCampos() {
    for (final c in _controllers) c.clear();
    setState(() {
      _errorMessage = null;
      _isLoading = false;
    });
  }

  Future<void> _pedirNuevoCodigo() async {
    _ignorarClipboard = true;
    _limpiarCampos();
    // Intentar abrir Telegram nativo primero, luego fallback a web
    final urls = [
      Uri.parse('tg://resolve?domain=RestobkBot&start=login'),
      Uri.parse('tg://resolve?domain=RestobkBot'),
      Uri.parse('https://t.me/RestobkBot?start=login'),
    ];
    for (final url in urls) {
      try {
        final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (ok) break;
      } catch (_) {}
    }
    await Future.delayed(const Duration(seconds: 3));
    _ignorarClipboard = false;
    if (mounted) _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.telegram, size: 72, color: Color(0xFF0088CC)),
            const SizedBox(height: 24),
            const Text(
              'Введите код из Telegram',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Мы отправили 6-значный код\nвашему боту @RestobkBot',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: _errorMessage != null
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0088CC),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onDigitEntered(index, value),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFF0B6E4F))
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _verificarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Подтвердить',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _pedirNuevoCodigo,
              child: const Text(
                'Получить новый код',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const BookingsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0B6E4F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Бронирования',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

// ─── WEATHER CARD ─────────────────────────────────────────────────────────────
class _WeatherCard extends StatefulWidget {
  const _WeatherCard();
  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  double? _temp;
  int? _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final resp = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=56.0184&longitude=92.8672&current_weather=true',
      ));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final cw = data['current_weather'];
        setState(() {
          _temp = (cw['temperature'] as num).toDouble();
          _code = cw['weathercode'] as int;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _icon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    return '⛈️';
  }

  String _desc(int code) {
    if (code == 0) return 'Ясно';
    if (code <= 3) return 'Облачно';
    if (code <= 48) return 'Туман';
    if (code <= 67) return 'Дождь';
    if (code <= 77) return 'Снег';
    if (code <= 82) return 'Ливень';
    if (code <= 86) return 'Снегопад';
    return 'Гроза';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6E4F), Color(0xFF1A9E72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B6E4F).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _loading
          ? const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                Text(
                  _code != null ? _icon(_code!) : '🌡️',
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Красноярск',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      _temp != null
                          ? '${_temp!.toStringAsFixed(0)}°C  ${_code != null ? _desc(_code!) : ''}'
                          : 'Нет данных',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ─── HOME SCREEN ──────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 24),
            UsuarioActual.nombre.isNotEmpty
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Привет,\n',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D2D2D),
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: '${UsuarioActual.nombre}! 👋',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B6E4F),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    'Добро пожаловать!',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
            const SizedBox(height: 6),
            Text(
              'Выберите ресторан для бронирования',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const _WeatherCard(),
            ...restaurantes.map((rest) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    _fadeRoute(RestaurantDetailScreen(restaurant: rest)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  height: 210,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          rest['foto']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.restaurant,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.75),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              rest['nombre']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── RESTAURANT DETAIL ────────────────────────────────────────────────────────
class RestaurantDetailScreen extends StatelessWidget {
  final Map<String, String> restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  Future<void> _llamar() async {
    final tel = restaurant['telefono']!.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$tel');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Error al llamar: $e');
    }
  }

  Future<void> _openMap() async {
    final direccion = Uri.encodeComponent(restaurant['direccion']!);
    // geo: abre la app de mapas predeterminada del usuario (Google Maps, Yandex, etc.)
    final geoUri = Uri.parse('geo:0,0?q=$direccion');
    // Fallback: Google Maps en navegador
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$direccion',
    );
    try {
      final ok = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (!ok) await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error abriendo mapa: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant['nombre']!),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              restaurant['foto']!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['nombre']!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restaurant['descripcion'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              _fadeRoute(NuevaReservaScreen(
                                restaurante: restaurant['nombre']!,
                              )),
                            );
                          },
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.white),
                          label: const Text(
                            'Забронировать',
                            style: TextStyle(
                                fontSize: 15, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B6E4F),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              _fadeRoute(MenuScreen(
                                restaurante: restaurant['nombre']!,
                              )),
                            );
                          },
                          icon: const Icon(Icons.restaurant_menu,
                              color: Color(0xFF0B6E4F)),
                          label: const Text(
                            'Меню',
                            style: TextStyle(fontSize: 15, color: Color(0xFF0B6E4F)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF0B6E4F)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Divider(color: Colors.grey, thickness: 1, height: 32),
                  GestureDetector(
                    onTap: _llamar,
                    child: _buildInfoRow(Icons.phone, restaurant['telefono']!),
                  ),
                  const Divider(color: Colors.grey, thickness: 1, height: 32),
                  GestureDetector(
                    onTap: _openMap,
                    child: _buildInfoRow(
                      Icons.location_on,
                      restaurant['direccion']!,
                    ),
                  ),
                  const Divider(color: Colors.grey, thickness: 1, height: 32),
                  _buildInfoRow(Icons.access_time, restaurant['horario']!),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 220,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: restaurantCoords[restaurant['nombre']] ??
                              const LatLng(56.0184, 92.8672),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.restobook',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: restaurantCoords[restaurant['nombre']] ??
                                    const LatLng(56.0184, 92.8672),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFF0B6E4F),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.grey[700]),
          const SizedBox(width: 20),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}

// ─── NUEVA RESERVA ────────────────────────────────────────────────────────────
class NuevaReservaScreen extends StatefulWidget {
  final String restaurante;

  const NuevaReservaScreen({super.key, required this.restaurante});

  @override
  State<NuevaReservaScreen> createState() => _NuevaReservaScreenState();
}

class _NuevaReservaScreenState extends State<NuevaReservaScreen> {
  DateTime? _selectedDate;
  String? _selectedHora;
  String? _selectedHoraFin;
  int _personas = 2;
  final TextEditingController _comentarioController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final List<String> _horarios = [
    for (int h = 12; h <= 23; h++)
      for (int m = 0; m < 60; m += 30)
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
    '00:00',
  ];

  List<String> get _horariosDisponibles {
    if (_selectedDate == null) return _horarios;
    final now = DateTime.now();
    final isToday = _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
    if (!isToday) return _horarios;
    return _horarios.where((hora) {
      final h = int.parse(hora.split(':')[0]);
      final m = int.parse(hora.split(':')[1]);
      if (h == 0) return true; // medianoche siempre válida
      final slotTime = DateTime(now.year, now.month, now.day, h, m);
      return slotTime.isAfter(now.add(const Duration(minutes: 10)));
    }).toList();
  }

  List<String> get _horariosHoraFin {
    if (_selectedHora == null) return _horariosDisponibles;
    final base = _horariosDisponibles;
    final idx = base.indexOf(_selectedHora!);
    if (idx < 0 || idx >= base.length - 1) return base;
    return base.sublist(idx + 1).take(4).toList(); // máx 4 × 30 min = 2 horas
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedHora = null;
        _selectedHoraFin = null;
      });
    }
  }

  Future<void> _confirmarReserva() async {
    if (_selectedDate == null || _selectedHora == null || _selectedHoraFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите дату, время прихода и ухода'),
        ),
      );
      return;
    }
    final soloDigitos = _telefonoController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный номер телефона')),
      );
      return;
    }

    final fecha =
        '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить бронирование?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(Icons.restaurant, widget.restaurante),
            const SizedBox(height: 8),
            _summaryRow(Icons.calendar_today, fecha),
            const SizedBox(height: 8),
            _summaryRow(
                Icons.access_time, '$_selectedHora – $_selectedHoraFin'),
            const SizedBox(height: 8),
            _summaryRow(Icons.people, '$_personas чел.'),
            const SizedBox(height: 8),
            _summaryRow(Icons.phone, _telefonoController.text.trim()),
            if (_comentarioController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _summaryRow(Icons.comment, _comentarioController.text.trim()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Изменить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B6E4F)),
            child: const Text(
              'Подтвердить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final nuevaReserva = Reserva(
      restaurante: widget.restaurante,
      fecha: fecha,
      hora: _selectedHora!,
      horaFin: _selectedHoraFin!,
      personas: _personas,
      comentario: _comentarioController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );
    // CREATE: insertar la nueva reserva en SQLite
    final localId = await ReservasDB.insertReserva(nuevaReserva);
    nuevaReserva.localId = localId;
    reservas.add(nuevaReserva);

    // Enviar reserva al backend para notificar al restaurante
    try {
      final response = await http.post(
        Uri.parse('https://web-production-86f86.up.railway.app/reserva'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'restaurante': nuevaReserva.restaurante,
          'fecha':       nuevaReserva.fecha,
          'hora':        nuevaReserva.hora,
          'horaFin':     nuevaReserva.horaFin,
          'personas':    nuevaReserva.personas,
          'comentario':  nuevaReserva.comentario,
          'telefono':    nuevaReserva.telefono,
          'nombre':      UsuarioActual.nombre,
          'telegram_id': UsuarioActual.telegramId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        nuevaReserva.id = data['id'];
        // UPDATE: guardar el backendId en SQLite
        await ReservasDB.updateBackendId(localId, data['id']);
      }
    } catch (_) {
      // Si falla el envío al backend, la reserva sigue guardada localmente
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Бронь отправлена! Ожидайте подтверждения.')),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0B6E4F)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Бронирование в ${widget.restaurante}'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Дата',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(
                _selectedDate == null
                    ? 'Выбрать дату'
                    : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Время',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedHora,
                    hint: const Text('С:'),
                    items: _horariosDisponibles.map((hora) {
                      return DropdownMenuItem<String>(
                          value: hora, child: Text(hora));
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedHora = value;
                      _selectedHoraFin = null;
                    }),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Приход',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedHoraFin,
                    hint: const Text('До:'),
                    items: _horariosHoraFin.map((hora) {
                      return DropdownMenuItem<String>(
                          value: hora, child: Text(hora));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedHoraFin = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Уход',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Количество гостей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF0B6E4F),
                  onPressed: () {
                    if (_personas > 1) setState(() => _personas--);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '$_personas',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF0B6E4F),
                  onPressed: () => setState(() => _personas++),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Номер телефона',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
              decoration: InputDecoration(
                hintText: '+7 XXX XXX XX XX',
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF0B6E4F)),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                hintStyle: TextStyle(color: Colors.grey[400]),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Комментарий',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Особые пожелания, повод, аллергии...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmarReserva,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6E4F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Далее →',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MENU SCREEN ──────────────────────────────────────────────────────────────
class MenuScreen extends StatelessWidget {
  final String restaurante;

  const MenuScreen({super.key, required this.restaurante});

  @override
  Widget build(BuildContext context) {
    final menuImage =
        menuImages[restaurante] ?? 'https://picsum.photos/id/365/800/600';

    return Scaffold(
      appBar: AppBar(
        title: Text('Меню - $restaurante'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.asset(
            menuImage,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 80,
                color: Colors.grey,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── BOOKINGS SCREEN ──────────────────────────────────────────────────────────
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _actualizando = false;

  // Colores y etiquetas según el estado
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Подтверждено':
        return Colors.green;
      case 'Отклонено':
        return Colors.red;
      case 'Отменено':
        return Colors.grey;
      default:
        return Colors.orange; // Ожидает подтверждения
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'Подтверждено':
        return Icons.check_circle;
      case 'Отклонено':
        return Icons.cancel;
      case 'Отменено':
        return Icons.block;
      default:
        return Icons.schedule;
    }
  }

  // Consulta el estado actualizado de cada reserva pendiente
  Future<void> _actualizarEstados() async {
    setState(() => _actualizando = true);
    for (final reserva in reservas) {
      if (reserva.id == null || reserva.localId == null) continue;
      if (reserva.estado == 'Отменено') continue;
      try {
        final response = await http.get(
          Uri.parse('https://web-production-86f86.up.railway.app/estado?id=${reserva.id}'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final estadoBackend = data['estado'];
          String? nuevoEstado;
          if (estadoBackend == 'confirmada') {
            nuevoEstado = 'Подтверждено';
          } else if (estadoBackend == 'rechazada') {
            nuevoEstado = 'Отклонено';
          }
          if (nuevoEstado != null && reserva.estado != nuevoEstado) {
            reserva.estado = nuevoEstado;
            // UPDATE: actualizar estado en SQLite
            await ReservasDB.updateEstado(reserva.localId!, nuevoEstado);
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _actualizando = false);
  }

  Future<void> _cancelarReserva(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить бронирование?'),
        content: Text(
          '${reservas[index].restaurante}\n${reservas[index].fecha} • ${reservas[index].hora}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, отменить',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && reservas[index].localId != null) {
      // UPDATE: marcar como cancelada en SQLite
      await ReservasDB.updateEstado(reservas[index].localId!, 'Отменено');
      setState(() => reservas[index].estado = 'Отменено');
    }
  }

  Future<void> _eliminarReserva(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
          '${reservas[index].restaurante}\n${reservas[index].fecha} • ${reservas[index].hora}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && reservas[index].localId != null) {
      // DELETE: eliminar permanentemente de SQLite
      await ReservasDB.deleteReserva(reservas[index].localId!);
      setState(() => reservas.removeAt(index));
    }
  }

  bool _esPasada(Reserva reserva) {
    try {
      final partes = reserva.fecha.split('.');
      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final anio = int.parse(partes[2]);
      final horaParts = reserva.hora.split(':');
      final h = int.parse(horaParts[0]);
      final m = int.parse(horaParts[1]);
      return DateTime(anio, mes, dia, h, m).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Widget _sectionHeader(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva, int index, {bool showCancel = true, bool showDelete = false}) {
    final color = _colorEstado(reserva.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.book_online, color: const Color(0xFF0B6E4F), size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reserva.restaurante,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reserva.fecha}  •  ${reserva.hora}${reserva.horaFin.isNotEmpty ? ' – ${reserva.horaFin}' : ''}  •  ${reserva.personas} чел.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (reserva.comentario.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('💬 ${reserva.comentario}',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconoEstado(reserva.estado),
                            size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          reserva.estado,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Удалить',
                onPressed: () => _eliminarReserva(index),
              )
            else if (showCancel &&
                reserva.estado != 'Отменено' &&
                reserva.estado != 'Отклонено')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: () => _cancelarReserva(index),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proximas = <MapEntry<int, Reserva>>[];
    final historial = <MapEntry<int, Reserva>>[];
    for (int i = 0; i < reservas.length; i++) {
      final r = reservas[i];
      if (!_esPasada(r) && r.estado != 'Отменено' && r.estado != 'Отклонено') {
        proximas.add(MapEntry(i, r));
      } else {
        historial.add(MapEntry(i, r));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои бронирования'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
        actions: [
          _actualizando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Обновить статусы',
                  onPressed: _actualizarEstados,
                ),
        ],
      ),
      body: reservas.isEmpty
          ? const Center(
              child: Text(
                'У вас пока нет бронирований',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (proximas.isNotEmpty) ...[
                  _sectionHeader('ПРЕДСТОЯЩИЕ', Icons.upcoming),
                  ...proximas.map((e) => _buildReservaCard(e.value, e.key)),
                ],
                if (historial.isNotEmpty) ...[
                  if (proximas.isNotEmpty) const SizedBox(height: 8),
                  _sectionHeader('ИСТОРИЯ', Icons.history),
                  ...historial.map(
                      (e) => _buildReservaCard(e.value, e.key, showCancel: false, showDelete: true)),
                ],
              ],
            ),
    );
  }
}

// ─── PROFILE SCREEN ───────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF0088CC),
              child: Text(
                UsuarioActual.nombre.isNotEmpty
                    ? UsuarioActual.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              UsuarioActual.nombre.isNotEmpty
                  ? UsuarioActual.nombre
                  : 'Пользователь',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 20),
                const SizedBox(width: 6),
                Text(
                  'ID: ${UsuarioActual.telegramId}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(),
            _buildInfoTile(
              Icons.book_online,
              'Мои бронирования',
              '${reservas.length} бронирований',
            ),
            const Divider(),
            _buildInfoTile(Icons.verified_user, 'Статус аккаунта', 'Активен ✓'),
            const Divider(),
            _buildInfoTile(Icons.login, 'Способ входа', 'Telegram'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await UsuarioActual.cerrarSesion();
                  Navigator.pushAndRemoveUntil(
                    context,
                    _fadeRoute(const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
