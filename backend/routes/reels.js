const express = require('express');
const router = express.Router();
const Reel = require('../models/Reel');
const User = require('../models/User'); // Ensure User model is imported
const verifyToken = require('../utils/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { generateVideoFromImages } = require('../utils/videoGenerator');
const { deleteFile } = require('../utils/fileCleaner');

// Multer setup
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        let uploadPath = 'uploads/';
        if (file.fieldname === 'audio') uploadPath += 'audio/';
        else if (file.fieldname === 'logo') uploadPath += 'images/';
        else if (file.fieldname === 'images') uploadPath += 'images/';
        else if (file.fieldname === 'video') uploadPath += 'videos/';
        else if (file.fieldname === 'thumbnail') uploadPath += 'thumbnails/';

        // Create directory if it doesn't exist
        fs.mkdirSync(uploadPath, { recursive: true });
        cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({ storage });

// @route   POST /api/reels/generate
// @desc    Generate a reel from images/audio
router.post('/generate', verifyToken, upload.fields([
    { name: 'images', maxCount: 10 },
    { name: 'audio', maxCount: 1 },
    { name: 'logo', maxCount: 1 }
]), async (req, res) => {
    try {
        const { title, link, description, category } = req.body;
        const images = req.files['images'] ? req.files['images'].map(f => f.path) : [];
        const audio = req.files['audio'] ? req.files['audio'][0].path : null;
        const logo = req.files['logo'] ? req.files['logo'][0].path : null;

        if (images.length === 0) {
            return res.status(400).json({ message: 'At least one image is required.' });
        }

        const outputPath = `uploads/generated/reel_${Date.now()}.mp4`;
        fs.mkdirSync('uploads/generated', { recursive: true });

        // Generate video
        await generateVideoFromImages(images, audio, outputPath);

        // Create thumbnail (mock for now or use frame extraction if needed, let's just use first image or default)
        // For simplicity, re-use first image as thumbnail or a placeholder
        // In real app, use ffmpeg to extract frame.
        // Let's copy first image to strict thumbnail path
        let thumbPath = images[0];


        // Don't save to DB yet. Just return the paths.
        // The frontend will download this, and then call /create to upload/save officially.

        res.json({
            success: true,
            videoUrl: outputPath,
            thumbnailUrl: thumbPath
        });

    } catch (err) {
        console.error('Generation Error:', err);
        res.status(500).json({ message: err.message || 'Error generating reel' });
    }
});

// @route   POST /api/reels/create
// @desc    Upload a new reel
router.post('/create', verifyToken, upload.fields([
    { name: 'video', maxCount: 1 },
    { name: 'thumbnail', maxCount: 1 },
    { name: 'logo', maxCount: 1 }
]), async (req, res) => {
    try {
        const { title, description, category, link, is_paid, price, is_single_image } = req.body;

        if (!req.files || !req.files['video'] || !req.files['thumbnail']) {
            return res.status(400).json({ message: 'Video and Thumbnail are required' });
        }

        const videoPath = req.files['video'][0].path;
        const thumbnailPath = req.files['thumbnail'][0].path;
        const logoPath = req.files['logo'] ? req.files['logo'][0].path : null;

        const newReel = new Reel({
            user: req.user.id || req.user.userId,
            title,
            description,
            category: category || 'General',
            video_url: videoPath,
            thumbnail_url: thumbnailPath,
            logo_url: logoPath,
            app_link: link,
            is_paid: is_paid === 'true' || is_paid === true,
            price: price ? parseFloat(price) : 0,
            is_single_image: is_single_image === 'true' || is_single_image === true
        });

        await newReel.save();
        res.json(newReel);

    } catch (err) {
        console.error('Upload Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/reels/feed
// @desc    Get all active reels
router.get('/feed', async (req, res) => {
    try {
        const reels = await Reel.find({ status: 'active' }).sort({ created_at: -1 });
        res.json(reels);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/reels/search/trending
// @desc    Get trending tags/categories
router.get('/search/trending', async (req, res) => {
    try {
        // Mock data or aggregate from DB
        res.json(['Viral', 'Comedy', 'Technology', 'Food', 'Travel']);
    } catch (err) {
        console.error('Trending Error:', err);
        res.status(500).json([]);
    }
});

// @route   GET /api/reels/search/suggestions
// @desc    Get search suggestions
router.get('/search/suggestions', async (req, res) => {
    try {
        const query = req.query.q;
        if (!query) return res.json([]);

        const regex = new RegExp(query, 'i');
        const reels = await Reel.find({ title: regex }).limit(5).select('title thumbnail_url');

        const suggestions = reels.map(r => ({
            text: r.title,
            type: 'reel',
            image: r.thumbnail_url
        }));

        res.json(suggestions);
    } catch (err) {
        console.error('Suggestions Error:', err);
        res.json([]);
    }
});

// @route   GET /api/reels/search
// @desc    Search reels by title, category, or description
router.get('/search', async (req, res) => {
    try {
        console.log('🔍 [API] Search V2 Hit');
        const query = req.query.q;
        const category = req.query.category;

        let filter = { status: 'active' }; // Only show active reels

        // Text Search
        if (query) {
            const regex = new RegExp(query, 'i'); // Case insensitive
            if (query.toLowerCase() === 'free') {
                filter.is_paid = false;
            } else if (query.toLowerCase() === 'paid') {
                filter.is_paid = true;
            } else {
                filter.$or = [
                    { title: regex },
                    { description: regex },
                    { category: regex },
                    { app_link: regex }
                ];
            }
        }

        // Category Filter
        if (category && category !== 'All') {
            filter.category = category;
        }

        const reels = await Reel.find(filter).sort({ created_at: -1 });

        res.json({
            results: reels,
            isFallback: false,
            message: reels.length === 0 ? 'No results found' : 'Success'
        });
    } catch (err) {
        console.error('Search Reels Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/reels/my-reels
// @desc    Get user's reels
router.get('/my-reels', verifyToken, async (req, res) => {
    try {
        const userId = req.user.id || req.user.userId;
        const reels = await Reel.find({ user: userId }).sort({ created_at: -1 });
        res.json(reels);
    } catch (err) {
        console.error('Fetch My Reels Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/reels/user/:id
// @desc    Get reels by specific user ID (Public or Admin)
router.get('/user/:id', verifyToken, async (req, res) => {
    try {
        const targetUserId = req.params.id;

        // Validation to prevent CastError crashing the server
        const mongoose = require('mongoose');
        if (!mongoose.Types.ObjectId.isValid(targetUserId)) {
            console.error(`❌ [API] Invalid User ID requested: ${targetUserId}`);
            return res.status(400).json({ message: 'Invalid User ID format' });
        }

        console.log(`🔍 [API] Fetching reels for UserID: "${targetUserId}"`);
        const query = { user: targetUserId };
        const reels = await Reel.find(query).sort({ created_at: -1 });

        console.log(`✅ [API] Found ${reels.length} reels for user ${targetUserId}`);
        // Log first reel's user field for comparison if exists
        if (reels.length > 0) {
            console.log(`   First match user field: "${reels[0].user}"`);
        } else {
            // Debug: check if ANY reels exist
            const totalReels = await Reel.countDocuments({});
            console.log(`   (Debug: Total reels in DB: ${totalReels}. Why no match?)`);
        }

        res.json(reels);
    } catch (err) {
        console.error('Fetch User Reels Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   DELETE /api/reels/:id
// @desc    Delete a reel
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        console.log(`🗑️ [DELETE] Request to delete reel: ${req.params.id}`);
        console.log(`   User requesting:`, req.user);

        const reel = await Reel.findById(req.params.id);
        if (!reel) {
            console.log('   ❌ Reel not found');
            return res.status(404).json({ message: 'Reel not found' });
        }

        console.log(`   Reel owner: ${reel.user}`);
        const requestingUserId = req.user.id || req.user.userId || req.user._id;
        console.log(`   Requesting User ID: ${requestingUserId}`);

        // Check user
        if (reel.user.toString() !== requestingUserId) {
            console.log('   ⛔ Not authorized');
            return res.status(401).json({ message: 'Not authorized' });
        }

        // Delete files
        deleteFile(reel.video_url);
        deleteFile(reel.thumbnail_url);
        if (reel.logo_url) deleteFile(reel.logo_url);

        await reel.deleteOne();
        console.log('   ✅ Reel deleted successfully');

        res.json({ message: 'Reel removed' });
    } catch (err) {
        console.error('Delete Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   POST /api/reels/:id/like
// @desc    Toggle like a reel
router.post('/:id/like', verifyToken, async (req, res) => {
    try {
        const reel = await Reel.findById(req.params.id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        const userId = req.user.id || req.user.userId;
        const index = reel.liked_by.indexOf(userId);

        if (index === -1) {
            // Like
            reel.liked_by.push(userId);
            reel.like_count += 1;
        } else {
            // Unlike
            reel.liked_by.splice(index, 1);
            reel.like_count = Math.max(0, reel.like_count - 1);
        }

        await reel.save();
        res.json({
            success: true,
            likes: reel.like_count,
            is_liked: index === -1
        });

    } catch (err) {
        console.error('Like Toggle Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   POST /api/reels/:id/save
// @desc    Toggle save reel for user
router.post('/:id/save', verifyToken, async (req, res) => {
    try {
        const reelId = req.params.id;
        const userId = req.user.id || req.user.userId;

        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Ensure savedReels is initialized
        if (!user.savedReels) user.savedReels = [];

        const index = user.savedReels.indexOf(reelId);
        let isSaved = false;

        if (index === -1) {
            // Save
            user.savedReels.push(reelId);
            isSaved = true;
        } else {
            // Unsave
            user.savedReels.splice(index, 1);
            isSaved = false;
        }

        await user.save();

        console.log(`💾 [REELS] Reel ${reelId} save status toggled to: ${isSaved} for user ${user.email}`);

        res.json({
            success: true,
            saved: isSaved
        });

    } catch (err) {
        console.error('Save Toggle Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   POST /api/reels/:id/comments
// @desc    Add a comment to a reel
router.post('/:id/comments', verifyToken, async (req, res) => {
    try {
        const reel = await Reel.findById(req.params.id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        const user = await User.findById(req.user.id || req.user.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const newComment = {
            userId: user._id,
            userName: user.name, // Store name for display
            userProfilePic: user.profile_pic,
            text: req.body.text,
            createdAt: new Date()
        };

        // Add to comments array
        reel.comments.unshift(newComment);

        // Update comment count
        reel.comment_count = reel.comments.length;

        await reel.save();

        const addedComment = reel.comments[0];

        res.json({
            _id: addedComment._id,
            reel_id: reel._id,
            user_id: user._id,
            user_name: user.name,
            text: addedComment.text,
            created_at: addedComment.createdAt
        });

    } catch (err) {
        console.error('Add Comment Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   POST /api/reels/:id/comments/:commentId/like
// @desc    Toggle like on a comment
router.post('/:id/comments/:commentId/like', verifyToken, async (req, res) => {
    try {
        const reel = await Reel.findById(req.params.id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        const comment = reel.comments.id(req.params.commentId);
        if (!comment) return res.status(404).json({ message: 'Comment not found' });

        const userId = req.user.id || req.user.userId;

        // Initialize if undefined (for old comments)
        if (!comment.likedBy) comment.likedBy = [];
        if (!comment.likes) comment.likes = 0;

        const index = comment.likedBy.indexOf(userId);

        if (index === -1) {
            // Like
            comment.likedBy.push(userId);
            comment.likes += 1;
        } else {
            // Unlike
            comment.likedBy.splice(index, 1);
            comment.likes = Math.max(0, comment.likes - 1);
        }

        await reel.save();

        res.json({
            success: true,
            likes: comment.likes,
            is_liked: index === -1
        });

    } catch (err) {
        console.error('Comment Like Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/reels/:id/comments
// @desc    Get comments for a reel
router.get('/:id/comments', async (req, res) => {
    try {
        const reel = await Reel.findById(req.params.id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        // Check for current user (optional - require auth middleware if we want is_liked)
        // But this is a public GET? Usually we need token to know is_liked.
        // For simplicity, we won't correct is_liked unless user sends header?
        // Let's assume we can't easily know is_liked without auth check here.
        // We'll update verifyToken later if strictly needed, or just return empty for unauth.

        // Actually, let's verify token OPTIONALLY or handle it. 
        // For now, simpler: The frontend calls this without token usually? 
        // Let's rely on frontend sending it.
        // Quick fix: user sending token in header enables is_liked check?
        // We will just return the list.

        const comments = reel.comments.map(c => ({
            id: c._id,
            reel_id: reel._id,
            user_id: c.userId,
            user_name: c.userName,
            user_profile_pic: c.userProfilePic,
            text: c.text,
            created_at: c.createdAt,
            likes: c.likes || 0,
            liked_by: c.likedBy || [] // Frontend can check if it contains their ID
        }));

        comments.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

        res.json(comments);
    } catch (err) {
        console.error('Fetch Comments Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/reels/test-ffmpeg
// @desc    Test if ffmpeg is working
router.get('/test-ffmpeg', async (req, res) => {
    try {
        const { path: ffmpegPath } = require('@ffmpeg-installer/ffmpeg');
        const { path: ffprobePath } = require('ffprobe-static');
        const { execSync } = require('child_process');

        const results = {
            ffmpegExists: fs.existsSync(ffmpegPath),
            ffprobeExists: fs.existsSync(ffprobePath),
            ffmpegPath,
            ffprobePath,
            ffmpegVersion: 'N/A',
            ffprobeVersion: 'N/A'
        };

        if (results.ffmpegExists) {
            results.ffmpegVersion = execSync(`"${ffmpegPath}" -version`).toString().split('\n')[0];
        }
        if (results.ffprobeExists) {
            results.ffprobeVersion = execSync(`"${ffprobePath}" -version`).toString().split('\n')[0];
        }

        res.json(results);
    } catch (err) {
        console.error('FFmpeg Test Error:', err);
        res.status(500).json({ message: 'Server Error', error: err.message });
    }
});

// @route   DELETE /api/reels/:id/comments/:commentId
// @desc    Delete a comment
router.delete('/:id/comments/:commentId', verifyToken, async (req, res) => {
    try {
        const reel = await Reel.findById(req.params.id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        const comment = reel.comments.id(req.params.commentId);
        if (!comment) return res.status(404).json({ message: 'Comment not found' });

        const userId = req.user.id || req.user.userId;

        // Check ownership: Comment Author OR Reel Owner
        if (comment.userId.toString() !== userId && reel.user.toString() !== userId) {
            return res.status(401).json({ message: 'Not authorized to delete this comment' });
        }

        // Remove comment
        // Mongoose Array.pull or id().remove() 
        // Note: subdoc.remove() is deprecated in newer Mongoose, use parent.comments.pull({_id: ...})
        reel.comments.pull({ _id: req.params.commentId });

        // Update count
        reel.comment_count = reel.comments.length;

        await reel.save();

        res.json({ success: true, message: 'Comment deleted' });

    } catch (err) {
        console.error('Delete Comment Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

module.exports = router;