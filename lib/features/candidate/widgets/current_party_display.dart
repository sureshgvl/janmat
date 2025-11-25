import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/symbol_utils.dart';
import '../controllers/change_party_symbol_controller.dart';

class CurrentPartyDisplay extends StatelessWidget {
  final ChangePartySymbolController controller;

  const CurrentPartyDisplay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Obx(() {
      final candidate = controller.currentCandidate.value;
      if (candidate == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            localizations.currentParty,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Box containing symbol and party info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Current Party Symbol
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  child: Image(
                    image: SymbolUtils.getSymbolImageProvider(
                      SymbolUtils.getPartySymbolPath(
                        controller.currentCandidate.value?.party ?? '',
                        candidate: controller.currentCandidate.value,
                      ),
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.flag,
                        size: 24,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SymbolUtils.getPartyFullNameWithLocale(
                          controller.currentCandidate.value?.party ?? '',
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (candidate.symbolName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          localizations.symbolLabel(
                            controller.getCurrentSymbolDisplayName(),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
