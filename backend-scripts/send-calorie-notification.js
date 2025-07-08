// This script is intended to be run on a backend server or as a scheduled task (e.g., cron job).
// It requires Node.js and the Firebase Admin SDK.

// 1. Install dependencies:
//    npm install firebase-admin

// 2. Set up Firebase Admin SDK:
//    - Go to your Firebase project settings -> Service accounts.
//    - Generate a new private key. This will download a JSON file.
//    - Store this JSON file securely (e.g., in the same directory as this script, but DO NOT commit it to public repositories).
//    - Replace 'path/to/your/serviceAccountKey.json' below with the actual path to your downloaded file.

const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
const serviceAccount = require("../backend-scripts/bitewise-76709-firebase-adminsdk-fbsvc-d5a2c4bb21.json"); // <--- IMPORTANT: Update this path!

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function sendCalorieReminderNotifications() {
  console.log("Starting calorie reminder notification process...");

  try {
    const usersSnapshot = await db.collection("users").get();

    if (usersSnapshot.empty) {
      console.log("No users found.");
      return;
    }

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userId = userDoc.id;
      const fcmToken = userData.fcmToken;
      const dailyCalorieGoal = userData.dailyCalorieGoal;
      const username = userData.username || "User";

      if (!fcmToken || !dailyCalorieGoal) {
        console.log(
          `Skipping user ${userId}: Missing FCM token or daily calorie goal.`
        );
        continue;
      }

      // Get today's date range (start of day to end of day)
      const now = new Date();
      const startOfDay = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate()
      );
      const endOfDay = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + 1
      ); // Start of next day

      // Fetch meals for the current user for today
      const mealsSnapshot = await db
        .collection("meals")
        .where("userId", "==", userId)
        .where("date", ">=", startOfDay)
        .where("date", "<", endOfDay)
        .get();

      let consumedCalories = 0;
      mealsSnapshot.forEach((mealDoc) => {
        consumedCalories += mealDoc.data().calories || 0;
      });

      const remainingCalories = dailyCalorieGoal - consumedCalories;

      if (remainingCalories > 0) {
        const message = {
          notification: {
            title: "Calorie Reminder!",
            body: `You have ${remainingCalories} kcal left from your daily goal of ${dailyCalorieGoal} kcal. Keep going!`,
          },
          token: fcmToken,
          data: {
            // Optional: custom data you can send to the app
            type: "calorie_reminder",
            remainingCalories: remainingCalories.toString(),
            dailyGoal: dailyCalorieGoal.toString(),
          },
        };

        try {
          const response = await admin.messaging().send(message);
          console.log(
            `Successfully sent message to ${username} (${userId}):`,
            response
          );
        } catch (error) {
          console.error(
            `Error sending message to ${username} (${userId}):`,
            error
          );
          // Handle specific errors, e.g., if token is invalid, remove it from user profile
          if (
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered"
          ) {
            console.log(`Removing invalid FCM token for user ${userId}`);
            await db
              .collection("users")
              .doc(userId)
              .update({ fcmToken: admin.firestore.FieldValue.delete() });
          }
        }
      } else {
        console.log(
          `User ${username} (${userId}) has met or exceeded their calorie goal. No notification sent.`
        );
      }
    }
    console.log("Calorie reminder notification process completed.");
  } catch (error) {
    console.error("Error in sendCalorieReminderNotifications:", error);
  }
}

// To run this script manually:
// node scripts/send-calorie-notification.js

// For production, you would schedule this script to run periodically
// (e.g., once a day in the afternoon/evening) using a cron job or a similar scheduler.
sendCalorieReminderNotifications();
