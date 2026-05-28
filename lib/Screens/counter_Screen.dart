// lib/screens/counter_screen.dart
//
// Covers:
//   Task 1 – setState to manage counter (increase / decrease)
//   Task 2 – SharedPreferences to persist counter across app restarts

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  int _counter = 0;
  bool _isLoading = true;

  // Animation controller for the number pop effect
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  // SharedPreferences key
  static const String _counterKey = 'counter_value';

  // ── Colors ─────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF1B2FC2);
  static const Color _surface   = Color(0xFFF5F6FF);
  static const Color _positive  = Color(0xFF43A047);
  static const Color _negative  = Color(0xFFE53935);

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Number pop animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _loadCounter(); // load saved value on start
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── SharedPreferences helpers ──────────────────────────────

  /// Load the counter value from local storage
  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter  = prefs.getInt(_counterKey) ?? 0; // default 0 if not saved yet
      _isLoading = false;
    });
  }

  /// Persist the current counter value to local storage
  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, _counter);
  }

  // ── Counter actions ────────────────────────────────────────

  void _increment() {
    setState(() => _counter++);
    _animController.forward(from: 0);
    _saveCounter(); // persist after every change
  }

  void _decrement() {
    setState(() => _counter--);
    _animController.forward(from: 0);
    _saveCounter();
  }

  void _reset() {
    setState(() => _counter = 0);
    _animController.forward(from: 0);
    _saveCounter();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Counter reset to 0'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Color valueColor = _counter > 0
        ? _positive
        : _counter < 0
        ? _negative
        : _primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Counter',
          style: TextStyle(
            color: Color(0xFF1B1B2F),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1B2FC2)),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Counter card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E4FF), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Value',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Animated number
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Text(
                      '$_counter',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                        height: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status label
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: valueColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _counter > 0
                          ? 'Positive'
                          : _counter < 0
                          ? 'Negative'
                          : 'Zero',
                      style: TextStyle(
                        fontSize: 12,
                        color: valueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Persistent storage hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Value auto-saved — restarts from here',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // ── Buttons ──
            Row(
              children: [
                // Decrease
                Expanded(
                  child: _CounterButton(
                    label: '−',
                    color: _negative,
                    onTap: _decrement,
                  ),
                ),
                const SizedBox(width: 16),
                // Increase
                Expanded(
                  child: _CounterButton(
                    label: '+',
                    color: _positive,
                    onTap: _increment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable button widget ─────────────────────────────────────
class _CounterButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CounterButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w400,
                color: color,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}