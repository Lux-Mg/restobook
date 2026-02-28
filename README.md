# RestoBook

Мобильное приложение для бронирования столиков в ресторанах . Разработано на Flutter.

## Функциональность

- Вход через Telegram (OTP-код)
- Просмотр 3 ресторанов с фото и меню
- Бронирование столика (дата, время, количество гостей)
- Список бронирований с возможностью отмены
- Сохранение сессии и бронирований между запусками

## Требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) версии 3.11.0 или выше
- Android SDK (устанавливается вместе с Android Studio)
- Подключение к интернету (для аутентификации через Telegram)

Проверить версию Flutter:
```bash
flutter --version
```

## Установка зависимостей

```bash
flutter pub get
```

## Запуск в режиме разработки

Подключить Android-устройство через USB с включённой отладкой USB, затем:

```bash
flutter run
```

## Сборка APK-файла (командная строка)

### Release APK (для установки на устройство)

```bash
flutter build apk --release
```

Готовый APK будет находиться по пути:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Debug APK (для тестирования)

```bash
flutter build apk --debug
```

## Установка APK на устройство

**Через USB:**
```bash
flutter install
```

**Вручную:** передать файл `app-release.apk` на устройство (через Telegram, WhatsApp и т.д.) и открыть для установки. При появлении предупреждения разрешить установку из неизвестных источников.

## Структура проекта

```
restobook/
├── lib/
│   └── main.dart          # Весь код приложения
├── assets/
│   └── images/            # Изображения ресторанов и меню
├── pubspec.yaml            # Зависимости проекта
└── README.md              # Данный файл
```

## Зависимости

| Пакет | Назначение |
|---|---|
| `http` | HTTP-запросы к серверу верификации |
| `shared_preferences` | Локальное сохранение сессии и бронирований |
| `url_launcher` | Открытие Telegram для получения OTP |
| `flutter_localizations` | Локализация (русский язык) |

## Backend

Сервер верификации OTP развёрнут на Railway:
`https://web-production-86f86.up.railway.app`

Исходный код backend: https://github.com/Lux-Mg/restobook-bot
