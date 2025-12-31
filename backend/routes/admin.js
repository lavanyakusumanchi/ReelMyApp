const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Reel = require('../models/Reel');
const verifyToken = require('../utils/auth');

// Middleware to check if user is admin
const verifyAdmin = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.userId);
        if (!user || user.role !== 'admin') {
            return res.status(403).json({ message: 'Access denied. Admin only.' });
        }
        next();
    } catch (err) {
        res.status(500).json({ message: 'Server error verifying admin' });
    }
};

// 1. Dashboard Stats
router.get('/stats', verifyToken, verifyAdmin, async (req, res) => {
    try {
        const totalUsers = await User.countDocuments();
        const totalReels = await Reel.countDocuments();
       
        
        // Calculate total views (sum of view_count from all reels)
        const viewsAgg = await Reel.aggregate([
            { $group: { _id: null, total: { $sum: "$view_count" } } }
        ]);
        const totalViews = viewsAgg.length > 0 ? viewsAgg[0].total : 0;

        // Active Today (users created today)
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const activeToday = await User.countDocuments({ createdAt: { $gte: startOfDay } });

        res.json({
            totalUsers,
            totalReels,
            totalViews,
            activeToday
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// 2. User Management
router.get('/users', verifyToken, verifyAdmin, async (req, res) => {
    try {
        const users = await User.find().select('-password').sort({ createdAt: -1 });

        // Enrich with stats
        const enrichedUsers = await Promise.all(users.map(async (user) => {
            const reelsCount = await Reel.countDocuments({ user: user._id });
            return {
                ...user.toObject(),
                reelsCount
            };
        }));

        res.json(enrichedUsers);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

router.post('/users/:id/:action', verifyToken, verifyAdmin, async (req, res) => {
    try {
        const { id, action } = req.params;
        const user = await User.findById(id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        if (action === 'block') {
            user.status = 'blocked';
        } else if (action === 'unblock') {
            user.status = 'active';
        } else if (action === 'delete') {
            await User.findByIdAndDelete(id);
            // Also delete their reels?
            await Reel.deleteMany({ user: id });
            return res.json({ message: 'User and their reels deleted' });
        } else {
            return res.status(400).json({ message: 'Invalid action' });
        }
        await user.save();
        res.json({ message: `User ${action}ed` });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// 3. Reel Moderation
router.get('/reels', verifyToken, verifyAdmin, async (req, res) => {
    try {
        const reels = await Reel.find()
            .populate('user', 'name email profile_pic')
            .sort({ created_at: -1 });
        res.json(reels);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

router.post('/reels/:id/:action', verifyToken, verifyAdmin, async (req, res) => {
    try {
        const { id, action } = req.params;
        const fs = require('fs');
        fs.appendFileSync('debug_id.txt', `[${new Date().toISOString()}] Received ID: "${id}" (Length: ${id.length})\n`);

        const mongoose = require('mongoose');
        if (!mongoose.Types.ObjectId.isValid(id)) {
            console.error(`❌ [AdminAPI] Invalid Reel ID rejected: "${id}"`);
            return res.status(400).json({ message: `Invalid Reel ID: '${id}' (Len: ${id.length})` });
        }

        const reel = await Reel.findById(id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        if (action === 'approve') {
            reel.status = 'active';
        } else if (action === 'reject') {
            reel.status = 'rejected';
        } else if (action === 'delete') {
            await Reel.findByIdAndDelete(id);
            return res.json({ message: 'Reel deleted' });
        } else {
            return res.status(400).json({ message: 'Invalid action' });
        }
        await reel.save();
        res.json({ message: `Reel ${action}d` });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// 4. Global Settings & Danger Zone
const GlobalSettings = require('../models/GlobalSettings');

// Get Settings
router.get('/settings', verifyToken, verifyAdmin, async (req, res) => {
    try {
        let settings = await GlobalSettings.findOne();
        if (!settings) {
            settings = await new GlobalSettings().save();
        }
        res.json(settings);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Update Settings
router.put('/settings', verifyToken, verifyAdmin, async (req, res) => {
    try {
        const settings = await GlobalSettings.findOneAndUpdate({}, req.body, { new: true, upsert: true });
        res.json(settings);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Danger: Clear Reels
router.delete('/danger/reels', verifyToken, verifyAdmin, async (req, res) => {
    try {
        await Reel.deleteMany({});
        res.json({ message: 'All reels deleted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Danger: Reset Users
router.delete('/danger/users', verifyToken, verifyAdmin, async (req, res) => {
    try {
        // Delete all except admins
        await User.deleteMany({ role: { $ne: 'admin' } });
        // Also delete their reels
        await Reel.deleteMany({});
        res.json({ message: 'All users and data deleted (except admins)' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
