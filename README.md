# College Outpass & In-Pass Management System

## Overview
This is a web-based application built using Flutter and Firebase to manage the outpass and in-pass system for a college. The system includes roles such as Admin, Head of Department (HOD), Faculty, and Security, each with specific responsibilities. The application streamlines the process of requesting, approving, and validating student outpasses, ensuring a secure and efficient flow for student movement within and outside the college.

## Key Features
- **Admin Panel**: Manage users (HODs, Faculty, Security), view reports, and monitor activity.
- **HOD Module**: Approve or reject outpass requests from faculty or students.
- **Faculty Module**: Approve outpasses for students and manage requests.
- **Security Module**: Validate outpasses at entry and exit points using the system.
- **Student Outpass Requests**: Students can submit outpass requests, which are reviewed by Faculty and HOD.
- **Firebase Authentication**: Secure login for all users.
- **Firebase Firestore**: Real-time database to manage requests, approvals, and security validations.
- **Firebase Storage**: Manage and display images such as security photos.

## Tech Stack
- **Flutter**: Frontend framework for building responsive web pages.
- **Firebase**: Backend for authentication, database, and storage.
  - **Firebase Authentication**: Used for secure login.
  - **Firebase Firestore**: Used to store data related to users, outpass requests, and approvals.
  - **Firebase Storage**: Used to store and serve user photos and documents.

## Roles & Responsibilities
1. **Admin**
   - Manages users (HOD, Faculty, Security).
   - Monitors all activities and generates reports.
   
2. **HOD**
   - Reviews outpass requests from students.
   - Approves or rejects requests based on rules.
   
3. **Faculty**
   - Initiates and approves outpass requests for students.
   - Coordinates with HOD for approval.

4. **Security**
   - Validates outpasses at entry and exit points.
   - Ensures student compliance with the system.

## Getting Started

### Prerequisites
- Flutter SDK: [Flutter installation guide](https://flutter.dev/docs/get-started/install)
- Firebase project set up with Authentication, Firestore, and Storage.

### Setup Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/college-outpass-system.git
   cd college-outpass-system
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project in the [Firebase console](https://console.firebase.google.com/).
   - Enable Firebase Authentication (Email/Password).
   - Set up Firestore Database and Firebase Storage.
   - Add your `google-services.json` and `firebase-config` files in the project.

4. Run the project:
   ```bash
   flutter run
   ```

### Folder Structure
- `lib/`: Contains the Flutter code for the application.
  - `screens/`: Contains the different UI screens (Admin, HOD, Faculty, Security).
  - `models/`: Contains data models for users, requests, and approvals.
  - `controllers/`: Business logic and controllers for interacting with Firebase.
  - `widgets/`: Reusable UI components.

### Firebase Configuration
Ensure your Firebase project is configured with the following:
- Authentication enabled for Email/Password login.
- Firestore database with collections for users, requests, and approvals.
- Storage for user photos and documents.

## Contribution
Feel free to fork the project and submit pull requests. Please follow best practices for Flutter development.

## License
This project is licensed under the MIT License.
