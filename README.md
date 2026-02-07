# SnapMap
<img width="180" height="400" alt="image" src="https://github.com/user-attachments/assets/27f4050e-20b0-464a-83ad-81e4408913d6" />
<img width="180" height="400" alt="image" src="https://github.com/user-attachments/assets/5b3d192f-ab4a-4d7d-908a-7fcedec7fbe9" />
<img width="180" height="400" alt="image" src="https://github.com/user-attachments/assets/1be5142f-c04e-40d5-bff2-8cd5fb39d38e" />
<img width="180" height="400" alt="image" src="https://github.com/user-attachments/assets/85cc97d3-2d70-439c-bcb2-1f9bd28047d8" />
<img width="180" height="400" alt="image" src="https://github.com/user-attachments/assets/518cae0c-a189-4d33-920f-e70d8a702a77" />


SnapMap is a location-based social platform that lets users explore the world through space and time. Users can capture photos, share them on a global map, and use Time Travel mode to view how places evolve across hours, days, months, and years.

The app combines real-time storytelling, historical archiving, and creative exploration into a single interactive experience.

---

## Features

- Capture and upload photos with automatic location tagging  
- Interactive global map with clustered photo markers  
- Time Travel mode for browsing past content by hour, day, month, and year  
- Story-style photo stacks for nearby locations  
- AI-powered content moderation for inappropriate content  
- Frosted glass interface with smooth animations  
- Camera and map navigation slider  
- Real-time updates and cloud storage  

---

## Download (Android APK)

You can install SnapMap on Android devices using the APK file.

### Step 1: Download

Download the latest APK from GitHub Releases:

https://github.com/YOUR_USERNAME/YOUR_REPO/releases

Download the file named:

snapmap.apk


---

### Step 2: Enable Installation from Unknown Sources

On your Android device:

1. Open Settings  
2. Navigate to Security or Privacy  
3. Enable Install Unknown Apps  
4. Allow your browser or file manager to install applications  

---

### Step 3: Install

1. Open the downloaded APK file  
2. Tap Install  
3. Wait for installation to complete  
4. Launch SnapMap  

---

## Development Setup

### Requirements

- Flutter SDK (3.0 or higher recommended)  
- Android Studio or Visual Studio Code  
- Android emulator or physical Android device  
- Supabase account  

---

### Install Dependencies

From the project root directory:

```bash
flutter pub get
Run in Development Mode
flutter run
Build Release APK
To generate a production APK:

flutter build apk --release
The generated file will be located at:

build/app/outputs/flutter-apk/app-release.apk
Project Structure
snapmap/
├── android/
├── ios/
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   ├── models/
│   ├── ui/
│   └── theme/
├── assets/
├── pubspec.yaml
└── README.md
Technology Stack
Flutter

Dart

Supabase (Storage, Database, Auth)

Flutter Map

Camera Plugin

Geolocator

Cached Network Image

Computer Vision Moderation

Time Travel Mode
Time Travel Mode allows users to explore photos based on when they were taken and uploaded.

Users can scroll through time using an interactive slider and switch between hours, days, months, and years. Only photos active within the selected time window appear on the map, creating a dynamic historical view of locations.

This feature turns SnapMap into a living archive of real-world perspectives.

Content Moderation
SnapMap uses AI-based computer vision to detect and block:

Graphic content

Nudity

Violence

Self-harm imagery

Sexually explicit material

This ensures a safer and more welcoming platform for users.

Use Cases
Explore how cities and landmarks change over time

Discover travel destinations and local cafes

Verify real locations from online posts

Document daily life and events

Study social and cultural trends

Create visual archives

Project Vision
SnapMap is designed as a global archive of human perspective.

By combining location, time, and storytelling, the platform connects people across cultures and generations. It supports creative expression, historical documentation, and global understanding.

The goal is to transform social media from disposable content into meaningful records of life and place.

Roadmap
Planned features include:

iOS TestFlight support

Social profiles and followers

Public and private collections

Collaborative maps

Event-based timelines

Web-based viewer

Contributing
Contributions are welcome.

To contribute:

Fork the repository

Create a feature branch

Commit your changes

Open a pull request

License
This project is developed for educational, research, and demonstration purposes.

All rights reserved.

Contact
For questions or collaboration inquiries:

Email: rachelto@andrew.cmu.edu

GitHub: https://github.com/racheltong29
