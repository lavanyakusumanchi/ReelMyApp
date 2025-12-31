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

## 📸 Output Screens

📸 Output Screens
🔐 Authentication Flow
Login	| Create Account |	Forgot Password

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/28338fc5-85e5-49f4-a999-57b077e08c3a" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/2207d142-74a9-4ad4-9b85-29caaca08ecd" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/21d719a4-3513-42e3-a3ed-a227d99c565d" />


	
🏠 Home Feed & Discovery
Home  |Feed	Category | Tabs	Reel Actions
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/753dd876-93f1-4b20-b07d-e1426a11080e" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/b5ec67ad-e900-461f-b308-bb6012a50ed2" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/8f5059cd-53c8-403d-a954-c027a57240ce" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/30d27a13-939a-4418-a0e7-c6c963bdd58e" />





➕ Create Reel Flow
Create Reel |	Media Inputs |	Generate Reel
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/5bbbe75c-8045-40d0-824d-36a4bcedabe6" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/631bd3cc-0ef2-467c-8100-3f7656fbaa24" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/87716bb0-54a8-4d54-9758-da1ed2e575d3" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/f5c39a90-e874-4d7f-b117-5375e60f0ce9" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/c0c902fb-215f-48e9-8829-c7fd097e34c1" />



	
	
👤 User Profile
Profile |	My Reels |	Saved Reels


<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/2e9910b7-3ab1-4eff-bdbc-a7676c46cbe6" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/d1545b0d-ec80-4b62-a22e-cfd93d393b1e" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/04f9331d-9adb-4274-a872-bc7a05e76e35" />



	
	
⚙️ Settings
Settings	| Dark Mode  |	Preferences

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/02db8a06-6ec6-4249-b692-a971e7f2fd68" />
<img width="540" height="1200" alt="image" src="https://github.com/user-attachments/assets/f3e8485b-fc67-4779-b450-368818974bcb" />

	
🛡 Admin Dashboard
Dashboard	 |  Users Management  | 	Reels Moderation

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/379a7699-65e6-4bed-bca1-931103516736" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/5a2db669-a577-4632-b98b-00b1e61207eb" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/4df58f3c-1a0b-4f2c-a66d-b0433e5ee5e5" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/2ce13941-069f-48fc-8d04-9cd861d611ac" />




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

