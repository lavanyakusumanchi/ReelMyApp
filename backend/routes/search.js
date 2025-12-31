const express = require('express');
const router = express.Router();
const Reel = require('../models/Reel');
const User = require('../models/User');
const { expandQuery } = require('../utils/video_synonyms');

// Helper to escape regex special characters
function escapeRegex(text) {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
}

/**
 * @route   GET /api/search
 * @desc    Main search endpoint with semantic features, filters, and fallback.
 * @access  Public (Optional Auth for personalization in future)
 */
router.get('/', async (req, res) => {
    try {
        let { q, category, minDuration, maxDuration, sort } = req.query;
        let queryObj = { status: 'active' };

        // 0. Pre-process Query for Paid/Free
        if (q) {
            const lowerQ = q.toLowerCase();
            if (lowerQ.includes('paid')) {
                queryObj.is_paid = true;
                q = q.replace(/paid/gi, '').trim(); // Remove 'paid' from text search
            } else if (lowerQ.includes('free')) {
                queryObj.is_paid = false;
                q = q.replace(/free/gi, '').trim(); // Remove 'free' from text search
            }
        }

        // 1. Semantic Expansion
        let allTerms = [];
        if (q) {
            allTerms = expandQuery(q);
        }

        // 2. Build MongoDB Query
        if (allTerms.length > 0) {
            const regexQueries = allTerms.map(term => new RegExp(escapeRegex(term), 'gi'));

            queryObj.$or = [
                { title: { $in: regexQueries } },
                { description: { $in: regexQueries } },
                { category: { $in: regexQueries } },
                { tags: { $in: regexQueries } },
                { 'product.brand': { $in: regexQueries } }
            ];
        }

        // 3. Apply Filters
        if (category && category !== 'All') {
            const categoryMap = {
                'Tech': ['Technology', 'Tech', 'Computing'],
                'Food': ['Foodi', 'Food', 'Cooking'],
                'Travel': ['Travel', 'Places'],
                'Business': ['Business', 'Startup'],
                'Gaming': ['Gaming', 'Games'],
                'Fashion': ['Fashion', 'Style']
            };

            if (categoryMap[category]) {
                queryObj.category = { $in: categoryMap[category] };
            } else {
                queryObj.category = category;
            }
        }

        // 4. Sorting logic
        let sortOption = { created_at: -1 };
        if (sort === 'most_liked') sortOption = { like_count: -1 };
        if (sort === 'most_viewed') sortOption = { view_count: -1 };

        // 5. Execute Search
        let reels = await Reel.find(queryObj)
            .sort(sortOption)
            .populate('user', 'name profile_pic')
            .limit(20);

        // 6. Fallback (Only if q was provided and resulted in 0 matches)
        if (reels.length === 0 && q) {
            console.log(`[Search] No results for "${q}". Fetching fallback reels.`);
            reels = await Reel.find({ status: 'active' })
                .sort({ view_count: -1 })
                .limit(10)
                .populate('user', 'name profile_pic');

            return res.json({
                results: reels,
                message: "No exact matches found. Here are some trending reels you might like!",
                isFallback: true
            });
        }

        res.json({ results: reels, isFallback: false });

    } catch (err) {
        console.error('Search Error:', err);
        res.status(500).json({ error: 'Server Error' });
    }
});

/**
 * @route   GET /api/search/suggestions
 * @desc    Auto-complete suggestions for reels/keywords ONLY (No Users).
 */
router.get('/suggestions', async (req, res) => {
    try {
        const { q } = req.query;
        if (!q) return res.json([]);

        const regex = new RegExp(escapeRegex(q), 'gi');

        // Only fetch Reels for keywords
        const reels = await Reel.find({
            $or: [
                { title: regex },
                { tags: regex },
                { 'product.brand': regex }
            ]
        }).limit(5).select('title tags product.brand');

        let suggestions = [];

        // Add Keywords/Hashtags (deduplicated)
        const keywordSet = new Set();
        reels.forEach(r => {
            if (r.title && r.title.match(regex)) keywordSet.add(r.title);
            if (r.product && r.product.brand && r.product.brand.match(regex)) keywordSet.add(r.product.brand);
            if (r.tags) {
                r.tags.forEach(t => {
                    if (t.match(regex)) keywordSet.add(t);
                });
            }
        });

        Array.from(keywordSet).slice(0, 5).forEach(k => {
            suggestions.push({ type: 'keyword', text: k });
        });

        res.json(suggestions);
    } catch (err) {
        console.error('Suggestion Error:', err);
        res.status(500).json({ error: 'Server Error' });
    }
});

/**
 * @route   GET /api/search/trending
 * @desc    Get trending keywords/hashtags based on recent popular reels
 */
router.get('/trending', async (req, res) => {
    try {
        // Aggregation to find most popular tags/categories from top 50 viewed reels
        const trending = await Reel.aggregate([
            { $match: { status: 'active' } },
            { $sort: { view_count: -1 } },
            { $limit: 50 },
            { $unwind: "$tags" },
            { $group: { _id: "$tags", count: { $sum: 1 } } },
            { $sort: { count: -1 } },
            { $limit: 10 }
        ]);

        const formatted = trending.map(t => t._id);
        res.json(formatted);
    } catch (err) {
        console.error('Trending Error:', err);
        res.status(500).json({ error: 'Server Error' });
    }
});

/**
 * @route   GET /api/search/history
 * @desc    Get user's recent search history
 */
router.get('/history', async (req, res) => {
    // Implementation depends on Authentication middleware availability
    // Assuming req.userId is available or passed as query param for valid user
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ error: 'UserId required' });

    try {
        const user = await User.findById(userId).select('searchHistory');
        if (!user) return res.status(404).json({ error: 'User not found' });

        // Return latest 10 unique searches
        const history = user.searchHistory
            .sort((a, b) => b.timestamp - a.timestamp)
            .slice(0, 10);

        res.json(history);
    } catch (err) {
        res.status(500).json({ error: 'Server Error' });
    }
});

/**
 * @route   POST /api/search/history
 * @desc    Add query to history
 */
router.post('/history', async (req, res) => {
    const { userId, query } = req.body;
    if (!userId || !query) return res.status(400).json({ error: 'Missing data' });

    try {
        await User.findByIdAndUpdate(userId, {
            $push: {
                searchHistory: {
                    $each: [{ query, timestamp: new Date() }],
                    $position: 0,
                    $slice: 20 // Keep only last 20
                }
            }
        });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Server Error' });
    }
});

module.exports = router;
