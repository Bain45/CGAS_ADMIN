import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAcademicYear extends StatefulWidget {
  const ManageAcademicYear({super.key});

  @override
  State<ManageAcademicYear> createState() => _ManageAcademicYearState();
}

class _ManageAcademicYearState extends State<ManageAcademicYear>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startYearController = TextEditingController();
  final TextEditingController _endYearController = TextEditingController();
  final CollectionReference _academicYearCollection =
      FirebaseFirestore.instance.collection('academicYears');

  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300); // Animation duration

  // Function to add new academic year to Firestore
  Future<void> _addAcademicYear() async {
    if (_formKey.currentState!.validate()) {
      try {
        String academicYear = "${_startYearController.text} - ${_endYearController.text}";

        await _academicYearCollection.add({
          'academicYear': academicYear,
        });

        _startYearController.clear();
        _endYearController.clear();

        setState(() {
          _isFormVisible = false; // Hide form after adding
        });
      } catch (e) {
        // Handle error (e.g., show a Snackbar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add academic year: $e")),
        );
      }
    }
  }

  // Function to delete an academic year from Firestore
  Future<void> _deleteAcademicYear(String docId) async {
    try {
      await _academicYearCollection.doc(docId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete academic year: $e")),
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
          // Add Academic Year Button at the top
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isFormVisible = !_isFormVisible; // Toggle form visibility
              });
            },
            icon: Icon(_isFormVisible ? Icons.close : Icons.add),
            label: Text(_isFormVisible ? "Cancel" : "Add Academic Year"),
          ),

          // Animated Form for adding academic years
          AnimatedSize(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _isFormVisible
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Add New Academic Year",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Academic Year Form
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            // Start Year Input Field
                            Expanded(
                              child: TextFormField(
                                controller: _startYearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Start Year",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the start year';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 20),

                            // End Year Input Field
                            Expanded(
                              child: TextFormField(
                                controller: _endYearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "End Year",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the end year';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Add Button
                      ElevatedButton.icon(
                        onPressed: _addAcademicYear,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Academic Year"),
                      ),
                      const SizedBox(height: 20), // Add some space after the form
                    ],
                  )
                : Container(), // If form is not visible, return an empty container
          ),

          const SizedBox(height: 20),

          // Table of Academic Years fetched from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _academicYearCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final academicYearData = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: MediaQuery.of(context)
                        .size
                        .width, // Set the width to full screen
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Sl.No')), // Serial number column
                        DataColumn(label: Text('Academic Year')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: academicYearData.asMap().entries.map((entry) {
                        String docId = entry.value.id;
                        String academicYear =
                            entry.value['academicYear'] as String;

                        return DataRow(cells: [
                          DataCell(Text((entry.key + 1).toString())), // Serial number
                          DataCell(Text(academicYear)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteAcademicYear(docId); // Delete academic year
                              },
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
}
