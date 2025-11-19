import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../controllers/profile_completion_controller.dart';

class PersonalInfoSection extends StatelessWidget {
  final ProfileCompletionController controller;

  const PersonalInfoSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        TextFormField(
          controller: controller.nameController,
          decoration: controller.buildInputDecoration(
            context,
            label: localizations.fullNameRequired,
            hint: localizations.enterYourFullName,
            icon: Icons.person,
            showPreFilledHelper: controller.isNamePreFilled,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.pleaseEnterYourName;
            }
            if (value.trim().length < 2) {
              return localizations.nameMustBeAtLeast2Characters;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone Field - conditionally disabled for OTP and Google login users
        if (controller.loginMethod == 'phone' || controller.loginMethod == 'google') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      localizations.translate('phoneNumberRequired'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '+91 ${controller.phoneController.text}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Phone number is managed by your login and cannot be changed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: controller.buildInputDecoration(
              context,
              label: localizations.translate('phoneNumberRequired'),
              hint: localizations.translate('enterYourPhoneNumber'),
              icon: Icons.phone,
              showPreFilledHelper: controller.isPhonePreFilled,
            ).copyWith(prefixText: '+91 '),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return localizations.pleaseEnterYourPhoneNumber;
              }
              if (value.trim().length != 10) {
                return localizations.phoneNumberMustBe10Digits;
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                return localizations.pleaseEnterValidPhoneNumber;
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),

        // Birth Date Field
        TextFormField(
          controller: controller.birthDateController,
          readOnly: true,
          onTap: () => controller.selectBirthDate(context),
          decoration: InputDecoration(
            labelText: localizations.translate('birthDateRequired'),
            hintText: localizations.translate('selectYourBirthDate'),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          validator: (value) {
            if (controller.selectedBirthDate == null) {
              return localizations.pleaseSelectYourBirthDate;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Gender Selection
        DropdownButtonFormField<String>(
          initialValue: controller.selectedGender,
          decoration: InputDecoration(
            labelText: localizations.genderRequired,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people),
          ),
          items: [
            DropdownMenuItem(
              value: 'Male',
              child: Text(localizations.male),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: Text(localizations.female),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Text(localizations.other),
            ),
            // DropdownMenuItem(
            //   value: 'Prefer Not to Say',
            //   child: Text(localizations.preferNotToSay),
            // ),
          ],
          onChanged: (value) {
            controller.updateSelectedGender(value);
          },
          validator: (value) {
            if (value == null) {
              return localizations.pleaseSelectYourGender;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
