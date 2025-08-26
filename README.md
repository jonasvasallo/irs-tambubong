# Tambubong Incident Reporting System - Mobile Application

The **Tambubong Incident Reporting Mobile App** is a mobile application built with **Flutter** that allows residents of Tambubong to quickly report community incidents.  
It integrates with **Firebase** for authentication, data storage, media uploads, and notifications.

---

## Features
- 📝 **Report Incidents** – Submit reports with description, type, and location  
- 📸 **Attach Evidence** – Upload photos or videos to support reports  
- 🔍 **Track Reports** – View the status of submitted incidents (Pending, In Progress, Resolved)  
- 🔔 **Push Notifications** – Receive real-time updates on your reports via FCM (Firebase Cloud Messagging)  
- 👤 **User Accounts** – Register and log in securely using Firebase Authentication  

---

## Tech Stack
- **Frontend:** Flutter (Dart)  
- **Backend:** Firebase (Serverless)  
  - **Authentication** – Email/Password login  
  - **Cloud Firestore** – Stores incident reports and user info  
  - **Cloud Storage** – Stores uploaded media files (photos/videos)  
  - **Cloud Functions** – Notifications, audit logging, role management  
  - **Firebase Cloud Messaging (FCM)** – Push notifications  

---
