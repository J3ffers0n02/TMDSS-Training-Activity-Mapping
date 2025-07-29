/*

Auth repository - outlines the possible auth operations for this app.

*/

import 'package:tmdss/components/auth/domain/entities/app_user.dart';

abstract class AuthRepo {
  //login
  Future<AppUser?> loginWithEmailPassword(String email, String password);

  //registration
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String contactNum,
    String password,
  );

  //logout
  Future<void> logout();

  //get current user
  Future<AppUser?> getCurrentUser();

  //reset password
  Future<void> resetPassword(String email);
}
