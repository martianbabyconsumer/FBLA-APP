# 6-Digit Email Verification System

## Overview

The app now uses a **6-digit verification code** system instead of email links. This provides a better user experience and is easier to implement without complex email service configurations.

## How It Works

### 1. **Signup Flow**
- User creates an account
- A 6-digit code is generated and stored in Firestore
- Code is displayed in console/debug output (for development)
- User enters the code in a dialog to verify their email
- Code expires after 15 minutes

### 2. **Password Change Flow**
- User changes their password in settings
- A new 6-digit verification code is sent
- User must verify with the code
- Can skip verification but recommended to verify

### 3. **Code Generation**
- Randomly generated 6-digit number (100000-999999)
- Stored in Firestore with:
  - User ID
  - Email address
  - Expiration time (15 minutes)
  - Verification status

### 4. **Code Verification**
- User enters the 6-digit code
- System checks:
  - Code exists
  - Code hasn't expired
  - Code matches
  - Code hasn't been used
- Updates Firestore to mark email as verified

## Database Structure

### Firestore Collections

#### `verification_codes/{userId}`
```json
{
  "code": "123456",
  "email": "user@example.com",
  "expiresAt": Timestamp,
  "verified": false,
  "createdAt": Timestamp,
  "verifiedAt": Timestamp (optional)
}
```

#### `users/{userId}`
```json
{
  "emailVerified": true,
  "verifiedAt": Timestamp,
  // ... other user data
}
```

## Features

### ✅ Implemented
- 6-digit code generation
- Code storage in Firestore
- Code expiration (15 minutes)
- Code verification
- Resend code functionality (60 second cooldown)
- Verification status tracking
- Console output for development

### 🔄 To Implement (Production)
- **Email service integration** (SendGrid, AWS SES, etc.)
- Cloud Functions to send actual emails
- Rate limiting for code generation
- SMS verification as alternative
- Email template customization

## Development Testing

Since we don't have email service configured yet, codes are printed to console:

```
==============================================
VERIFICATION EMAIL
==============================================
To: user@example.com
Subject: Verify your email for FBLA HIVE

Hello John Doe,

Your verification code is: 123456

This code will expire in 15 minutes.

If you didn't ask to verify this address, you can ignore this email.

Thanks,
FBLA HIVE team
==============================================
```

### How to Test:
1. Sign up with a new account
2. Check the **console/terminal output** for the verification code
3. Enter the code in the verification dialog
4. Code will be verified and stored

## Setting Up Real Email (Future)

To send actual emails, you'll need to:

### Option 1: Firebase Extensions (Recommended)
1. Install "Trigger Email" extension from Firebase Console
2. Configure SMTP or SendGrid API
3. Create email template
4. Update `sendVerificationEmail()` to use the extension

### Option 2: Cloud Functions
1. Create a Cloud Function
2. Use NodeMailer or SendGrid SDK
3. Call function from Flutter app
4. Handle email sending server-side

### Option 3: Third-Party Service
1. Sign up for SendGrid, Mailgun, or similar
2. Get API key
3. Use HTTP package to call their API
4. Send emails directly from Flutter

## Security Considerations

✅ **Already Implemented:**
- Codes expire after 15 minutes
- Codes can only be used once
- Codes are tied to specific user IDs
- Verification status stored separately

⚠️ **Should Add:**
- Rate limiting (max 5 codes per hour)
- IP tracking for abuse prevention
- Account lockout after too many failed attempts
- Audit log of verification attempts

## User Experience

### Signup
1. Fill registration form
2. Submit
3. **Verification dialog appears**
4. Check email/console for code
5. Enter 6-digit code
6. Click "Verify"
7. Success! Return to login

### Password Change
1. Go to Settings
2. Click "Change Password"
3. Enter current and new passwords
4. **Verification dialog appears**
5. Enter code from email/console
6. Verified! Password updated

## Error Messages

| Error | Meaning |
|-------|---------|
| "No verification code found" | Code doesn't exist, need to resend |
| "This code has expired" | Code is older than 15 minutes |
| "This code has already been used" | Code was previously verified |
| "Invalid verification code" | Code doesn't match |
| "Please wait X seconds before requesting a new code" | Rate limit protection |

## Customization

### Change Code Length
Edit `_generateVerificationCode()` in `email_verification_service.dart`:
```dart
// For 4-digit code:
return (1000 + random.nextInt(9000)).toString();

// For 8-digit code:
return (10000000 + random.nextInt(90000000)).toString();
```

### Change Expiration Time
Edit `createVerificationCode()`:
```dart
// For 30 minutes:
final expiresAt = DateTime.now().add(const Duration(minutes: 30));

// For 1 hour:
final expiresAt = DateTime.now().add(const Duration(hours: 1));
```

### Change Rate Limit
Edit `resendVerificationCode()`:
```dart
// For 2 minutes:
if (timeSinceCreation.inSeconds < 120) {
  // ...
}
```

## Next Steps

1. **Test the current system** - Make sure codes generate and verify correctly
2. **Set up email service** - Choose one of the options above
3. **Integrate email sending** - Update `sendVerificationEmail()` method
4. **Add production security** - Implement rate limiting and logging
5. **Monitor usage** - Track verification success rates

## Troubleshooting

### Code not appearing in console
- Check if Flutter app is running in debug mode
- Look for "VERIFICATION EMAIL" header in console output
- Check terminal/Run tab in VS Code

### Code not working
- Make sure you're entering all 6 digits
- Check if code has expired (15 minutes)
- Try requesting a new code
- Verify you're using the most recent code

### Can't resend code
- Wait 60 seconds between resend attempts
- Check Firestore to verify code document exists
- Ensure user is still logged in

### Firestore errors
- Verify Firestore rules allow read/write to verification_codes collection
- Check Firebase project is properly initialized
- Ensure internet connection is stable
