# Firebase BiteWise Database Setup

This document explains the Firebase database structure and setup for the BiteWise app.

## 🗄️ Database Structure

### Firestore Collections

```
bitewise-db/
├── users/                          # User documents
│   └── {userId}/                   # Individual user document
│       ├── foods/                  # User's food entries
│       │   └── {foodId}/           # Individual food document
│       ├── meals/                  # User's meal entries
│       │   └── {mealId}/           # Individual meal document
│       ├── recent_foods/           # Recently used foods
│       │   └── {foodId}/           # Individual recent food document
│       └── preferences/            # User preferences
│           └── settings/           # User settings document
```

## 📋 Document Schemas

### User Document
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "photoURL": "string (optional)",
  "createdAt": "timestamp"
}
```

### Food Document
```json
{
  "id": "string",
  "name": "string",
  "mealType": "string (Breakfast/Lunch/Dinner/Snack)",
  "calories": "number",
  "nutrition": {
    "protein": "number",
    "carbs": "number",
    "fat": "number",
    "fiber": "number",
    "sugar": "number"
  },
  "ingredients": ["string"],
  "servingSize": "string",
  "source": "string (ai_scan/local_database)",
  "imagePath": "string (optional)",
  "timestamp": "timestamp",
  "confidence": "number (optional)"
}
```

### Meal Document
```json
{
  "id": "string",
  "name": "string (Breakfast/Lunch/Dinner/Snack)",
  "items": [FoodDocument],
  "totalCalories": "number",
  "time": "string (HH:MM)",
  "date": "string (YYYY-MM-DD)"
}
```

### Recent Food Document
```json
{
  "id": "string",
  "name": "string",
  "mealType": "string",
  "calories": "number",
  "nutrition": "object",
  "ingredients": ["string"],
  "servingSize": "string",
  "source": "string",
  "imagePath": "string (optional)",
  "timestamp": "timestamp",
  "confidence": "number (optional)",
  "lastUsed": "timestamp"
}
```

### User Preferences Document
```json
{
  "calorieGoal": "number",
  "weightGoal": "number (optional)",
  "activityLevel": "string (low/medium/high)",
  "dietaryRestrictions": ["string"],
  "notifications": {
    "mealReminders": "boolean",
    "waterReminders": "boolean",
    "goalReminders": "boolean"
  }
}
```

## 🔧 Firebase Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it "BiteWise"
4. Follow the setup wizard

### 2. Enable Authentication
1. In Firebase Console, go to Authentication
2. Click "Get started"
3. Enable Email/Password authentication
4. Enable Google Sign-in (optional)

### 3. Create Firestore Database
1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users

### 4. Set Up Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 5. Download Configuration Files
1. Go to Project Settings
2. Download `google-services.json` for Android
3. Place it in `android/app/` directory

## 🚀 Features Implemented

### ✅ Real Data Integration
- **User Management**: Users are automatically saved to Firestore when they sign up/sign in
- **Food Tracking**: All scanned and manually added foods are saved to Firestore
- **Meal Management**: Meals are created and updated in real-time
- **Recent Foods**: Recently used foods are tracked for quick access
- **Nutrition Summary**: Real-time calculation of daily nutrition totals

### ✅ Data Persistence
- All user data persists across app sessions
- Data is synced across devices for the same user
- Offline support (Firestore handles offline data automatically)

### ✅ Real-time Updates
- Changes are reflected immediately across the app
- Multiple users can use the app simultaneously
- Data is automatically synced when connection is restored

## 🔍 Testing the Connection

To test if Firebase is working:

1. **Run the app** and sign up/sign in
2. **Check Firebase Console** - you should see a new user document
3. **Add some food** using the scanner or manual entry
4. **Check Firestore** - you should see food documents being created
5. **Verify data persistence** - restart the app and check if data is still there

## 📱 App Features Using Real Data

- **Authentication**: Real user accounts with Firebase Auth
- **Food Scanner**: AI-analyzed foods saved to user's database
- **Meal Planning**: Real meals with actual nutrition data
- **Nutrition Tracking**: Real-time calorie and macro tracking
- **User Profiles**: Persistent user data and preferences
- **Recent Foods**: Quick access to frequently used foods

## 🔒 Security Considerations

- Users can only access their own data
- Authentication required for all operations
- Data is automatically backed up by Firebase
- No sensitive data is stored in plain text

## 📊 Performance Optimizations

- Data is loaded on-demand
- Pagination for large datasets
- Efficient queries with proper indexing
- Offline-first approach with automatic sync

## 🛠️ Troubleshooting

### Common Issues:
1. **Authentication errors**: Check Firebase Auth setup
2. **Permission denied**: Verify Firestore security rules
3. **Data not loading**: Check internet connection
4. **App crashes**: Verify `google-services.json` is in the correct location

### Debug Steps:
1. Check Firebase Console for errors
2. Verify configuration files are correct
3. Test with Firebase CLI
4. Check app logs for specific error messages 