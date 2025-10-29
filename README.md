# BookSwap

BookSwap is a cross-platform mobile app built with Flutter and Firebase that allows students to swap and chat about books in real time. The app offers user registration and login, book listing management (CRUD), swap offer workflow, real-time chat, in-app notifications, and an accessible, modern UI/UX.

## Features

- **User Authentication:** Register, login, and email verification using Firebase Auth
- **Book Listings:** Create, edit, delete, and browse all posted listings
- **Swap Offers:** Users can offer to swap for another user's book; offers can be accepted or rejected
- **Notifications:** Real-time notification system (for swap offers, acceptances, rejections, chat messages)
- **Chat:** Real-time, per-listing chat between any user and listing owner
- **Responsive and Accessible UI:** Consistent with modern mobile app standards

## Database Model (Firestore)
- users: stores user profiles
- listings: stores book details
- swap_offers: tracks offers for swaps, with status/state
- notifications: tracks notification events per user
- chat_messages: chat history, per user-pair, per listing

## Getting Started

### Prerequisites
- Flutter 3.x installed ([Flutter docs](https://docs.flutter.dev/get-started/install))
- Firebase account + project (iOS/Android apps registered)
- Cloud Firestore and Authentication enabled in Firebase Console
- Cloudinary account for image storage (or use native Firebase Storage with minor code changes)

### Installation
1. **Clone the repo:**
```bash
git clone <your-repo-url>
cd book_swap
```
2. **Install dependencies:**
```bash
flutter pub get
```
3. **Configure Firebase:**
   - Place your `google-services.json` (Android) into `android/app/`
   - Place `GoogleService-Info.plist` (iOS) into `ios/Runner/`
   - Ensure Firebase project has Firestore & Auth enabled
4. **Configure Environment Variables:**
   - Create a `.env` file in the root directory for Cloudinary credentials:
     ```env
     CLOUDINARY_CLOUD_NAME=your_cloud_name
     CLOUDINARY_API_KEY=your_api_key
     CLOUDINARY_API_SECRET=your_api_secret
     CLOUDINARY_UPLOAD_PRESET=your_upload_preset
     ```
   - Register `.env` as a Flutter asset if not already done in `pubspec.yaml`
5. **Android/iOS Setup:**
   - For image upload: set required permissions in `android/app/src/main/AndroidManifest.xml` and iOS `Info.plist`
   - For iOS: ensure minimum platform is 15.0 in Podfile

### Running the App
```bash
flutter run
```
Choose your desired platform: emulator, physical Android, or iOS device.

### Linting & Analysis
```bash
flutter analyze
```
- This reports errors/warnings/lints from Dart Analyzer. Take a screenshot for code audits if needed.

### Project Structure
- `lib/`
  - `main.dart` — App entrypoint and providers setup
  - `models/` — Dart classes for users, listings, swap_offers, chat_message, notification
  - `providers/` — State management (Provider/ChangeNotifier) for all domain logic
  - `screens/` — UI for authentication, home, listing detail, chat, notifications, my listings, settings, etc.
  - `services/` — Service util classes (Cloudinary, Auth logic)

### Key Design Decisions
- State is managed using Provider and ChangeNotifier
- Firestore is modeled with top-level collections and redundant IDs for easy querying
- Enum fields (e.g., swap offer `state` field) are stored as strings
- Images are uploaded to Cloudinary for cost/scalability (replaceable)
- Notifications and chat are real-time (using Firestore streams)

### Troubleshooting
- Ensure all Firebase credentials (`google-services.json`, `.plist`) are correct and in place
- Check the Firebase Console for API errors and make sure rules/permissions are permissive for dev
- Run `flutter clean`, `flutter pub get`, or rebuild the app if changes don’t show up

### Screenshots & Analysis
If submitting for school, include:
- Dart Analyzer report (`flutter analyze`)
- Screenshots of error messages from terminal and how you fixed them
- (Optional) ERD of your database model

---

### Contact
For any issues/bugs, feel free to open an issue or reach out directly!
