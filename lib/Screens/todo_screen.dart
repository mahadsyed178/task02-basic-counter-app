// lib/screens/todo_screen.dart
//
// Covers:
//   Task 3 – Add tasks, display in ListView, save with SharedPreferences

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  final List<Task> _tasks     = [];
  bool _isLoading             = true;
  String _filter              = 'all'; // 'all' | 'active' | 'done'

  // Input
  final _textController = TextEditingController();
  final _focusNode      = FocusNode();

  // SharedPreferences key
  static const String _tasksKey = 'todo_tasks';

  // ── Colors ─────────────────────────────────────────────────
  static const Color _primary  = Color(0xFF1B2FC2);
  static const Color _success  = Color(0xFF43A047);
  static const Color _error    = Color(0xFFE53935);
  static const Color _surface  = Color(0xFFF5F6FF);

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── SharedPreferences ──────────────────────────────────────

  /// Load tasks from local storage
  Future<void> _loadTasks() async {
    final prefs     = await SharedPreferences.getInstance();
    final jsonList  = prefs.getStringList(_tasksKey) ?? [];

    setState(() {
      _tasks.clear();
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _tasks.add(Task.fromJson(map));
        } catch (_) {
          // skip malformed entries
        }
      }
      _isLoading = false;
    });
  }

  /// Persist all tasks to local storage
  Future<void> _saveTasks() async {
    final prefs    = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toJson()).toList();
    await prefs.setStringList(_tasksKey, jsonList);
  }

  // ── Task actions ───────────────────────────────────────────

  void _addTask() {
    final title = _textController.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      title:     title,
      createdAt: DateTime.now(),
    );

    setState(() => _tasks.insert(0, task)); // newest on top
    _saveTasks();
    _textController.clear();
    _focusNode.unfocus();
  }

  void _toggleTask(String id) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) _tasks[index].isDone = !_tasks[index].isDone;
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    final task  = _tasks.firstWhere((t) => t.id == id);
    final index = _tasks.indexOf(task);

    setState(() => _tasks.removeWhere((t) => t.id == id));
    _saveTasks();

    // Undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _tasks.insert(index, task));
            _saveTasks();
          },
        ),
      ),
    );
  }

  void _clearCompleted() {
    setState(() => _tasks.removeWhere((t) => t.isDone));
    _saveTasks();
  }

  // ── Filtered list ──────────────────────────────────────────
  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'active':
        return _tasks.where((t) => !t.isDone).toList();
      case 'done':
        return _tasks.where((t) => t.isDone).toList();
      default:
        return _tasks;
    }
  }

  int get _doneCount   => _tasks.where((t) => t.isDone).length;
  int get _activeCount => _tasks.where((t) => !t.isDone).length;

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'To-Do List',
          style: TextStyle(
            color: Color(0xFF1B1B2F),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_doneCount > 0)
            TextButton.icon(
              onPressed: _clearCompleted,
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Color(0xFFE53935), size: 18),
              label: const Text(
                'Clear done',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ──
          _buildStatsBar(),

          // ── Add task input ──
          _buildAddInput(),

          // ── Filter chips ──
          _buildFilterChips(),

          const SizedBox(height: 8),

          // ── Task list ──
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E4FF)),
      ),
      child: Row(
        children: [
          _StatChip(
              label: 'Total',
              value: _tasks.length,
              color: _primary),
          const SizedBox(width: 12),
          _StatChip(
              label: 'Active',
              value: _activeCount,
              color: const Color(0xFFF57C00)),
          const SizedBox(width: 12),
          _StatChip(
              label: 'Done',
              value: _doneCount,
              color: _success),

          const Spacer(),

          // Progress bar
          if (_tasks.isNotEmpty) ...[
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${((_doneCount / _tasks.length) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _doneCount / _tasks.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(_success),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Add task input ─────────────────────────────────────────
  Widget _buildAddInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTask(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1B1B2F)),
              decoration: InputDecoration(
                hintText: 'Add a new task...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.add_task_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                filled: true,
                fillColor: _surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Add button
          SizedBox(
            height: 50,
            width: 50,
            child: ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            count: _tasks.length,
            isSelected: _filter == 'all',
            onTap: () => setState(() => _filter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            count: _activeCount,
            isSelected: _filter == 'active',
            onTap: () => setState(() => _filter = 'active'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Done',
            count: _doneCount,
            isSelected: _filter == 'done',
            onTap: () => setState(() => _filter = 'done'),
          ),
        ],
      ),
    );
  }

  // ── Task list ──────────────────────────────────────────────
  Widget _buildTaskList() {
    final tasks = _filteredTasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == 'done'
                  ? Icons.task_alt_outlined
                  : Icons.checklist_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              _filter == 'done'
                  ? 'No completed tasks yet'
                  : _filter == 'active'
                  ? 'All tasks completed! 🎉'
                  : 'No tasks yet.\nAdd one above!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskTile(
          task: task,
          onToggle: () => _toggleTask(task.id),
          onDelete: () => _deleteTask(task.id),
        );
      },
    );
  }
}

// ── Task Tile ──────────────────────────────────────────────────
class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE53935), size: 22),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: task.isDone
              ? const Color(0xFFF0FFF0)
              : const Color(0xFFF5F6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isDone
                ? const Color(0xFF43A047).withOpacity(0.3)
                : const Color(0xFFE0E4FF),
          ),
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

          // Checkbox
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone
                    ? const Color(0xFF43A047)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isDone
                      ? const Color(0xFF43A047)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),
          ),

          // Title
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: task.isDone
                  ? Colors.grey.shade400
                  : const Color(0xFF1B1B2F),
              decoration:
              task.isDone ? TextDecoration.lineThrough : null,
              decorationColor: Colors.grey.shade400,
            ),
          ),

          // Timestamp
          subtitle: Text(
            _formatDate(task.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),

          // Delete button
          trailing: IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.grey.shade400, size: 20),
            onPressed: onDelete,
            splashRadius: 20,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays == 1)     return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Stat chip ──────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B2FC2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
          isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? primary : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}