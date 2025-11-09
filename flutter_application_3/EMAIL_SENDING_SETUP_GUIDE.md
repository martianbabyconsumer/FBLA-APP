# Email Verification Setup Guide - Sending Real Emails

## Overview

Currently, verification codes are printed to the console. To send real emails, you need to integrate an email service. This guide covers multiple options from easiest to most customizable.

---

## Option 1: Firebase Extensions - Trigger Email (RECOMMENDED - Easiest)

### Step 1: Install the Extension

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **fbla-app-72e34**
3. Click **Extensions** in the left sidebar
4. Click **Install Extension**
5. Search for **"Trigger Email"** by Firebase
6. Click **Install**

### Step 2: Configure SMTP Settings

During installation, you'll need to provide:

**For Gmail (Free):**
```
SMTP Server: smtp.gmail.com
SMTP Port: 587
SMTP Username: your-email@gmail.com
SMTP Password: [App Password - see below]
```

**Getting Gmail App Password:**
1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Enable 2-Factor Authentication (required)
3. Go to Security → App Passwords
4. Generate an app password for "Mail"
5. Use this password in Firebase Extension

**For SendGrid (Recommended for Production):**
```
SMTP Server: smtp.sendgrid.net
SMTP Port: 587
SMTP Username: apikey
SMTP Password: [Your SendGrid API Key]
```

**Other Options:**
- AWS SES: smtp.amazonaws.com (port 587)
- Mailgun: smtp.mailgun.org (port 587)
- Outlook: smtp-mail.outlook.com (port 587)

### Step 3: Configure Firestore Collection

The extension watches a Firestore collection for new documents. Configure:

```
Email documents collection: mail
Default FROM address: noreply@fbla-app-72e34.firebaseapp.com
Default FROM name: FBLA HIVE
```

### Step 4: Update Your Code

Replace the `sendVerificationEmail` method in `lib/services/email_verification_service.dart`:

```dart
Future<bool> sendVerificationEmail(String email, String displayName, String code) async {
  try {
    // Add document to Firestore 'mail' collection
    await _firestore.collection('mail').add({
      'to': email,
      'message': {
        'subject': 'Verify your email for FBLA HIVE',
        'text': '''
Hello $displayName,

Your verification code is: $code

This code will expire in 15 minutes.

If you didn't ask to verify this address, you can ignore this email.

Thanks,
FBLA HIVE team
''',
        'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1976D2; color: white; padding: 20px; text-align: center; }
    .code-box { background-color: #f5f5f5; border: 2px dashed #1976D2; padding: 20px; text-align: center; margin: 20px 0; }
    .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1976D2; }
    .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>FBLA HIVE</h1>
    </div>
    <p>Hello $displayName,</p>
    <p>Your verification code is:</p>
    <div class="code-box">
      <div class="code">$code</div>
    </div>
    <p>This code will expire in 15 minutes.</p>
    <p>If you didn't ask to verify this address, you can safely ignore this email.</p>
    <div class="footer">
      <p>Thanks,<br>FBLA HIVE team</p>
      <p>This is an automated message, please do not reply to this email.</p>
    </div>
  </div>
</body>
</html>
''',
      },
    });
    
    print('Verification email queued for: $email');
    return true;
  } catch (e) {
    print('Error sending verification email: $e');
    return false;
  }
}
```

### Step 5: Test

1. Sign up with a real email address
2. Check your email inbox (and spam folder)
3. Enter the 6-digit code from the email

---

## Option 2: Cloud Functions with SendGrid

### Step 1: Install SendGrid

1. Sign up at [SendGrid](https://sendgrid.com/)
2. Get a free plan (100 emails/day)
3. Create an API Key in SendGrid dashboard

### Step 2: Create Cloud Function

Create `functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as sgMail from '@sendgrid/mail';

admin.initializeApp();
sgMail.setApiKey(functions.config().sendgrid.key);

export const sendVerificationEmail = functions.firestore
  .document('verification_codes/{userId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const email = data.email;
    const code = data.code;
    const displayName = 'User'; // You can get from users collection

    const msg = {
      to: email,
      from: 'noreply@fblahive.com', // Use your verified domain
      subject: 'Verify your email for FBLA HIVE',
      text: `Hello ${displayName},\n\nYour verification code is: ${code}\n\nThis code will expire in 15 minutes.\n\nIf you didn't ask to verify this address, you can ignore this email.\n\nThanks,\nFBLA HIVE team`,
      html: `
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial, sans-serif;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #1976D2;">FBLA HIVE</h1>
            <p>Hello ${displayName},</p>
            <p>Your verification code is:</p>
            <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
              <h2 style="color: #1976D2; letter-spacing: 8px;">${code}</h2>
            </div>
            <p>This code will expire in 15 minutes.</p>
            <p>If you didn't ask to verify this address, you can ignore this email.</p>
            <p>Thanks,<br>FBLA HIVE team</p>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log('Email sent to:', email);
    } catch (error) {
      console.error('Error sending email:', error);
    }
  });
```

### Step 3: Deploy

```bash
cd functions
npm install @sendgrid/mail
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
firebase deploy --only functions
```

### Step 4: Update Flutter Code

The Flutter code stays the same - emails are automatically sent when verification codes are created in Firestore.

---

## Option 3: Direct HTTP API Call (SendGrid)

### Step 1: Add HTTP Package

In `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

### Step 2: Update sendVerificationEmail

Replace in `lib/services/email_verification_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> sendVerificationEmail(String email, String displayName, String code) async {
  const sendgridApiKey = 'YOUR_SENDGRID_API_KEY_HERE'; // Store securely!
  
  final emailHtml = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1976D2; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: #ffffff; padding: 30px; }
    .code-box { background-color: #f5f5f5; border: 2px dashed #1976D2; padding: 20px; text-align: center; margin: 20px 0; border-radius: 5px; }
    .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1976D2; }
    .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; text-align: center; }
    .button { background-color: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin: 0;">FBLA HIVE</h1>
    </div>
    <div class="content">
      <h2>Hello $displayName,</h2>
      <p>Thank you for signing up! Please verify your email address to get started.</p>
      <p>Your verification code is:</p>
      <div class="code-box">
        <div class="code">$code</div>
      </div>
      <p><strong>This code will expire in 15 minutes.</strong></p>
      <p>If you didn't request this verification, you can safely ignore this email.</p>
    </div>
    <div class="footer">
      <p><strong>Thanks,</strong><br>FBLA HIVE Team</p>
      <p style="margin-top: 20px;">This is an automated message, please do not reply to this email.</p>
    </div>
  </div>
</body>
</html>
''';

  try {
    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $sendgridApiKey',
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
          'email': 'noreply@fblahive.com', // Use your verified domain
          'name': 'FBLA HIVE'
        },
        'content': [
          {
            'type': 'text/plain',
            'value': 'Hello $displayName,\n\nYour verification code is: $code\n\nThis code will expire in 15 minutes.\n\nIf you didn\'t ask to verify this address, you can ignore this email.\n\nThanks,\nFBLA HIVE team'
          },
          {
            'type': 'text/html',
            'value': emailHtml
          }
        ]
      }),
    );

    if (response.statusCode == 202) {
      print('Verification email sent to: $email');
      return true;
    } else {
      print('Failed to send email: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error sending verification email: $e');
    return false;
  }
}
```

**⚠️ Security Note:** Never hardcode API keys! Use environment variables or Firebase Remote Config.

---

## Customizing Email Templates

### Current Template Location

The email template is in `lib/services/email_verification_service.dart` in the `sendVerificationEmail` method.

### Template Variables Available

You can use these variables in your templates:
- `$email` - Recipient's email address
- `$displayName` - User's display name
- `$code` - 6-digit verification code

### Email Template Components

#### 1. Plain Text Version (for email clients that don't support HTML)

```dart
'text': '''
Hello $displayName,

Your verification code is: $code

This code will expire in 15 minutes.

If you didn't ask to verify this address, you can ignore this email.

Thanks,
FBLA HIVE team
''',
```

#### 2. HTML Version (styled email)

```dart
'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    /* Your CSS styles here */
  </style>
</head>
<body>
  <!-- Your HTML content here -->
</body>
</html>
''',
```

### Customization Examples

#### Example 1: Add Logo

```html
<div class="header">
  <img src="https://your-domain.com/logo.png" alt="FBLA HIVE" style="max-width: 150px;">
  <h1>FBLA HIVE</h1>
</div>
```

#### Example 2: Add Button Instead of Code

```html
<div style="text-align: center; margin: 20px 0;">
  <a href="https://your-app.com/verify?code=$code" 
     style="background-color: #1976D2; color: white; padding: 15px 30px; 
            text-decoration: none; border-radius: 5px; display: inline-block;">
    Verify Email
  </a>
</div>
<p style="text-align: center; color: #666; font-size: 12px;">
  Or enter this code: <strong>$code</strong>
</p>
```

#### Example 3: Add Social Media Links

```html
<div class="footer">
  <p>Follow us:</p>
  <a href="https://facebook.com/fblahive">Facebook</a> |
  <a href="https://twitter.com/fblahive">Twitter</a> |
  <a href="https://instagram.com/fblahive">Instagram</a>
</div>
```

#### Example 4: Different Colors/Branding

Change the primary color from blue (#1976D2) to your brand color:

```css
.header { background-color: #YOUR_COLOR; }
.code { color: #YOUR_COLOR; }
.code-box { border-color: #YOUR_COLOR; }
.button { background-color: #YOUR_COLOR; }
```

---

## Testing Email Delivery

### 1. Test with MailTrap (Free Testing Service)

MailTrap catches all emails for testing without sending to real inboxes:

1. Sign up at [Mailtrap.io](https://mailtrap.io/)
2. Get SMTP credentials from your inbox
3. Use these credentials in development:

```
SMTP Server: smtp.mailtrap.io
SMTP Port: 587
SMTP Username: [from Mailtrap]
SMTP Password: [from Mailtrap]
```

### 2. Test with Real Email

1. Use your personal email
2. Check spam folder first
3. Test with multiple providers:
   - Gmail
   - Outlook
   - Yahoo
   - ProtonMail

### 3. Check Email Deliverability

Use these tools to test your email HTML:
- [Litmus](https://litmus.com/) - Email preview across clients
- [Mail Tester](https://www.mail-tester.com/) - Check spam score
- [HTML Email Check](https://www.htmlemailcheck.com/) - Validate HTML

---

## Email Best Practices

### ✅ Do's

1. **Keep it simple** - Avoid complex layouts
2. **Use tables** - Better email client support than divs
3. **Inline CSS** - Most email clients strip `<style>` tags
4. **Include plain text** - Always provide a text alternative
5. **Test thoroughly** - Check on mobile and desktop
6. **Add unsubscribe** - Required for marketing emails (not verification)
7. **Use alt text** - For images, in case they don't load

### ❌ Don'ts

1. **Don't use JavaScript** - Email clients block it
2. **Don't use external CSS** - Won't load in most clients
3. **Don't use background images** - Limited support
4. **Don't use @font-face** - Use web-safe fonts
5. **Don't embed videos** - Link to video instead
6. **Don't use forms** - Won't work in emails

### Recommended Email Width

```css
.container {
  max-width: 600px; /* Standard email width */
  margin: 0 auto;
}
```

### Web-Safe Fonts

```css
font-family: Arial, Helvetica, sans-serif;
/* OR */
font-family: 'Times New Roman', Times, serif;
/* OR */
font-family: 'Courier New', Courier, monospace;
```

---

## Troubleshooting

### Emails Going to Spam

**Solutions:**
1. Verify your domain with email service
2. Set up SPF, DKIM, and DMARC records
3. Avoid spam trigger words (FREE, URGENT, etc.)
4. Include unsubscribe link
5. Don't use URL shorteners
6. Maintain good sender reputation

### Emails Not Sending

**Check:**
1. API key is correct and active
2. Firestore rules allow writes to mail collection
3. Email service has remaining quota
4. Console for error messages
5. Sender email is verified
6. Recipient email is valid format

### Code Not Appearing

**Check:**
1. Variable interpolation is correct (`$code` not `{code}`)
2. HTML encoding isn't breaking the code
3. Email client isn't hiding content
4. Code is actually being generated (check Firestore)

### HTML Not Rendering

**Solutions:**
1. Use inline CSS instead of `<style>` tags
2. Use tables for layout
3. Test with email HTML validators
4. Check email client compatibility

---

## Production Checklist

Before going live:

- [ ] Set up proper email service (SendGrid/AWS SES)
- [ ] Verify sender domain
- [ ] Configure SPF, DKIM, DMARC records
- [ ] Test on multiple email clients
- [ ] Test on mobile devices
- [ ] Set up email analytics/tracking
- [ ] Add error logging
- [ ] Set up rate limiting
- [ ] Monitor deliverability rates
- [ ] Have support contact in footer
- [ ] Comply with CAN-SPAM/GDPR

---

## Cost Comparison

| Service | Free Tier | Paid Plans |
|---------|-----------|------------|
| SendGrid | 100/day | $19.95/mo for 50k |
| AWS SES | 62k/mo (if on EC2) | $0.10 per 1000 |
| Mailgun | 5k/mo (3 months) | $35/mo for 50k |
| Gmail SMTP | Limited | Not for production |
| Firebase Extension | Depends on SMTP | - |

## Support

If you need help:
1. Check Firebase Extension logs in Firebase Console
2. Review Cloud Functions logs
3. Check SendGrid dashboard for delivery stats
4. Test with MailTrap first
5. Verify Firestore security rules allow writing to mail collection

---

**Current Status:** Verification codes print to console only.
**Recommended Next Step:** Install Firebase "Trigger Email" extension for quick setup.
