# BookSwap App — Implementation Plan

## Table of Contents

1. [Project Goals & Overview](#1-project-goals--overview)
2. [Feature Breakdown & User Flows](#2-feature-breakdown--user-flows)
3. [State Management Choice](#3-state-management-choice)
4. [Navigation & Routing](#4-navigation--routing)
5. [Folder/File Structure](#5-folderfile-structure)
6. [Where to Write Firebase Code](#6-where-to-write-firebase-code)
7. [Firebase Data Model](#7-firebase-data-model)
8. [Key Screens & Widgets](#8-key-screens--widgets)
9. [Implementation Steps / Milestones](#9-implementation-steps--milestones)
10. [Testing Plan](#10-testing-plan)
11. [Out of Scope (Bonus Features)](#11-out-of-scope-bonus-features)

---

## 1. Project Goals & Overview

**BookSwap** is a Flutter app for university students to trade textbooks via a secure, reactive and user-friendly marketplace leveraging Firebase for:

- User authentication (sign up, login, logout, verification)
- Cloud Firestore for real-time book listings and swap state sync
- Profile and settings management
- State management for reactive UI
- Persistent navigation with named routes

---

## 2. Feature Breakdown & User Flows

### 2.1. Authentication
- Users sign up, log in, and log out (Email/Password, Firebase Auth)
- Email verification required before posting/viewing listings
- Each user has a profile (name, email, photo, etc.)
- Authentication enforced for routes other than login

### 2.2. Book Listings (CRUD)
- **Create:** Add a book (title, author, condition: enum(New, Like New, Good, Used), cover image, optional description)
- **Read:** Browse all active listings, real-time updates
- **Update:** Edit fields and replace cover image (own listings only)
- **Delete:** Remove own listing

### 2.3. Swap Functionality
- Initiate swap offer via “Swap” button
- Swap state: Pending → Accepted → Completed (for bonus/future), or Cancelled
- Listing moves to “My Offers” (pending/outbound and inbound requests separated)
- Both users see real-time swap state changes

### 2.4. State Management
- App state reflects changes from Firestore/Authentication instantly
- Riverpod or Provider recommended for ease of testing, modularity, and scalability

### 2.5. Navigation — Named Routes & Structure
- BottomNavigationBar for 4 core sections:
  1. Browse Listings (`/browse`)
  2. My Listings (`/my-listings`)
  3. My Offers (`/offers`)
  4. Settings (`/settings`)
- Onboarding/Login & Email Verification handled with explicit routes/screens outside tab bar
- Use Flutter’s named route navigation throughout

### 2.6. Settings & Profile
- View profile info, including email verification status
- Edit display name, upload/change profile photo
- Notification preference toggle

---

## 3. State Management Choice

**Riverpod (preferred, or Provider if simpler for assignment scope)**
- Pros: Global, modular, testable, handles listening to Firestore changes and Auth status

---

## 4. Navigation & Routing

- All navigation uses named routes (constants for all route names).
- Authentication/verification gates by redirecting to login or verify screens as needed.
- Deep linking supported (for future, optional).

---

## 5. Folder/File Structure

**Following the recommended scalable structure for mid-sized Flutter+Firebase apps:**

```plaintext
book_swap/
├── android/
├── ios/
├── lib/
│   ├── main.dart                # Entry point, initializes Firebase, sets up routers/providers
│   ├── app.dart                 # App widget with MaterialApp/router config
│   ├── core/
│   │   ├── constants.dart
│   │   ├── theme.dart
│   │   └── routing.dart         # Named routes, navigation helpers
│   ├── models/
│   │   ├── user.dart            # AppUser model
│   │   ├── book_listing.dart    # BookListing model
│   │   ├── swap_offer.dart      # SwapOffer model
│   ├── services/
│   │   ├── auth_service.dart        # <--- Firebase Auth logic here
│   │   ├── firestore_service.dart   # <--- Firestore CRUD, streams here
│   │   ├── storage_service.dart     # <--- Firebase Storage logic here
│   │   └── notification_service.dart # Push/local notification handling
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── listings_provider.dart
│   │   ├── offers_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── verify_email_screen.dart
│   │   ├── browse_listings/
│   │   │   ├── browse_listings_screen.dart
│   │   │   ├── listing_detail_screen.dart
│   │   ├── my_listings/
│   │   │   ├── my_listings_screen.dart
│   │   │   ├── edit_listing_screen.dart
│   │   │   ├── add_listing_screen.dart
│   │   ├── offers/
│   │   │   ├── my_offers_screen.dart
│   │   │   ├── swap_offer_detail_screen.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── profile_screen.dart
│   ├── widgets/
│   │   ├── book_card.dart
│   │   ├── swap_button.dart
│   │   ├── listings_list.dart
│   │   ├── condition_chip.dart
│   │   └── etc...
│   ├── utils/
│   │   ├── validators.dart
│   │   └── helpers.dart
│   └── firebase_options.dart    # Generated (by FlutterFire CLI)
├── pubspec.yaml
├── README.md
└── IMPLEMENTATION_PLAN.md       # <--- THIS FILE
```

---

## 6. Where to Write Firebase Code

**All direct interaction with Firebase is organized under the `lib/services/` directory.**
- Place all Firebase authentication logic in `services/auth_service.dart`
- Place all Firestore logic (CRUD, queries, real-time streams) in `services/firestore_service.dart`
- Place Firebase Storage code for uploads/downloads in `services/storage_service.dart`
- Any notification logic with Firebase or local notifications goes in `services/notification_service.dart`

**Structure Example:**
- `auth_service.dart`: signUp, signIn, signOut, getCurrentUser, sendEmailVerification, etc.
- `firestore_service.dart`: createListing, updateListing, deleteListing, listenToListings, createSwapOffer, etc.
- `storage_service.dart`: uploadImage, getDownloadUrl, deleteImage, etc.

If you have very tiny reusable Firebase helpers or constants, you may optionally add to `lib/utils/firebase_helpers.dart`.

*Providers in `lib/providers/` wrap these services for UI state management.*

---

## 7. Firebase Data Model

### **Users Collection (`users`)**
```json
{
  "uid": "string",
  "displayName": "string",
  "email": "string",
  "photoUrl": "string",
  "emailVerified": true,
  "createdAt": "timestamp",
  "notificationEnabled": true
}
```

### **Book Listings Collection (`listings`)**
```json
{
  "listingId": "string",
  "ownerId": "userId",
  "title": "string",
  "author": "string",
  "condition": "New" | "Like New" | "Good" | "Used",
  "coverUrl": "string",
  "description": "string",
  "createdAt": "timestamp",
  "isActive": true
}
```

### **Swap Offers Collection (`swap_offers`)**
```json
{
  "offerId": "string",
  "listingId": "string",
  "fromUserId": "userId",
  "toUserId": "userId",
  "state": "pending" | "accepted" | "completed" | "cancelled",
  "createdAt": "timestamp"
}
```

*All collections have Firestore security rules so users can only write/manage their own data.*

---

## 8. Key Screens & Widgets

- **Browse Listings:** List all books, tap to view details, can initiate swap if email verified & not own listing.
- **Listing Detail:** Cover, info, swap button (unless owner), condition, etc.
- **My Listings:** View, edit, delete own listings.
- **Edit/Add Flow:** Form for book creation/edit, with image picker/upload to Firebase Storage.
- **My Offers:** Inbound/outbound offers, see swap state, real-time update.
- **Settings:** Notification toggle, profile view/edit.
- **Auth Screens:** Sign up, login, verify email, forgot password.
- **Navigation:** BottomNavigationBar (named routes via Navigator, easy to deep-link and unit test).
- **Reusable Widgets:** Book card, chips, buttons, etc.

---

## 9. Implementation Steps / Milestones

1. **Project Setup**
    - Initialize Flutter project with Firebase (FlutterFire CLI for auth, firestore, storage)
    - Setup all core folders in `lib/`

2. **Authentication Module**
    - Implement login, registration, and email verification screens
    - Setup `AuthProvider` with FirebaseAuth
    - Test auth flow (including verification, state listeners)

3. **Book Listing Functionality**
    - Design `BookListing` model & Firestore integration (`FirestoreService`)
    - List, add, edit, delete listings (CRUD)
    - Image picker/upload with Firebase Storage
    - Restrict edit/delete to owner

4. **Browse Listings & Detail View**
    - Real-time list of listings (excluding swapped/inactive)
    - Detail view page

5. **Swap Offers**
    - Implement swap offer initiation and Firestore structure
    - Show pending/offers in “My Offers” (outbound and inbound)
    - State transitions for swap offers

6. **State Management**
    - Riverpod (or Provider) for:
        - Auth state
        - Listings provider (all, mine)
        - Offers provider (my swaps)
        - Settings provider

7. **Navigation**
    - MaterialApp with named route map and guards
    - BottomNavigationBar for 4 main areas

8. **Settings/Profile**
    - Profile screen
    - Notification preference toggle (simulated)

9. **Polish & Testing**
    - Responsive UI
    - Accessibility (semantics for screen readers, tap targets, color contrast)
    - Field validation
    - Manual and widget tests for each core feature

10. **(If time permits)** Clean up, optimize performance, profile app, update README

---

## 10. Testing Plan

- **Manual testing:** Every core feature, auth, CRUD, state updates
- **Widget testing:** Forms, providers, widgets
- **Integration testing:** Auth flow, adding/deleting listings, swap offers (user simulation)
- **Firebase Rules:** Protect user data (manual security review + test access as a non-owner)

---

## 11. Out of Scope (Bonus Features)

- Chats between users after a swap is initiated **(chat logic/implementation NOT included)**
- Advanced notification (only simple toggle/simulated notification in settings)
- Payment, reviews, or reporting

---

## Notes

- All navigation should use named routes for clarity, maintainability, and deep-link support.
- Each major feature gets separated into `screens/`, `models/`, `providers/`, `services/`, and `widgets/` folders for clarity and scalability.
- Use Riverpod (or Provider) to keep code reactive and testable.
- All images stored in Firebase Storage; URLs referenced in Firestore.
- Make sure to use clear validation and feedback (e.g. email must be verified to use listings or offer features).

---

**End of Implementation Plan**
