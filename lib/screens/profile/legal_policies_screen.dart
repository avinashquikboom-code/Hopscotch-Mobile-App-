import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/models/policy_model.dart';
import 'package:hopscotch/providers/policy_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class LegalPoliciesScreen extends ConsumerStatefulWidget {
  const LegalPoliciesScreen({super.key});

  @override
  ConsumerState<LegalPoliciesScreen> createState() => _LegalPoliciesScreenState();
}

class _LegalPoliciesScreenState extends ConsumerState<LegalPoliciesScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(policyCategoriesProvider);

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Legal & Policies',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: responsive.fontSize18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: categoriesAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2.5,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceM)),
              Text(
                'Loading policies...',
                style: TextStyle(
                  fontSize: responsive.fontSize13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: responsive.iconSize(44),
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                Text(
                  'Unable to load policies',
                  style: TextStyle(
                    fontSize: responsive.fontSize16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                Text(
                  'Please verify your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(policyCategoriesProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: responsive.iconSize(48),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    Text(
                      'No policies available at this time.',
                      style: TextStyle(
                        fontSize: responsive.fontSize14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final safeIndex = _activeTab >= categories.length ? 0 : _activeTab;
          final activeCategory = categories[safeIndex];
          final policies = activeCategory.policies;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(policyCategoriesProvider);
            },
            color: AppTheme.primaryColor,
            child: Column(
              children: [
                // Horizontal category tab selector
                Padding(
                  padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(categories.length, (index) {
                        final isSelected = safeIndex == index;
                        final category = categories[index];
                        return Padding(
                          padding: EdgeInsets.only(right: responsive.spacing(8)),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _activeTab = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.spacing(16),
                                  vertical: responsive.spacing(10),
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : (isDark
                                          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : (isDark
                                            ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                                            : AppTheme.borderColor),
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected && !isDark
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Theme.of(context).colorScheme.onSurface
                                            : AppTheme.textPrimaryColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Policy Body / Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(
                      responsive.spacing(AppTheme.spaceXL),
                      0,
                      responsive.spacing(AppTheme.spaceXL),
                      responsive.spacing(AppTheme.spaceXL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Text(
                          activeCategory.name,
                          style: TextStyle(
                            fontSize: responsive.fontSize20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (activeCategory.description != null &&
                            activeCategory.description!.isNotEmpty) ...[
                          SizedBox(height: responsive.spacing(4)),
                          Text(
                            activeCategory.description!,
                            style: TextStyle(
                              fontSize: responsive.fontSize12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                        if (policies.isEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'No published policy documents under this category.',
                              style: TextStyle(
                                fontSize: responsive.fontSize12,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ] else ...[
                          ...policies.map((policy) => _buildPolicyCard(context, responsive, policy)),
                        ],

                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, dynamic responsive, PolicyModel policy) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plainContent = policy.plainTextContent;

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(AppTheme.spaceXL)),
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)
              : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(8)),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: responsive.iconSize(18),
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: responsive.spacing(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.title,
                      style: TextStyle(
                        fontSize: responsive.fontSize15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (policy.updatedAt != null)
                      Text(
                        'Last updated: ${policy.updatedAt!.day}/${policy.updatedAt!.month}/${policy.updatedAt!.year}',
                        style: TextStyle(
                          fontSize: responsive.fontSize10,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          const Divider(height: 1),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),

          // Render formatted text
          Text(
            plainContent,
            style: TextStyle(
              fontSize: responsive.fontSize12,
              height: 1.7,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
