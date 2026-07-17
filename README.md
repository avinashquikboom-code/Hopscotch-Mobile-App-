# FCISeller Mobile App 🌟

A premium, feature-rich Kids E-Commerce Mobile Application built with Flutter. This project leverages modern architecture, robust state management, and high-quality UI/UX designs to deliver a seamless shopping experience.

---

## 📱 Screenshots & Visuals
*(Add application screenshots/mockups here to showcase the beautiful interface)*

---

## ✨ Features

- **🚶‍♂️ Onboarding & Splash**: Smooth, animated introduction slides introducing the app's value proposition.
- **🔐 User Authentication**: Complete security flow featuring **Login**, **Sign Up**, and **Password Recovery**.
- **🏠 Home Dashboard**: Curated home feed showcasing dynamic promotional banners, categories, and trending products.
- **🔍 Advanced Search & Filters**: Instant search results with rating feedback and categories.
- **🏷️ Category Browsing**: Structured department grids and detail listings to easily find children's clothing, toys, and accessories.
- **🛍️ Cart & Wishlist**: Real-time persistent state management allowing users to save items for later or proceed to buy.
- **💳 Checkout Flow**: Multi-step checkout with delivery info confirmation and order completion animations.
- **👤 Profile & Settings**: Personal dashboard to track orders, manage active addresses, view policy agreements, and customize notification settings.
- **🌓 Theme & Theme Providers**: Adaptable light/dark mode support with Google Fonts integration.

---

## 🛠️ Tech Stack & Packages

- **Core**: [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
- **State Management**: [Riverpod (`flutter_riverpod`)](https://riverpod.dev/) with code generation (`riverpod_generator`) for scalable, safe, and testable states.
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing.
- **API Client**: [Dio](https://pub.dev/packages/dio) for optimized HTTP requests.
- **Data Modeling**: [Freezed](https://pub.dev/packages/freezed) & [JSON Serializable](https://pub.dev/packages/json_serializable) for type-safe models.
- **UI Enhancements**:
  - `google_fonts` (premium typography)
  - `shimmer` (skeleton loading placeholders)
  - `flutter_rating_bar` (interactive star ratings)
  - `remixicon` (clean, modern icon set)

---

## 📁 Project Architecture

The project follows a **Feature-First** structure, making it highly modular and easy to scale:

```text
lib/
├── core/
│   ├── constants/       # App Colors, URL paths, Asset paths
│   ├── dummy_data/      # Mock database for mock testing/pre-integration
│   ├── routes/          # GoRouter configuration & routes list
│   ├── theme/           # Light/Dark material theme & provider
│   └── widgets/         # Shared UI widgets (ProductCard, Buttons, Skeletal Loaders)
└── features/            # Feature modules (Auth, Cart, Product, Profile, etc.)
    ├── auth/
    ├── cart_wishlist/
    ├── categories/
    ├── checkout/
    ├── home/
    ├── product/
    ├── profile/
    └── splash_onboarding/
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version `^3.12.1`)
- Dart SDK
- Xcode (for iOS development on macOS)
- Android Studio / Android SDK (for Android development)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/avinashquikboom-code/Hopscotch-Mobile-App-.git
   cd Hopscotch-Mobile-App-
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code files:**
   Since this project uses code generation (Freezed & Riverpod Generator), run the following command to generate the necessary files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application:**
   Ensure you have a simulator/emulator or real device connected, then run:
   ```bash
   flutter run
   ```

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying or distribution is strictly prohibited.
