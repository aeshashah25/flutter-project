import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:t_att/login_screen.dart'; // For date formatting

class StudentScreen extends StatefulWidget {
  final String subjectId;
  final String classId;

  StudentScreen({required this.subjectId, required this.classId});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? selectedMonth;
  String? selectedStatus;

  DateTime selectedDate = DateTime.now();

  List<String> months = List.generate(12, (index) {
    return DateFormat('MMMM').format(DateTime(2021, index + 1, 1));
  });

  List<String> statuses = ['Present', 'Absent'];

  Future<void> _addStudent(BuildContext context) async {
    if (_studentNameController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('Classes')
          .doc(widget.classId)
          .collection('Subjects')
          .doc(widget.subjectId)
          .collection('Students')
          .add({'student_name': _studentNameController.text});
      _studentNameController.clear(); // Clear the input after adding
    }
  }

  Future<void> _markAttendance(BuildContext context, String studentId,
      bool isPresent, DateTime date) async {
    final dateString = DateTime(date.year, date.month, date.day);

    final attendanceQuery = await FirebaseFirestore.instance
        .collection('Classes')
        .doc(widget.classId)
        .collection('Subjects')
        .doc(widget.subjectId)
        .collection('Students')
        .doc(studentId)
        .collection('Attendance')
        .where('date', isGreaterThanOrEqualTo: dateString)
        .where('date', isLessThan: dateString.add(Duration(days: 1)))
        .get();

    if (attendanceQuery.docs.isNotEmpty) {
      _showErrorDialog(
          context, "Attendance already marked for the selected date.");
    } else {
      await FirebaseFirestore.instance
          .collection('Classes')
          .doc(widget.classId)
          .collection('Subjects')
          .doc(widget.subjectId)
          .collection('Students')
          .doc(studentId)
          .collection('Attendance')
          .add({
        'date': date,
        'status': isPresent ? 'present' : 'absent',
      });
    }
  }

  Future<void> _updateAttendanceStatus(
      String studentId, String attendanceId, bool isPresent) async {
    await FirebaseFirestore.instance
        .collection('Classes')
        .doc(widget.classId)
        .collection('Subjects')
        .doc(widget.subjectId)
        .collection('Students')
        .doc(studentId)
        .collection('Attendance')
        .doc(attendanceId)
        .update({
      'status': isPresent ? 'present' : 'absent',
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Attendance Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Center(
          child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ));
              },
              child: Text("Logout")),
        ),
      ),
      appBar: AppBar(
        title: Text("Students"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _studentNameController,
              decoration: InputDecoration(
                labelText: "Student Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _addStudent(context),
              child: Text("Add Student"),
            ),
            SizedBox(height: 20),
            Text(
              "Filter Students by:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select Month"),
                    value: selectedMonth,
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value;
                      });
                    },
                    items: months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select Status"),
                    value: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                    items: statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: "Select Date",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 10),
            Text(
              "Students List:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Classes')
                    .doc(widget.classId)
                    .collection('Subjects')
                    .doc(widget.subjectId)
                    .collection('Students')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  var students = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var studentData = students[index];
                      return ListTile(
                        title: Text(studentData['student_name']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Row(
                                children: [
                                  Icon(Icons.check, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text("Present",
                                      style: TextStyle(color: Colors.green)),
                                ],
                              ),
                              onPressed: () => _markAttendance(
                                  context, studentData.id, true, selectedDate),
                            ),
                            IconButton(
                              icon: Row(
                                children: [
                                  Icon(Icons.close, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text("Absent",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onPressed: () => _markAttendance(
                                  context, studentData.id, false, selectedDate),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Filtered Attendance Records:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Classes')
                    .doc(widget.classId)
                    .collection('Subjects')
                    .doc(widget.subjectId)
                    .collection('Students')
                    .snapshots(),
                builder: (context, studentSnapshot) {
                  if (!studentSnapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  var students = studentSnapshot.data!.docs;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var studentData = students[index];
                      return StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('Classes')
                            .doc(widget.classId)
                            .collection('Subjects')
                            .doc(widget.subjectId)
                            .collection('Students')
                            .doc(studentData.id)
                            .collection('Attendance')
                            .snapshots(),
                        builder: (context, attendanceSnapshot) {
                          if (!attendanceSnapshot.hasData)
                            return SizedBox(); // or return a placeholder
                          var attendanceRecords =
                              attendanceSnapshot.data!.docs.where((record) {
                            bool matchesMonth = selectedMonth == null ||
                                DateFormat('MMMM')
                                        .format(record['date'].toDate()) ==
                                    selectedMonth;
                            bool matchesStatus = selectedStatus == null ||
                                record['status'].toLowerCase() ==
                                    selectedStatus!.toLowerCase();
                            return matchesMonth && matchesStatus;
                          }).toList();

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text("Student Name")),
                                DataColumn(label: Text("Date")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Actions")),
                              ],
                              rows: attendanceRecords.map<DataRow>((record) {
                                return DataRow(cells: [
                                  DataCell(Text(studentData['student_name'])),
                                  DataCell(
                                      Text(record['date'].toDate().toString())),
                                  DataCell(Text(record['status'])),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Call the update function
                                            bool newStatus =
                                                record['status'] == 'present'
                                                    ? false
                                                    : true;
                                            _updateAttendanceStatus(
                                                studentData.id,
                                                record.id,
                                                newStatus);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
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
      ),
    );
  }
}
