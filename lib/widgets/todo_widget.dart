import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../core/theme/app_theme.dart';

/// A fully functional, composite Todo widget that combines:
/// • Checkbox (task completion)
/// • Text (task name)
/// • Delete button (remove task with confirmation)
/// • FloatingActionButton (add task)
/// • Dialog (add task input + delete confirmation)
/// • ListView (display all tasks)
///
/// This widget manages its own state (tasks) and does NOT rely on external
/// state management. It's self-contained and can be used as a single dragged widget.
class TodoWidget extends StatefulWidget {
  final String title;
  final Color primaryColor;
  final String emptyMessage;

  const TodoWidget({
    Key? key,
    this.title = 'My Tasks',
    this.primaryColor = AppTheme.primary,
    this.emptyMessage = 'No tasks yet. Add one!',
  }) : super(key: key);

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
  // ══════════════════════════════════════════════════════════════════════
  // STATE: Tasks stored locally in this widget
  // ══════════════════════════════════════════════════════════════════════
  late List<Task> tasks;
  final TextEditingController _inputController = TextEditingController();
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Initialize with empty task list (can be loaded from widget state)
    tasks = [];
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  // ACTIONS: Core functionality
  // ══════════════════════════════════════════════════════════════════════

  /// Shows dialog to add a new task
  void _showAddTaskDialog() {
    _inputController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Task'),
        content: TextField(
          controller: _inputController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter task name...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onSubmitted: (_) => _addTask(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
            ),
            onPressed: _addTask,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Adds a task to the list
  void _addTask() {
    final taskTitle = _inputController.text.trim();
    if (taskTitle.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task cannot be empty!')));
      return;
    }

    setState(() {
      tasks.add(Task(id: uuid.v4(), title: taskTitle, isCompleted: false));
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task added!'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  /// Toggles task completion status
  void _toggleTask(String taskId) {
    setState(() {
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        tasks[taskIndex] = tasks[taskIndex].copyWith(
          isCompleted: !tasks[taskIndex].isCompleted,
        );
      }
    });
  }

  /// Shows confirmation dialog before deleting a task
  void _showDeleteConfirmation(String taskId, String taskTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(taskId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Deletes a task from the list
  void _deleteTask(String taskId) {
    setState(() {
      tasks.removeWhere((t) => t.id == taskId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task deleted!'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD: Complete UI with all functionality
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: widget.primaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.emptyMessage,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskTile(task);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: widget.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds a single task tile with checkbox, title, and delete button
  Widget _buildTaskTile(Task task) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTask(task.id),
          activeColor: widget.primaryColor,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task.isCompleted ? Colors.grey[400] : Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(task.id, task.title),
        ),
      ),
    );
  }
}
