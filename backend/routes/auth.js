const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your_super_see7899c79fdfa235cb35d74276f02a53f0834667a5692ba586ab4fed1c30e67a2c5def0fca4bab7320b0ada5848eeff546522f17ea89365f6af0b6402ff10727e';


router.use((req, res, next) => {
    console.log(`🔹 AUTH ROUTE HIT: ${req.method} ${req.path}`);
    next();
});

const verifyToken = (req, res, next) => {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ message: 'Access Denied: No Token Provided' });

    try {
        const verified = jwt.verify(token, JWT_SECRET);
        req.user = verified;
        next();
    } catch (err) {
        res.status(400).json({ message: 'Invalid Token' });
    }
};


router.get('/me', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.userId || req.user.id).select('-password'); // Exclude password
        if (!user) return res.status(404).json({ message: 'User not found' });
        const reelCount = await require('../models/Reel').countDocuments({ user: req.user.userId || req.user.id });
        const userObj = user.toObject();
        userObj.reel_count = reelCount;
        res.json(userObj);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

// GET SAVED REELS
router.get('/saved-reels', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.userId || req.user.id)
            .populate({
                path: 'savedReels',
                populate: { path: 'user', select: 'name' }
            });

        if (!user) return res.status(404).json({ message: 'User not found' });

        // Filter out nulls (in case a reel was deleted)
        const reels = user.savedReels.filter(reel => reel !== null);

        res.json(reels);
    } catch (error) {
        console.error("Get Saved Reels Error:", error);
        res.status(500).json({ message: 'Server Error' });
    }
});

// UPDATE PASSWORD (Logged In User)
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Multer Config for Profile Pics
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dest = 'uploads/avatars';
        if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
        cb(null, dest);
    },
    filename: (req, file, cb) => {
        cb(null, `${req.user.userId}_${Date.now()}${path.extname(file.originalname)}`);
    }
});
const upload = multer({ storage });

// UPDATE PROFILE
router.put('/profile', verifyToken, upload.single('profile_pic'), async (req, res) => {
    try {
        const userId = req.user.userId || req.user.id;
        const { name, email } = req.body;
        const user = await User.findById(userId);

        if (!user) return res.status(404).json({ message: 'User not found' });

        if (name) user.name = name;
        if (email) user.email = email.toLowerCase();

        if (req.file) {
            // Delete old avatar if exists and not external url
            if (user.profile_pic && !user.profile_pic.startsWith('http') && fs.existsSync(user.profile_pic.substring(1))) { // Remove leading slash
                try {
                    fs.unlinkSync(user.profile_pic.substring(1));
                } catch (e) { console.error("Error deleting old avatar:", e); }
            }
            user.profile_pic = `/uploads/avatars/${req.file.filename}`;
        }

        await user.save();

        res.json({
            message: 'Profile updated successfully',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                profile_pic: user.profile_pic
            }
        });

    } catch (error) {
        console.error("Update Profile Error:", error);
        res.status(500).json({ message: 'Server Error' });
    }
});

router.post('/update-password', verifyToken, async (req, res) => {
    try {
        const { password, oldPassword } = req.body;

        if (!password || password.length < 8) {
            return res.status(400).json({ message: 'New password must be at least 8 characters long' });
        }

        const user = await User.findById(req.user.userId || req.user.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // If user HAS set a password before, they MUST provide the old one
        if (user.hasSetPassword) {
            if (!oldPassword) {
                return res.status(400).json({ message: 'Please provide your current password' });
            }
            const isMatch = await bcrypt.compare(oldPassword, user.password);
            if (!isMatch) {
                return res.status(400).json({ message: 'Incorrect current password' });
            }
        }

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(password, salt);

        // Mark as set
        user.hasSetPassword = true;

        // Reset lock status
        user.failedLoginAttempts = 0;
        user.lockUntil = null;

        await user.save();
        res.json({ message: 'Password updated successfully' });

    } catch (error) {
        console.error("Update Password Error:", error);
        res.status(500).json({ message: 'Server Error' });
    }
});
router.post('/signup', async (req, res) => {
    console.log('🔹 Signup Request Received:', req.body);
    try {
        const { name, email, password } = req.body;

        // Trim password to avoid whitespace issues
        const trimmedPassword = password ? password.trim() : '';
        const trimmedEmail = email ? email.trim().toLowerCase() : '';

        if (!name || !trimmedEmail || !trimmedPassword) {
            console.log('❌ Signup Failed: Missing fields');
            return res.status(400).json({ message: 'Please fill in all fields' });
        }

        // Password strength check (regex matches frontend: 1 upper, 1 lower, 1 num, 1 special)
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;
        if (!passwordRegex.test(password)) {
            console.log('❌ Signup Failed: Weak password', password);
            return res.status(400).json({ message: 'Password does not meet complexity requirements' });
        }

        // Check if user exists
        const existingUser = await User.findOne({ email: trimmedEmail });
        if (existingUser) {
            console.log('❌ Signup Failed: Email already exists:', trimmedEmail);
            return res.status(400).json({ message: 'Email already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(trimmedPassword, salt);

        // Create user
        const newUser = new User({
            name,
            email: trimmedEmail,
            password: hashedPassword,
            hasSetPassword: true
        });

        const savedUser = await newUser.save();
        console.log('✅ Signup Successful. User ID:', savedUser._id);
        console.log('✅ User saved to collection:', User.collection.name);

        res.status(201).json({ message: 'User registered successfully' });

    } catch (error) {
        console.error('Signup Error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// LOGIN
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const trimmedEmail = email ? email.trim().toLowerCase() : '';

        if (!trimmedEmail || !password) {
            return res.status(400).json({ message: 'Please provide email and password' });
        }

        const user = await User.findOne({ email: trimmedEmail });

        // Check lock
        if (user && user.lockUntil && user.lockUntil > Date.now()) {
            return res.status(403).json({ message: 'Account is temporarily locked. Try again later.' });
        }

        // Check if Blocked
        if (user && user.status === 'blocked') {
            return res.status(403).json({ message: 'Your account has been blocked by an admin.' });
        }

        if (!user) {
            // Specific error code for frontend to detect
            // 404 Not Found is appropriate for "User not found"
            return res.status(404).json({ message: 'User not found. Please create an account.' });
        }

        // Check password
        const trimmedPassword = password ? password.trim() : '';
        const isMatch = await bcrypt.compare(trimmedPassword, user.password);

        console.log(`🔹 Login Attempt for ${trimmedEmail}:`);
        console.log(`   - Input Password Length: ${trimmedPassword.length}`);
        console.log(`   - Stored Hash: ${user.password}`);
        console.log(`   - Comparison Result: ${isMatch}`);

        if (!isMatch) {
            // Increment failed attempts
            user.failedLoginAttempts += 1;

            // Lock if 5 failed attempts
            if (user.failedLoginAttempts >= 5) {
                user.lockUntil = Date.now() + 15 * 60 * 1000; // 15 minutes
                user.failedLoginAttempts = 0; // Reset after locking
                await user.save();
                return res.status(403).json({ message: 'Too many failed attempts. Account locked for 15 minutes.' });
            }

            await user.save();
            return res.status(400).json({ message: 'Invalid email or password' });
        }

        // Reset failed attempts on success
        user.failedLoginAttempts = 0;
        user.lockUntil = null;
        await user.save();

        // Generate JWT
        const token = jwt.sign(
            { userId: user._id, email: user.email },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                profile_pic: user.profile_pic,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// GOOGLE LOGIN (Auto-create if not exists)
router.post('/google-login', async (req, res) => {
    console.log('🔹 Google Login Request Body:', req.body);
    try {
        const { email, name, googleId } = req.body; // googleId not strictly needed if we trust the email from client (insecure for prod, okay for MVP)

        if (!email) {
            return res.status(400).json({ message: 'Email is required' });
        }

        let user = await User.findOne({
            $or: [
                { googleId: googleId },
                { email: email.toLowerCase() }
            ]
        });

        if (user && user.status === 'blocked') {
            return res.status(403).json({ message: 'Your account has been blocked by an admin.' });
        }

        if (!user) {
            console.log('🔹 Creating NEW User from Google...');

            // Generate a random password since they use Google
            const randomPassword = Math.random().toString(36).slice(-8) + 'A1!';
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(randomPassword, salt);

            user = new User({
                name: name || 'Google User',
                email: email.toLowerCase(),
                password: hashedPassword,
                googleId: googleId,
                hasSetPassword: false
            });
            await user.save();
            console.log('✅ NEW Google User Saved to DB:', user.email);
        } else if (!user.googleId && googleId) {
            console.log('🔹 Linking Google ID to EXISTING User...');
            // Link googleId to existing user if not present
            user.googleId = googleId;
            await user.save();
            console.log('✅ User Updated with Google ID:', user.email);
        } else {
            console.log('🔹 User already exists and is linked. Logging in:', user.email);
        }

        // Generate JWT
        const token = jwt.sign(
            { userId: user._id, email: user.email },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            message: 'Google login successful',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                profile_pic: user.profile_pic,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Google Login Error:', error);
        res.status(500).json({ message: 'Server error during Google auth' });
    }
});

// FORGOT PASSWORD
// SEND OTP
router.post('/send-otp', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            // Return success even if not found to prevent enumeration
            return res.json({ message: 'OTP sent if email exists' });
        }

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        user.otp = otp;
        user.otpExpires = Date.now() + 2 * 60 * 1000; // 2 Minutes
        user.otpAttempts = 0;
        await user.save();

        const nodemailer = require('nodemailer');
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS
            }
        });

        const mailOptions = {
            from: `"ReelMyApp" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'ReelMyApp - Password Reset OTP',
            html: `
                <h3>Password Reset Request</h3>
                <p>Your verification code is:</p>
                <h1 style="color: #6C63FF; letter-spacing: 5px;">${otp}</h1>
                <p>This code expires in 2 minutes.</p>
                <p>If you did not request this, please ignore this email.</p>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log(`✅ OTP sent to ${email}`);

        res.json({ message: 'OTP sent successfully' });

    } catch (error) {
        console.error('Send OTP Error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// VERIFY OTP
router.post('/verify-otp', async (req, res) => {
    try {
        const { email, otp } = req.body;
        if (!email || !otp) return res.status(400).json({ message: 'Email and OTP required' });

        const user = await User.findOne({ email: email.toLowerCase() }).select('+otp');
        if (!user) return res.status(400).json({ message: 'Invalid Request' });

        if (user.otpAttempts >= 5) {
            return res.status(400).json({ message: 'Too many attempts. Please request a new OTP.' });
        }

        if (user.otp !== otp) {
            user.otpAttempts += 1;
            await user.save();
            return res.status(400).json({ message: 'Invalid OTP' });
        }

        if (user.otpExpires < Date.now()) {
            return res.status(400).json({ message: 'OTP Expired' });
        }

        res.json({ message: 'OTP Verified' });

    } catch (error) {
        console.error('Verify OTP Error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// GET: Serve Simple HTML Form for Reset Password
router.get('/reset-password-page', (req, res) => {
    const { token } = req.query;
    if (!token) return res.send("Invalid Token");

    // Simple HTML form
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Reset Password</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { background-color: #121212; color: white; font-family: 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                form { background: #1E1E2E; padding: 30px; border-radius: 12px; width: 90%; max-width: 400px; box-shadow: 0 8px 20px rgba(0,0,0,0.5); }
                .input-group { margin-bottom: 15px; position: relative; }
                label { display: block; margin-bottom: 5px; color: #ccc; font-size: 0.9em; }
                input { width: 100%; padding: 12px; padding-right: 40px; border: 1px solid #444; border-radius: 6px; background: #2A2A3A; color: white; box-sizing: border-box; font-size: 16px; transition: border-color 0.3s; }
                input:focus { border-color: #6C63FF; outline: none; }
                .toggle-password { position: absolute; right: 10px; top: 38px; cursor: pointer; color: #888; }
                button { width: 100%; padding: 12px; background: linear-gradient(135deg, #2E8AF6, #6C63FF); color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; font-size: 16px; margin-top: 10px; transition: opacity 0.3s; }
                button:hover { opacity: 0.9; }
                h2 { text-align: center; margin-bottom: 25px; color: #fff; }
                .error { color: #ff5555; font-size: 0.85em; margin-top: 5px; display: none; }
            </style>
        </head>
        <body>
            <form action="/api/auth/reset-password" method="POST" onsubmit="return validateForm()">
                <h2>Reset Password</h2>
                <input type="hidden" name="token" value="${token}" />
                
                <div class="input-group">
                    <label>New Password</label>
                    <input type="password" id="password" name="password" placeholder="Min 8 chars, 1 upper, 1 lower, 1 num, 1 special" required />
                    <span class="toggle-password" onclick="togglePwd('password', 'icon1')">
                        <svg id="icon1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </span>
                    <div id="pwdError" class="error">Password must be strong (8+ chars, uppercase, number, special)</div>
                </div>

                <div class="input-group">
                    <label>Confirm Password</label>
                    <input type="password" id="confirmPassword" placeholder="Re-enter password" required />
                    <span class="toggle-password" onclick="togglePwd('confirmPassword', 'icon2')">
                         <svg id="icon2" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </span>
                    <div id="matchError" class="error">Passwords do not match</div>
                </div>

                <button type="submit">Update Password</button>
            </form>

            <script>
                function togglePwd(inputId, iconId) {
                    const input = document.getElementById(inputId);
                    const icon = document.getElementById(iconId);
                    if (input.type === "password") {
                        input.type = "text";
                        // Change to Eye Off Icon
                        icon.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07-2.3 2.3"></path><line x1="1" y1="1" x2="23" y2="23"></line>';
                    } else {
                        input.type = "password";
                        // Change back to Eye Icon
                        icon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>';
                    }
                }

                function validateForm() {
                    const pwd = document.getElementById('password').value;
                    const confirm = document.getElementById('confirmPassword').value;
                    const pwdError = document.getElementById('pwdError');
                    const matchError = document.getElementById('matchError');
                    let isValid = true;

                    // Reset errors
                    pwdError.style.display = 'none';
                    matchError.style.display = 'none';

                    // Strong Password Regex
                    const strongRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{8,}$/;
                    if (!strongRegex.test(pwd)) {
                        pwdError.style.display = 'block';
                        isValid = false;
                    }

                    if (pwd !== confirm) {
                        matchError.style.display = 'block';
                        isValid = false;
                    }

                    return isValid;
                }
            </script>
        </body>
        </html>
    `);
});

// POST: Handle the password update
// RESET PASSWORD WITH OTP
router.post('/reset-password-with-otp', async (req, res) => {
    try {
        const { email, otp, password } = req.body;

        if (!email || !otp || !password) return res.status(400).json({ message: "Missing fields" });

        const user = await User.findOne({ email: email.toLowerCase() }).select('+otp');
        if (!user) return res.status(400).json({ message: "User not found" });

        // Validate OTP Again (Security)
        if (user.otp !== otp || user.otpExpires < Date.now()) {
            return res.status(400).json({ message: "Invalid or expired OTP" });
        }

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(password, salt);

        // Mark as set
        user.hasSetPassword = true;

        // Clear OTP
        user.otp = undefined;
        user.otpExpires = undefined;
        user.otpAttempts = 0;

        // Clear locks
        user.failedLoginAttempts = 0;
        user.lockUntil = null;

        await user.save();

        // Send Confirmation Email
        try {
            const nodemailer = require('nodemailer');
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
            });
            await transporter.sendMail({
                from: `"ReelMyApp" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: 'Password Changed Successfully',
                html: `<h3>Your password has been changed successfully.</h3><p>If this wasn't you, please contact support immediately.</p>`
            });
        } catch (e) {
            console.error("Confirmation email failed:", e);
        }

        res.json({ message: "Password reset successfully" });

    } catch (error) {
        console.error("Reset Error:", error);
        res.status(500).json({ message: "Server error" });
    }
});



module.exports = router;
