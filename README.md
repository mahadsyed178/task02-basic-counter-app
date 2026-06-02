# task02-basic-counter-app

This Flutter screen implements a persistent animated counter with two main features:
1. State Management (setState)

_counter is the core state variable
_increment(), _decrement(), and _reset() each call setState() to update the UI instantly
The counter color changes dynamically — green (positive), red (negative), blue (zero)

2. Persistence (SharedPreferences)

On app start, _loadCounter() reads the saved value from local storage
After every change, _saveCounter() writes the new value back
So the counter survives app restarts

3. Animation

An AnimationController with a TweenSequence creates a quick scale pop (1.0 → 1.18 → 1.0) on the number each time it changes, giving tactile feedback

4. UI Structure

A card displays the current value + a status label ("Positive / Negative / Zero")
Two _CounterButton widgets (+ and −) sit below it
A reset button lives in the AppBar
A loading spinner shows while SharedPreferences is being read on startup.
Core Purpose: A full-featured task manager with filtering, persistence, and swipe-to-delete.

1. State Variables

_tasks — the main list of Task objects
_filter — current view: 'all', 'active', or 'done'
_textController — controls the text input field


2. Persistence (SharedPreferences)
Tasks are stored as a JSON string list since SharedPreferences can't store objects directly:

_loadTasks() — reads the list on startup, decodes each JSON string back into a Task
_saveTasks() — encodes every task to JSON and saves the whole list after any change


3. Task Actions
MethodWhat it does_addTask()Creates a Task with a timestamp ID, inserts at top_toggleTask()Flips isDone true/false_deleteTask()Removes task + shows Undo snackbar to restore it_clearCompleted()Bulk-removes all done tasks

4. Filtering
_filteredTasks is a computed getter — it doesn't store a separate list, it just filters _tasks on the fly based on _filter.

5. UI Components

Stats bar — shows Total / Active / Done counts + a live progress bar (% completed)
Add input — text field + button; also submits on keyboard "done"
Filter chips — All / Active / Done tabs with animated selection
_TaskTile — each task row supports:

Tap circle → toggle done (with strikethrough text)
Swipe left → delete
Delete icon button → delete
Relative timestamp (Just now, 2h ago, etc.)

