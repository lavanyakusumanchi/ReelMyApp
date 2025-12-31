
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

        // Return the new comment with ID (mongoose adds _id by default to subdocs if configured, but let's ensure we return what flutter needs)
        // Flutter model expects: id, reelId, userId, userName, text, createdAt
        // We'll return the last added comment (first in array)

        const addedComment = reel.comments[0];

        res.json({
            _id: addedComment._id,
            reelId: reel._id,
            userId: user._id,
            userName: user.name,
            text: addedComment.text,
            timestamp: addedComment.createdAt // Flutter expects 'createdAt' or 'timestamp'? Model says createdAt. Adapter handles it?
            // Let's check Comment model.
        });

    } catch (err) {
        console.error('Add Comment Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/reels/:id/comments
// @desc    Get comments for a reel
router.get('/:id/comments', async (req, res) => {
    try {
        const reel = await Reel.findById(req.params.id);
        if (!reel) return res.status(404).json({ message: 'Reel not found' });

        // Sort by newest first
        res.json(reel.comments);
    } catch (err) {
        console.error('Fetch Comments Error:', err);
        res.status(500).json({ message: 'Server Error' });
    }
});
