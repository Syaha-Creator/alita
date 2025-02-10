import 'package:flutter/material.dart';
import 'theme/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Theme Example',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Mengikuti tema sistem
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Themed UI Demo"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hello, Flutter!",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Card dengan surface color agar berbeda dengan background
              Card(
                color: theme
                    .colorScheme.surface, // Tetap gunakan surface untuk Card
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "This is a themed Card",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Icon(
                        Icons.palette,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {},
                child: Text("Primary Button"),
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  side:
                      BorderSide(color: theme.colorScheme.secondary, width: 2),
                ),
                child: Text("Secondary Button"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
