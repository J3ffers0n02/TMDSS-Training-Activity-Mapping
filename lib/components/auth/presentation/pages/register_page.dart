import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_cubit.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_states.dart';
import 'package:tmdss/helpers/my_button.dart';
import 'package:tmdss/helpers/my_textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactNumController = TextEditingController();
  final passwordController = TextEditingController();

  void register() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final contactNum = contactNumController.text.trim();
    final password = passwordController.text.trim();

    if (name.isNotEmpty && email.isNotEmpty && contactNum.isNotEmpty && password.isNotEmpty) {
      context.read<AuthCubit>().register(name, email, contactNum, password).then((_) {
        // No direct navigation here; let MyApp handle it
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactNumController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/FPRDI.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay for opacity
          Container(
            color: Colors.black.withOpacity(0),
          ),
          // Registration form
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
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
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    // Name field
                    MyTextfield(
                      hintText: "Full Name",
                      obscureText: false,
                      controller: nameController,
                    ),
                    const SizedBox(height: 10),
                    // Email field
                    MyTextfield(
                      hintText: "Email",
                      obscureText: false,
                      controller: emailController,
                    ),
                    const SizedBox(height: 10),
                    // Contact number field
                    MyTextfield(
                      hintText: "Contact Number",
                      obscureText: false,
                      controller: contactNumController,
                    ),
                    const SizedBox(height: 10),
                    // Password field
                    MyTextfield(
                      hintText: "Password",
                      obscureText: true,
                      controller: passwordController,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 10),
                    // Back to login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 45),
                    // Register button
                    BlocBuilder<AuthCubit, AuthStates>(
                      builder: (context, state) {
                        return MyButton(
                          text: state is AuthLoading ? "Registering..." : "Register",
                          onTap: state is AuthLoading ? null : register,
                        );
                      },
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