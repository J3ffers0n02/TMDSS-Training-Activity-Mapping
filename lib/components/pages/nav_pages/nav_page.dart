  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:tmdss/components/Map/pages/map_page.dart';
  import 'package:tmdss/components/admin/crud.dart';
  import 'package:tmdss/components/auth/presentation/cubits/auth_cubit.dart';
  import 'package:tmdss/components/auth/presentation/cubits/auth_states.dart';  

  class NavigationPage extends StatefulWidget {
    const NavigationPage({super.key});

    @override
    State<NavigationPage> createState() => _NavigationPageState();
  }

  class _NavigationPageState extends State<NavigationPage> {
    int _selectedIndex = 0;
    late final List<Widget> _widgetOptions;

    @override
    void initState() {
      super.initState();
      _widgetOptions = [
        const MapPage(),
        const FileManagementAdminPage(),
      ];
    }

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    @override
    Widget build(BuildContext context) {
      return BlocBuilder<AuthCubit, AuthStates>(
        builder: (context, authState) {
          final isAuthenticated = authState is Authenticated;

          if (!isAuthenticated && _selectedIndex > 0) {
            _selectedIndex = 0;
          }

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
                                  selectedIndex: _selectedIndex,
                                  onDestinationSelected: _onItemTapped,
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
                                    icon: const Icon(Icons.login),
                                    tooltip: 'Login',
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/login')
                                          .then((_) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.person_add),
                                    tooltip: 'Register',
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register')
                                          .then((_) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ),
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
                        child: _widgetOptions.elementAt(
                            _selectedIndex < _widgetOptions.length
                                ? _selectedIndex
                                : 0),
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
