const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5001;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/reelmyapps';

process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ [CRITICAL] Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (err) => {
    console.error('❌ [CRITICAL] Uncaught Exception:', err);
    
});


app.use(cors());
app.use((req, res, next) => {
    console.log(`📡 [${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies (HTML forms)
app.use(express.json());


const path = require('path');

// Enhanced static file serving for videos with proper headers
app.use('/uploads', (req, res, next) => {
    // Log all upload requests for debugging
    console.log(`📁 [UPLOAD] ${req.method} ${req.url}`);
    if (req.headers.range) {
        console.log(`   - Range: ${req.headers.range}`);
    }
    next();
}, express.static(path.join(__dirname, 'uploads'), {
    setHeaders: (res, filePath) => {
        if (filePath.endsWith('.mp4')) {
            res.setHeader('Content-Type', 'video/mp4');
        }
        res.setHeader('Access-Control-Allow-Origin', '*');
    }
}));

// Database Connection
console.log('📡 [DB] Attempting to connect to:', MONGODB_URI.split('@')[1] || MONGODB_URI); // Log only host if possible
mongoose.connect(MONGODB_URI, {
    socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
})
    .then(() => {
        console.log('✅ Connected to MongoDB');
        console.log('📡 [DB] Database Name:', mongoose.connection.name);
    })
    .catch(err => {
        console.error('❌ Initial MongoDB connection error:', err);
    });

// Monitor runtime connection errors
mongoose.connection.on('error', err => {
    console.error('❌ MongoDB runtime error:', err);
});

mongoose.connection.on('disconnected', () => {
    console.warn('⚠️ MongoDB disconnected. Attempting to reconnect...');
});

mongoose.connection.on('reconnected', () => {
    console.log('✅ MongoDB reconnected');
});

// Routes
const authRoutes = require('./routes/auth');
const reelRoutes = require('./routes/reels');
app.use('/api/auth', authRoutes);
const chatRoutes = require('./routes/chat');
app.use('/api/reels', reelRoutes);
app.use('/api/chats', chatRoutes);
const adminRoutes = require('./routes/admin');
app.use('/api/admin', adminRoutes);

const searchRoutes = require('./routes/search');
app.use('/api/search', searchRoutes);

app.get('/', (req, res) => {
    res.send('ReelFlow Backend is running');
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
});
