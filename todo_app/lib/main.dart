import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  final _taskController = TextEditingController();

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> task = Map();
      task["title"] = _taskController.text;
      _taskController.text = "";
      task["check"] = false;
      _toDoList.add(task);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["check"] && !b["check"])
          return 1;
        else if (!a["check"] && b["check"])
          return -1;
        else
          return 0;
      });

      _saveData();
    });

    return Null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task List"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                      labelText: "New Task",
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                )),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 2.0),
                      itemCount: _toDoList.length,
                      itemBuilder: buidItem)))
        ],
      ),
    );
  }

  Widget buidItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment(-0.9, 0),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["check"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["check"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["check"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
              content: Text("Task \"${_lastRemoved["title"]}\" was removed!"),
              action: SnackBarAction(
                  label: "Undo",
                  onPressed: () {
                    setState(() {
                      _toDoList.insert(_lastRemovedIndex, _lastRemoved);
                      _saveData();
                    });
                  }),
              duration: Duration(seconds: 2));
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
