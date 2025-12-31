const mongoose = require('mongoose');

const globalSettingsSchema = new mongoose.Schema({
    enableReelUploads: {
        type: Boolean,
        default: true
    },
    enableAutomation: {
        type: Boolean,
        default: false
    },
    enable2FA: {
        type: Boolean,
        default: false
    },
    emailNotifications: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

module.exports = mongoose.model('GlobalSettings', globalSettingsSchema);
