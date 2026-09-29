import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_loader.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  const CreatePetScreen({super.key});

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final _playerCtrl = TextEditingController(text: 'Саша');
  final _petCtrl = TextEditingController(text: 'Финни');
  final _rng = Random();

  int step = 0; // 0 pet, 1 name, 2 age
  String color = 'синий';
  String eyes = 'голубые';
  String accessory = 'без';
  AgeTrack ageTrack = AgeTrack.junior;

  static const _stepTitles = [
    'Собери питомца',
    'Придумай имена',
    'Выбери возраст',
  ];

  PetAppearance get appearance => PetAppearance.combo(
        color: color,
        eyes: eyes,
        accessory: accessory,
      );

  @override
  void dispose() {
    _playerCtrl.dispose();
    _petCtrl.dispose();
    super.dispose();
  }

  void _surprise(GameContent content) {
    HapticFeedback.selectionClick();
    setState(() {
      color = content.colors[_rng.nextInt(content.colors.length)];
      eyes = content.eyes[_rng.nextInt(content.eyes.length)];
      accessory =
          content.accessories[_rng.nextInt(content.accessories.length)];
    });
  }

  Future<void> _finish() async {
    await ref.read(gameControllerProvider.notifier).createProfile(
          playerName: _playerCtrl.text,
          petName: _petCtrl.text,
          appearance: appearance,
          ageTrack: ageTrack,
        );
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(contentProvider);
    return Scaffold(
      body: PlayBackground(
        child: contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка контента: $e')),
          data: (content) {
            return Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        if (step > 0)
                          IconButton(
                            onPressed: () => setState(() => step -= 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            _stepTitles[step],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: _StepDots(current: step, total: 3),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (step) {
                      0 => _PetStep(
                          key: const ValueKey('pet'),
                          content: content,
                          appearance: appearance,
                          color: color,
                          eyes: eyes,
                          accessory: accessory,
                          onColor: (v) => setState(() => color = v),
                          onEyes: (v) => setState(() => eyes = v),
                          onAccessory: (v) => setState(() => accessory = v),
                          onSurprise: () => _surprise(content),
                        ),
                      1 => _NameStep(
                          key: const ValueKey('name'),
                          appearance: appearance,
                          playerCtrl: _playerCtrl,
                          petCtrl: _petCtrl,
                        ),
                      _ => _AgeStep(
                          key: const ValueKey('age'),
                          ageTrack: ageTrack,
                          onChanged: (t) => setState(() => ageTrack = t),
                          appearance: appearance,
                          petName: _petCtrl.text.trim().isEmpty
                              ? 'Финни'
                              : _petCtrl.text.trim(),
                        ),
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        if (step < 2)
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                if (step == 1 &&
                                    _petCtrl.text.trim().isEmpty) {
                                  _petCtrl.text = 'Финни';
                                }
                                setState(() => step += 1);
                              },
                              child: const Text('Дальше'),
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton(
                              onPressed: _finish,
                              child: const Text('Начать игру'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: i == current
                  ? FinnyColors.purpleBright
                  : FinnyColors.line,
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _PetStep extends StatelessWidget {
  const _PetStep({
    super.key,
    required this.content,
    required this.appearance,
    required this.color,
    required this.eyes,
    required this.accessory,
    required this.onColor,
    required this.onEyes,
    required this.onAccessory,
    required this.onSurprise,
  });

  final GameContent content;
  final PetAppearance appearance;
  final String color;
  final String eyes;
  final String accessory;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onEyes;
  final ValueChanged<String> onAccessory;
  final VoidCallback onSurprise;

  Color _swatch(String c) => switch (c) {
        'розовый' => const Color(0xFFBE608A),
        'фиолетовый' => const Color(0xFF8B5CF6),
        _ => const Color(0xFF6AA8C3),
      };

  Color _eyeSwatch(String e) => switch (e) {
        'карие' => const Color(0xFF3D2C0F),
        'зелёные' => const Color(0xFF0F2F0E),
        _ => const Color(0xFF143D52),
      };

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final petSize = (screenH * 0.34).clamp(220.0, 360.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: PetAvatar(
              key: ValueKey(
                '${appearance.color}-${appearance.eyes}-${appearance.accessory}',
              ),
              appearance: appearance,
              stage: 1,
              size: petSize,
              scaleByStage: false,
              showLabel: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appearance.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FinnyColors.mist,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OptionRow(
                title: 'Цвет',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in content.colors)
                      _ColorChip(
                        label: c,
                        selected: color == c,
                        swatch: _swatch(c),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onColor(c);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OptionRow(
                title: 'Глаза',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in content.eyes)
                      _ColorChip(
                        label: e,
                        selected: eyes == e,
                        swatch: _eyeSwatch(e),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onEyes(e);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OptionRow(
                title: 'Дополнение',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in content.accessories)
                      ChoiceChip(
                        label: Text(_addonLabel(a)),
                        selected: accessory == a,
                        showCheckmark: true,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onAccessory(a);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onSurprise,
          icon: const Icon(Icons.casino_rounded),
          label: const Text('Сюрприз!'),
        ),
      ],
    );
  }

  static String _addonLabel(String id) => switch (id) {
        'ромбики' => 'На теле',
        'на голове' => 'На голове',
        _ => 'Без',
      };
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.selected,
    required this.swatch,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color swatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    super.key,
    required this.appearance,
    required this.playerCtrl,
    required this.petCtrl,
  });

  final PetAppearance appearance;
  final TextEditingController playerCtrl;
  final TextEditingController petCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        Center(
          child: PetAvatar(
            appearance: appearance,
            stage: 1,
            size: 220,
            scaleByStage: false,
            showLabel: false,
            petName: petCtrl.text.trim().isEmpty ? 'Финни' : petCtrl.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Как зовут этого друга?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FinnyColors.mist,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: petCtrl,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Имя питомца',
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: playerCtrl,
          decoration: InputDecoration(
            labelText: 'Твоё игровое имя',
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({
    super.key,
    required this.ageTrack,
    required this.onChanged,
    required this.appearance,
    required this.petName,
  });

  final AgeTrack ageTrack;
  final ValueChanged<AgeTrack> onChanged;
  final PetAppearance appearance;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        Center(
          child: PetAvatar(
            appearance: appearance,
            stage: 1,
            size: 200,
            scaleByStage: false,
            showLabel: false,
            petName: petName,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$petName готов к приключениям!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Выбери уровень заданий.\nПитомец сам вырастет: малыш → растущий → чемпион.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FinnyColors.mist, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final track in AgeTrack.values)
              ChoiceChip(
                label: Text(track.shortLabel),
                selected: ageTrack == track,
                showCheckmark: true,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onChanged(track);
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ageTrack.shortLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(ageTrack.description),
              const SizedBox(height: 8),
              Text(
                'Для старта лучше «ПРОСТОЙ».',
                style: TextStyle(color: FinnyColors.mist, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
