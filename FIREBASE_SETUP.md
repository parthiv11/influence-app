# Firebase Setup Guide for InfluencerConnect App

This guide explains how to set up Firebase for the InfluencerConnect app, including Firestore database structure, authentication, and storage configuration.

## Getting Started

1. Install Firebase CLI if you haven't already:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Initialize Firebase for your project:
   ```
   firebase init
   ```
   Select the following services:
   - Authentication
   - Firestore Database
   - Storage

4. Configure your project:
   ```
   firebase use --add
   ```
   Follow the prompts to select your Firebase project.

## Data Structure

Our Firestore database has the following collections:

### Users Collection

Each document represents a user with the following fields:
- `uid`: String - User ID
- `name`: String - Display name
- `email`: String - Email address
- `phone`: String (optional) - Phone number
- `profilePic`: String - URL to profile picture
- `bio`: String - User biography
- `website`: String - Personal website
- `userType`: String - "influencer" or "brand"
- `createdAt`: Timestamp - When account was created
- `socialAccounts`: Map - Connected social accounts
- `metrics`: Map (for influencers) - Audience metrics
  - `totalFollowers`: Number
  - `engagementRate`: Number
  - `lastUpdated`: String (ISO date)

### Chats Collection

Each document represents a chat conversation:
- `type`: String - "public" or "direct"
- `name`: String - Chat room name (for public chats)
- `participants`: Array - User IDs (for direct chats)
- `createdAt`: Timestamp
- `lastMessage`: String - Preview of the last message
- `lastMessageTime`: Timestamp

#### Messages Subcollection

Each chat has a subcollection of messages:
- `senderId`: String - User ID of sender
- `message`: String - Message content
- `timestamp`: Timestamp - When message was sent

### Campaigns Collection

Each document represents a brand campaign:
- `title`: String - Campaign title
- `brandId`: String - User ID of brand
- `description`: String - Campaign details
- `requirements`: Array - List of requirements
- `budget`: String - Budget range
- `status`: String - "active", "closed", "draft"
- `createdAt`: Timestamp
- `deadline`: String - ISO date
- `applicants`: Array - User IDs of applicants

## Security Rules

We have set up Firestore security rules to protect data:

1. Users can only read/write their own user documents
2. All authenticated users can read the users collection
3. Chat messages can only be created by authenticated users
4. Users can only delete messages they created
5. Campaigns are readable by all authenticated users

## Storage Structure

Firebase Storage is organized as follows:

1. `/profile_images/{userId}/*` - Profile pictures
2. `/campaign_media/{campaignId}/*` - Media for campaigns
3. `/chat_attachments/{chatId}/*` - Files shared in chats

## Seeding the Database

You can seed the database with sample data using the provided script:

```
flutter run scripts/firebase_seed.dart
```

This will create sample users, chats, and campaigns to help with development and testing.

## Troubleshooting

If you encounter issues with Firebase:

1. Ensure you're logged in with `firebase login`
2. Check your project is selected with `firebase projects:list`
3. Verify your app is configured correctly in `firebase.json`
4. Check that Firestore is enabled in your Firebase console 