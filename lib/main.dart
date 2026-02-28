import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UsuarioActual.cargarSesion();
  await ReservasStorage.cargar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RestoBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red, fontFamily: 'Roboto'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      locale: const Locale('ru', 'RU'),
      // Si hay sesión guardada, ir directo a MainScreen
      home: UsuarioActual.nombre.isNotEmpty
          ? const MainScreen()
          : const LoginScreen(),
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
  },
  {
    'nombre': 'Ресторан Los Amigos',
    'foto': 'assets/images/rest2.webp',
    'telefono': '+7 (391) 252-73-61',
    'direccion': 'пр. Мира, 10, Красноярск',
    'horario': '11:00 – 00:00 (Пн–Вс)',
  },
  {
    'nombre': 'Ресторан Picante!',
    'foto': 'assets/images/rest3.webp',
    'telefono': '+7 (391) 252-73-62',
    'direccion': 'пр. Мира, 10, Красноярск',
    'horario': '12:00 – 01:00 (Пн–Вс)',
  },
];

final Map<String, String> menuImages = {
  'Ресторан Дон Лучо': 'assets/images/menu1.jpg',
  'Ресторан Los Amigos': 'assets/images/menu2.jpg',
  'Ресторан Picante!': 'assets/images/menu3.webp',
};

// ─── MODELO RESERVA ───────────────────────────────────────────────────────────
class Reserva {
  final String restaurante;
  final String fecha;
  final String hora;
  final int personas;
  final String estado;

  Reserva({
    required this.restaurante,
    required this.fecha,
    required this.hora,
    required this.personas,
    this.estado = 'Ожидает подтверждения',
  });

  Map<String, dynamic> toJson() => {
        'restaurante': restaurante,
        'fecha': fecha,
        'hora': hora,
        'personas': personas,
        'estado': estado,
      };

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
        restaurante: json['restaurante'],
        fecha: json['fecha'],
        hora: json['hora'],
        personas: json['personas'],
        estado: json['estado'],
      );
}

List<Reserva> reservas = [];

class ReservasStorage {
  static Future<void> guardar() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = reservas.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('reservas', lista);
  }

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('reservas') ?? [];
    reservas = lista.map((s) => Reserva.fromJson(jsonDecode(s))).toList();
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
              MaterialPageRoute(builder: (context) => const OtpScreen()),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Добро пожаловать в RestoBook!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text(
                'Войдите, чтобы продолжить',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _loginWithTelegram(context),
                  icon: const Icon(
                    Icons.telegram,
                    size: 32,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Войти через Telegram',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0088CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Вход по email скоро будет доступен'),
                    ),
                  );
                },
                child: const Text(
                  'Войти по email и паролю',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
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

  static const String botApiUrl = 'https://web-production-86f86.up.railway.app/verify';

  @override
  void initState() {
    super.initState();
    _focusNodes[0].addListener(() {
      if (_focusNodes[0].hasFocus) _checkClipboard();
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
            MaterialPageRoute(builder: (context) => const MainScreen()),
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
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
              const CircularProgressIndicator(color: Colors.red)
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _verificarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
              onPressed: _limpiarCampos,
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
        selectedItemColor: Colors.red,
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

// ─── HOME SCREEN ──────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: restaurantes.length,
          itemBuilder: (context, index) {
            final rest = restaurantes[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RestaurantDetailScreen(restaurant: rest),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.asset(
                        rest['foto']!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.restaurant,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        rest['nombre']!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── RESTAURANT DETAIL ────────────────────────────────────────────────────────
class RestaurantDetailScreen extends StatelessWidget {
  final Map<String, String> restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  Future<void> _openMap() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(restaurant['direccion']!)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error abriendo mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant['nombre']!),
        backgroundColor: Colors.red,
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
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NuevaReservaScreen(
                                restaurante: restaurant['nombre']!,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Забронировать',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuScreen(
                                restaurante: restaurant['nombre']!,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            const Text('Меню', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Divider(color: Colors.grey, thickness: 1, height: 32),
                  _buildInfoRow(Icons.phone, restaurant['telefono']!),
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
  int _personas = 2;

  final List<String> _horarios = [
    for (int h = 12; h <= 23; h++)
      for (int m = 0; m < 60; m += 30)
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
    '00:00',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmarReserva() async {
    if (_selectedDate == null || _selectedHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите дату и время')),
      );
      return;
    }

    reservas.add(
      Reserva(
        restaurante: widget.restaurante,
        fecha:
            '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
        hora: _selectedHora!,
        personas: _personas,
      ),
    );
    await ReservasStorage.guardar();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Бронь подтверждена (ожидает подтверждения)'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Бронирование в ${widget.restaurante}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
            DropdownButtonFormField<String>(
              value: _selectedHora,
              hint: const Text('Выбрать время'),
              items: _horarios.map((hora) {
                return DropdownMenuItem<String>(value: hora, child: Text(hora));
              }).toList(),
              onChanged: (value) => setState(() => _selectedHora = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
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
                  color: Colors.red,
                  onPressed: () {
                    if (_personas > 1) setState(() => _personas--);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '$_personas',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.red,
                  onPressed: () => setState(() => _personas++),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmarReserva,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Подтвердить бронирование',
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
        backgroundColor: Colors.red,
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
            child: const Text(
              'Да, отменить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => reservas.removeAt(index));
      await ReservasStorage.guardar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои бронирования'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: reservas.isEmpty
          ? const Center(
              child: Text(
                'У вас пока нет бронирований',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservas.length,
              itemBuilder: (context, index) {
                final reserva = reservas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.book_online,
                      color: Colors.red,
                      size: 40,
                    ),
                    title: Text(
                      reserva.restaurante,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${reserva.fecha} • ${reserva.hora} • ${reserva.personas} чел.\nСтатус: ${reserva.estado}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () => _cancelarReserva(index),
                    ),
                  ),
                );
              },
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
        backgroundColor: Colors.red,
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
                  reservas.clear();
                  await ReservasStorage.guardar();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
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
