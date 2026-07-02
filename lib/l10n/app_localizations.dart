import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('ja'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('pa'),
    Locale('pt'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Aura Couture'**
  String get appName;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Currency label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// Marathi language
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// Japanese language
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// Settings option
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Search label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Cart label
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Profile label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Add to cart button
  ///
  /// In en, this message translates to:
  /// **'ADD TO CART'**
  String get addToCart;

  /// Buy now button
  ///
  /// In en, this message translates to:
  /// **'BUY NOW'**
  String get buyNow;

  /// Checkout button
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// Skip onboarding button
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// Begin button
  ///
  /// In en, this message translates to:
  /// **'BEGIN'**
  String get begin;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Curated Elite Wear'**
  String get onboardingTitle1;

  /// Onboarding slide 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'AURA COUTURE'**
  String get onboardingSubtitle1;

  /// Onboarding slide 1 description
  ///
  /// In en, this message translates to:
  /// **'Browse hand-selected luxury items tailored specifically to your discerning fashion tastes. Pure materials, handcrafted details, timeless styles.'**
  String get onboardingDesc1;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Bespoke Tailoring'**
  String get onboardingTitle2;

  /// Onboarding slide 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'SAVILE ROW DIRECT'**
  String get onboardingSubtitle2;

  /// Onboarding slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Elevate your wardrobe with personalized fit recommendation software and customized sizing options direct from European design houses.'**
  String get onboardingDesc2;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Express Logistics'**
  String get onboardingTitle3;

  /// Onboarding slide 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'WHITE-GLOVE DELIVERY'**
  String get onboardingSubtitle3;

  /// Onboarding slide 3 description
  ///
  /// In en, this message translates to:
  /// **'Uncompromising speed. Your hand-wrapped garments are dispatched with secure elite courier delivery straight to your doorstep.'**
  String get onboardingDesc3;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your custom couture selections.'**
  String get signInDescription;

  /// Email input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Password input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Create account link/button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Sign up screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// Sign up screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Aura Couture for custom tailor fits, priority shipping, and member pricing.'**
  String get signupDescription;

  /// Name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validEmail;

  /// Password input hint for signup
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password'**
  String get choosePassword;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLength;

  /// Login prompt in signup
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Forgot password screen title
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecovery;

  /// Forgot password screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email. We\'ll send a secure link to reset your password.'**
  String get recoveryDescription;

  /// Send recovery email button
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Email'**
  String get sendRecoveryEmail;

  /// Recovery sent dialog title
  ///
  /// In en, this message translates to:
  /// **'Recovery Sent ✉️'**
  String get recoverySent;

  /// Recovery sent dialog message
  ///
  /// In en, this message translates to:
  /// **'A security link has been sent to your email. Please click the link to reset your secure passcode.'**
  String get recoverySentMessage;

  /// Got it button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// Cart screen title
  ///
  /// In en, this message translates to:
  /// **'YOUR BAG'**
  String get yourBag;

  /// Clear cart button
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clear;

  /// Empty cart message
  ///
  /// In en, this message translates to:
  /// **'Your Bag is Empty'**
  String get bagEmpty;

  /// Empty cart description
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any garments to your luxury bag yet. Browse our Collections to begin.'**
  String get bagEmptyDescription;

  /// Shop new arrivals button
  ///
  /// In en, this message translates to:
  /// **'Shop New Arrivals'**
  String get shopNewArrivals;

  /// Items label in cart
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get items;

  /// Subtotal label
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Shipping label
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// Tax label
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// Gift wrapping option
  ///
  /// In en, this message translates to:
  /// **'Gift Wrapping'**
  String get giftWrapping;

  /// Subcategories description
  ///
  /// In en, this message translates to:
  /// **'Explore hand-curated luxury subdivisions.'**
  String get exploreSubcategories;

  /// Shop all label
  ///
  /// In en, this message translates to:
  /// **'Shop All'**
  String get shopAll;

  /// Order summary header
  ///
  /// In en, this message translates to:
  /// **'ORDER SUMMARY'**
  String get orderSummary;

  /// Gift wrapping description
  ///
  /// In en, this message translates to:
  /// **'Premium boxed wrap with note card'**
  String get giftWrappingDesc;

  /// Tax percentage label
  ///
  /// In en, this message translates to:
  /// **'Tax (8%)'**
  String get taxPercent;

  /// Total label in checkout
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalLabel;

  /// Proceed to checkout button
  ///
  /// In en, this message translates to:
  /// **'PROCEED TO CHECKOUT'**
  String get proceedToCheckout;

  /// Categories screen title
  ///
  /// In en, this message translates to:
  /// **'COUTURE DEPARTMENTS'**
  String get coutureDepartments;

  /// Promo banner 1 title
  ///
  /// In en, this message translates to:
  /// **'THE COUTURE SALE'**
  String get theCoutureSale;

  /// Promo banner 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Up to 30% Off New Autumwear'**
  String get upToOff;

  /// Promo banner 1 action
  ///
  /// In en, this message translates to:
  /// **'Shop Couture'**
  String get shopCouture;

  /// Promo banner 2 title
  ///
  /// In en, this message translates to:
  /// **'GENTLEMAN\'S APPAREL'**
  String get gentlemansApparel;

  /// Promo banner 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'English Wool Suits & Coats'**
  String get englishWoolSuits;

  /// Promo banner 2 action
  ///
  /// In en, this message translates to:
  /// **'Explore Tailored'**
  String get exploreTailored;

  /// Promo banner 3 title
  ///
  /// In en, this message translates to:
  /// **'ITALIAN CRADLE'**
  String get italianCradle;

  /// Promo banner 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Handcrafted Full-Grain Loafers'**
  String get handcraftedLoafers;

  /// Promo banner 3 action
  ///
  /// In en, this message translates to:
  /// **'View Footwear'**
  String get viewFootwear;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'MY PORTFOLIO'**
  String get myPortfolio;

  /// Default member name
  ///
  /// In en, this message translates to:
  /// **'Aura Member'**
  String get auraMember;

  /// Elite member badge
  ///
  /// In en, this message translates to:
  /// **'ELITE MEMBER'**
  String get eliteMember;

  /// Order history option
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// Order history description
  ///
  /// In en, this message translates to:
  /// **'Track status and view purchases'**
  String get orderHistoryDesc;

  /// Notifications option
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications description
  ///
  /// In en, this message translates to:
  /// **'Offers, discounts, and dispatch logs'**
  String get notificationsDesc;

  /// Settings description
  ///
  /// In en, this message translates to:
  /// **'Security, privacy, and measurements'**
  String get settingsDesc;

  /// Help center option
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Help center description
  ///
  /// In en, this message translates to:
  /// **'24/7 dedicated elite concierge chat'**
  String get helpCenterDesc;

  /// Legal policies option
  ///
  /// In en, this message translates to:
  /// **'Legal Policies'**
  String get legalPolicies;

  /// Legal policies description
  ///
  /// In en, this message translates to:
  /// **'Terms of service and privacy rules'**
  String get legalPoliciesDesc;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'LOG OUT FROM APP'**
  String get logOut;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'SETTINGS & FIT PROFILE'**
  String get settingsFitProfile;

  /// Profile save success message
  ///
  /// In en, this message translates to:
  /// **'Couture profile saved! ✨'**
  String get coutureProfileSaved;

  /// Tailoring profile section title
  ///
  /// In en, this message translates to:
  /// **'Bespoke Tailoring Profile'**
  String get bespokeTailoringProfile;

  /// Tailoring profile description
  ///
  /// In en, this message translates to:
  /// **'Input your measurements below. Our European design mills will recommend customized garments based on your exact structure.'**
  String get bespokeTailoringDesc;

  /// Height input label
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get height;

  /// Chest input label
  ///
  /// In en, this message translates to:
  /// **'Chest (cm)'**
  String get chest;

  /// Waist input label
  ///
  /// In en, this message translates to:
  /// **'Waist (cm)'**
  String get waist;

  /// Notification section title
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// Push alerts option
  ///
  /// In en, this message translates to:
  /// **'Push Alerts'**
  String get pushAlerts;

  /// Push alerts description
  ///
  /// In en, this message translates to:
  /// **'Order dispatches, shipping status'**
  String get pushAlertsDesc;

  /// Exclusive drops option
  ///
  /// In en, this message translates to:
  /// **'Exclusive Drops'**
  String get exclusiveDrops;

  /// Exclusive drops description
  ///
  /// In en, this message translates to:
  /// **'Limited runs, VIP sales, designer news'**
  String get exclusiveDropsDesc;

  /// Security section title
  ///
  /// In en, this message translates to:
  /// **'Security Preferences'**
  String get securityPreferences;

  /// Biometric authentication option
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// Biometric authentication description
  ///
  /// In en, this message translates to:
  /// **'Access billing and purchase secure keys instantly'**
  String get biometricAuthDesc;

  /// Language & currency section title
  ///
  /// In en, this message translates to:
  /// **'Language & Currency'**
  String get languageCurrency;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// System theme description
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get systemDesc;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Light theme description
  ///
  /// In en, this message translates to:
  /// **'Always light mode'**
  String get lightDesc;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Dark theme description
  ///
  /// In en, this message translates to:
  /// **'Always dark mode'**
  String get darkDesc;

  /// Save preferences button
  ///
  /// In en, this message translates to:
  /// **'SAVE PREFERENCES'**
  String get savePreferences;

  /// Home screen greeting when not logged in
  ///
  /// In en, this message translates to:
  /// **'Discover Luxury'**
  String get discoverLuxury;

  /// Search bar placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search luxury knitwear, suits, silks...'**
  String get searchPlaceholder;

  /// Limited edition badge on promo banner
  ///
  /// In en, this message translates to:
  /// **'LIMITED EDITION'**
  String get limitedEdition;

  /// Categories section title
  ///
  /// In en, this message translates to:
  /// **'Couture Collections'**
  String get coutureCollections;

  /// View all button
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Trending products section title
  ///
  /// In en, this message translates to:
  /// **'Trending Highlights'**
  String get trendingHighlights;

  /// See all button
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// New arrivals section title
  ///
  /// In en, this message translates to:
  /// **'The New Guard'**
  String get theNewGuard;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Product not found message
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// Product description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Select size label
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get selectSize;

  /// Select color label
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// Customer reviews section title
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// Reviews label
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// Similar products section title
  ///
  /// In en, this message translates to:
  /// **'You May Also Like'**
  String get youMayAlsoLike;

  /// No recommendations message
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get noRecommendations;

  /// Added to cart button state
  ///
  /// In en, this message translates to:
  /// **'ADDED'**
  String get added;

  /// Share product message
  ///
  /// In en, this message translates to:
  /// **'Check out this product on Hopscotch!'**
  String get shareProduct;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Rating label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Sizes label
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get sizes;

  /// Colors label
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colors;

  /// Link label
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// Original price label
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// Discount off label
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// Wishlist screen title
  ///
  /// In en, this message translates to:
  /// **'MY WISHLIST'**
  String get myWishlist;

  /// Empty wishlist message
  ///
  /// In en, this message translates to:
  /// **'Your Wishlist is Empty'**
  String get wishlistEmpty;

  /// Empty wishlist description
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any design to save your favored luxury items here for later.'**
  String get wishlistEmptyDesc;

  /// Explore departments button
  ///
  /// In en, this message translates to:
  /// **'Explore Departments'**
  String get exploreDepartments;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'gu',
    'hi',
    'ja',
    'kn',
    'ml',
    'mr',
    'pa',
    'pt',
    'ru',
    'ta',
    'te',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
