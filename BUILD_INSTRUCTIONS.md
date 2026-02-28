# Инструкция по сборке APK — RestoBook

## Требования

| Инструмент | Версия |
|---|---|
| Flutter SDK | >= 3.11.0 |
| Dart SDK | >= 3.11.0 |
| Android SDK | API 21+ (Android 5.0) |
| Java JDK | 17+ |

---

## 1. Установка Flutter

1. Скачать Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Распаковать архив и добавить `flutter/bin` в PATH
3. Проверить установку:
   ```bash
   flutter doctor
   ```

---

## 2. Клонирование репозитория

```bash
git clone https://github.com/<usuario>/restobook.git
cd restobook
```

---

## 3. Установка зависимостей

```bash
flutter pub get
```

---

## 4. Сборка APK

### Release (для публикации / финального тестирования)

```bash
flutter build apk --release
```

Готовый файл:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Debug (для разработки и тестирования)

```bash
flutter build apk --debug
```

Готовый файл:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 5. Установка APK на устройство

### Через USB (автоматически)

```bash
flutter install
```

### Вручную

Скопировать `app-release.apk` на Android-устройство и открыть файл для установки.
На устройстве необходимо разрешить установку из неизвестных источников:
**Настройки → Безопасность → Неизвестные источники**

---

## 6. Запуск в режиме разработки

```bash
flutter run
```

> Требуется подключённое устройство или запущенный эмулятор.

---

## Примечания

- Минимальная версия Android: **5.0 (API 21)**
- Для работы авторизации нужен **Telegram** и **интернет**
- Бэкенд (бот + API): `https://web-production-86f86.up.railway.app`
- База данных: **SQLite** (локальная, хранится на устройстве)
