const mongoose = require('mongoose');

const reelSchema = new mongoose.Schema({
    video_url: {
        type: String,
        required: true
    },
    thumbnail_url: {
        type: String,
    },
    logo_url: {
        type: String,
    },
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    category: {
        type: String,
        default: 'All'
    },
    status: {
        type: String,
        enum: ['active', 'pending', 'rejected'],
        default: 'active'
    },
    app_link: {
        type: String
    },
    is_paid: {
        type: Boolean,
        default: false
    },
    price: {
        type: Number,
        default: 0
    },
    like_count: {
        type: Number,
        default: 0
    },
    view_count: {
        type: Number,
        default: 0
    },
    liked_by: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    comments: [{
        userId: mongoose.Schema.Types.ObjectId,
        userName: String,
        userProfilePic: String,
        text: String,
        createdAt: { type: Date, default: Date.now },
        likes: { type: Number, default: 0 },
        likedBy: [{ type: mongoose.Schema.Types.ObjectId }]
    }],
    comment_count: {
        type: Number,
        default: 0
    },
    // Search Optimization
    tags: {
        type: [String],
        default: []
    }
}, {
    timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
    toJSON: {
        transform: (doc, ret) => {
            ret.id = ret._id;
            delete ret._id;
            delete ret.__v;
            return ret;
        }
    }
});

// Text Indexes for Semantic Search
reelSchema.index({
    title: 'text',
    description: 'text',
    category: 'text',
    tags: 'text',
    'product.name': 'text',
    'product.brand': 'text'
}, {
    weights: {
        title: 10,
        tags: 8,
        category: 5,
        description: 3
    }
});
// Index for filtering/sorting
reelSchema.index({ category: 1, like_count: -1, view_count: -1, created_at: -1 });

module.exports = mongoose.model('Reel', reelSchema);
