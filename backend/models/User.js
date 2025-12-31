const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        minlength: 2
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    profile_pic: {
        type: String,
        default: ''
    },
    role: {
        type: String,
        enum: ['user', 'admin'],
        default: 'user'
    },
    status: {
        type: String,
        enum: ['active', 'blocked'],
        default: 'active'
    },
    password: {
        type: String,
        required: true,
        minlength: 8
    },
    failedLoginAttempts: {
        type: Number,
        default: 0
    },
    lockUntil: {
        type: Number
    },
    googleId: {
        type: String,
        unique: true,
        sparse: true
    },
    // OTP Fields for Forgot Password
    otp: {
        type: String,
        select: false // Don't return by default
    },
    otpExpires: {
        type: Date
    },
    otpAttempts: {
        type: Number,
        default: 0
    },
    hasSetPassword: {
        type: Boolean,
        default: false
    },
    savedReels: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reel'
    }],
    searchHistory: [{
        query: String,
        timestamp: { type: Date, default: Date.now }
    }]
}, { timestamps: true });

// Text Index for User Search
userSchema.index({ name: 'text', email: 'text' });

module.exports = mongoose.model('User', userSchema);
