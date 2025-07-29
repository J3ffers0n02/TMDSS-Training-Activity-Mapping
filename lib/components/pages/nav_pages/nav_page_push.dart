import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tmdss/components/Map/pages/map_page.dart';
import 'package:tmdss/components/admin/crud.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_cubit.dart';
import 'package:tmdss/components/auth/presentation/cubits/auth_states.dart';  

class NavigationPagePush extends StatefulWidget {
  const NavigationPagePush({super.key});

  @override
  State<NavigationPagePush> createState() => _NavigationPagePushState();
}

class _NavigationPagePushState extends State<NavigationPagePush> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthStates>(
      builder: (context, authState) {
        final isAuthenticated = authState is Authenticated;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Scaffold(
              body: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          width: 0.28,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Image.asset(
                                'assets/images/FPRDILOGO.png',
                                height: 45,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SizedBox(
                            width: 50,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                navigationRailTheme: NavigationRailThemeData(
                                  useIndicator: false,
                                  indicatorColor: Colors.transparent,
                                ),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                focusColor: Colors.transparent,
                              ),
                              child: NavigationRail(
                                indicatorColor: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.transparent
                                    : null,
                                selectedLabelTextStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                                ),
                                unselectedLabelTextStyle: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                selectedIconTheme: IconThemeData(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                                ),
                                unselectedIconTheme: IconThemeData(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                selectedIndex: 0,
                                onDestinationSelected: (index) {
                                  if (index == 1 && isAuthenticated) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const FileManagementAdminPage(),
                                      ),
                                    );
                                  }
                                },
                                labelType: NavigationRailLabelType.none,
                                destinations: [
                                  const NavigationRailDestination(
                                    icon: Icon(Icons.home),
                                    label: Text('Home'),
                                  ),
                                  if (isAuthenticated)
                                    const NavigationRailDestination(
                                      icon: Icon(Icons.folder),
                                      label: Text('File Management'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        if (!isAuthenticated)
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: IconButton(
                                  icon: Icon(Icons.account_circle),
                                  tooltip: 'Login',
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login')
                                        .then((_) {
                                      setState(() {});
                                    });
                                  },
                                ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 16.0),
                              //   child: IconButton(
                              //     icon: const Icon(Icons.person_add),
                              //     tooltip: 'Register',
                              //     onPressed: () {
                              //       Navigator.pushNamed(context, '/register')
                              //           .then((_) {
                              //         setState(() {});
                              //       });
                              //     },
                              //   ),
                              // ),
                            ],
                          ),
                        if (isAuthenticated)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: 'Logout',
                              onPressed: () {
                                context.read<AuthCubit>().logout();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: const MapPage(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}