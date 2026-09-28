# Реестр документации «Питомец Финни»

Единая точка входа для эксперта, разработчика и системного аналитика.  
Продукт: офлайн-прототип игрового сервиса финансовой грамотности для детей 7–11 лет  
(ТЗ Департамента финансов г. Москвы, задача «Город 6», 2026).

Package: `ru.moscow.finny.pet` · Версия: `1.0.0+1`

---

## 1. Как читать документы

| Роль | С чего начать | Зачем |
|------|---------------|-------|
| Эксперт / жюри | [`demo_instruction.md`](demo_instruction.md) → [`requirements_matrix.md`](requirements_matrix.md) | Запуск, сценарий, покрытие ТЗ |
| Системный аналитик | [`system_analysis.md`](system_analysis.md) → [`functional_spec.md`](functional_spec.md) → [`use_cases.md`](use_cases.md) | Контекст, ФТ, сценарии |
| Middle-разработчик | [`architecture.md`](architecture.md) → [`data_structures.md`](data_structures.md) → [`economy_rules.md`](economy_rules.md) | Слои, модели, формулы |
| Родитель / продукт | [`education_content_map.md`](education_content_map.md), [`ux_accessibility.md`](ux_accessibility.md) | Чему учит, как устроен UX |
| Сдача | [`submission_checklist_29.md`](submission_checklist_29.md) + DOCX | Чеклист артефактов |

Единый DOCX для платформы: [`Finny_soprovoditelnaya_dokumentaciya.docx`](Finny_soprovoditelnaya_dokumentaciya.docx)  
Пересборка: `python scripts/generate_docs_docx.py`

---

## 2. Карта артефактов

### 2.1. Аналитика (системный анализ)

| Документ | Содержание |
|----------|------------|
| [`system_analysis.md`](system_analysis.md) | Концепция, границы, акторы, контекст, NFR, глоссарий, риски |
| [`functional_spec.md`](functional_spec.md) | Функциональные требования (FR), приоритеты, критерии приёмки |
| [`use_cases.md`](use_cases.md) | Каталог use case, предусловия, основной/альтернативный поток |
| [`user_stories.md`](user_stories.md) | User stories по эпикам (MoSCoW) |
| [`business_processes.md`](business_processes.md) | Жизненный цикл периода, статусы, BPMN-описание потоков |
| [`screens_navigation.md`](screens_navigation.md) | Карта экранов и навигация для middle-разработки |

### 2.2. Сопроводительная документация по ТЗ §5

| № ТЗ | Документ |
|------|----------|
| 1 | [`../README.md`](../README.md) |
| 2 | [`build_guide.md`](build_guide.md) |
| 3 | [`architecture.md`](architecture.md) |
| 4 | [`data_structures.md`](data_structures.md) |
| 5 | [`requirements_matrix.md`](requirements_matrix.md) |
| 6 | [`economy_rules.md`](economy_rules.md) |
| 7 | [`education_content_map.md`](education_content_map.md) |
| 8 | [`ux_accessibility.md`](ux_accessibility.md) |
| 9 | [`privacy_permissions.md`](privacy_permissions.md) |
| 10 | [`test_cases.md`](test_cases.md), [`device_test_report.md`](device_test_report.md) |
| 11 | [`limitations_roadmap.md`](limitations_roadmap.md) |
| 12 | [`licenses.md`](licenses.md) |

### 2.3. Эксплуатация и сдача

| Документ | Содержание |
|----------|------------|
| [`demo_instruction.md`](demo_instruction.md) | Установка APK, демо-сценарий, сброс (§7.2) |
| [`rustore_card.md`](rustore_card.md) | Черновик карточки магазина |
| [`submission_checklist_29.md`](submission_checklist_29.md) | Чеклист финальной сдачи |
| [`my_part_economy.md`](my_part_economy.md) | Отчёт по модулю экономики |

---

## 3. Трассировка: требование → документ → код

| Область | Аналитика | Правила | Код |
|---------|-----------|---------|-----|
| Бюджет периода | FR-BUD-* | `economy_rules.md` §3, §7 | `GameEconomy.confirmPlan`, `comparePlanFact` |
| Покупки | FR-SHOP-* | `economy_rules.md` §4, §6 | `purchase`, `canAfford` |
| Копилка | FR-SAV-* | `economy_rules.md` §5 | `transferToSavings`, `claimGoal` |
| Задания | FR-QST-* | `economy_rules.md` §9 | `completeQuest`, `pickPeriodQuests` |
| Питомец | FR-PET-* | `economy_rules.md` §10 | статы, `applyStageProgress` |
| Взрослый / демо | FR-ADT-* | `demo_instruction.md` | `AdultGateScreen`, `demoMode` |
| Сохранение | FR-PERSIST-* | `data_structures.md` | `ProfileRepository` |

Полная матрица MVP: [`requirements_matrix.md`](requirements_matrix.md).

---

## 4. Версионирование docs

| Поле | Значение |
|------|----------|
| Версия пакета docs | 1.0 |
| Соответствует версии приложения | 1.0.0+1 |
| Язык | русский |
| Формат исходников | Markdown в `docs/` |
| Формат сдачи | DOCX + MD + APK |
