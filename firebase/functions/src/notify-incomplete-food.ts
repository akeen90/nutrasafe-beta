import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

/**
 * Firebase function to notify team about incomplete food information
 * Sends an email to info@nutrasafe.co.uk when a user reports missing data
 */
export const notifyIncompleteFood = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    // Extract data from request body (iOS sends nested in "data" field)
    const requestData = req.body.data || req.body;
    const { foodName, brandName, foodId, userId, userEmail } = requestData;

    if (!foodName) {
      res.status(400).json({
        result: { success: false, error: 'Food name is required' }
      });
      return;
    }

    // Log the notification
    console.log('Incomplete food notification:', {
      foodName,
      brandName,
      userId,
      userEmail,
      timestamp: new Date().toISOString()
    });

    // Store notification in Firestore for tracking
    const docRef = await admin.firestore().collection('incompleteFood').add({
      foodName,
      brandName: brandName || null,
      foodId: foodId || null,
      userId: userId || 'anonymous',
      userEmail: userEmail || 'anonymous',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      notificationSent: false
    });

    console.log('✅ Notification saved to Firestore:', docRef.id);

    // Try to send email if credentials are configured
    const emailUser = functions.config().email?.user || process.env.EMAIL_USER;
    const emailPassword = functions.config().email?.password || process.env.EMAIL_PASSWORD;

    if (emailUser && emailPassword) {
      try {
        // Configure email transport
        const transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user: emailUser,
            pass: emailPassword
          }
        });

        // Prepare email content
        const emailSubject = `[NutraSafe] Incomplete Food Data: ${foodName}`;
        const emailBody = `
Hello NutraSafe Team,

A user has reported incomplete food information:

Food Name: ${foodName}
Brand: ${brandName || 'Not specified'}
User Email: ${userEmail || 'Anonymous'}
User ID: ${userId || 'Not provided'}
Reported: ${new Date().toLocaleString('en-GB', { timeZone: 'Europe/London' })}

The user has indicated that this food is missing important information such as:
- Ingredients list
- Nutritional information
- Allergen information
- Additive analysis

Please review and update this food in the database when possible.

---
This is an automated message from NutraSafe app.
        `.trim();

        // Send email
        await transporter.sendMail({
          from: 'NutraSafe App <noreply@nutrasafe.co.uk>',
          to: 'info@nutrasafe.co.uk',
          subject: emailSubject,
          text: emailBody
        });

        console.log('✅ Email sent successfully to info@nutrasafe.co.uk');

        // Update Firestore to mark email as sent
        await docRef.update({ notificationSent: true });
      } catch (emailError) {
        console.warn('⚠️ Failed to send email notification:', emailError);
        // Don't throw - notification is still logged to Firestore
      }
    } else {
      console.log('ℹ️ Email credentials not configured - notification logged to Firestore only');
    }

    res.status(200).json({
      result: {
        success: true,
        message: 'Team has been notified successfully',
        notificationId: docRef.id
      }
    });

  } catch (error) {
    console.error('❌ Error notifying team about incomplete food:', error);
    res.status(500).json({
      result: {
        success: false,
        error: 'Failed to notify team. Please try again later.'
      }
    });
  }
});
