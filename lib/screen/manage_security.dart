import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

class ManageSecurity extends StatefulWidget {
  const ManageSecurity({super.key});

  @override
  State<ManageSecurity> createState() => _ManageSecurityState();
}

class _ManageSecurityState extends State<ManageSecurity> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  Uint8List? _selectedImage;

  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300); // Animation duration

  List<Map<String, dynamic>> securityList = []; // To hold security personnel data

  @override
  void initState() {
    super.initState();
    _fetchSecurityData(); // Fetch data when widget is initialized
  }

  Future<void> _fetchSecurityData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('security').get();
      setState(() {
        securityList = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id, // Store the document ID for deletion
            'name': data['name'],
            'email': data['email'],
            'contact': data['phone'],
            'photo': data['imageUrl'] ?? 'assets/dummy-profile-pic.jpg', // Fallback photo
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching security data: $e");
      Fluttertoast.showToast(
        msg: "Error fetching security data",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _registerSecurity() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
        _fetchSecurityData(); // Refresh the security list after registration
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

      // Store user data along with the document ID as a field
      await firestore.collection('security').doc(userId).set({
        'id': userId, // Storing the document ID as a field
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _contactController.text,
      });

      await _uploadImage(userId);
    } catch (e) {
      print("Error storing user data: $e");
    }
  }

  Future<void> _uploadImage(String userId) async {
  try {
    if (_selectedImage != null) {
      // Create a reference to the Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child('security_images/$userId.jpg');
      
      // Upload the image from Uint8List
      UploadTask uploadTask = ref.putData(_selectedImage!);
      
      // Wait for the upload to complete
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the download URL
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore with the image URL
      await FirebaseFirestore.instance.collection('security').doc(userId).update({
        'imageUrl': imageUrl,
      });

      Fluttertoast.showToast(
        msg: "Image uploaded successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
  } catch (e) {
    print("Error uploading image: $e");
    Fluttertoast.showToast(
      msg: "Error uploading image: ${e.toString()}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}


  Future<void> _deleteSecurity(String id) async {
    try {
      await FirebaseFirestore.instance.collection('security').doc(id).delete();
      setState(() {
        securityList.removeWhere((security) => security['id'] == id);
      });
      Fluttertoast.showToast(
        msg: "Security deleted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      print("Error deleting security: $e");
      Fluttertoast.showToast(
        msg: "Error deleting security",
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
    return SingleChildScrollView( // Make the entire page scrollable
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Security Button at the top
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isFormVisible = !_isFormVisible; // Toggle form visibility
                });
              },
              icon: Icon(_isFormVisible ? Icons.close : Icons.add),
              label: Text(_isFormVisible ? "Cancel" : "Add Security"),
            ),

            // Animated Form
            AnimatedSize(
              duration: _animationDuration,
              curve: Curves.easeInOut,
              child: _isFormVisible
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Add New Security Personnel",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // Security Personnel Form
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
                                            : const AssetImage('assets/dummy-profile-pic.jpg') as ImageProvider,
                                        child: _selectedImage == null
                                            ? const Icon(
                                                Icons.add,
                                                size: 40,
                                                color: Color.fromARGB(255, 134, 134, 134),
                                              )
                                            : null,
                                      ),
                                      if (_selectedImage != null)
                                        const Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: 18,
                                            child: Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Name Input Field
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: "Name",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              // Email Input Field
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              // Contact Input Field
                              TextFormField(
                                controller: _contactController,
                                decoration: const InputDecoration(
                                  labelText: "Contact",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a contact number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Input Field (Masked)
                              TextFormField(
                                controller: _passController,
                                obscureText: true, // Mask password input
                                decoration: const InputDecoration(
                                  labelText: "Password",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              ElevatedButton(
                                onPressed: _registerSecurity,
                                child: const Text("Add Security"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(), // Hide if not visible
            ),

            const SizedBox(height: 20),

            // Display Security Personnel Table
            const Text(
              "Security Personnel",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ListView to display security personnel
            ListView.builder(
              itemCount: securityList.length,
              itemBuilder: (context, index) {
                final security = securityList[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(security['photo']),
                    ),
                    title: Text(security['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(security['email']),
                        Text(security['contact']),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteSecurity(security['id']); // Delete security
                      },
                    ),
                  ),
                );
              },
              shrinkWrap: true, // Allow ListView to take only the space it needs
              physics: const NeverScrollableScrollPhysics(), // Prevent ListView from scrolling
            ),
          ],
        ),
      ),
    );
  }
}
