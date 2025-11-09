import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Store verification code in Firestore
  Future<String> createVerificationCode(String userId, String email) async {
    final code = _generateVerificationCode();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    await _firestore.collection('verification_codes').doc(userId).set({
      'code': code,
      'email': email,
      'expiresAt': expiresAt,
      'verified': false,
      'createdAt': DateTime.now(),
    });

    return code;
  }

  // Verify the code
  Future<Map<String, dynamic>> verifyCode(String userId, String code) async {
    try {
      final doc = await _firestore.collection('verification_codes').doc(userId).get();

      if (!doc.exists) {
        return {'success': false, 'message': 'No verification code found. Please request a new one.'};
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final verified = data['verified'] as bool;

      if (verified) {
        return {'success': false, 'message': 'This code has already been used.'};
      }

      if (DateTime.now().isAfter(expiresAt)) {
        return {'success': false, 'message': 'This code has expired. Please request a new one.'};
      }

      if (code.trim() != storedCode) {
        return {'success': false, 'message': 'Invalid verification code. Please try again.'};
      }

      // Mark as verified
      await _firestore.collection('verification_codes').doc(userId).update({
        'verified': true,
        'verifiedAt': DateTime.now(),
      });

      // Update user's email verification status in a custom field
      await _firestore.collection('users').doc(userId).set({
        'emailVerified': true,
        'verifiedAt': DateTime.now(),
      }, SetOptions(merge: true));

      return {'success': true, 'message': 'Email verified successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Check if user is verified
  Future<bool> isUserVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      return doc.data()?['emailVerified'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Send email with verification code (mock - you'll need to integrate with an email service)
  Future<bool> sendVerificationEmail(String email, String displayName, String code) async {
    // In a real app, you would integrate with:
    // - SendGrid
    // - Firebase Extensions (Trigger Email)
    // - Cloud Functions to send emails
    
    print('==============================================');
    print('VERIFICATION EMAIL');
    print('==============================================');
    print('To: $email');
    print('Subject: Verify your email for FBLA HIVE');
    print('');
    print('Hello $displayName,');
    print('');
    print('Your verification code is: $code');
    print('');
    print('This code will expire in 15 minutes.');
    print('');
    print('If you didn\'t ask to verify this address, you can ignore this email.');
    print('');
    print('Thanks,');
    print('FBLA HIVE team');
    print('==============================================');

    // For now, return true to simulate successful sending
    // TODO: Integrate with real email service
    return true;
  }

  // Resend verification code
  Future<String> resendVerificationCode(String userId, String email, String displayName) async {
    // Check if there's a recent code (prevent spam)
    final doc = await _firestore.collection('verification_codes').doc(userId).get();
    
    if (doc.exists) {
      final data = doc.data()!;
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final timeSinceCreation = DateTime.now().difference(createdAt);
      
      if (timeSinceCreation.inSeconds < 60) {
        throw Exception('Please wait ${60 - timeSinceCreation.inSeconds} seconds before requesting a new code.');
      }
    }

    final code = await createVerificationCode(userId, email);
    await sendVerificationEmail(email, displayName, code);
    return code;
  }
}
