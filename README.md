# Питомец Финни

Мобильный прототип для Android: игровой сервис финансовой грамотности для детей 7–11 лет (ТЗ Департамента финансов города Москвы, 2026).

## Стек

- Flutter / Dart
- Состояние: `flutter_riverpod`
- Локальное хранение: `shared_preferences`
- Package name / applicationId: `ru.moscow.finny.pet`
- Версия: `1.0.0+1` (см. `pubspec.yaml`)

Android Studio нужен для Android SDK, эмулятора и установки APK. Код можно редактировать в Cursor / VS Code.

## Быстрый запуск

```bash
flutter pub get
flutter run
```

Юнит-тесты:

```bash
flutter test
```

## Запуск локально в Google Chrome (Windows)

Проект уже содержит папку `web/`, поэтому приложение можно открыть в браузере без Android-эмулятора. Ниже — полный сценарий, который нужен на **другом / новом** устройстве.

### 1. Установи Flutter (если ещё нет)

1. Скачай Flutter SDK (stable) с [flutter.dev](https://docs.flutter.dev/get-started/install/windows).
2. Распакуй, например в `C:\flutter` или `%USERPROFILE%\flutter`.
3. Убедись, что есть файл `...\flutter\bin\flutter.bat`.

На машине проекта часто используется junction: `C:\flutter` → `%USERPROFILE%\flutter`. Команды ниже рассчитаны на путь `C:\flutter\bin`. Если Flutter у тебя в другом месте — подставь свой путь.

### 2. Добавь Flutter в PATH (обязательно)

Без этого терминал пишет: `Имя "flutter" не распознано`.

#### Вариант A — навсегда (рекомендуется)

1. Windows: **Параметры → Система → О системе → Дополнительные параметры системы**.
2. **Переменные среды** → в блоке «Переменные среды пользователя» выбери `Path` → **Изменить**.
3. **Создать** → добавь: `C:\flutter\bin` (или свой `...\flutter\bin`).
4. ОК → **полностью закрой Cursor / VS Code** и открой снова (старые терминалы PATH не подхватывают).
5. В новом терминале проверь:

```powershell
flutter --version
```

#### Вариант B — только для текущего окна PowerShell

Если не хочешь менять системные настройки или Cursor всё ещё не видит PATH:

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter --version
```

Эту строку с `$env:PATH` нужно повторять **в каждом новом** терминале, пока не сделан вариант A и не перезапущен редактор.

### 3. Проверь Chrome и включи web

1. Установи [Google Chrome](https://www.google.com/chrome/), если его нет.
2. Один раз включи поддержку web:

```powershell
flutter config --enable-web
```

3. Проверь устройства:

```powershell
flutter doctor
flutter devices
```

В списке должна быть строка `Chrome (web)` / `chrome`.

Если Chrome не находится:

```powershell
$env:CHROME_EXECUTABLE = "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

### 4. Запуск приложения в Chrome

Открой терминал **в корне проекта** (папка с `pubspec.yaml`):

```powershell
# если flutter снова «не распознан» — сначала:
# $env:PATH = "C:\flutter\bin;$env:PATH"

flutter pub get
flutter run -d chrome
```

Дождись сборки: откроется окно Chrome (адрес вида `http://localhost:xxxxx`). Первая сборка может занять несколько минут — это нормально.

Пока `flutter run` работает в терминале:

| Клавиша | Действие |
|---------|----------|
| `r` | hot reload |
| `R` | hot restart |
| `q` | остановить приложение |

Сохранение файла в редакторе тоже обычно вызывает hot reload.

Фиксированный порт:

```powershell
flutter run -d chrome --web-port=8080
```

Открыть вручную: [http://localhost:8080](http://localhost:8080).

### 5. Сборка web без постоянной отладки

```powershell
flutter build web
```

Результат: `build/web/`.

Просмотр:

```powershell
flutter run -d chrome --release
```

или через Python:

```powershell
cd build\web
python -m http.server 8080
```

Затем в Chrome: [http://localhost:8080](http://localhost:8080).

Не открывай `index.html` двойным кликом (`file://`) — нужен HTTP-сервер.

### Типичные проблемы

| Проблема | Что сделать |
|----------|-------------|
| `Имя "flutter" не распознано` | Добавь `...\flutter\bin` в PATH (шаг 2A) **или** в этом терминале: `$env:PATH = "C:\flutter\bin;$env:PATH"`. После правки PATH перезапусти Cursor |
| PATH добавлен, но в Cursor всё равно не видно | Закрой все окна Cursor, открой заново, создай **новый** терминал |
| `chrome` не в `flutter devices` | Установи Chrome, выполни `flutter config --enable-web`, перезапусти терминал |
| `Unable to find suitable browser` | Задай `$env:CHROME_EXECUTABLE` на `chrome.exe` |
| Долгая первая сборка | Нормально для первого web-run |
| Белый экран / ошибка в консоли | F12 → Console; затем `flutter clean`, `flutter pub get`, `flutter run -d chrome` |
| Порт занят | `flutter run -d chrome --web-port=8081` |

### Краткая шпаргалка (другое устройство)

```powershell
# 1) PATH (если flutter не находится)
$env:PATH = "C:\flutter\bin;$env:PATH"

# 2) один раз
flutter config --enable-web

# 3) каждый раз в корне проекта
flutter pub get
flutter run -d chrome
```

## Android: Release APK

Release APK (нужны Android Studio → SDK и JDK 17):

```bash
# после установки Android Studio задай SDK, например:
# set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
scripts\build_release.bat
```

Или в Android Studio: Open project → Run / Build → Flutter APK.

Файл: `build/app/outputs/flutter-apk/app-release.apk`

## Демо-режим

В разделе для взрослого (иконка на главном экране → арифметический барьер) включён **демо-режим**: периоды и задания без ожидания — удобно для экспертов. Вне демо пауза между периодами ~2 мин, обновление заданий ~5 мин. Там же сброс тестового профиля.

## Обязательный сценарий

1. Онбординг (три типа решений)
2. Создание питомца: цвет (синий/розовый) × глаза × дополнение → имена → возраст
3. Главный экран: баланс, копилка, состояние, задания
4. План бюджета (обязательное / желаемое / накопления)
5. Задания (≥6, темы: бюджет, накопления, покупки)
6. Покупки (≥8 позиций двух типов), отказ при нехватке средств
7. Цель и пополнение копилки, снятие с подтверждением
8. Итог периода (план vs факт) и переход к следующему
9. Сохранение после перезапуска
10. Раздел взрослого + сброс профиля

## Структура

```
lib/
  domain/     модели и правила экономики
  data/       сохранение профиля
  content/    загрузка JSON
  features/   экраны
  state/      GameController
assets/content/
  items.json, goals.json, quests.json, lessons.json, pets.json
docs/         сопроводительная документация (ТЗ §5)
```

### Документация для сдачи (кроме презентации)

Реестр всех docs: [`docs/00_index.md`](docs/00_index.md)  
Единый DOCX: [`docs/Finny_soprovoditelnaya_dokumentaciya.docx`](docs/Finny_soprovoditelnaya_dokumentaciya.docx)  
Чеклист на 29 число: [`docs/submission_checklist_29.md`](docs/submission_checklist_29.md)

#### Системный анализ (аналитик / middle)

| Документ | Содержание |
|----------|------------|
| [`docs/system_analysis.md`](docs/system_analysis.md) | Концепция, акторы, границы, NFR, глоссарий, риски |
| [`docs/functional_spec.md`](docs/functional_spec.md) | Функциональные требования FR + приёмка |
| [`docs/use_cases.md`](docs/use_cases.md) | Каталог use case |
| [`docs/user_stories.md`](docs/user_stories.md) | User stories по эпикам |
| [`docs/business_processes.md`](docs/business_processes.md) | Жизненный цикл периода, BPMN-процессы |
| [`docs/screens_navigation.md`](docs/screens_navigation.md) | Карта экранов и навигация |

#### Сопроводительная документация ТЗ §5

| Пункт ТЗ §5 | Файл |
|-------------|------|
| Сборка APK | [`docs/build_guide.md`](docs/build_guide.md) |
| Архитектура | [`docs/architecture.md`](docs/architecture.md) |
| Структура данных | [`docs/data_structures.md`](docs/data_structures.md) |
| Матрица требований | [`docs/requirements_matrix.md`](docs/requirements_matrix.md) |
| Формулы экономики | [`docs/economy_rules.md`](docs/economy_rules.md) |
| Карта обучения | [`docs/education_content_map.md`](docs/education_content_map.md) |
| UX / доступность | [`docs/ux_accessibility.md`](docs/ux_accessibility.md) |
| Разрешения и данные | [`docs/privacy_permissions.md`](docs/privacy_permissions.md) |
| Тест-кейсы | [`docs/test_cases.md`](docs/test_cases.md) |
| Отчёт с устройства | [`docs/device_test_report.md`](docs/device_test_report.md) |
| Ограничения и план | [`docs/limitations_roadmap.md`](docs/limitations_roadmap.md) |
| Лицензии | [`docs/licenses.md`](docs/licenses.md) |
| Инструкция эксперта | [`docs/demo_instruction.md`](docs/demo_instruction.md) |
| RuStore | [`docs/rustore_card.md`](docs/rustore_card.md) |

## Обучение по возрасту

При создании питомца (и в разделе взрослого) выбирается трек:

| Трек | Возраст | Сложность заданий |
|------|---------|-------------------|
| Лёгкий | 7–8 | easy |
| Средний | 9–10 | easy + medium |
| Сложный | 11 | easy + medium + hard |

Механика: звёзды, XP по темам (бюджет / копилка / покупки), комбо за серию верных ответов, подсказки-уроки в заданиях.

## Контент MVP

| Элемент | Минимум ТЗ | Факт в прототипе |
|---------|------------|-----------------|
| Питомец | ≥ 2 различимые внешности | 27 обликов (3 стадии роста × 3 цвета × 3 дополнения) + эмоции |
| Покупки | ≥ 8 | 25 |
| Цели | ≥ 3 | 5 |
| Задания | ≥ 6 | 155 (есть интерактив «разложи по корзинам») |
| Уроки | — | 18 |
| Стадии роста | 3 | 3 |

## RuStore

Черновик карточки: [`docs/rustore_card.md`](docs/rustore_card.md)

## Ограничения

Нет реальных платежей, рекламы, аккаунтов и сбора персональных данных. Учебный контент отделён от UI (JSON в `assets/content`).
