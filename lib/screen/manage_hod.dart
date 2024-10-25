import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

class ManageHOD extends StatefulWidget {
  const ManageHOD({super.key});

  @override
  State<ManageHOD> createState() => _ManageHODState();
}

class _ManageHODState extends State<ManageHOD> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  Uint8List? _selectedImage;

  bool _isFormVisible = false; // To manage form visibility

  List<Map<String, dynamic>> hodList = []; // To hold HOD data
  Map<String, String> departmentMap = {}; // To hold department ID to name mapping
  String? selectedDepartmentId; // To hold selected department ID

  @override
  void initState() {
    super.initState();
    _fetchDepartments(); // Fetch department data first
    _fetchHODData(); // Fetch HOD data after departments are fetched
  }

  Future<void> _fetchDepartments() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('department').get();
      setState(() {
        // Create a mapping of department IDs to names
        departmentMap = {
          for (var doc in querySnapshot.docs)
            doc.id: doc['department'], // Assuming department name is stored in 'name' field
        };
      });
    } catch (e) {
      print("Error fetching departments: $e");
      Fluttertoast.showToast(
        msg: "Error fetching departments",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _fetchHODData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('hod').get();

      List<Map<String, dynamic>> tempHodList = []; // Create a temporary list

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String departmentName = await fetchDepartmentName(data['departmentId']); // Wait for department name

        tempHodList.add({
          'id': doc.id, // Store the document ID for deletion
          'name': data['name'],
          'email': data['email'],
          'contact': data['phone'],
          'photo': data['imageUrl'] ?? 'assets/dummy-profile-pic.jpg', // Fallback photo
          'departmentId': data['departmentId'], // Store the department ID for later use
          'departmentName': departmentName, // Fetch the department name
        });
      }

      setState(() {
        hodList = tempHodList; // Update state with the complete list
      });
    } catch (e) {
      print("Error fetching HOD data: $e");
      Fluttertoast.showToast(
        msg: "Error fetching HOD data",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<String> fetchDepartmentName(String departmentId) async {
    try {
      // Fetch the document from the 'departments' collection using the departmentId
      final doc = await FirebaseFirestore.instance
          .collection('department')
          .doc(departmentId)
          .get();

      // Check if the document exists and return the name
      if (doc.exists) {
        return doc['department']; // Return the department name
      } else {
        return 'Unknown'; // Handle the case where the department does not exist
      }
    } catch (e) {
      print("Error fetching department name: $e");
      return 'Error'; // Handle error case
    }
  }

  Future<void> _registerHOD() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passController.text,
        );

        await _storeUserData(userCredential.user!.uid);
        Fluttertoast.showToast(
          msg: "Registration Successful",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _fetchHODData(); // Refresh the HOD list after registration
            }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Registration Failed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print("Error registering user: $e");
    }
  }

  Future<void> _storeUserData(String userId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('hod').doc(userId).set({
        'uid': userId, // Add the uid to the Firestore document
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _contactController.text,
        'departmentId': selectedDepartmentId, // Store selected department ID
      });

      await _uploadImage(userId); // Upload image after storing basic data
    } catch (e) {
      print("Error storing user data: $e");
    }
  }

  Future<void> _uploadImage(String userId) async {
    try {
      if (_selectedImage != null) {
        Reference ref =
            FirebaseStorage.instance.ref().child('hod_images/$userId.jpg');

        // Upload the image from Uint8List
        UploadTask uploadTask =
            ref.putData(_selectedImage!); // Use putData for Uint8List
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        // Update Firestore with the image URL
        await FirebaseFirestore.instance.collection('hod').doc(userId).update({
          'imageUrl': imageUrl,
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _deleteHOD(String id) async {
    try {
      await FirebaseFirestore.instance.collection('hod').doc(id).delete();
      setState(() {
        hodList.removeWhere((hod) => hod['id'] == id);
      });
      Fluttertoast.showToast(
        msg: "HOD deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      print("Error deleting HOD: $e");
      Fluttertoast.showToast(
        msg: "Error deleting HOD",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _pickImage() async {
    // Use ImagePickerWeb to get the image as Uint8List
    final Uint8List? pickedFile = await ImagePickerWeb.getImageAsBytes();

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile; // Store the image bytes directly
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Wrap everything in a SingleChildScrollView
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add HOD Button at the top
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isFormVisible = !_isFormVisible; // Toggle form visibility
                });
              },
              icon: Icon(_isFormVisible ? Icons.close : Icons.add),
              label: Text(_isFormVisible ? "Cancel" : "Add HOD"),
            ),

            // HOD Form (Only show if _isFormVisible is true)
            if (_isFormVisible) ...[
              const SizedBox(height: 20),
              const Text(
                "Add New HOD",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // HOD Form
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
                                  ? MemoryImage(_selectedImage!) // Use MemoryImage for web
                                  : const AssetImage('assets/dummy-profile-pic.jpg')
                                      as ImageProvider,
                              child: _selectedImage == null
                                  ? const Icon(
                                      Icons.add,
                                      size: 40,
                                      color: Color(0xfff7f7f7),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: "Contact"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your contact number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passController,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Select Department"),
                      items: departmentMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartmentId = value; // Store the selected department ID
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _registerHOD,
                      child: const Text("Register HOD"),
                    ),
                  ],
                ),
              ),
            ],

            // HOD List
            const SizedBox(height: 20),
            const Text(
              "Registered HODs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling
              itemCount: hodList.length,
              itemBuilder: (context, index) {
                final hod = hodList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(hod['photo']),
                    ),
                    title: Text(hod['name']),
                    subtitle: Text(hod['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteHOD(hod['id']); // Delete HOD on button press
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
