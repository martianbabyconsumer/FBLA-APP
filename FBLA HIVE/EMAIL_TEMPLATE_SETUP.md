# How to Customize Firebase Verification Email Template

Firebase email templates can only be customized through the Firebase Console, not in code. Follow these steps to set up your custom email:

## Step-by-Step Instructions

### 1. Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **fbla-app-72e34**

### 2. Navigate to Email Templates
1. Click on **Authentication** in the left sidebar
2. Click on the **Templates** tab at the top
3. Find and click on **Email address verification**

### 3. Customize the Template

Click **Edit** (pencil icon) and use the following template:

#### **Email Subject:**
```
Verify your email for FBLA HIVE
```

#### **Email Body:**
```
Hello %DISPLAY_NAME%,

Follow this link to verify your email address.
%LINK%

If you didn't ask to verify this address, you can ignore this email.

Thanks,
FBLA HIVE team
```

**Note:** 
- `%DISPLAY_NAME%` will be automatically replaced with the user's display name
- `%LINK%` will be automatically replaced with the verification link
- Firebase uses these placeholders - keep them exactly as shown

### 4. Customize Sender Name (Optional)

1. In the same template editor, look for **Sender name**
2. Change from `noreply` to: `FBLA HIVE`
3. The email will appear as from: "FBLA HIVE <noreply@fbla-app-72e34.firebaseapp.com>"

**Note:** To use a custom email address (like team@fblahive.com), you need:
- A custom domain
- Domain verification in Firebase
- This requires the Blaze (pay-as-you-go) plan

### 5. Save Your Changes

1. Click **Save** at the bottom of the template editor
2. The changes will take effect immediately for all new verification emails

### 6. Test the New Template

1. Sign up with a new test email in your app
2. Check your inbox for the verification email
3. Verify it matches your custom template

## Available Template Variables

Firebase provides these variables you can use in your email template:

| Variable | Description | Example |
|----------|-------------|---------|
| `%DISPLAY_NAME%` | User's display name | "John Doe" |
| `%EMAIL%` | User's email address | "john@example.com" |
| `%LINK%` | Verification action link | [Verify Email Button] |
| `%APP_NAME%` | Your app name from Firebase settings | "FBLA App" |

## Recommended Template (Full Version)

If you want a more detailed email, use this:

```
Hello %DISPLAY_NAME%,

Thank you for signing up for FBLA HIVE!

Follow this link to verify your email address:
%LINK%

This link will expire in 24 hours.

If you didn't create an account with FBLA HIVE, you can safely ignore this email.

Thanks,
FBLA HIVE Team

---
This is an automated message, please do not reply to this email.
```

## Troubleshooting

### Template not updating?
- Clear your browser cache
- Wait 5-10 minutes for changes to propagate
- Try signing up with a completely new email

### Variables not working?
- Make sure you use the exact variable names with % symbols
- Don't add spaces inside the variable names
- Variables are case-sensitive

### Can't edit template?
- Ensure you have Owner or Editor role in Firebase
- Check that Email/Password authentication is enabled
- Try a different browser if the editor doesn't load

## Current Template Text to Use

Copy and paste this exactly into Firebase Console:

**Subject:**
```
Verify your email for FBLA HIVE
```

**Body:**
```
Hello %DISPLAY_NAME%,

Follow this link to verify your email address.
%LINK%

If you didn't ask to verify this address, you can ignore this email.

Thanks,
FBLA HIVE team
```

## Additional Customization Options

Once in the Firebase Console template editor, you can also customize:

1. **Action URL** - Where users go after clicking the link
2. **Reply-to address** - If on Blaze plan with verified domain
3. **Email language** - For internationalization
4. **HTML styling** - Advanced: Use custom HTML/CSS

---

**Important:** Remember to click **Save** after making any changes!
