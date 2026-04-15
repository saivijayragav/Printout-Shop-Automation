# Printout Shop Automation

A comprehensive Flutter mobile application for automated print shop operations, enabling users to upload files, configure print settings, calculate prices dynamically, process payments, and track orders in real-time.

## Features

- **User Authentication** - Secure login and registration with Firebase Auth
- **File Upload & Management** - Upload PDF files with validation and preprocessing
- **Print Configuration** - Customize print settings (color, quality, paper type, etc.)
- **Dynamic Price Calculation** - Real-time pricing based on selected options
- **Shopping Cart** - Manage multiple orders before checkout
- **Payment Processing** - Integrated Razorpay payment gateway
- **Order Tracking** - Real-time order status and history
- **Push Notifications** - Firebase Cloud Messaging with local notifications
- **Cloud Storage** - Cloudflare R2 integration for secure file storage
- **Offline Support** - Work offline with internet connection detection
- **Cross-Platform** - Native support for iOS and Android

## Tech Stack

- **Frontend Framework**: Flutter 3.0+
- **Backend Services**: Firebase (Authentication, Firestore, Cloud Messaging)
- **Payment Gateway**: Razorpay
- **Cloud Storage**: Cloudflare R2
- **State Management**: Provider / Shared Preferences
- **Local Storage**: SQLite (via Firestore sync)
- **Notifications**: Firebase Cloud Messaging + Local Notifications

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0+
- iOS 11.0+ (for iOS development)
- Android 5.0+ / API level 21+
- Active Firebase project
- Cloudflare account with R2 bucket
- Razorpay account for payments

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/printout-shop-automation.git
cd printout-shop-automation
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Environment Configuration

Copy the example environment file and configure with your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your actual API keys:
```env
# Firebase Configuration
FIREBASE_WEB_API_KEY=your_web_api_key
FIREBASE_ANDROID_API_KEY=your_android_api_key
FIREBASE_IOS_API_KEY=your_ios_api_key

# Cloudflare Configuration
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_ACCESS_ID=your_access_id
CLOUDFLARE_SECRET_ACCESS_KEY=your_secret_access_key
CLOUDFLARE_BUCKET=your_bucket_name
```

### 4. iOS Setup (if developing for iOS)

```bash
cd ios
pod install
cd ..
```

### 5. Android Setup (if developing for Android)

Add your `google-services.json` to `android/app/`:
```bash
cp path/to/google-services.json android/app/
```

## Running the App

### Development
```bash
# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d <device_id>

# Run in debug mode with verbose output
flutter run -v
```

### Release Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme.dart               # Global theme configuration
├── firebase_options.dart    # Firebase configuration
├── components/              # Reusable business logic components
│   ├── fileclearing.dart
│   ├── fileconfig.dart
│   ├── pricecalculation.dart
│   ├── pagegenerator.dart
│   └── ...
├── customthemes/            # Custom UI themes
│   ├── appbar_theme.dart
│   ├── elevated_button_theme.dart
│   ├── text_theme.dart
│   └── ...
├── pages/                   # App screens/pages
│   ├── home_page.dart
│   ├── login_page.dart
│   ├── upload.dart
│   ├── cart_page.dart
│   ├── orderprocessing.dart
│   └── ...
├── services/                # External service integrations
│   ├── firebase_messaging_service.dart
│   ├── firestore.dart
│   ├── cloudflarebackend.dart
│   ├── payment_service.dart
│   └── ...
└── utils/                   # Utility functions
    └── file_utils.dart
```

## Security

⚠️ **Important Security Notes:**

1. **Never commit `.env` file** - API keys are sensitive and should never be in version control
2. **Use `.env.example`** - Share this template with your team instead of actual credentials
3. **Rotate keys regularly** - Periodically refresh your API keys in Firebase and Cloudflare
4. **Firebase Security Rules** - Ensure Firestore rules restrict unauthorized access
5. **Cloudflare R2 Access** - Use bucket policies to limit object access

### Setting up Environment Variables

The app loads configuration from `.env` file at startup. The `flutter_dotenv` package handles this securely without exposing keys in the compiled app.

## Configuration

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication, Firestore Database, and Cloud Messaging
3. Generate API keys for Web, Android, and iOS platforms
4. Add to `.env` file

### Cloudflare R2 Setup
1. Create an R2 bucket in your Cloudflare account
2. Generate API token with R2 permissions
3. Add credentials to `.env` file

### Razorpay Setup
1. Create a Razorpay account
2. Get API keys from dashboard
3. Configure in payment service

## API Integration Points

- **Firebase Firestore**: Real-time database for orders, users, and configurations
- **Firebase Authentication**: User login and registration
- **Firebase Cloud Messaging**: Push notifications
- **Cloudflare R2**: File storage and retrieval
- **Razorpay**: Payment processing

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/payment_service_test.dart

# Generate coverage report
flutter test --coverage
```

## Troubleshooting

### Common Issues

**"Cannot find FirebaseOptions"**
- Ensure `.env` file exists and `flutter_dotenv` is properly imported
- Run `flutter pub get` again

**"Cloudflare upload fails"**
- Verify credentials in `.env` are correct
- Check bucket name matches configuration
- Ensure API token has R2 permissions

**"Firebase initialization fails"**
- Verify Firebase project is properly configured
- Check `google-services.json` is in correct location
- Ensure API keys in `.env` match Firebase console

## Build & Deployment

### Android
```bash
flutter build apk --release
# or for App Bundle (Google Play)
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Ensure code follows project style guidelines
4. Submit a pull request

## License

This project is proprietary and confidential.

## Support

For issues and questions, please contact the development team.

---

**Last Updated**: January 2026
