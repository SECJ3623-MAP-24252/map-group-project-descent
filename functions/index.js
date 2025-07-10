const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

exports.onMealCreate = functions.firestore
    .document("meals/{mealId}")
    .onCreate(async (snap, context) => {
      const meal = snap.data();
      const userId = meal.userId;
      const analyticsRef = db.collection("user_analytics").doc(userId);

      return db.runTransaction(async (transaction) => {
        const analyticsDoc = await transaction.get(analyticsRef);

        if (!analyticsDoc.exists) {
          return transaction.set(analyticsRef, {
            userId: userId,
            totalCalories: meal.calories,
            totalProtein: meal.protein,
            totalCarbs: meal.carbs,
            totalFat: meal.fat,
            totalMeals: 1,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        const currentAnalytics = analyticsDoc.data();
        const newTotalMeals = (currentAnalytics.totalMeals || 0) + 1;
        const newTotalCalories = (currentAnalytics.totalCalories || 0) + meal.calories;
        const newTotalProtein = (currentAnalytics.totalProtein || 0) + meal.protein;
        const newTotalCarbs = (currentAnalytics.totalCarbs || 0) + meal.carbs;
        const newTotalFat = (currentAnalytics.totalFat || 0) + meal.fat;

        return transaction.update(analyticsRef, {
          totalMeals: newTotalMeals,
          totalCalories: newTotalCalories,
          totalProtein: newTotalProtein,
          totalCarbs: newTotalCarbs,
          totalFat: newTotalFat,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    });

exports.onMealUpdate = functions.firestore
    .document("meals/{mealId}")
    .onUpdate(async (change, context) => {
        const oldMeal = change.before.data();
        const newMeal = change.after.data();
        const userId = newMeal.userId;
        const analyticsRef = db.collection("user_analytics").doc(userId);

        return db.runTransaction(async (transaction) => {
            const analyticsDoc = await transaction.get(analyticsRef);

            if (!analyticsDoc.exists) {
                // This should not happen if meals are created before being updated
                return;
            }

            const currentAnalytics = analyticsDoc.data();

            const caloriesChange = newMeal.calories - oldMeal.calories;
            const proteinChange = newMeal.protein - oldMeal.protein;
            const carbsChange = newMeal.carbs - oldMeal.carbs;
            const fatChange = newMeal.fat - oldMeal.fat;

            return transaction.update(analyticsRef, {
                totalCalories: (currentAnalytics.totalCalories || 0) + caloriesChange,
                totalProtein: (currentAnalytics.totalProtein || 0) + proteinChange,
                totalCarbs: (currentAnalytics.totalCarbs || 0) + carbsChange,
                totalFat: (currentAnalytics.totalFat || 0) + fatChange,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
    });

exports.onMealDelete = functions.firestore
    .document("meals/{mealId}")
    .onDelete(async (snap, context) => {
        const deletedMeal = snap.data();
        const userId = deletedMeal.userId;
        const analyticsRef = db.collection("user_analytics").doc(userId);

        return db.runTransaction(async (transaction) => {
            const analyticsDoc = await transaction.get(analyticsRef);

            if (!analyticsDoc.exists) {
                return;
            }

            const currentAnalytics = analyticsDoc.data();

            return transaction.update(analyticsRef, {
                totalCalories: (currentAnalytics.totalCalories || 0) - deletedMeal.calories,
                totalProtein: (currentAnalytics.totalProtein || 0) - deletedMeal.protein,
                totalCarbs: (currentAnalytics.totalCarbs || 0) - deletedMeal.carbs,
                totalFat: (currentAnalytics.totalFat || 0) - deletedMeal.fat,
                totalMeals: (currentAnalytics.totalMeals || 0) - 1,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
    });
