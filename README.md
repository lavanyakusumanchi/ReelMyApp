# ReelMyApp 🎬

**ReelMyApp** is an automated marketing video generator designed to help brands and creators instantly produce engaging content. 

The app takes simple inputs—**Brand Logo, Description, Sound, Thumbnail, and Category**—and automatically generates a professional **5–15 second marketing reel**. These generated videos are instantly published to a seamless, scrollable "Reel Feed" maximizing discovery and engagement.

## 🚀 Core Functionality

### 🤖 Automatic Reel Generation
Instead of manual video editing, users simply provide the assets, and the system handles the rest:
1.  **Input**: Select a Brand Logo, write a Description, pick a Thumbnail, choose a Category, and add Audio.
2.  **Process**: The backend automates the assembly of these assets into a dynamic 5-15 second video.
3.  **Output**: The reel is immediately available in the global feed.

### 📱 Mobile Experience (Flutter)
- **Cinematic Feed**: A "Neo-Glass" scrollable interface (like TikTok/Reels) to view generated content.
- **Smart Creation Studio**: Simple form-based input for generating reels. 
- **User Engagement**: Like, save, comment, and share generated marketing clips.
- **Shake-to-Edit IP**: Developer utility to dynamically update the backend server IP.

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
  - `provider` (State Management)
  - `dio` (Networking)
  - `video_player` & `chewie` (Media)
  
- **Backend**: Node.js & Express
  - **FFmpeg**: For automated video processing and assembly.
  - **MongoDB**: Stores user data and reel metadata.
  - **Local Filesystem**: Handles media assets.

## 📸 Usage Workflow

1.  **Create**: Tap the "+" button. Upload your **Brand Logo** and **Thumbnail**. Enter your **Description** and select a **Category** and **Sound**.
2.  **Generate**: detailed inputs are sent to the backend.
3.  **View**: The generated marketing reel appears in the main scrollable feed, complete with your branding and audio.

📸 Output Screens
🔐 Authentication Flow

Secure and simple onboarding for users

<p align="center"> <img src="https://github.com/user-attachments/assets/a212be9e-269e-4a38-a10a-3a722ab3b6f8" width="180"/> <img src="https://github.com/user-attachments/assets/c2ca2cc0-72d8-4263-965a-80cc2c4080e1" width="180"/> <img src="https://github.com/user-attachments/assets/a11444a3-2eaa-44e4-b0c3-d27e152787cd" width="180"/> </p> <p align="center"> <i>Login · Create Account · Forgot Password</i> </p>
🏠 Home Feed & Discovery

Immersive, scrollable reel feed with engagement actions

<p align="center"> <img src="https://github.com/user-attachments/assets/70932dc2-3e74-40c3-afcb-994f79ef6ae6" width="180"/> <img src="https://github.com/user-attachments/assets/271c385d-129d-40f4-b8e9-a5150c0e0deb" width="180"/> <img src="https://github.com/user-attachments/assets/dee796cb-7310-4229-b621-9e845f2ad91d" width="180"/> <img src="https://github.com/user-attachments/assets/94e23284-f6dd-4503-a640-e199124eb445" width="180"/> </p> <p align="center"> <i>Home Feed · Category Tabs · Reel Actions</i> </p>
➕ Create Reel Flow

Step-by-step reel creation using minimal inputs

<p align="center"> <img src="https://github.com/user-attachments/assets/7a03ea90-c40a-49e0-a152-55dfb23837e8" width="180"/> <img src="https://github.com/user-attachments/assets/c45d7214-3994-4db6-8ea9-a01f40974f94" width="180"/> <img src="https://github.com/user-attachments/assets/8c5a9cce-a764-4bcd-bd8a-a3b5c4cdabd8" width="180"/> <img src="https://github.com/user-attachments/assets/ceb71fcc-ef54-4e61-8588-b6c41707084e" width="180"/> <img src="https://github.com/user-attachments/assets/261b3a96-1881-4b11-8205-0fe6553cad9a" width="180"/> </p> <p align="center"> <i>Create Reel · Media Inputs · Generate Reel</i> </p>
👤 User Profile

Personalized profile with created and saved reels

<p align="center"> <img src="https://github.com/user-attachments/assets/1da770b0-f8a2-4019-8343-0fe5afa0b6b6" width="180"/> <img src="https://github.com/user-attachments/assets/a532248b-f382-4761-b652-349f2cb115f9" width="180"/> <img src="https://github.com/user-attachments/assets/6c99bf43-0b48-42b6-ba90-2318a8ddb089" width="180"/> </p> <p align="center"> <i>Profile · My Reels · Saved Reels</i> </p>
⚙️ Settings

App preferences with theme customization

<p align="center"> <img src="https://github.com/user-attachments/assets/d21abebd-c560-442d-90d7-fb50c6755c4f" width="180"/> <img src="https://github.com/user-attachments/assets/3da467f8-bb5f-4d49-914c-4303c37c47ef" width="180"/> </p> <p align="center"> <i>Settings · Dark Mode</i> </p>
🛡 Admin Dashboard

Moderation and management interface for platform control

<p align="center"> <img src="https://github.com/user-attachments/assets/d4e21dc4-21e6-4a59-901a-1734dd9b2488" width="220"/> <img src="https://github.com/user-attachments/assets/894b1b60-84d4-4391-9ce3-3948005c86e7" width="220"/> <img src="https://github.com/user-attachments/assets/1feba271-7c3e-469f-ad89-4a8f1b78bfad" width="220"/> <img src="https://github.com/user-attachments/assets/de33eff9-f7af-4299-a82c-09f427fd9310" width="220"/> </p> <p align="center"> <i>Dashboard · Users Management · Reels Moderation</i> </p>299-a82c-09f427fd9310" />



## 🏗 Installation & Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.x or higher)
- [Node.js](https://nodejs.org/) (v16+)
- [FFmpeg](https://ffmpeg.org/download.html) (Required on the server/backend machine for video generation)
- [MongoDB](https://www.mongodb.com/try/download/community)

### 1. Backend Setup
Navigate to the backend directory:

```bash
cd backend
npm install
```

**Note:** Ensure `ffmpeg` is installed and accessible in your system path.


Start the server:
```bash
npm run dev
```

### 2. Mobile App Setup
Navigate to the project root:

```bash
flutter pub get
flutter run
```

