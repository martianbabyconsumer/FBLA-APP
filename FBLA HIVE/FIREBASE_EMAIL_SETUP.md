# Firebase Email Verification Setup Guide

If you're not receiving verification emails, you need to configure Firebase properly. Follow these steps:

## Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **fbla-app-72e34**
3. Navigate to **Authentication** → **Sign-in method**
4. Make sure **Email/Password** is enabled
5. Click on **Email/Password** provider
6. Enable **Email link (passwordless sign-in)** if available

## Step 2: Configure Email Templates

1. In Firebase Console, go to **Authentication** → **Templates**
2. Select **Email address verification**
3. Customize the email template (optional):
   - Edit the subject line
   - Edit the email body
   - Customize the sender name (may require domain verification)

## Step 3: Check Email Settings

1. Go to **Project Settings** (gear icon)
2. Navigate to **Email** tab
3. Verify the sender email is configured
4. Default is: `noreply@<your-project>.firebaseapp.com`

## Step 4: Authorized Domains

1. In **Authentication** → **Settings**
2. Check **Authorized domains**
3. Make sure your domain is listed:
   - `fbla-app-72e34.firebaseapp.com` (should be there by default)
   - Add `localhost` for development if testing locally

## Step 5: Test Email Delivery

After configuration:

1. Sign up with a new test email
2. Check your inbox (may take 1-5 minutes)
3. **Check spam/junk folder** - Firebase emails often land there initially
4. Add `noreply@fbla-app-72e34.firebaseapp.com` to your contacts to prevent future spam filtering

## Common Issues

### Emails going to spam
- Add sender to contacts/whitelist
- Check with different email providers (Gmail, Outlook, etc.)
- Some educational/corporate emails block automated emails

### Emails not sending at all
- Verify Firebase Authentication is enabled
- Check Firebase project quota (free tier has limits)
- Ensure no Firebase errors in console logs

### Rate limiting
- Firebase limits verification emails to prevent abuse
- Wait a few minutes between resend attempts
- Check Firebase usage quota in console

## Development Tips

- Use **real email addresses** for testing (temporary email services may be blocked)
- Check **browser console** for error messages
- Review **Firebase Console logs** under Analytics → Events
- Test with multiple email providers to ensure compatibility

## Support

If issues persist:
1. Check Firebase Status: https://status.firebase.google.com/
2. Review Firebase Auth documentation: https://firebase.google.com/docs/auth
3. Check project quotas in Firebase Console
4. Verify billing is set up if on Blaze plan (free tier works for basic email)
