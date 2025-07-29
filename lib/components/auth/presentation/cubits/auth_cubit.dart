import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tmdss/components/auth/domain/entities/app_user.dart';
import 'package:tmdss/components/auth/domain/repos/auth_repo.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthStates> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial()) ;

   void checkAuth() async {
    emit(AuthLoading());
    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        _currentUser = null;
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login(String email, String pw) async {
    emit(AuthLoading());
    try {
      final user = await authRepo.loginWithEmailPassword(email, pw);
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(AuthError("Invalid email or password. Please try again."));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> register(
    String name,
    String email,
    String contactNum,
    String password,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepo.registerWithEmailPassword(
        name,
        email,
        contactNum,
        password,
      );
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        _currentUser = null;
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await authRepo.logout();
      _currentUser = null;
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await authRepo.resetPassword(email);
      emit(AuthPasswordResetSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  AppUser? get currentUser => _currentUser;
}