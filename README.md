# GRIM - Goal & Task Management App

A comprehensive Flutter application for productivity and goal tracking with Firebase authentication and local data synchronization.

## 🚀 Features

### 🔐 Authentication
- **Email/Password Authentication** - Secure Firebase Auth integration
- **Google Sign-In** - One-tap Google authentication
- **Account Creation** - User registration with validation
- **Local Storage Backup** - Offline data persistence
- **Error Handling** - Comprehensive user feedback

### 📊 Dashboard & Analytics
- **Quarterly Overview** - Quarterly goal tracking
- **Year Analytics** - Comprehensive progress metrics
- **Progress Visualization** - Charts and statistics
- **Goal Achievement Tracking** - Milestone monitoring
- **Data Export** - Backup and share functionality

### ✅ Task Management
- **Goal Creation** - SMART goal setup
- **Task Execution** - Focus time tracking
- **Progress Monitoring** - Real-time status updates
- **Completion Tracking** - Achievement logging
- **Priority Management** - Task organization

### 🛠️ Productivity Tools
- **Strict Mode** - App blocking for focus
- **Notification System** - Task reminders and alerts
- **Background Service** - Persistent task tracking
- **Fullscreen Reminders** - Focus session management
- **Theme Support** - Dark/Light mode toggle

### 📱 User Experience
- **Onboarding Flow** - Smooth user introduction
- **Responsive Design** - Optimized for all screen sizes
- **Material Design** - Modern, intuitive interface
- **GetX State Management** - Reactive and performant

## 🏗️ Technical Architecture

### **Frontend**
- **Flutter** - Cross-platform mobile development
- **GetX** - State management and routing
- **Material Design** - Google's design system
- **Responsive Layout** - Adaptive UI components

### **Backend**
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - Media and file storage
- **GetStorage** - Local data persistence

### **Services**
- **AuthService** - Authentication management
- **NotificationService** - Push notifications
- **BackgroundService** - Task tracking
- **StrictModeService** - App blocking
- **ThemeController** - UI preferences

## 🚀 Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Firebase account and project setup
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/grim_app.git
   cd grim_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Add `google-services.json` to `android/app/`
   - Configure Firebase Auth and Firestore
   - Set up OAuth for Google Sign-In

4. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Screens & Navigation

### **Authentication Flow**
- **Onboarding** → **Login/Signup** → **Dashboard**
- Seamless user journey with proper error handling
- Route management with GetX navigation

### **Main App Structure**
- **Dashboard** - Central hub for all features
- **Goals** - Create and manage objectives
- **Execution** - Track task completion
- **Analytics** - View progress and insights
- **Settings** - Configure app preferences

## 🔧 Configuration

### **Firebase Setup**
1. Create Firebase project
2. Enable Authentication (Email/Password, Google)
3. Set up Firestore database
4. Configure Android SHA-1 fingerprint
5. Add `google-services.json` to project

### **Environment Variables**
```bash
# Firebase Configuration
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

## 🎯 Future Enhancements

### **Phase 1 - Core Improvements**
- [ ] **Password Reset** - Firebase password recovery flow
- [ ] **Profile Management** - User avatar and info editing
- [ ] **Data Sync** - Enhanced offline/online synchronization
- [ ] **Push Notifications** - Advanced notification system

### **Phase 2 - Advanced Features**
- [ ] **Team Collaboration** - Shared goals and tasks
- [ ] **AI Assistant** - Smart goal suggestions
- [ ] **Voice Commands** - Hands-free task management
- [ ] **Wearable Integration** - Smartwatch support

### **Phase 3 - Platform Expansion**
- [ ] **Web Dashboard** - Desktop productivity interface
- [ ] **Desktop App** - Native Windows/macOS/Linux
- [ ] **API Integration** - Third-party service connections
- [ ] **Advanced Analytics** - Machine learning insights

## 📊 Current Status

### **Completed Features** ✅
- Authentication system (Email + Google)
- Dashboard with quarterly views
- Goal creation and tracking
- Task execution with focus timer
- Basic analytics and progress tracking
- Theme switching (Dark/Light)
- Local data persistence
- Notification system

### **In Development** 🚧
- Enhanced error handling
- Performance optimizations
- UI/UX improvements
- Additional security features

### **Known Issues** 🐛
- Google Sign-In type casting (resolved in v1.2)
- Offline sync improvements needed
- App blocking requires device-specific testing

## 🤝 Contributing

### **Development Guidelines**
1. Follow Flutter and Dart best practices
2. Maintain GetX architecture patterns
3. Write comprehensive tests
4. Document new features thoroughly
5. Use semantic versioning

### **Code Style**
- Use meaningful variable names
- Add comprehensive error handling
- Include user feedback (snackbars)
- Maintain responsive design principles
- Follow Material Design guidelines

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and inquiries:
- Create an issue in the GitHub repository
- Check existing documentation and FAQs
- Review error logs for debugging

---

**GRIM** - *Goal-Driven Productivity* 🎯

*Built with ❤️ using Flutter and Firebase*
