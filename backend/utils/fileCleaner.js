const fs = require('fs');
const path = require('path');

const deleteFile = (filePath) => {
    if (!filePath) return;

    // Resolve full path if relative
    // Assuming uploads are relative to backend root 'backend/' or 'backend/uploads/' depending on storage config.
    // However, multer usually stores relative path like 'uploads/images/...' in DB.
    // So we can try to resolve it from the project root.

    try {
        const fullPath = path.resolve(__dirname, '..', filePath);
        if (fs.existsSync(fullPath)) {
            fs.unlinkSync(fullPath);
            console.log(`🗑️ Deleted file: ${fullPath}`);
        } else {
            console.warn(`⚠️ File not found for deletion: ${fullPath}`);
        }
    } catch (err) {
        console.error(`❌ Error deleting file ${filePath}:`, err.message);
    }
};

module.exports = { deleteFile };
