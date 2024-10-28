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

  bool _isFormVisible = false;

  List<Map<String, dynamic>> hodList = [];
  Map<String, String> departmentMap = {};
  String? selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchHODData();
  }

  Future<void> _fetchDepartments() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('department').get();
      setState(() {
        departmentMap = {
          for (var doc in querySnapshot.docs) doc.id: doc['department'],
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
      final querySnapshot = await FirebaseFirestore.instance.collection('hod').get();
      List<Map<String, dynamic>> tempHodList = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String departmentName = await fetchDepartmentName(data['departmentId']);

        tempHodList.add({
          'id': doc.id,
          'name': data['name'],
          'email': data['email'],
          'contact': data['phone'],
          'photo': data['imageUrl'] ?? '', // Use empty string if imageUrl is null
          'departmentId': data['departmentId'],
          'departmentName': departmentName,
        });
      }

      setState(() {
        hodList = tempHodList;
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
      final doc = await FirebaseFirestore.instance.collection('department').doc(departmentId).get();
      if (doc.exists) {
        return doc['department'];
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print("Error fetching department name: $e");
      return 'Error';
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
        _fetchHODData();
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
        'uid': userId,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _contactController.text,
        'departmentId': selectedDepartmentId,
      });

      await _uploadImage(userId);
    } catch (e) {
      print("Error storing user data: $e");
    }
  }

  Future<void> _uploadImage(String userId) async {
    try {
      if (_selectedImage != null) {
        Reference ref = FirebaseStorage.instance.ref().child('hod_images/$userId.jpg');
        UploadTask uploadTask = ref.putData(_selectedImage!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

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
    final Uint8List? pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null; // Remove the selected image
    });
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
              label: Text(_isFormVisible ? "Cancel" : "Add HOD"),
            ),
            if (_isFormVisible) ...[
              const SizedBox(height: 20),
              const Text(
                "Add New HOD",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Image selection and display
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
                            : const AssetImage('assets/dummy-profile-pic.jpg'),
                      ),
                      if (_selectedImage != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: "Contact"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a contact number';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField(
                      value: selectedDepartmentId,
                      decoration: const InputDecoration(labelText: 'Department'),
                      items: departmentMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartmentId = value as String?;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _registerHOD,
                      child: const Text("Register HOD"),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              "HOD List",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hodList.length,
              itemBuilder: (context, index) {
                final hod = hodList[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(hod['photo']),
                      child: hod['photo'].isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(hod['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hod['email']),
                        Text(hod['contact']),
                        Text(hod['departmentName']),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteHOD(hod['id']);
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
