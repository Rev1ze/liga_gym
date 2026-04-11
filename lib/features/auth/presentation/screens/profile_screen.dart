import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/russian_cities.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/utils/localization_extensions.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileScreenTitle)),
      body: SafeArea(
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
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return l10n.profileCityRequired;
                                    }
                                    return null;
                                  },
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
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
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
