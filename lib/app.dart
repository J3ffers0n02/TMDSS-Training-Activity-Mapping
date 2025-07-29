import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tmdss/components/Map/pages/geocoding.dart';
import 'package:tmdss/components/admin/add_data.dart';
import 'package:tmdss/components/admin/crud.dart';
import 'package:tmdss/components/auth/data/supabase_auth_repo.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_cubit.dart';
import 'package:tmdss/components/auth/presentation/pages/login_page.dart';
import 'package:tmdss/components/auth/presentation/pages/register_page.dart';
import 'package:tmdss/components/pages/nav_pages/nav_page.dart';
import 'package:tmdss/components/pages/nav_pages/nav_page_push.dart';
import 'package:tmdss/components/pages/splash_screen.dart';
import 'package:tmdss/themes.dart/dark_mode.dart';

class MyApp extends StatelessWidget {
  final supabaseAuthRepo = SupabaseAuthRepo();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
            create: (context) =>
                AuthCubit(authRepo: supabaseAuthRepo) //..checkAuth(),
            ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkMode,
        title: 'DOST-FPRDI Tracker',
        home: SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
        },
      ),
    );
  }
}
