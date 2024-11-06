import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_screen.dart';

class ClassScreen extends StatefulWidget {
  @override
  _ClassScreenState createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  final TextEditingController _classNameController = TextEditingController();

  Future<void> _createClass() async {
    await FirebaseFirestore.instance.collection('Classes').add({
      'class_name': _classNameController.text,
      'teacher_id': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  Future<void> _deleteClass(String classId) async {
    await FirebaseFirestore.instance
        .collection('Classes')
        .doc(classId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Classes")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _classNameController,
              decoration: InputDecoration(
                labelText: "Class Name",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _createClass,
            child: Text("Create Class"),
          ),
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('Classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var classes = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    var classData = classes[index];
                    return ListTile(
                      title: Text(classData['class_name']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Show confirmation dialog before deleting
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Delete Class'),
                                content: Text(
                                    'Are you sure you want to delete this class?'),
                                actions: [
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Delete'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );

                          // Delete class if confirmed
                          if (confirmDelete == true) {
                            await _deleteClass(classData.id);
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SubjectScreen(classId: classData.id)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
