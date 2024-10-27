import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageDept extends StatefulWidget {
  const ManageDept({super.key});

  @override
  State<ManageDept> createState() => _ManageDeptState();
}

class _ManageDeptState extends State<ManageDept>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _deptNameController = TextEditingController();
  final CollectionReference _deptCollection =
      FirebaseFirestore.instance.collection('department');

  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration =
      const Duration(milliseconds: 300); // Animation duration

  // Function to add a new department to Firestore
  Future<void> _addDept() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Generate a unique document reference
        DocumentReference newDeptRef = _deptCollection.doc();

        // Add the department data including the departmentId
        await newDeptRef.set({
          'departmentId': newDeptRef.id, // Store the department ID
          'department': _deptNameController.text,
        });

        _deptNameController.clear();
        setState(() {
          _isFormVisible = false; // Hide form after adding
        });
      } catch (e) {
        // Handle error (e.g., show a Snackbar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add department: $e")),
        );
      }
    }
  }

  // Function to delete a department from Firestore
  Future<void> _deleteDept(String departmentId) async {
    try {
      await _deptCollection.doc(departmentId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete department: $e")),
      );
    }
  }

  // Function to edit a department in Firestore
  Future<void> _editDept(String departmentId, String newDepartment) async {
    try {
      await _deptCollection.doc(departmentId).update({
        'department': newDepartment,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to edit department: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Department Button at the top
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isFormVisible = !_isFormVisible; // Toggle form visibility
              });
            },
            icon: Icon(_isFormVisible ? Icons.close : Icons.add),
            label: Text(_isFormVisible ? "Cancel" : "Add Department"),
          ),

          // Animated Form for adding departments
          AnimatedSize(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _isFormVisible
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Add New Department",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Department Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Department Name Input Field
                            TextFormField(
                              controller: _deptNameController,
                              decoration: const InputDecoration(
                                labelText: "Department Name",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a Department name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Add Button
                            ElevatedButton.icon(
                              onPressed: _addDept,
                              icon: const Icon(Icons.add),
                              label: const Text("Add Department"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                          height: 20), // Add some space after the form
                    ],
                  )
                : Container(), // If form is not visible, return an empty container
          ),

          const SizedBox(height: 20),

          // Table of Departments fetched from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _deptCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final deptData = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width, // Set the width to full screen
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Sl.No')),
                        DataColumn(label: Text('Department Name')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: deptData.asMap().entries.map((entry) {
                        String departmentId = entry.value.id;
                        String department =
                            entry.value['department'] as String;

                        return DataRow(cells: [
                          DataCell(Text((entry.key + 1).toString())),
                          DataCell(Text(department)),
                          DataCell(
                            Row(
                              children: [
                                // Delete Button
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDept(departmentId),
                                ),
                                // Edit Button
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditDialog(departmentId, department);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to show edit dialog
  void _showEditDialog(String departmentId, String currentDepartment) {
    TextEditingController _editController =
        TextEditingController(text: currentDepartment);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department'),
        content: TextFormField(
          controller: _editController,
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _editDept(departmentId, _editController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
