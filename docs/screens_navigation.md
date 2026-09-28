# Карта экранов и навигация

Документ для middle-разработчика и аналитика: **какие экраны есть, откуда открываются, какие предусловия**.

Навигация: `MaterialApp` + `Navigator.push` / условный `home` в `lib/app.dart`. Отдельного router-пакета нет.

---

## 1. Корневой роутинг (`FinnyApp`)

| Условие | Экран |
|---------|--------|
| `profileAsync` loading | Splash-скелет с индикатором |
| error | Текст ошибки |
| `profile == null` и онбординг не закрыт | `OnboardingScreen` |
| `profile == null` и онбординг закрыт | `CreatePetScreen` |
| `profile != null` | `HomeScreen` |

После `resetProfile` снова `profile == null` → онбординг/создание.

---

## 2. Реестр экранов

| Экран | Файл | Актор | Фаза / условие |
|-------|------|-------|----------------|
| Онбординг | `features/onboarding/onboarding_screen.dart` | Ребёнок | Нет профиля |
| Создание питомца | `features/create_pet/create_pet_screen.dart` | Ребёнок | Нет профиля |
| Главный | `features/home/home_screen.dart` (+ `junior_play_shell.dart`) | Ребёнок | Есть профиль |
| Бюджет / план | `features/budget/budget_screen.dart` | Ребёнок | planning (редактирование); просмотр факта — позже |
| Магазин | `features/shop/shop_screen.dart` | Ребёнок | playing для покупки |
| Копилка | `features/savings/savings_screen.dart` | Ребёнок | playing для операций |
| Задания | `features/quests/quests_screen.dart` | Ребёнок | После плана; каталог всегда |
| Учёба | `features/learn/learn_screen.dart` | Ребёнок | Всегда при профиле |
| Итог периода | `features/period/period_summary_screen.dart` | Ребёнок | После close / summary |
| Барьер взрослого | `features/adult/adult_screen.dart` (`AdultGateScreen`) | Взрослый | Из главного |
| Панель взрослого | тот же файл (`AdultPanelScreen`) | Взрослый | После барьера |

Общие виджеты: `features/widgets/common.dart`, оверлеи `fx_overlays.dart`.

---

## 3. Переходы (граф)

```
Onboarding ──done──► CreatePet ──save──► Home
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    ▼                      ▼                      ▼
                 Budget                 Shop/Savings           Quests
                    │                      │                      │
                    └──────────► (playing loop) ◄─────────────────┘
                                           │
                                           ▼
                                    PeriodSummary
                                           │
                                           ▼
                                      Home (planning)
                                           
Home ──► Learn (стек)
Home ──► AdultGate ──ok──► AdultPanel ──reset──► Onboarding
```

Junior-трек может встраивать разделы в `junior_play_shell` (оболочка «комнаты»), middle/senior — чаще push отдельных экранов. Поведение UX различается, **доменные правила одни**.

---

## 4. Состояние на экране: источник правды

| Данные UI | Провайдер / слой |
|-----------|------------------|
| Профиль | `gameControllerProvider` (`GameController`) |
| Контент (items, quests…) | загрузка при старте контроллера / ContentLoader |
| Мутации | методы контроллера → `GameEconomy` → save |

Запрещено менять баланс только в виджете в обход контроллера.

---

## 5. Диалоги, требующие подтверждения

| Действие | Где |
|----------|-----|
| Покупка | `shop_screen` |
| Снятие с копилки | `savings_screen` |
| Сброс профиля | `adult_screen` |

---

## 6. Трассировка экран → UC

| Экран | UC |
|-------|-----|
| Onboarding | UC-01 |
| CreatePet | UC-02 |
| Home | UC-03, UC-16 |
| Budget | UC-04 |
| Shop | UC-05 |
| Savings | UC-06…08 |
| Quests | UC-09 |
| Learn | UC-10 |
| PeriodSummary | UC-11…12 |
| Adult* | UC-13…15 |
