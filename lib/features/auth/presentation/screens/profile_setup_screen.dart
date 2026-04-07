import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/gender.dart';
import '../controllers/auth_action_controller.dart';
import '../widgets/auth_page_scaffold.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();

  Gender? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: l10n.profileBirthDatePickerHelp,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonSave,
    );

    if (date == null) {
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

  Future<void> _handleSaveProfile() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final route = await ref
          .read(authActionControllerProvider.notifier)
          .saveUserProfile(
            name: _nameController.text,
            gender: _selectedGender,
            birthDate: _selectedBirthDate,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(route);
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authActionControllerProvider).isLoading;

    return AuthPageScaffold(
      title: l10n.profileSetupTitle,
      subtitle: l10n.profileSetupSubtitle,
      isLoading: isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: AppKeys.profileNameField,
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(labelText: l10n.commonName),
              validator: (value) {
                final errorCode = InputValidators.validateName(value);
                return errorCode?.localize(l10n);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender>(
              key: AppKeys.profileGenderField,
              initialValue: _selectedGender,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(labelText: l10n.commonGender),
              items: Gender.values
                  .map(
                    (gender) => DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(gender.localize(l10n)),
                    ),
                  )
                  .toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
              validator: (value) {
                return value == null
                    ? AppErrorCode.emptyGender.localize(l10n)
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: AppKeys.profileBirthDateField,
              controller: _birthDateController,
              readOnly: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: l10n.commonBirthDate,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: isLoading ? null : _pickBirthDate,
              validator: (_) {
                final errorCode = InputValidators.validateBirthDate(
                  _selectedBirthDate,
                );
                return errorCode?.localize(l10n);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: AppKeys.saveProfileButton,
              onPressed: isLoading ? null : _handleSaveProfile,
              child: Text(l10n.profileSetupButton),
            ),
          ],
        ),
      ),
    );
  }
}
