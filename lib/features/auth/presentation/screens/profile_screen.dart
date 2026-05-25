import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/russian_cities.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/app_theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/app_language_switcher.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/user_goal.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profile_update_data.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _startWeightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _friendCodeController = TextEditingController();

  Gender? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedCity;
  bool _isSaving = false;
  bool _didPopulateForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _startWeightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _friendCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(currentUserProfileProvider);

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(l10n.profileScreenTitle)),
      child: SafeArea(
        child: profileState.when(
          data: (profile) {
            if (profile == null) {
              return Center(child: Text(l10n.errorUnauthorized));
            }

            _populateFormIfNeeded(profile);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      l10n.profileScreenSubtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProfileOverviewCard(profile: profile),
                    const SizedBox(height: 20),
                    const _TodayProfileMetricsCard(),
                    const SizedBox(height: 20),
                    const _LanguagePickerCard(),
                    const SizedBox(height: 20),
                    const _ThemePickerCard(),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionCard(
                            title: l10n.profilePersonalSection,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: l10n.commonName,
                                  ),
                                  validator: (value) {
                                    final errorCode =
                                        InputValidators.validateName(value);
                                    return errorCode?.localize(l10n);
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<Gender>(
                                  initialValue: _selectedGender,
                                  decoration: InputDecoration(
                                    labelText: l10n.commonGender,
                                  ),
                                  items: Gender.values
                                      .map(
                                        (gender) => DropdownMenuItem<Gender>(
                                          value: gender,
                                          child: Text(gender.localize(l10n)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedGender = value;
                                          });
                                        },
                                  validator: (value) {
                                    return value == null
                                        ? AppErrorCode.emptyGender.localize(
                                            l10n,
                                          )
                                        : null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _birthDateController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.commonBirthDate,
                                    suffixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                  ),
                                  onTap: _isSaving ? null : _pickBirthDate,
                                  validator: (_) {
                                    final errorCode =
                                        InputValidators.validateBirthDate(
                                          _selectedBirthDate,
                                        );
                                    return errorCode?.localize(l10n);
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCity,
                                  decoration: InputDecoration(
                                    labelText: l10n.profileCity,
                                  ),
                                  items: russianCities
                                      .map(
                                        (city) => DropdownMenuItem<String>(
                                          value: city,
                                          child: Text(city),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedCity = value;
                                          });
                                        },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _friendCodeController,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: _socialCopy(context).friendCode,
                                    helperText: _socialCopy(
                                      context,
                                    ).friendCodeHint,
                                    prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed:
                                          _friendCodeController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : () => Clipboard.setData(
                                              ClipboardData(
                                                text: _normalizeFriendCode(
                                                  _friendCodeController.text,
                                                ),
                                              ),
                                            ),
                                      icon: const Icon(Icons.copy_rounded),
                                      tooltip: _socialCopy(context).copyCode,
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9_-]'),
                                    ),
                                    LengthLimitingTextInputFormatter(24),
                                    TextInputFormatter.withFunction((
                                      oldValue,
                                      newValue,
                                    ) {
                                      return newValue.copyWith(
                                        text: newValue.text.toLowerCase(),
                                        selection: newValue.selection,
                                      );
                                    }),
                                  ],
                                  validator: (value) =>
                                      _validateFriendCode(context, value),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: l10n.profileBodySection,
                            child: Column(
                              children: [
                                _DecimalFormField(
                                  controller: _heightController,
                                  label: l10n.profileHeight,
                                  validatorMessage:
                                      l10n.validationInvalidHeight,
                                ),
                                const SizedBox(height: 16),
                                _DecimalFormField(
                                  controller: _currentWeightController,
                                  label: l10n.profileCurrentWeight,
                                  validatorMessage:
                                      l10n.validationInvalidCurrentWeight,
                                ),
                                if (profile.goalType !=
                                    UserGoalType.maintainWeight) ...[
                                  const SizedBox(height: 16),
                                  _DecimalFormField(
                                    controller: _startWeightController,
                                    label: l10n.profileStartWeight,
                                    validatorMessage:
                                        l10n.validationInvalidCurrentWeight,
                                  ),
                                  const SizedBox(height: 16),
                                  _DecimalFormField(
                                    controller: _targetWeightController,
                                    label: l10n.profileTargetWeight,
                                    validatorMessage:
                                        l10n.validationInvalidTargetWeight,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _handleSave(profile),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(l10n.profileSaveButton),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_profileErrorMessage(error, l10n)),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final initialDate =
        _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: l10n.profileBirthDatePickerHelp,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonSave,
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _selectedBirthDate = date;
      _birthDateController.text = formatLocalizedDate(
        date,
        Localizations.localeOf(context),
      );
    });
  }

  Future<void> _handleSave(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() ||
        _selectedGender == null ||
        _selectedBirthDate == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(updateUserProfileUseCaseProvider)
          .call(
            UserProfileUpdateData(
              userId: profile.userId,
              email: profile.email,
              name: _nameController.text.trim(),
              gender: _selectedGender!,
              birthDate: _selectedBirthDate!,
              city: _selectedCity,
              friendCode: _normalizeFriendCode(_friendCodeController.text),
              heightCm: _parseDouble(_heightController.text),
              startWeightKg: profile.goalType == UserGoalType.maintainWeight
                  ? null
                  : _parseDouble(_startWeightController.text),
              currentWeightKg: _parseDouble(_currentWeightController.text),
              targetWeightKg: profile.goalType == UserGoalType.maintainWeight
                  ? null
                  : _parseDouble(_targetWeightController.text),
              goalType: profile.goalType,
              dailyStepGoal: profile.dailyStepGoal,
              dailyCalorieGoal: profile.dailyCalorieGoal,
            ),
          );
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSavedMessage)));
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _populateFormIfNeeded(UserProfile profile) {
    if (_didPopulateForm) {
      return;
    }

    _didPopulateForm = true;
    _nameController.text = profile.name;
    _selectedGender = profile.gender;
    _selectedBirthDate = profile.birthDate;
    _selectedCity = profile.city;
    _friendCodeController.text = profile.friendCode ?? '';
    _birthDateController.text = formatLocalizedDate(
      profile.birthDate,
      Localizations.localeOf(context),
    );
    _heightController.text = _formatDouble(profile.heightCm);
    _startWeightController.text = _formatDouble(profile.startWeightKg);
    _currentWeightController.text = _formatDouble(profile.currentWeightKg);
    _targetWeightController.text = _formatDouble(profile.targetWeightKg);
  }

  String _formatDouble(double? value, {int fractionDigits = 1}) {
    if (value == null) {
      return '';
    }
    return value
        .toStringAsFixed(fractionDigits)
        .replaceAll(RegExp(r'\.0$'), '');
  }

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  String _profileErrorMessage(Object error, AppLocalizations l10n) {
    if (error is AppException) {
      return error.code.localize(l10n);
    }
    return l10n.errorUnknown;
  }

  String _normalizeFriendCode(String value) {
    return value.trim().toLowerCase();
  }

  String? _validateFriendCode(BuildContext context, String? value) {
    final code = _normalizeFriendCode(value ?? '');
    if (code.isEmpty) {
      return null;
    }
    final copy = _socialCopy(context);
    if (code.length < 4 || code.length > 24) {
      return copy.friendCodeLengthError;
    }
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(code)) {
      return copy.friendCodeFormatError;
    }
    return null;
  }
}

class _TodayProfileMetricsCard extends ConsumerWidget {
  const _TodayProfileMetricsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final isRu = locale.languageCode == 'ru';
    final metricsState = ref.watch(
      dailyProfileMetricsProvider(DateUtils.dateOnly(DateTime.now())),
    );

    return _SectionCard(
      title: isRu ? 'Сегодня в профиле' : 'Today in profile',
      child: metricsState.when(
        data: (metrics) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatLocalizedDate(metrics.date, locale),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _OverviewPill(
                    icon: Icons.directions_walk_outlined,
                    label: isRu
                        ? '${metrics.steps} шагов'
                        : '${metrics.steps} steps',
                  ),
                  _OverviewPill(
                    icon: Icons.restaurant_outlined,
                    label: isRu
                        ? '${metrics.caloriesConsumed.toStringAsFixed(0)} ккал'
                        : '${metrics.caloriesConsumed.toStringAsFixed(0)} kcal',
                  ),
                  _OverviewPill(
                    icon: Icons.local_fire_department_outlined,
                    label: isRu
                        ? '${metrics.caloriesBurned.toStringAsFixed(0)} ккал сожжено'
                        : '${metrics.caloriesBurned.toStringAsFixed(0)} kcal burned',
                  ),
                  _OverviewPill(
                    icon: Icons.pie_chart_outline_rounded,
                    label: isRu
                        ? 'БЖУ ${metrics.proteins.toStringAsFixed(0)}/${metrics.fats.toStringAsFixed(0)}/${metrics.carbs.toStringAsFixed(0)} г'
                        : 'PFC ${metrics.proteins.toStringAsFixed(0)}/${metrics.fats.toStringAsFixed(0)}/${metrics.carbs.toStringAsFixed(0)} g',
                  ),
                  _OverviewPill(
                    icon: Icons.fitness_center_outlined,
                    label: isRu
                        ? '${metrics.workoutsCount} тренировок'
                        : '${metrics.workoutsCount} workouts',
                  ),
                ],
              ),
            ],
          );
        },
        error: (_, _) => Text(
          isRu ? 'Сводка пока недоступна.' : 'Summary is not available yet.',
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GlassCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _OverviewPill(
            icon: Icons.flag_outlined,
            label: profile.goalType.localize(l10n),
          ),
          if (profile.currentWeightKg != null)
            _OverviewPill(
              icon: Icons.monitor_weight_outlined,
              label:
                  '${l10n.profileCurrentWeightShort} ${profile.currentWeightKg!.toStringAsFixed(1)} ${l10n.profileKgUnit}',
            ),
          if (profile.goalType != UserGoalType.maintainWeight &&
              profile.startWeightKg != null)
            _OverviewPill(
              icon: Icons.play_arrow_outlined,
              label:
                  '${l10n.profileStartWeightShort} ${profile.startWeightKg!.toStringAsFixed(1)} ${l10n.profileKgUnit}',
            ),
          if (profile.goalType != UserGoalType.maintainWeight &&
              profile.targetWeightKg != null)
            _OverviewPill(
              icon: Icons.track_changes_outlined,
              label:
                  '${l10n.profileTargetWeightShort} ${profile.targetWeightKg!.toStringAsFixed(1)} ${l10n.profileKgUnit}',
            ),
          if (profile.heightCm != null)
            _OverviewPill(
              icon: Icons.height_outlined,
              label:
                  '${l10n.profileHeightShort} ${profile.heightCm!.toStringAsFixed(0)} ${l10n.profileCmUnit}',
            ),
          if ((profile.city ?? '').isNotEmpty)
            _OverviewPill(
              icon: Icons.location_city_outlined,
              label: profile.city!,
            ),
          if ((profile.friendCode ?? '').isNotEmpty)
            _OverviewPill(
              icon: Icons.alternate_email_rounded,
              label:
                  '${_socialCopy(context).friendCode}: ${profile.friendCode!}',
            ),
          _OverviewPill(
            icon: Icons.directions_walk_outlined,
            label: '${profile.dailyStepGoal} ${l10n.dashboardAnalyticsSteps}',
          ),
          _OverviewPill(
            icon: Icons.local_fire_department_outlined,
            label:
                '${profile.dailyCalorieGoal.toStringAsFixed(0)} ${l10n.profileCaloriesUnit}',
          ),
          Text(
            profile.email,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _LanguagePickerCard extends StatelessWidget {
  const _LanguagePickerCard();

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    return _SectionCard(
      title: isRu ? 'Язык' : 'Language',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRu
                ? 'Выберите язык интерфейса приложения.'
                : 'Choose the app interface language.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 16),
          const AppLanguageSwitcher(),
        ],
      ),
    );
  }
}

class _ThemePickerCard extends ConsumerWidget {
  const _ThemePickerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final activePalette = ref.watch(appThemeProvider);
    final isRu = locale.languageCode == 'ru';

    return _SectionCard(
      title: isRu ? 'Оформление' : 'Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isRu
                ? 'Выберите одну из трех цветовых тем. Логотип и основные анимации подстроятся под выбранные цвета.'
                : 'Choose one of three color themes. The logo and main animations adapt to the selected colors.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final children = AppThemePalettes.all
                  .map((palette) {
                    return _ThemeOptionTile(
                      key: _paletteKey(palette),
                      palette: palette,
                      locale: locale,
                      isSelected: palette.id == activePalette.id,
                      onTap: () => ref
                          .read(appThemeProvider.notifier)
                          .setPalette(palette),
                    );
                  })
                  .toList(growable: false);

              if (!isWide) {
                return Column(
                  children: [
                    for (final child in children) ...[
                      child,
                      if (child != children.last) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final child in children) ...[
                    Expanded(child: child),
                    if (child != children.last) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static Key _paletteKey(AppThemePalette palette) {
    return switch (palette.id) {
      'volt_coral' => AppKeys.profileThemeVoltCoral,
      'graphite_energy' => AppKeys.profileThemeGraphiteEnergy,
      _ => AppKeys.profileThemePulseBlue,
    };
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required super.key,
    required this.palette,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemePalette palette;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ThemeSwatch(color: palette.primary),
                  const SizedBox(width: 6),
                  _ThemeSwatch(color: palette.secondary),
                  const SizedBox(width: 6),
                  _ThemeSwatch(color: palette.tertiary),
                  const Spacer(),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: isSelected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                palette.name(locale),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                palette.description(locale),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

_ProfileSocialCopy _socialCopy(BuildContext context) {
  return _ProfileSocialCopy(
    Localizations.localeOf(context).languageCode == 'ru',
  );
}

class _ProfileSocialCopy {
  const _ProfileSocialCopy(this.isRu);

  final bool isRu;

  String get friendCode => isRu ? 'Код друга' : 'Friend code';
  String get friendCodeHint => isRu
      ? 'По этому коду вас смогут найти друзья. 4-24 символа: a-z, 0-9, _ или -.'
      : 'Friends can find you by this code. 4-24 chars: a-z, 0-9, _ or -.';
  String get copyCode => isRu ? 'Скопировать код' : 'Copy code';
  String get friendCodeLengthError => isRu
      ? 'Код должен быть от 4 до 24 символов'
      : 'Code must be 4 to 24 characters';
  String get friendCodeFormatError => isRu
      ? 'Используйте только латиницу, цифры, _ или -'
      : 'Use only letters, numbers, _ or -';
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DecimalFormField extends StatelessWidget {
  const _DecimalFormField({
    required this.controller,
    required this.label,
    required this.validatorMessage,
  });

  final TextEditingController controller;
  final String label;
  final String validatorMessage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final normalized = (value ?? '').trim().replaceAll(',', '.');
        if (normalized.isEmpty) {
          return null;
        }

        final parsed = double.tryParse(normalized);
        if (parsed == null || parsed <= 0) {
          return validatorMessage;
        }
        return null;
      },
    );
  }
}
