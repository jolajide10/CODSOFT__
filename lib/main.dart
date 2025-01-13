import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class Task {
  String title;
  bool isCompleted;

  Task({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
  };

  static Task fromJson(Map<String, dynamic> json) =>
      Task(title: json['title'], isCompleted: json['isCompleted']);
}

class _TodoHomePageState extends State<TodoHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<Task> _todoList = [];
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _loadTodoList() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      final String? tasksJson = _prefs?.getString('todoList');
      if (tasksJson != null) {
        _todoList = (json.decode(tasksJson) as List)
            .map((item) => Task.fromJson(item))
            .toList();
      }
    });
  }

  Future<void> _saveTodoList() async {
    final String tasksJson = json.encode(_todoList.map((task) => task.toJson()).toList());
    await _prefs?.setString('todoList', tasksJson);
  }

  Future<void> _addTodo() async {
    final String taskTitle = _controller.text.trim();
    if (taskTitle.isNotEmpty) {
      setState(() {
        _todoList.add(Task(title: taskTitle));
      });
      _controller.clear();
      await _saveTodoList();
    }
  }

  Future<void> _editTodo(int index) async {
    final TextEditingController editController =
    TextEditingController(text: _todoList[index].title);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Update task',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _todoList[index].title = editController.text.trim();
              });
              await _saveTodoList();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompletion(int index) async {
    setState(() {
      _todoList[index].isCompleted = !_todoList[index].isCompleted;
    });
    await _saveTodoList();
  }

  Future<void> _deleteTodo(int index) async {
    setState(() {
      _todoList.removeAt(index);
    });
    await _saveTodoList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Enter a task',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
              ),
              onSubmitted: (_) => _addTodo(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _todoList.isEmpty
                  ? const Center(
                child: Text(
                  'No tasks yet!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _todoList.length,
                itemBuilder: (context, index) {
                  final task = _todoList[index];
                  return Card(
                    color: task.isCompleted ? Colors.green[200] : Colors.white,
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => _toggleCompletion(index),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTodo(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTodo(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
