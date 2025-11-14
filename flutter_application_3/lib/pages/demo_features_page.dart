import 'package:flutter/material.dart';
import '../utils/app_typography.dart';
import '../utils/micro_interactions.dart';

/// Demo page showcasing new UI features:
/// - Micro-interactions with ripple effects
/// - Theme-compatible gradients
/// - Better spacing (8px grid system)
/// - Theme-compatible color accents
class DemoFeaturesPage extends StatelessWidget {
  const DemoFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('UI Features Demo', style: AppTypography.pageTitle(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: context.primaryGradient, // Theme gradient
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Micro-interactions
            Text(
              '1. Micro-Interactions',
              style: AppTypography.sectionHeading(context),
            ),
            AppSpacing.verticalSM,
            Text(
              'Tap these cards to see ripple and scale effects:',
              style: AppTypography.bodyMedium(context),
            ),
            AppSpacing.verticalMD,
            
            Row(
              children: [
                Expanded(
                  child: MicroInteraction(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card 1 tapped!')),
                      );
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: context.cardGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(
                          'Tap Me',
                          style: AppTypography.cardTitle(context),
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: MicroInteraction(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card 2 tapped!')),
                      );
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: context.accentGradient(theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Tap Me',
                          style: AppTypography.cardTitle(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            AppSpacing.verticalXL,

            // Section 2: Theme Gradients
            Text(
              '2. Theme-Compatible Gradients',
              style: AppTypography.sectionHeading(context),
            ),
            AppSpacing.verticalSM,
            Text(
              'All gradients adapt to light/dark theme:',
              style: AppTypography.bodyMedium(context),
            ),
            AppSpacing.verticalMD,
            
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Primary Gradient',
                  style: AppTypography.subsectionHeading(context).copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            AppSpacing.verticalMD,
            
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: context.secondaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Secondary Gradient',
                  style: AppTypography.subsectionHeading(context).copyWith(
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
            AppSpacing.verticalMD,
            
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: context.surfaceGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  'Surface Gradient',
                  style: AppTypography.subsectionHeading(context),
                ),
              ),
            ),

            AppSpacing.verticalXL,

            // Section 3: Spacing System
            Text(
              '3. Better Spacing (8px Grid)',
              style: AppTypography.sectionHeading(context),
            ),
            AppSpacing.verticalSM,
            Text(
              'Consistent spacing using 8px multiples:',
              style: AppTypography.bodyMedium(context),
            ),
            AppSpacing.verticalMD,
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XS: 4px', style: AppTypography.bodySmall(context)),
                  AppSpacing.verticalXS,
                  Container(height: 2, width: AppSpacing.xs, color: theme.colorScheme.primary),
                  AppSpacing.verticalSM,
                  
                  Text('SM: 8px', style: AppTypography.bodySmall(context)),
                  AppSpacing.verticalXS,
                  Container(height: 2, width: AppSpacing.sm, color: theme.colorScheme.primary),
                  AppSpacing.verticalSM,
                  
                  Text('MD: 16px', style: AppTypography.bodySmall(context)),
                  AppSpacing.verticalXS,
                  Container(height: 2, width: AppSpacing.md, color: theme.colorScheme.primary),
                  AppSpacing.verticalSM,
                  
                  Text('LG: 24px', style: AppTypography.bodySmall(context)),
                  AppSpacing.verticalXS,
                  Container(height: 2, width: AppSpacing.lg, color: theme.colorScheme.primary),
                  AppSpacing.verticalSM,
                  
                  Text('XL: 32px', style: AppTypography.bodySmall(context)),
                  AppSpacing.verticalXS,
                  Container(height: 2, width: AppSpacing.xl, color: theme.colorScheme.primary),
                ],
              ),
            ),

            AppSpacing.verticalXL,

            // Section 4: Color Accents
            Text(
              '4. Theme-Compatible Accents',
              style: AppTypography.sectionHeading(context),
            ),
            AppSpacing.verticalSM,
            Text(
              'Semantic colors that adapt to theme:',
              style: AppTypography.bodyMedium(context),
            ),
            AppSpacing.verticalMD,
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppAccents.success(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppAccents.success(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: AppAccents.success(context), size: 32),
                        AppSpacing.verticalXS,
                        Text('Success', style: AppTypography.label(context)),
                      ],
                    ),
                  ),
                ),
                AppSpacing.horizontalSM,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppAccents.error(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppAccents.error(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error, color: AppAccents.error(context), size: 32),
                        AppSpacing.verticalXS,
                        Text('Error', style: AppTypography.label(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSM,
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppAccents.warning(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppAccents.warning(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning, color: AppAccents.warning(context), size: 32),
                        AppSpacing.verticalXS,
                        Text('Warning', style: AppTypography.label(context)),
                      ],
                    ),
                  ),
                ),
                AppSpacing.horizontalSM,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppAccents.info(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppAccents.info(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info, color: AppAccents.info(context), size: 32),
                        AppSpacing.verticalXS,
                        Text('Info', style: AppTypography.label(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            AppSpacing.verticalXL,
          ],
        ),
      ),
    );
  }
}
