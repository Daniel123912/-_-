# Структура данных

Локальный прогресс хранится в `SharedPreferences` (ключ профиля) как JSON.
Сервера нет: все структуры — клиентские.

## PlayerProfile

Главный снимок состояния игрока / питомца.

| Поле | Тип | Смысл |
|------|-----|--------|
| `playerName` / `petName` | string | Имена |
| `appearance` | `PetAppearance` | Цвет, глаза, дополнение, model id |
| `balance` / `savingsBalance` | int | Карман и копилка |
| `hunger` / `mood` | int 0–100 | Сытость и настроение |
| `growthStage` | int 1–3 | Малыш → растущий → чемпион (меняет модель тела) |
| `ageTrack` | enum | Сложность контента: junior / middle / senior |
| `period` | `GamePeriod` | Текущий период: план, факт, фаза, квесты |
| `skills` | `SkillProgress` | XP тем: бюджет / копилка / покупки |
| `ownedItemIds` | string[] | Купленные товары (коллекции / косметика) |
| `soundEnabled` | bool | Тумблер звука в разделе взрослого |
| `demoMode` | bool | Без кулдаунов между периодами |
| `selectedGoalId` | string? | Цель копилки |
| `completedQuestIds` / `completedLessonIds` | string[] | Прогресс заданий и учёбы |

Файл модели: `lib/domain/models.dart`. Сохранение: `lib/data/profile_repository.dart`.

## PetAppearance

| Поле | Смысл |
|------|--------|
| `color` | `синий` / `розовый` / `фиолетовый` |
| `eyes` | Связаны с цветом: голуб / карие / зелёные |
| `accessory` | `без` / `ромбики` / `на голове` |
| `model` | Базовый id стадии 1 (`pet_01`…); на экране — `modelForStage(growthStage)` |

Эмоции лица (Полина): `joy` / `calm` / `bliss` / `confused` / `sad` → SVG/PNG суффиксы.

## Контент (assets/content)

| Файл | Содержимое |
|------|------------|
| `pets.json` | Модели `pet_01`–`pet_27`, цвета, глаза, аксессуары |
| `items.json` | Магазин: `mandatory` / `optional` / `gift` |
| `quests.json` | Задания периода |
| `lessons.json` | Учёба |
| `goals.json` | Цели копилки |

Загрузка: `lib/content/content_loader.dart` → `GameContent`.

## Бюджет периода

- `BudgetPlan` — план: mandatory / optional / savings / gift  
- `BudgetFact` — факт трат и отложений  
- Фазы: `planning` → `playing` → `summary`

Правила сравнения и роста: `lib/domain/economy.dart`, `docs/economy_rules.md`.
