import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tmdss/components/auth/data/auth_service.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_cubit.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_states.dart';
import 'package:tmdss/helpers/helper_function.dart';
import 'package:tmdss/helpers/my_button.dart';
import 'package:tmdss/helpers/my_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //get auth services
  final authService = AuthService();

  //text editing controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //login method
  void login() async {
    //prepare data
    final String email = emailController.text.trim();
    final String pw = passwordController.text.trim();

    final authCubit = context.read<AuthCubit>();

    if (email.isNotEmpty && pw.isNotEmpty) {
      //login!
      await authCubit.login(email, pw);
      if (authCubit.state is Authenticated) {
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } else {
      displayMessageToUser("Please enter both email and password", context);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //the pic
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/FPRDI.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          //Pang opaque
          Container(
            color: Colors.black.withOpacity(0),
          ),
          //container for the fields and button
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/FPRDILOGO.png',
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    //email textfield
                    MyTextfield(
                      hintText: "Email",
                      obscureText: false,
                      controller: emailController,
                    ),
                    const SizedBox(height: 10),
                    //password textfield
                    MyTextfield(
                      hintText: "Password",
                      obscureText: true,
                      controller: passwordController,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 10),
                    //forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed('/forgot_password');
                            },
                            child: Text(
                              "Forgot Password",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 45),
                    //sign in button  
                    MyButton(
                      text: "Login",
                      onTap: login,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}