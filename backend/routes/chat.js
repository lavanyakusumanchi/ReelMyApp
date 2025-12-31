const express = require('express');
const router = express.Router();
const auth = require('../utils/auth'); // Middleware to verify token
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');

// GET /api/chats - Get all chats for the current user
router.get('/', auth, async (req, res) => {
    try {
        const userId = req.user.id; // From auth middleware

        const chats = await Chat.find({ participants: userId })
            .populate('participants', 'name email profile_pic') // Populate user details
            .populate('lastMessage')                          // Populate last message
            .sort({ updatedAt: -1 });                         // Newest first

        // Format the response to be friendly for the frontend
        const formattedChats = chats.map(chat => {
            // Find the "other" participant
            const otherUser = chat.participants.find(p => p._id.toString() !== userId);
            return {
                id: chat._id,
                otherUser: otherUser ? {
                    id: otherUser._id,
                    name: otherUser.name,
                    email: otherUser.email,
                    profile_pic: otherUser.profile_pic
                } : null,
                lastMessage: chat.lastMessage ? {
                    content: chat.lastMessage.content,
                    sender: chat.lastMessage.sender,
                    timestamp: chat.lastMessage.timestamp,
                    read: chat.lastMessage.read
                } : null,
                updatedAt: chat.updatedAt
            };
        });

        res.json(formattedChats);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// GET /api/chats/:chatId/messages - Get messages for a specific chat
router.get('/:chatId/messages', auth, async (req, res) => {
    try {
        const messages = await Message.find({ chatId: req.params.chatId })
            .sort({ timestamp: 1 }); // Oldest first
        res.json(messages);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// POST /api/chats/message - Send a message
// Body: { recipientId, content }
router.post('/message', auth, async (req, res) => {
    try {
        const senderId = req.user.id;
        const { recipientId, content } = req.body;

        // 1. Check if chat exists
        let chat = await Chat.findOne({
            participants: { $all: [senderId, recipientId] }
        });

        // 2. If not, create new chat
        if (!chat) {
            chat = new Chat({
                participants: [senderId, recipientId]
            });
            await chat.save();
        }

        // 3. Create Message
        const newMessage = new Message({
            chatId: chat._id,
            sender: senderId,
            content: content
        });
        await newMessage.save();

        // 4. Update Chat with lastMessage
        chat.lastMessage = newMessage._id;
        chat.updatedAt = Date.now();
        await chat.save();

        // 5. Return the message
        res.json(newMessage);

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// GET /api/chats/users - Search users to start a chat with (Simple search)
router.get('/users/search', auth, async (req, res) => {
    try {
        const { q } = req.query; // Search query
        if (!q) return res.json([]);

        const users = await User.find({
            name: { $regex: q, $options: 'i' },
            _id: { $ne: req.user.id } // Exclude self
        }).select('name email profile_pic');

        res.json(users);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
