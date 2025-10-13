import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../models/candidate_model.dart';
import '../controllers/change_party_symbol_controller.dart';
import '../widgets/current_party_display.dart';
import '../widgets/party_selector.dart';
import '../widgets/symbol_upload_section.dart';
import '../widgets/update_button.dart';

class ChangePartySymbolScreen extends StatefulWidget {
  final Candidate? currentCandidate;

  const ChangePartySymbolScreen({
    super.key,
    required this.currentCandidate,
  });

  @override
  State<ChangePartySymbolScreen> createState() =>
      _ChangePartySymbolScreenState();
}

class _ChangePartySymbolScreenState extends State<ChangePartySymbolScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ChangePartySymbolController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChangePartySymbolController());
    controller.initializeWithCandidate(widget.currentCandidate);
  }

  @override
  void dispose() {
    Get.delete<ChangePartySymbolController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.changePartySymbolTitle),
        // actions: [
        //   TextButton(
        //     onPressed: controller.isLoading.value
        //         ? null
        //         : () async {
        //             if (_formKey.currentState!.validate()) {
        //               final success = await controller.updatePartyAndSymbol(context);
        //               if (success) {
        //                 Get.back(result: controller.currentCandidate.value);
        //               }
        //             }
        //           },
        //     child: Obx(() => controller.isLoading.value
        //         ? const SizedBox(
        //             width: 20,
        //             height: 20,
        //             child: CircularProgressIndicator(strokeWidth: 2),
        //           )
        //         : Text(
        //             localizations.updateButton,
        //             style: const TextStyle(color: Colors.white),
        //           )),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                // Text(
                //   localizations.updatePartyAffiliationHeader,
                //   style: const TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.black87,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Text(
                //   localizations.updatePartyAffiliationSubtitle,
                //   style: const TextStyle(fontSize: 16, color: Colors.black54),
                // ),
                const SizedBox(height: 70),

                // Current Party Display
                CurrentPartyDisplay(controller: controller),
                const SizedBox(height: 32),

                // Party Selection
                PartySelector(controller: controller),
                const SizedBox(height: 24),

                // Independent Symbol Fields
                SymbolUploadSection(
                  controller: controller,
                  formKey: _formKey,
                ),
                const SizedBox(height: 24),

                // Warning Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.importantNotice,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizations.partyChangeWarning,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Update Button
                UpdateButton(
                  controller: controller,
                  formKey: _formKey,
                ),

                // Additional Info Text
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    localizations.updateInstructionText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
