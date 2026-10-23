// ============================================================
//  AGE CALCULATOR APP — Flutter (main.dart)
//  A clean, animated, beginner-friendly age calculator
//  with dark mode toggle and exact age display.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'banner_ad_widget.dart';


// --------------- ENTRY POINT ----------------
// Every Flutter app starts from main() → runApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();
  runApp(const AgeCalculatorApp());
}

// --------------- ROOT WIDGET ----------------
// This is a StatefulWidget because we need to toggle dark/light mode
// at the top level and pass the theme down to the whole app.
class AgeCalculatorApp extends StatefulWidget {
  const AgeCalculatorApp({super.key});

  @override
  State<AgeCalculatorApp> createState() => _AgeCalculatorAppState();
}

class _AgeCalculatorAppState extends State<AgeCalculatorApp> {
  // Track whether dark mode is ON or OFF
  bool _isDarkMode = false;

  // This callback is passed to the child screen so it can toggle the theme
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Age Calculator',
      debugShowCheckedModeBanner: false, // hides the debug banner

      // Switch between dark and light theme based on _isDarkMode
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ---- LIGHT THEME ----
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF), // purple seed color
        brightness: Brightness.light,
        fontFamily: 'Roboto',
      ),

      // ---- DARK THEME ----
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),

      // HomeScreen is our main screen — we pass the toggle callback to it
      home: HomeScreen(onToggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

// --------------- HOME SCREEN ----------------
// This is where all the logic and UI lives.
// StatefulWidget because we update UI on date select and button press.
class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme; // callback to toggle dark/light
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ---- STATE VARIABLES ----
  DateTime? _selectedDOB; // stores the user-selected date of birth
  int? _years; // calculated age in years
  int? _months; // calculated age in months (remainder)
  int? _days; // calculated age in days (remainder)
  String? _errorMessage; // error message if no date selected
  bool _showResult = false; // controls result card visibility

  // Animation controller for result card fade+slide in
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Set up animation: 600ms duration
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Fade from 0 → 1
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    // Slide from slightly below → normal position
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose(); // free memory when widget is removed
    super.dispose();
  }

  // ---- DATE PICKER ----
  // Opens Flutter's built-in date picker dialog
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(2000), // default to year 2000
      firstDate: DateTime(1900), // oldest possible DOB
      lastDate: now, // can't pick future date
      helpText: 'Select Date of Birth',
      confirmText: 'CONFIRM',
      cancelText: 'CANCEL',
    );

    if (picked != null) {
      setState(() {
        _selectedDOB = picked;
        _errorMessage = null; // clear error when date is picked
        _showResult = false; // hide old result when new date is picked
      });
    }
  }

  // ---- AGE CALCULATION LOGIC ----
  // Calculates exact years, months, and days between DOB and today
  void _calculateAge() {
    // If no date selected, show error
    if (_selectedDOB == null) {
      setState(() {
        _errorMessage = '⚠️ Please select your Date of Birth first!';
        _showResult = false;
      });
      return;
    }

    final DateTime today = DateTime.now();
    final DateTime dob = _selectedDOB!;

    // Step 1: Calculate years
    int years = today.year - dob.year;

    // Step 2: Calculate months
    int months = today.month - dob.month;

    // Step 3: Calculate days
    int days = today.day - dob.day;

    // Adjust if days are negative (borrow from months)
    if (days < 0) {
      months--; // borrow one month
      // Get number of days in the previous month
      final DateTime lastMonth = DateTime(today.year, today.month, 0);
      days += lastMonth.day; // add those days to current days
    }

    // Adjust if months are negative (borrow from years)
    if (months < 0) {
      years--; // borrow one year
      months += 12; // add 12 months
    }

    // Update state with calculated values
    setState(() {
      _years = years;
      _months = months;
      _days = days;
      _errorMessage = null;
      _showResult = true;
    });

    // Trigger animation: reset then play forward
    _animController.reset();
    _animController.forward();
  }

  // ---- FORMAT DATE FOR DISPLAY ----
  // Converts DateTime to readable string like "15 Aug 2000"
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ---- BUILD UI ----
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // ---- APP BAR ----
      appBar: AppBar(
        title: const Text(
          'Age Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Dark mode toggle button in top-right corner
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      // ---- BODY ----
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView prevents overflow on small screens
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ---- HEADER ILLUSTRATION ----
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // ---- TITLE TEXT ----
              Text(
                'Find Your Exact Age',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your date of birth and\nwe\'ll calculate your exact age.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ---- DOB SELECTOR CARD ----
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: _pickDate, // tap anywhere on card to pick date
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Calendar icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Show selected date or placeholder
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date of Birth',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDOB != null
                                    ? _formatDate(_selectedDOB!)
                                    : 'Tap to select date',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedDOB != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---- ERROR MESSAGE ----
              // Only shows if _errorMessage is not null
              if (_errorMessage != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              // ---- CALCULATE BUTTON ----
              SizedBox(
                width: double.infinity, // full width button
                height: 54,
                child: FilledButton.icon(
                  onPressed: _calculateAge,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text(
                    'Calculate Age',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ---- RESULT CARD ----
              // Only shows after successful calculation, with animation
              if (_showResult)
                FadeTransition(
                  opacity: _fadeAnimation, // fade in animation
                  child: SlideTransition(
                    position: _slideAnimation, // slide up animation
                    child: Column(
                      children: [
                        Text(
                          '🎉 Your Age',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Three age boxes: Years, Months, Days
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _AgeBox(
                              value: _years!,
                              label: 'Years',
                              color: colorScheme.primaryContainer,
                              textColor: colorScheme.primary,
                            ),
                            _AgeBox(
                              value: _months!,
                              label: 'Months',
                              color: colorScheme.secondaryContainer,
                              textColor: colorScheme.secondary,
                            ),
                            _AgeBox(
                              value: _days!,
                              label: 'Days',
                              color: colorScheme.tertiaryContainer,
                              textColor: colorScheme.tertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Fun message based on age
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _getFunMessage(_years!),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  // ---- FUN MESSAGE BASED ON AGE ----
  String _getFunMessage(int years) {
    if (years < 5) return '🍼 Just a baby! Hello little one!';
    if (years < 13) return '🌟 A bright young star! Keep shining!';
    if (years < 18) return '🎒 Teen life! Enjoy every moment!';
    if (years < 25) return '🔥 Young & wild! The world is yours!';
    if (years < 35) return '💼 Prime time! Building your empire!';
    if (years < 50) return '🌳 Like fine wine, getting better!';
    if (years < 65) return '👑 Wise and wonderful!';
    return '🦋 A legend! Age is just a number!';
  }
}

// --------------- REUSABLE AGE BOX WIDGET ----------------
// Displays a single value (years / months / days) in a colored box
class _AgeBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color textColor;

  const _AgeBox({
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Big number
          Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          // Label below number
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}
