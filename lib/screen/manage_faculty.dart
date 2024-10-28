import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

class ManageFaculty extends StatefulWidget {
  const ManageFaculty({super.key});

  @override
  State<ManageFaculty> createState() => _ManageFacultyState();
}

class _ManageFacultyState extends State<ManageFaculty> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  Uint8List? _selectedImage;

  bool _isFormVisible = false; // To manage form visibility

  List<Map<String, dynamic>> facultyList = []; // To hold Faculty data
  Map<String, String> departmentMap = {}; // To hold department ID to name mapping
  String? selectedDepartmentId; // To hold selected department ID
  String? selectedHodId; // To hold selected HOD ID

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchFacultyData();
  }

  Future<void> _fetchDepartments() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('department').get();
      setState(() {
        departmentMap = {
          for (var doc in querySnapshot.docs)
            if (doc.data().containsKey('department')) // Check if 'department' exists
              doc.id: doc['department'],
        };
      });
      print("Departments loaded: $departmentMap"); // Debugging output
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching departments: $e", // Log the error message
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print("Error fetching departments: $e"); // Log to console for debugging
    }
  }

  Future<void> _fetchHodByDepartment(String departmentId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('hod')
          .where('departmentId', isEqualTo: departmentId) // Assume HOD has departmentId field
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        selectedHodId = querySnapshot.docs.first.id; // Get the first HOD for the department
      } else {
        selectedHodId = null; // No HOD found for the department
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching HOD data: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _fetchFacultyData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('faculty').get();
      List<Map<String, dynamic>> tempFacultyList = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String departmentName = await fetchDepartmentName(data['departmentId']);
        tempFacultyList.add({
          'id': doc.id,
          'name': data['name'],
          'email': data['email'],
          'contact': data['phone'],
          'photo': data['imageUrl'] ?? 'assets/dummy-profile-pic.jpg',
          'departmentId': data['departmentId'],
          'departmentName': departmentName,
        });
      }
      setState(() {
        facultyList = tempFacultyList;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching faculty data: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<String> fetchDepartmentName(String departmentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('department')
          .doc(departmentId)
          .get();
      if (doc.exists) {
        return doc['department']; // Change to 'department' as per your collection
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Error';
    }
  }

  Future<void> _registerFaculty() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passController.text,
        );
        String facultyId = userCredential.user!.uid; // Use Firebase UID
        await _storeUserData(facultyId);
        Fluttertoast.showToast(
          msg: "Registration Successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _fetchFacultyData();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Registration Failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _storeUserData(String facultyId) async {
    try {
      await FirebaseFirestore.instance.collection('faculty').doc(facultyId).set({
        'id': facultyId, // Storing the faculty ID in Firestore
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _contactController.text,
        'departmentId': selectedDepartmentId,
        'hodId': selectedHodId, // Store the selected HOD ID
      });
      await _uploadImage(facultyId);
    } catch (e) {
      print("Error storing user data: $e");
    }
  }

  Future<void> _uploadImage(String facultyId) async {
    try {
      if (_selectedImage != null) {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('faculty_images/$facultyId.jpg');
        UploadTask uploadTask = ref.putData(_selectedImage!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String imageUrl = await taskSnapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('faculty')
            .doc(facultyId)
            .update({'imageUrl': imageUrl});
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _deleteFaculty(String id) async {
    try {
      await FirebaseFirestore.instance.collection('faculty').doc(id).delete();
      setState(() {
        facultyList.removeWhere((faculty) => faculty['id'] == id);
      });
      Fluttertoast.showToast(
        msg: "Faculty deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting faculty: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _pickImage() async {
    final Uint8List? pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isFormVisible = !_isFormVisible;
                });
              },
              icon: Icon(_isFormVisible ? Icons.close : Icons.add),
              label: Text(_isFormVisible ? "Cancel" : "Add Faculty"),
            ),
            if (_isFormVisible)
              ...[
                const SizedBox(height: 20),
                const Text(
                  "Add New Faculty",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xff4c505b),
                                backgroundImage: _selectedImage != null
                                    ? MemoryImage(_selectedImage!)
                                    : const AssetImage(
                                        'assets/dummy-profile-pic.jpg'),
                              ),
                              if (_selectedImage != null)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12.0), // Add padding for better touch target
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey), // Border color
    borderRadius: BorderRadius.circular(8.0), // Rounded corners
  ),
  child: DropdownButton<String>(
    hint: const Text("Select Department"),
    value: selectedDepartmentId,
    isExpanded: true, // Make the dropdown expand to full width
    underline: SizedBox(), // Remove the default underline
    items: departmentMap.entries
        .map((entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ))
        .toList(),
    onChanged: (value) async {
      setState(() {
        selectedDepartmentId = value;
        _fetchHodByDepartment(value!); // Fetch HOD when department changes
      });
    },
  ),
),

                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _registerFaculty,
                        child: const Text('Register Faculty'),
                      ),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: 20),
            const Text(
              "Registered Faculty",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: facultyList.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(facultyList[index]['photo']),
                    ),
                    title: Text(facultyList[index]['name']),
                    subtitle: Text(
                      'Email: ${facultyList[index]['email']}\n'
                      'Contact: ${facultyList[index]['contact']}\n'
                      'Department: ${facultyList[index]['departmentName']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteFaculty(facultyList[index]['id']);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
