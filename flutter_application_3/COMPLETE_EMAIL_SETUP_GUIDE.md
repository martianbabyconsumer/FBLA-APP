# Complete Email Verification Setup - Step by Step Guide

## Table of Contents
1. [Quick Overview](#quick-overview)
2. [Method 1: Firebase Extension (Easiest - 15 Minutes)](#method-1-firebase-extension-easiest)
3. [Method 2: SendGrid Direct Integration (30 Minutes)](#method-2-sendgrid-direct-integration)
4. [Method 3: Cloud Functions (Advanced - 45 Minutes)](#method-3-cloud-functions-advanced)
5. [Customizing Email Templates](#customizing-email-templates)
6. [Testing Your Setup](#testing-your-setup)
7. [Troubleshooting](#troubleshooting)

---

## Quick Overview

**Current Status:**
- ✅ 6-digit verification codes are generated
- ✅ Codes stored in Firestore
- ✅ Verification UI works perfectly
- ❌ Codes only print to console (no real emails)

**What You'll Achieve:**
- ✅ Real emails sent to users
- ✅ Custom email design with your branding
- ✅ Professional HTML emails
- ✅ Automatic email delivery

**Choose Your Method:**
- **Firebase Extension** - Easiest, no code changes, uses SMTP
- **SendGrid Direct** - Moderate, requires API key, direct control
- **Cloud Functions** - Advanced, most flexible, server-side

---

## Method 1: Firebase Extension (EASIEST)

### Time Required: ~15 minutes
### Cost: Free (100 emails/day with Gmail, 100/day with SendGrid free tier)
### Difficulty: ⭐ Beginner Friendly

---

### Step 1: Sign Up for SendGrid (Recommended) or Use Gmail

#### Option A: SendGrid (Recommended for Production)

1. Go to https://sendgrid.com/
2. Click **"Start for Free"**
3. Fill in your information:
   - Email address
   - Password
   - Company name (can be "FBLA HIVE" or your school name)
4. Verify your email address
5. Complete the setup survey (select "Education" or "Non-profit")

**Get Your API Key:**
1. In SendGrid dashboard, click **Settings** → **API Keys**
2. Click **"Create API Key"**
3. Name it: `FBLA_HIVE_FIREBASE`
4. Select **"Restricted Access"**
5. Toggle on: **Mail Send** → **Mail Send** (FULL ACCESS)
6. Click **"Create & View"**
7. **IMPORTANT:** Copy the API key immediately! You won't see it again.
   - Format: `SG.xxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

#### Option B: Gmail SMTP (Quick Testing Only)

1. Go to your Google Account: https://myaccount.google.com/
2. Click **Security** (left sidebar)
3. Enable **2-Step Verification** (required for app passwords)
4. After enabling 2FA, go back to **Security**
5. Search for "App passwords" or scroll to find it
6. Click **App passwords**
7. Select:
   - App: **Mail**
   - Device: **Other (custom name)** → Type "FBLA HIVE"
8. Click **Generate**
9. **Copy the 16-character password** (format: `xxxx xxxx xxxx xxxx`)

---

### Step 2: Install Firebase Extension

1. **Open Firebase Console:**
   - Go to https://console.firebase.google.com/
   - Select your project: **fbla-app-72e34**

2. **Navigate to Extensions:**
   - Click **Build** in left sidebar
   - Click **Extensions**
   - Or go directly: https://console.firebase.google.com/project/fbla-app-72e34/extensions

3. **Find the Email Extension:**
   - Click **"Install Extension"** (top right)
   - Search for: **"Trigger Email"**
   - Look for the official Firebase extension (has Firebase logo)
   - Click **"Install"**

4. **Review Billing:**
   - Extension requires Blaze plan (pay-as-you-go)
   - Don't worry! Free tier is generous:
     - 50,000 document reads/day
     - 20,000 document writes/day
   - Click **"Upgrade project to continue"** if needed
   - You won't be charged unless you exceed free limits

5. **Grant Permissions:**
   - Click **"Next"** to review APIs and resources
   - The extension needs to access Cloud Firestore
   - Click **"Next"**

---

### Step 3: Configure the Extension

Now you'll configure the extension settings:

#### Basic Settings:

**1. Cloud Firestore path for email documents:**
```
mail
```
(This is the collection where emails will be added)

**2. Email documents collection:**
```
mail
```

**3. SMTP connection URI:**

**For SendGrid:**
```
smtps://apikey:YOUR_SENDGRID_API_KEY@smtp.sendgrid.net:465
```
Replace `YOUR_SENDGRID_API_KEY` with your actual SendGrid API key from Step 1.

Example:
```
smtps://apikey:SG.abc123xyz.789def456ghi@smtp.sendgrid.net:465
```

**For Gmail:**
```
smtps://your-email@gmail.com:YOUR_APP_PASSWORD@smtp.gmail.com:465
```
Replace with your Gmail and app password (remove spaces from the 16-char password).

Example:
```
smtps://john@gmail.com:abcdabcdabcdabcd@smtp.gmail.com:465
```

**4. Email from address (FROM):**
```
noreply@fbla-app-72e34.firebaseapp.com
```

**5. Email from name (optional):**
```
FBLA HIVE
```

**6. Users collection (optional):**
```
users
```

**7. Templates collection (optional):**
Leave empty for now

Click **"Install extension"**

⏳ Installation takes 3-5 minutes. You'll see a progress indicator.

---

### Step 4: Update Your Flutter Code

Now we need to modify the code to send emails through Firestore instead of just printing to console.

#### Open this file:
`lib/services/email_verification_service.dart`

#### Find the `sendVerificationEmail` method (around line 85)

**Replace the entire method with this:**

```dart
Future<bool> sendVerificationEmail(String email, String displayName, String code) async {
  try {
    // Create the email HTML template
    final emailHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: Arial, Helvetica, sans-serif;
      background-color: #f4f4f4;
    }
    .email-container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
    }
    .header {
      background: linear-gradient(135deg, #1976D2 0%, #1565C0 100%);
      padding: 30px 20px;
      text-align: center;
    }
    .header h1 {
      color: #ffffff;
      margin: 0;
      font-size: 28px;
      font-weight: 700;
      letter-spacing: 1px;
    }
    .content {
      padding: 40px 30px;
    }
    .greeting {
      font-size: 18px;
      color: #333333;
      margin-bottom: 20px;
    }
    .message {
      font-size: 16px;
      color: #555555;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .code-container {
      background: linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%);
      border: 3px dashed #1976D2;
      border-radius: 12px;
      padding: 30px;
      text-align: center;
      margin: 30px 0;
    }
    .code-label {
      font-size: 14px;
      color: #1976D2;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 10px;
    }
    .code {
      font-size: 42px;
      font-weight: 800;
      color: #1976D2;
      letter-spacing: 10px;
      font-family: 'Courier New', Courier, monospace;
      margin: 10px 0;
    }
    .expiry {
      font-size: 13px;
      color: #E65100;
      font-weight: 600;
      margin-top: 15px;
    }
    .warning {
      background-color: #FFF3E0;
      border-left: 4px solid #FF9800;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .warning p {
      margin: 0;
      font-size: 14px;
      color: #E65100;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 25px 30px;
      text-align: center;
      border-top: 1px solid #e0e0e0;
    }
    .footer p {
      margin: 5px 0;
      font-size: 13px;
      color: #666666;
    }
    .footer-team {
      font-weight: 600;
      color: #1976D2;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="header">
      <h1>🐝 FBLA HIVE</h1>
    </div>
    
    <div class="content">
      <p class="greeting"><strong>Hello $displayName,</strong></p>
      
      <p class="message">
        Thank you for signing up! To complete your registration and verify your email address, 
        please use the verification code below.
      </p>
      
      <div class="code-container">
        <div class="code-label">Your Verification Code</div>
        <div class="code">$code</div>
        <div class="expiry">⏰ Expires in 15 minutes</div>
      </div>
      
      <div class="warning">
        <p>
          <strong>⚠️ Security Notice:</strong> If you didn't request this code, 
          you can safely ignore this email. Your account is secure.
        </p>
      </div>
      
      <p class="message" style="margin-top: 30px; font-size: 14px; color: #666;">
        Enter this code in the FBLA HIVE app to verify your email and get started!
      </p>
    </div>
    
    <div class="footer">
      <p class="footer-team">Thanks,<br>The FBLA HIVE Team</p>
      <p style="margin-top: 15px;">This is an automated message, please do not reply.</p>
      <p style="color: #999; font-size: 12px; margin-top: 10px;">
        © 2025 FBLA HIVE. All rights reserved.
      </p>
    </div>
  </div>
</body>
</html>
''';

    // Plain text version for email clients that don't support HTML
    final emailText = '''
Hello $displayName,

Follow this link to verify your email address.

Your verification code is: $code

This code will expire in 15 minutes.

If you didn't ask to verify this address, you can ignore this email.

Thanks,
FBLA HIVE team
''';

    // Add document to Firestore 'mail' collection
    // The Firebase Extension will automatically send the email
    await _firestore.collection('mail').add({
      'to': email,
      'message': {
        'subject': 'Verify your email for FBLA HIVE',
        'text': emailText,
        'html': emailHtml,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Verification email queued for: $email');
    print('📧 Code: $code (also sent to email)');
    return true;
  } catch (e) {
    print('❌ Error queueing verification email: $e');
    return false;
  }
}
```

**Add this import at the top of the file:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

The complete imports section should look like:
```dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
```

---

### Step 5: Test Your Setup

1. **Rebuild your app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Create a test account:**
   - Open the app
   - Click "Sign Up"
   - Use a **real email address** you have access to
   - Fill in all fields
   - Click "Sign Up"

3. **Check for the email:**
   - Check your inbox (the email should arrive in 5-30 seconds)
   - **Check spam/junk folder** if not in inbox
   - You should see a beautiful HTML email with your 6-digit code

4. **Enter the code:**
   - Copy the 6-digit code from the email
   - Paste it in the verification dialog
   - Click "Verify"

5. **Check Firebase Console:**
   - Go to Firebase Console → Firestore Database
   - Look for the `mail` collection
   - You should see documents with delivery status

---

### Step 6: Monitor Email Delivery

**Check Extension Logs:**
1. Go to Firebase Console
2. Click **Extensions** in the sidebar
3. Click on **"Trigger Email"** extension
4. Click **"View in Cloud Functions"**
5. Look at the logs to see:
   - Email processing
   - Delivery status
   - Any errors

**Check Firestore for Status:**
1. Go to Firestore Database
2. Open `mail` collection
3. Click on a document
4. Look for these fields:
   - `delivery.state`: Should say "SUCCESS"
   - `delivery.endTime`: When it was sent
   - `delivery.error`: Will show any errors

---

## Method 2: SendGrid Direct Integration

### Time Required: ~30 minutes
### Cost: Free (100 emails/day)
### Difficulty: ⭐⭐ Intermediate

This method sends emails directly from your Flutter app using SendGrid's API.

---

### Step 1: Get SendGrid API Key

(Same as Method 1, Step 1, Option A)

---

### Step 2: Add HTTP Package

**Open `pubspec.yaml`** and add the http package:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  shared_preferences: ^2.2.2
  provider: ^6.1.1
  image_picker: ^1.0.7
  http: ^1.2.0  # Add this line
```

**Save the file and run:**
```bash
flutter pub get
```

---

### Step 3: Create Configuration File

**Create a new file:** `lib/config/email_config.dart`

```dart
class EmailConfig {
  // ⚠️ SECURITY WARNING: Never commit API keys to Git!
  // In production, use environment variables or Firebase Remote Config
  static const String sendgridApiKey = 'YOUR_SENDGRID_API_KEY_HERE';
  static const String fromEmail = 'noreply@fblahive.com';
  static const String fromName = 'FBLA HIVE';
}
```

**Replace `YOUR_SENDGRID_API_KEY_HERE` with your actual SendGrid API key from Step 1.**

---

### Step 4: Update Email Verification Service

**Open:** `lib/services/email_verification_service.dart`

**Add these imports at the top:**
```dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/email_config.dart';
```

**Replace the `sendVerificationEmail` method:**

```dart
Future<bool> sendVerificationEmail(String email, String displayName, String code) async {
  final emailHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: Arial, Helvetica, sans-serif;
      background-color: #f4f4f4;
    }
    .email-container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
    }
    .header {
      background: linear-gradient(135deg, #1976D2 0%, #1565C0 100%);
      padding: 30px 20px;
      text-align: center;
    }
    .header h1 {
      color: #ffffff;
      margin: 0;
      font-size: 28px;
      font-weight: 700;
      letter-spacing: 1px;
    }
    .content {
      padding: 40px 30px;
    }
    .greeting {
      font-size: 18px;
      color: #333333;
      margin-bottom: 20px;
    }
    .message {
      font-size: 16px;
      color: #555555;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .code-container {
      background: linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%);
      border: 3px dashed #1976D2;
      border-radius: 12px;
      padding: 30px;
      text-align: center;
      margin: 30px 0;
    }
    .code-label {
      font-size: 14px;
      color: #1976D2;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 10px;
    }
    .code {
      font-size: 42px;
      font-weight: 800;
      color: #1976D2;
      letter-spacing: 10px;
      font-family: 'Courier New', Courier, monospace;
      margin: 10px 0;
    }
    .expiry {
      font-size: 13px;
      color: #E65100;
      font-weight: 600;
      margin-top: 15px;
    }
    .warning {
      background-color: #FFF3E0;
      border-left: 4px solid #FF9800;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .warning p {
      margin: 0;
      font-size: 14px;
      color: #E65100;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 25px 30px;
      text-align: center;
      border-top: 1px solid #e0e0e0;
    }
    .footer p {
      margin: 5px 0;
      font-size: 13px;
      color: #666666;
    }
    .footer-team {
      font-weight: 600;
      color: #1976D2;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="header">
      <h1>🐝 FBLA HIVE</h1>
    </div>
    
    <div class="content">
      <p class="greeting"><strong>Hello $displayName,</strong></p>
      
      <p class="message">
        Thank you for signing up! To complete your registration and verify your email address, 
        please use the verification code below.
      </p>
      
      <div class="code-container">
        <div class="code-label">Your Verification Code</div>
        <div class="code">$code</div>
        <div class="expiry">⏰ Expires in 15 minutes</div>
      </div>
      
      <div class="warning">
        <p>
          <strong>⚠️ Security Notice:</strong> If you didn't request this code, 
          you can safely ignore this email. Your account is secure.
        </p>
      </div>
      
      <p class="message" style="margin-top: 30px; font-size: 14px; color: #666;">
        Enter this code in the FBLA HIVE app to verify your email and get started!
      </p>
    </div>
    
    <div class="footer">
      <p class="footer-team">Thanks,<br>The FBLA HIVE Team</p>
      <p style="margin-top: 15px;">This is an automated message, please do not reply.</p>
      <p style="color: #999; font-size: 12px; margin-top: 10px;">
        © 2025 FBLA HIVE. All rights reserved.
      </p>
    </div>
  </div>
</body>
</html>
''';

  try {
    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer ${EmailConfig.sendgridApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [
              {'email': email}
            ],
            'subject': 'Verify your email for FBLA HIVE',
          }
        ],
        'from': {
          'email': EmailConfig.fromEmail,
          'name': EmailConfig.fromName,
        },
        'content': [
          {
            'type': 'text/plain',
            'value': 'Hello $displayName,\\n\\nYour verification code is: $code\\n\\nThis code will expire in 15 minutes.\\n\\nIf you didn\\'t ask to verify this address, you can ignore this email.\\n\\nThanks,\\nFBLA HIVE team'
          },
          {
            'type': 'text/html',
            'value': emailHtml
          }
        ]
      }),
    );

    if (response.statusCode == 202) {
      print('✅ Verification email sent to: $email');
      print('📧 Code: $code');
      return true;
    } else {
      print('❌ Failed to send email: ${response.statusCode}');
      print('Response: ${response.body}');
      return false;
    }
  } catch (e) {
    print('❌ Error sending verification email: $e');
    return false;
  }
}
```

---

### Step 5: Test Direct Integration

1. **Rebuild app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Sign up with a real email**

3. **Check SendGrid Dashboard:**
   - Go to https://app.sendgrid.com/
   - Click **Activity** in the left sidebar
   - You should see your email in the list
   - Status should be "Delivered"

---

## Customizing Email Templates

### Change Colors

**Find these lines in the HTML template and replace colors:**

```css
/* Primary color (blue) */
background: linear-gradient(135deg, #1976D2 0%, #1565C0 100%);
color: #1976D2;
border: 3px dashed #1976D2;

/* Change to your color, e.g., green */
background: linear-gradient(135deg, #4CAF50 0%, #388E3C 100%);
color: #4CAF50;
border: 3px dashed #4CAF50;
```

### Add Your Logo

**Replace the header h1 with an image:**

```html
<div class="header">
  <img src="https://yourdomain.com/logo.png" alt="FBLA HIVE" style="max-width: 200px;">
  <h1 style="margin-top: 10px;">FBLA HIVE</h1>
</div>
```

### Change Font

```css
body {
  font-family: 'Georgia', 'Times New Roman', serif; /* Elegant */
}

/* OR */

body {
  font-family: 'Verdana', 'Tahoma', sans-serif; /* Modern */
}
```

### Make Code Larger/Smaller

```css
.code {
  font-size: 48px; /* Larger */
  /* OR */
  font-size: 36px; /* Smaller */
}
```

---

## Testing Your Setup

### 1. Test with Multiple Email Providers

Try signing up with:
- ✅ Gmail
- ✅ Outlook/Hotmail
- ✅ Yahoo Mail
- ✅ ProtonMail
- ✅ School email

### 2. Check Spam Folders

Most common issue! Always check spam folder first.

### 3. Use MailTrap for Safe Testing

1. Sign up at https://mailtrap.io/ (free)
2. Get SMTP credentials
3. Use them in development instead of real email
4. All emails caught in MailTrap inbox (won't send to real users)

---

## Troubleshooting

### Emails Not Arriving

**Check:**
1. ✅ Is SendGrid API key correct?
2. ✅ Is API key activated in SendGrid dashboard?
3. ✅ Check spam folder
4. ✅ Wait 5 minutes (sometimes delayed)
5. ✅ Check SendGrid Activity dashboard
6. ✅ Check Firebase Extension logs

### Extension Not Installed

**Error:** "Collection 'mail' not triggering emails"

**Solution:**
1. Go to Firebase Console → Extensions
2. Make sure "Trigger Email" shows as "Installed"
3. Check extension configuration
4. Reinstall if needed

### API Key Invalid

**Error:** "Unauthorized" or "403 Forbidden"

**Solution:**
1. Generate new API key in SendGrid
2. Make sure it has "Mail Send" permissions
3. Update EmailConfig or extension settings
4. Rebuild app

### Emails Going to Spam

**Solutions:**
1. Verify sender domain in SendGrid
2. Set up SPF, DKIM records (ask IT department)
3. Don't use URL shorteners
4. Don't use ALL CAPS
5. Add "unsubscribe" link (for marketing emails)

---

## Production Checklist

Before launching to real users:

- [ ] Use SendGrid (not Gmail SMTP)
- [ ] Verify sender domain
- [ ] Test on multiple email providers
- [ ] Check spam score with mail-tester.com
- [ ] Add company logo to email
- [ ] Customize colors to match brand
- [ ] Test on mobile email clients
- [ ] Set up error monitoring
- [ ] Add analytics tracking (optional)
- [ ] Store API keys securely (not in code)
- [ ] Set up rate limiting
- [ ] Add email unsubscribe for marketing (if applicable)

---

## Security Best Practices

### ⚠️ NEVER Commit API Keys to Git

**Bad:**
```dart
static const String sendgridApiKey = 'SG.abc123...'; // ❌ DON'T DO THIS
```

**Good Options:**

**Option 1: Environment Variables**
```dart
static String get sendgridApiKey => 
  const String.fromEnvironment('SENDGRID_KEY');
```

Run with:
```bash
flutter run --dart-define=SENDGRID_KEY=your_key_here
```

**Option 2: Firebase Remote Config**
```dart
final remoteConfig = FirebaseRemoteConfig.instance;
final apiKey = remoteConfig.getString('sendgrid_api_key');
```

**Option 3: .env file (with flutter_dotenv)**
```
SENDGRID_API_KEY=your_key_here
```

Add `.env` to `.gitignore`!

---

## Summary

**You've learned to:**
✅ Set up Firebase Extension for email sending
✅ Integrate SendGrid API directly
✅ Customize email templates with HTML/CSS
✅ Test email delivery
✅ Troubleshoot common issues
✅ Prepare for production

**Next Steps:**
1. Choose your method (Firebase Extension recommended)
2. Follow the step-by-step instructions
3. Test with your email
4. Customize the template
5. Deploy to production

**Need Help?**
- Firebase Extension docs: https://extensions.dev/extensions/firebase/firestore-send-email
- SendGrid API docs: https://docs.sendgrid.com/
- Check Firebase Console logs
- Test with MailTrap first

Good luck! 🚀
