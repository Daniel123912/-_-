# Чеклист финальной сдачи (29 число)

Исключено по запросу: **презентация**. Ниже — всё остальное по ТЗ §5 и §7.2.

---

## Реестр документации

Полный указатель: [`00_index.md`](00_index.md).

### Системный анализ (сверх минимума ТЗ)

| Артефакт | Статус |
|----------|--------|
| [`system_analysis.md`](system_analysis.md) | готово |
| [`functional_spec.md`](functional_spec.md) | готово |
| [`use_cases.md`](use_cases.md) | готово |
| [`user_stories.md`](user_stories.md) | готово |
| [`business_processes.md`](business_processes.md) | готово |
| [`screens_navigation.md`](screens_navigation.md) | готово |

### Обязательная документация (§5)

| # | Требование | Артефакт | Статус |
|---|------------|----------|--------|
| 1 | README | [`README.md`](../README.md) | готово |
| 2 | Окружение и сборка APK | [`build_guide.md`](build_guide.md) | готово |
| 3 | Архитектура | [`architecture.md`](architecture.md) | готово |
| 4 | Структура данных | [`data_structures.md`](data_structures.md) | готово |
| 5 | Матрица требований | [`requirements_matrix.md`](requirements_matrix.md) | готово |
| 6 | Формулы экономики | [`economy_rules.md`](economy_rules.md) | готово |
| 7 | Карта обучения | [`education_content_map.md`](education_content_map.md) | готово |
| 8 | UX / доступность | [`ux_accessibility.md`](ux_accessibility.md) | готово |
| 9 | Разрешения и данные | [`privacy_permissions.md`](privacy_permissions.md) | готово |
| 10 | Тест-кейсы + отчёт с устройства | [`test_cases.md`](test_cases.md), [`device_test_report.md`](device_test_report.md) | шаблон готов — **заполнить факт с телефона** |
| 11 | Ограничения и план | [`limitations_roadmap.md`](limitations_roadmap.md) | готово |
| 12 | Лицензии | [`licenses.md`](licenses.md) | готово |

**Единый документ DOCX (для загрузки на платформу):**  
[`Finny_soprovoditelnaya_dokumentaciya.docx`](Finny_soprovoditelnaya_dokumentaciya.docx)

Пересборка DOCX:

```bash
python scripts/generate_docs_docx.py
```

---

## Финальная сдача (§7.2), кроме презентации

| Артефакт | Статус | Действие |
|----------|--------|----------|
| Репозиторий доступен экспертам | зависит от команды | проверить права на SourceCraft/Git |
| Релизный тег | сделать перед сдачей | `git tag v1.0.0-final` (когда код заморожен) |
| Release APK | собрать | `scripts/build_release.bat` или `flutter build apk --release` |
| Инструкция установки / демо / сброс | готово | [`demo_instruction.md`](demo_instruction.md) |
| Документация §5 | готово | DOCX + `docs/` |
| Резервное видео ≤ 3 мин | **не документ** | записать живой сценарий Приложения А |
| Интерактивный прототип (если был) | опционально | Figma / web-ссылка |
| Черновик RuStore | готово | [`rustore_card.md`](rustore_card.md) + иконка/скриншоты |
| Сервер | не применимо | нет backend |

---

## Что сделать руками до загрузки

1. Собрать и прогнать APK на физическом Android.
2. Заполнить [`device_test_report.md`](device_test_report.md) (модель, Android, ОЗУ, OK/fail).
3. При необходимости экспортировать отчёт в PDF/DOCX и приложить к сдаче.
4. Записать резервное видео демонстрации (не презентация).
5. Подготовить 3+ скриншота и иконку 512 для RuStore.
6. Поставить релизный тег и убедиться, что ссылки открываются без запроса доступа.
7. Презентацию готовите отдельно (вне этого чеклиста).

---

## Контент (факт на момент подготовки docs)

| Элемент | Количество |
|---------|------------|
| Задания | 155 |
| Уроки | 18 |
| Товары | 25 |
| Цели | 5 |
| Модели питомцев | 36 |
| Стадии роста | 3 |
