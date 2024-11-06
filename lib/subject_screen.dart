import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_screen.dart';

class SubjectScreen extends StatelessWidget {
  final String classId;

  SubjectScreen({required this.classId});

  final TextEditingController _subjectNameController = TextEditingController();

  Future<void> _createSubject() async {
    await FirebaseFirestore.instance
        .collection('Classes')
        .doc(classId)
        .collection('Subjects')
        .add({'subject_name': _subjectNameController.text});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subjects")),
      body: Column(
        children: [
          TextField(
            controller: _subjectNameController,
            decoration: InputDecoration(labelText: "Subject Name"),
          ),
          ElevatedButton(
            onPressed: _createSubject,
            child: Text("Create Subject"),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Classes')
                  .doc(classId)
                  .collection('Subjects')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var subjects = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    var subjectData = subjects[index];
                    return ListTile(
                      title: Text(subjectData['subject_name']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StudentScreen(
                                  subjectId: subjectData.id, classId: classId)),
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
