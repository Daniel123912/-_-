# Сборка и окружение

Пошаговая инструкция для стороннего специалиста (ТЗ §5 п. 2, §7.2).

---

## 1. Требования к окружению

| Компонент | Минимум |
|-----------|---------|
| ОС разработки | Windows 10/11, macOS или Linux |
| Flutter SDK | **3.47.x stable** (Dart **3.13.3**) |
| JDK | **17** (для Android-сборки) |
| Android Studio | для Android SDK + эмулятор (рекомендуется) |
| Android SDK | API 26+ (minSdk), targetSdk — как в проекте |
| Chrome | опционально, для `flutter run -d chrome` |
| Git | для клонирования репозитория |

Проверка:

```bash
flutter doctor
flutter --version
```

Ожидается канал `stable`, Dart 3.13.x.

---

## 2. Получение исходников

```bash
git clone <URL_репозитория>
cd <папка_проекта>
git checkout main   # или релизный тег финальной версии
flutter pub get
```

Package name: `ru.moscow.finny.pet`. Версия: `1.0.0+1` (`pubspec.yaml`).

---

## 3. Быстрый запуск (отладка)

```bash
flutter run                 # устройство / эмулятор по умолчанию
flutter run -d chrome       # браузер
```

Юнит-тесты:

```bash
flutter test
```

Покрывают доменную экономику: план, покупки, копилка, задания, периоды, демо-cooldown, уроки (`test/domain/economy_test.dart`).

---

## 4. Release APK (финальная сборка)

### Вариант A — скрипт (Windows)

```bat
scripts\build_release.bat
```

Скрипт выполняет `flutter pub get`, `flutter test`, `flutter build apk --release`.

### Вариант B — вручную

```bash
flutter pub get
flutter test
flutter build apk --release
```

Результат:

`build/app/outputs/flutter-apk/app-release.apk`

Установка на устройство:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

или через проводник устройства / Android Studio.

### Подпись

Для конкурсной проверки используется стандартная debug/release-подпись Flutter/Gradle проекта. Для публикации в RuStore потребуется keystore команды (не коммитить секреты в репозиторий).

---

## 5. Web-сборка (не обязательна для Android-сдачи)

```bash
flutter build web
# артефакт: build/web/
```

Не открывать `index.html` через `file://` — нужен HTTP-сервер.

---

## 6. Типичные проблемы

| Симптом | Действие |
|---------|----------|
| `flutter` не найден | Добавить `...\flutter\bin` в PATH |
| Нет Android SDK | Установить Android Studio, задать `ANDROID_HOME` |
| Нет JDK 17 | Установить Temurin/Oracle JDK 17 |
| Chrome не в devices | `flutter config --enable-web` |
| Белый экран web | `flutter clean` → `pub get` → повторный run |

Подробнее для Chrome на Windows: корневой [`README.md`](../README.md).
