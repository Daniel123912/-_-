#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate final accompanying DOCX for hackathon submission (TZ §5)."""

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt, Cm
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "Finny_soprovoditelnaya_dokumentaciya.docx"


def set_run_font(run, name="Times New Roman", size=12, bold=False):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    run.font.size = Pt(size)
    run.bold = bold


def add_heading(doc, text, level=1):
    p = doc.add_heading(text, level=level)
    for run in p.runs:
        set_run_font(run, size=16 if level == 1 else 14, bold=True)
    return p


def add_para(doc, text, bold=False, size=12):
    p = doc.add_paragraph()
    run = p.add_run(text)
    set_run_font(run, size=size, bold=bold)
    p.paragraph_format.space_after = Pt(6)
    return p


def add_bullets(doc, items):
    for item in items:
        p = doc.add_paragraph(style="List Bullet")
        run = p.add_run(item)
        set_run_font(run)


def add_table(doc, headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        for p in cell.paragraphs:
            for run in p.runs:
                set_run_font(run, size=10, bold=True)
    for r_i, row in enumerate(rows):
        for c_i, val in enumerate(row):
            cell = table.rows[r_i + 1].cells[c_i]
            cell.text = str(val)
            for p in cell.paragraphs:
                for run in p.runs:
                    set_run_font(run, size=10)
    doc.add_paragraph()


def main():
    doc = Document()
    for section in doc.sections:
        section.top_margin = Cm(2)
        section.bottom_margin = Cm(2)
        section.left_margin = Cm(2.5)
        section.right_margin = Cm(2)

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = title.add_run(
        "Сопроводительная документация\n"
        "«Питомец Финни» — игровой сервис финансовой грамотности\n"
        "для детей 7–11 лет"
    )
    set_run_font(r, size=16, bold=True)

    meta = doc.add_paragraph()
    meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = meta.add_run(
        "Хакатон Мэра Москвы / задача Департамента финансов города Москвы\n"
        "Package: ru.moscow.finny.pet  ·  Версия: 1.0.0+1\n"
        "Формат по ТЗ §5 (пункты 1–12). Презентация — отдельный артефакт."
    )
    set_run_font(r, size=11)

    add_para(
        doc,
        "Документ позволяет стороннему специалисту собрать решение, запустить его, "
        "воспроизвести демонстрационный сценарий и понять, как финансовые решения "
        "преобразуются в игровой результат. Детальные приложения также лежат в "
        "каталоге docs/ репозитория (Markdown).",
    )

    # --- 1 README ---
    add_heading(doc, "1. Назначение продукта и состав репозитория", 1)
    add_para(
        doc,
        "«Питомец Финни» — мобильный офлайн-прототип: ребёнок планирует бюджет, "
        "различает нужные и желаемые покупки, копит на цель и выполняет задания по "
        "финансовой грамотности. Состояние и рост виртуального питомца зависят от "
        "финансовых решений. Нет реальных платежей, рекламы, аккаунтов и сбора ПДн.",
    )
    add_para(doc, "Стек: Flutter / Dart, flutter_riverpod, shared_preferences.", bold=True)
    add_bullets(
        doc,
        [
            "lib/domain — модели и правила экономики",
            "lib/data — сохранение профиля",
            "lib/content — загрузка JSON",
            "lib/features — экраны",
            "lib/state — GameController",
            "assets/content — items, goals, quests, lessons, pets",
            "docs/ — сопроводительная документация",
            "test/domain — юнит-тесты формул",
        ],
    )
    add_para(doc, "Быстрый запуск: flutter pub get && flutter run. Подробнее — README.md в корне.")
    add_para(
        doc,
        "Реестр документации: docs/00_index.md. Пакет системного анализа: "
        "system_analysis.md, functional_spec.md, use_cases.md, user_stories.md, "
        "business_processes.md, screens_navigation.md.",
    )

    # --- 1b System analysis summary ---
    add_heading(doc, "1.1. Краткий системный анализ", 1)
    add_para(
        doc,
        "Проблема: детям 7–11 лет нужна безопасная игровая среда, где финансовые "
        "решения видны через последствия для питомца, ошибка обучает, а взрослый "
        "видит прогресс без сбора ПДн. Решение: офлайн-клиент с циклом периода "
        "planning → playing → summary. Акторы: ребёнок, взрослый, эксперт. "
        "Backend отсутствует. NFR: старт ≤5 с, офлайн, локальный прогресс, этичный soft fail.",
    )
    add_para(doc, "Полный анализ: docs/system_analysis.md; ФТ: docs/functional_spec.md.")

    # --- 2 Build ---
    add_heading(doc, "2. Окружение и сборка APK", 1)
    add_table(
        doc,
        ["Компонент", "Требование"],
        [
            ["Flutter", "3.47.x stable / Dart 3.13.3"],
            ["JDK", "17"],
            ["Android SDK", "API 26+"],
            ["ОС проверки", "Android-устройство, ОЗУ ≥ 3 ГБ"],
        ],
    )
    add_para(doc, "Сборка релизного APK:")
    add_bullets(
        doc,
        [
            "flutter pub get",
            "flutter test",
            "flutter build apk --release",
            "или scripts/build_release.bat (Windows)",
            "Файл: build/app/outputs/flutter-apk/app-release.apk",
        ],
    )
    add_para(doc, "Полная инструкция: docs/build_guide.md")

    # --- 3 Architecture ---
    add_heading(doc, "3. Функциональная и компонентная архитектура", 1)
    add_para(
        doc,
        "Клиентское приложение без серверной части. UI (features) обращается к "
        "GameController (Riverpod); контроллер вызывает чистый домен GameEconomy и "
        "сохраняет PlayerProfile через ProfileRepository (SharedPreferences). "
        "Учебный контент загружается ContentLoader из assets/content/*.json и "
        "отделён от UI-логики.",
    )
    add_para(
        doc,
        "Игровой цикл: planning (план бюджета) → playing (задания, покупки, копилка) → "
        "summary (план/факт) → следующий период. OpenAPI не применим (нет backend).",
    )
    add_para(doc, "Схема и детали: docs/architecture.md")

    # --- 4 Data ---
    add_heading(doc, "4. Структура данных профиля, экономики, заданий и прогресса", 1)
    add_para(
        doc,
        "Профиль PlayerProfile хранит имена, внешность питомца, balance / savingsBalance, "
        "hunger / mood / growthStage, ageTrack, skills (XP по темам), stars, период "
        "GamePeriod (phase, plan, fact, purchases, activeQuestIds), completedQuestIds, "
        "completedLessonIds, demoMode, lastFeedback и служебные поля родителя/ротаций.",
    )
    add_para(
        doc,
        "Контент: ShopItem, SavingsGoal, Quest (включая sort_buckets), LearningLesson, "
        "справочники pets.json. Ключи хранения: finny_profile_v1 + backup.",
    )
    add_para(doc, "Подробные таблицы полей: docs/data_structures.md")

    # --- 5 Matrix ---
    add_heading(doc, "5. Матрица соответствия обязательным требованиям", 1)
    add_table(
        doc,
        ["ID", "Требование", "Статус", "Где"],
        [
            ["2.5.1", "Онбординг, гостевой профиль", "готово", "onboarding / create_pet"],
            ["2.5.2", "Создание питомца", "готово", "create_pet, pets.json"],
            ["2.5.3", "Главный экран", "готово", "home_screen"],
            ["2.5.4", "Игровая валюта", "готово", "economy + квесты"],
            ["2.5.5", "План бюджета", "готово", "budget_screen"],
            ["2.5.6", "Покупки", "готово", "shop_screen"],
            ["2.5.7", "Накопления и цель", "готово", "savings_screen"],
            ["2.5.8", "Задания", "готово", "quests_screen"],
            ["2.5.9", "Обратная связь", "готово", "lastFeedback / nextAction"],
            ["2.5.10", "Рост питомца", "готово", "3 стадии"],
            ["2.5.11", "История / справка", "готово", "Learn / словарь"],
            ["2.5.12", "Раздел взрослого", "готово", "adult_screen"],
            ["2.5.13", "Сохранение + демо", "готово", "repository + demoMode"],
            ["2.5.14", "Контент отдельно", "готово", "assets/content"],
            ["3.3", "APK / RuStore черновик", "частично", "собрать APK; rustore_card.md"],
            ["5.6", "Формулы", "готово", "economy_rules.md"],
        ],
    )
    add_para(doc, "Актуальная матрица: docs/requirements_matrix.md")

    # --- 6 Formulas ---
    add_heading(doc, "6. Формулы баланса, наград, состояния и роста", 1)
    add_bullets(
        doc,
        [
            "Стартовый баланс: junior 100 / middle 110 / senior 120",
            "Доход периода: 40 (+5 для junior и senior) при startNextPeriod",
            "План: total ≤ balance, mandatory ≥ 1, суммы ≥ 0",
            "Покупка: canAfford → списание; иначе отказ",
            "Задание периода: монеты + XP + ★ + комбо; практика каталога — только XP",
            "Бонус «все квесты периода»: +10 при closePeriod",
            "Копилка: transfer / withdraw с подтверждением в UI; claim цели",
            "Статы питомца: дельты hunger/mood от решений; мягкий пол; 3 стадии роста",
            "Вне демо: cooldown периода ~2 мин, ротация заданий ~5 мин",
        ],
    )
    add_para(doc, "Полные таблицы: docs/economy_rules.md; код: lib/domain/economy.dart; тесты: test/domain/economy_test.dart")

    # --- 7 Education ---
    add_heading(doc, "7. Карта образовательного контента", 1)
    add_table(
        doc,
        ["Навык", "Механика", "Контент"],
        [
            ["Бюджет ≤ доходам", "План, остаток, запрет минуса", "уроки + quests theme budget"],
            ["Нужное vs желаемое", "Корзины + магазин", "l_j_need_want, sort_buckets"],
            ["Покупки при лимите", "Отказ при нехватке", "theme purchases"],
            ["Цель и накопления", "Копилка, claim", "theme savings"],
            ["Оценка решений", "План/факт, soft fail", "period summary"],
            ["Роль взрослого", "Раздел с барьером", "adult_screen"],
        ],
    )
    add_para(
        doc,
        "Объём MVP-контента (факт): задания 155, уроки 18, товары 25, цели 5, "
        "модели питомцев 36 + комбинации цвета/глаз/аксессуара. "
        "Карта: docs/education_content_map.md",
    )

    # --- 8 UX ---
    add_heading(doc, "8. UX/UI и доступность", 1)
    add_bullets(
        doc,
        [
            "Питомец как понятная метафора последствий финансовых решений",
            "Явный выбор обязательное / желаемое / накопление",
            "Текстовая обратная связь; ошибка исправима",
            "Трек «попроще / средне / посложнее» без стигматизации",
            "Подтверждения для покупки, снятия с копилки, сброса",
            "Критичная информация не только звуком; звук не обязателен для смысла",
            "Контраст светлого текста на тёмных панелях; крупные CTA",
        ],
    )
    add_para(doc, "Обоснование: docs/ux_accessibility.md")

    # --- 9 Privacy ---
    add_heading(doc, "9. Разрешения, данные, удаление профиля", 1)
    add_para(
        doc,
        "Release-манифест не запрашивает INTERNET и чувствительные разрешения. "
        "Все данные профиля хранятся только на устройстве (SharedPreferences). "
        "Нет аналитики, рекламы, аккаунтов и реальных платежей.",
    )
    add_para(
        doc,
        "Удаление: раздел взрослого → арифметический барьер → «Сбросить тестовый профиль» "
        "→ подтверждение → clear основного и backup-ключа. Удаление приложения также "
        "стирает локальные данные.",
    )
    add_para(doc, "docs/privacy_permissions.md")

    # --- 10 Tests ---
    add_heading(doc, "10. Тест-кейсы и проверка на устройстве", 1)
    add_para(
        doc,
        "Автотесты: flutter test (доменная экономика). Ручные кейсы: установка APK, "
        "онбординг, план, задания, покупки (в т.ч. отказ), копилка, 2–3 периода в демо, "
        "сохранение после перезапуска, сброс профиля, офлайн.",
    )
    add_para(
        doc,
        "Шаблон отчёта по физическому устройству (модель, Android, ОЗУ, факты по "
        "сценарию А): docs/device_test_report.md — заполнить фактическими данными "
        "перед загрузкой на платформу. Сводка кейсов: docs/test_cases.md. "
        "Инструкция эксперта: docs/demo_instruction.md",
    )

    # --- 11 Limitations ---
    add_heading(doc, "11. Ограничения и план развития", 1)
    add_bullets(
        doc,
        [
            "Нет облачной синхронизации и iOS в обязательном объёме",
            "Публикация в RuStore не выполнялась (есть черновик карточки)",
            "Шрифты Fredoka/Nunito запечены в assets/fonts; звук отключается в разделе взрослого",
            "Нужны финальные скриншоты/иконка 512 и резервное видео ≤ 3 мин",
            "Далее: доступность TalkBack, расширение уроков по Единой рамке, signed keystore",
        ],
    )
    add_para(doc, "docs/limitations_roadmap.md")

    # --- 12 Licenses ---
    add_heading(doc, "12. Сторонние библиотеки, шрифты, ассеты", 1)
    add_para(
        doc,
        "Flutter (BSD-3), riverpod (MIT), shared_preferences / path_provider (BSD-3), "
        "flutter_svg (MIT), audioplayers (MIT), google_fonts (BSD-3). "
        "Шрифты Fredoka и Nunito — SIL OFL 1.1. "
        "Изображения питомцев, магазина, фонов и WAV-звуки подготовлены для проекта. "
        "Полная таблица: docs/licenses.md",
    )

    # --- Extra for 7.2 ---
    add_heading(doc, "Приложение A. Демо-режим и сброс", 1)
    add_para(
        doc,
        "Раздел взрослого (иконка на главном) → арифметический барьер → "
        "переключатель «Демо-режим» (периоды без ожидания). "
        "Сброс профиля — красная кнопка с подтверждением.",
    )

    add_heading(doc, "Приложение B. Материалы RuStore (черновик)", 1)
    add_para(
        doc,
        "Название: Питомец Финни. Категория: Образование / Дети. "
        "Без регистрации, рекламы и платежей. Черновик описания: docs/rustore_card.md. "
        "Для витрины подготовить иконку 512×512 и ≥3 скриншота.",
    )

    add_heading(doc, "Приложение C. Ссылки на файлы в репозитории", 1)
    add_bullets(
        doc,
        [
            "README.md",
            "docs/architecture.md",
            "docs/build_guide.md",
            "docs/data_structures.md",
            "docs/requirements_matrix.md",
            "docs/economy_rules.md",
            "docs/education_content_map.md",
            "docs/ux_accessibility.md",
            "docs/privacy_permissions.md",
            "docs/test_cases.md",
            "docs/device_test_report.md",
            "docs/limitations_roadmap.md",
            "docs/licenses.md",
            "docs/demo_instruction.md",
            "docs/rustore_card.md",
            "docs/submission_checklist_29.md",
            "docs/00_index.md",
            "docs/system_analysis.md",
            "docs/functional_spec.md",
            "docs/use_cases.md",
            "docs/user_stories.md",
            "docs/business_processes.md",
            "docs/screens_navigation.md",
        ],
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
