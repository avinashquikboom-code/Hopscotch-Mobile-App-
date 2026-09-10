import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/policy_model.dart';
import 'package:hopscotch/providers/policy_provider.dart';
import 'package:hopscotch/screens/profile/legal_policies_screen.dart';
import 'package:hopscotch/screens/about/privacy_policy_screen.dart';
import 'package:hopscotch/screens/about/terms_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Policy Model Unit Tests', () {
    test('PolicyCategoryModel and PolicyModel fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Privacy Policy',
        'slug': 'privacy-policy',
        'description': 'User data protection terms',
        'sortOrder': 1,
        'isActive': true,
        'policies': [
          {
            'id': 101,
            'categoryId': 1,
            'title': 'Privacy Policy',
            'slug': 'privacy-policy',
            'content': '<h3>1. Collection</h3><p>We collect your details.</p>',
            'isActive': true,
          }
        ]
      };

      final cat = PolicyCategoryModel.fromJson(json);
      expect(cat.id, 1);
      expect(cat.name, 'Privacy Policy');
      expect(cat.slug, 'privacy-policy');
      expect(cat.policies.length, 1);

      final policy = cat.policies.first;
      expect(policy.id, 101);
      expect(policy.categoryId, 1);
      expect(policy.title, 'Privacy Policy');
      expect(policy.plainTextContent, contains('1. Collection'));
      expect(policy.plainTextContent, contains('We collect your details.'));
      expect(policy.plainTextContent.contains('<p>'), isFalse);
    });

    test('plainTextContent strips HTML tags and cleans entities', () {
      final policy = PolicyModel(
        id: 2,
        categoryId: 1,
        title: 'Terms & Conditions',
        slug: 'terms',
        content: '<h2>Heading</h2><p>Paragraph with &amp; &quot;quotes&quot; and <br/>break.</p><ul><li>Item 1</li><li>Item 2</li></ul>',
      );

      final clean = policy.plainTextContent;
      expect(clean, contains('Heading'));
      expect(clean, contains('Paragraph with & "quotes" and'));
      expect(clean, contains('• Item 1'));
      expect(clean, contains('• Item 2'));
      expect(clean.contains('<h2>'), isFalse);
      expect(clean.contains('<li>'), isFalse);
    });
  });

  group('LegalPoliciesScreen Widget Tests', () {
    final mockCategories = [
      PolicyCategoryModel(
        id: 1,
        name: 'Privacy Policy',
        slug: 'privacy-policy',
        description: 'Customer privacy commitments',
        sortOrder: 1,
        policies: [
          PolicyModel(
            id: 101,
            categoryId: 1,
            title: 'Privacy Policy Document',
            slug: 'privacy-policy',
            content: 'Fashion City India Ltd protects your personal data.',
          ),
        ],
      ),
      PolicyCategoryModel(
        id: 2,
        name: 'Terms & Conditions',
        slug: 'terms-and-conditions',
        description: 'General user terms',
        sortOrder: 2,
        policies: [
          PolicyModel(
            id: 102,
            categoryId: 2,
            title: 'Terms of Use',
            slug: 'terms-and-conditions',
            content: 'By using this app, you agree to our terms.',
          ),
        ],
      ),
      PolicyCategoryModel(
        id: 3,
        name: 'Shipping Policy',
        slug: 'shipping-policy',
        description: 'Delivery guidelines',
        sortOrder: 3,
        policies: [
          PolicyModel(
            id: 103,
            categoryId: 3,
            title: 'Shipping & Delivery',
            slug: 'shipping-policy',
            content: 'Orders dispatch within 24 to 48 hours.',
          ),
        ],
      ),
    ];

    testWidgets('Renders all category tabs dynamically from Riverpod', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyCategoriesProvider.overrideWith((ref) => Future.value(mockCategories)),
          ],
          child: const MaterialApp(
            home: LegalPoliciesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Legal & Policies'), findsOneWidget);

      // Check tab names
      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Shipping Policy'), findsOneWidget);

      // Check default active policy content
      expect(find.text('Privacy Policy Document'), findsOneWidget);
      expect(find.textContaining('Fashion City India Ltd protects your personal data.'), findsOneWidget);
    });

    testWidgets('Tapping another category tab updates policy display', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyCategoriesProvider.overrideWith((ref) => Future.value(mockCategories)),
          ],
          child: const MaterialApp(
            home: LegalPoliciesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Shipping Policy' tab
      await tester.tap(find.text('Shipping Policy'));
      await tester.pumpAndSettle();

      // Verify that shipping policy content is now visible
      expect(find.text('Shipping & Delivery'), findsOneWidget);
      expect(find.textContaining('Orders dispatch within 24 to 48 hours.'), findsOneWidget);
    });

    testWidgets('Shows error state with retry button on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyCategoriesProvider.overrideWith((ref) => Future.error(Exception('Network timeout'))),
          ],
          child: const MaterialApp(
            home: LegalPoliciesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load policies'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Privacy & Terms Screen Dynamic Tests', () {
    testWidgets('PrivacyPolicyScreen renders dynamic backend content', (tester) async {
      final mockPolicy = PolicyModel(
        id: 1,
        categoryId: 1,
        title: 'Privacy Policy',
        slug: 'privacy-policy',
        content: 'Official Privacy Policy of Fashion City India Ltd. Contact: fashioncityinidia18@gmail.com',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyDetailProvider('privacy-policy').overrideWith((ref) => Future.value(mockPolicy)),
          ],
          child: const MaterialApp(
            home: PrivacyPolicyScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.textContaining('fashioncityinidia18@gmail.com'), findsOneWidget);
    });

    testWidgets('TermsScreen renders dynamic backend content', (tester) async {
      final mockPolicy = PolicyModel(
        id: 2,
        categoryId: 2,
        title: 'Terms of Service',
        slug: 'terms-and-conditions',
        content: 'Terms governing use of Fashion City India Ltd platform under GSTIN 24GUKPS9446A1ZA.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyDetailProvider('terms-and-conditions').overrideWith((ref) => Future.value(mockPolicy)),
          ],
          child: const MaterialApp(
            home: TermsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsWidgets);
      expect(find.textContaining('24GUKPS9446A1ZA'), findsOneWidget);
    });
  });
}
