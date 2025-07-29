  import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:tmdss/app.dart';
  import 'package:tmdss/components/auth/domain/entities/supabase_config.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load();

    // Initialize Supabase  
    await SupabaseConfig.initialize();
    runApp(MyApp());
  }
    

  //fixed hardcoded years in filter variables 