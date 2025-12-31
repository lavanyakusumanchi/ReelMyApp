const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('@ffmpeg-installer/ffmpeg').path;
const ffprobePath = require('ffprobe-static').path;
const path = require('path');
const fs = require('fs');

ffmpeg.setFfmpegPath(ffmpegPath);
ffmpeg.setFfprobePath(ffprobePath);

/**
 * Generates a video from a list of images.
 * @param {Array<string>} images - Array of absolute paths to images.
 * @param {string|null} audio - Absolute path to audio file (optional).
 * @param {string} outputVideoPath - Path to save the generated video.
 * @returns {Promise<string>}
 */
async function generateVideoFromImages(images, audio, outputVideoPath) {
    return new Promise((resolve, reject) => {
        if (!images || images.length === 0) {
            return reject(new Error('No images provided for video generation.'));
        }

        

        const tempFilePath = path.join(process.cwd(), path.dirname(outputVideoPath), `concat_${Date.now()}.txt`);
        const durationPerImage = 0.5; // seconds (Faster speed)

        let fileContent = '';
        images.forEach((img) => {
           
            const absolutePath = path.resolve(img).replace(/\\/g, '/');
            const escapedPath = absolutePath.replace(/'/g, "'\\''");
            fileContent += `file '${escapedPath}'\nduration ${durationPerImage}\n`;
        });
        // Repeat the last image to fix a common ffmpeg behavior where the last item's duration is ignored
        if (images.length > 0) {
            const lastPath = path.resolve(images[images.length - 1]).replace(/\\/g, '/').replace(/'/g, "'\\''");
            fileContent += `file '${lastPath}'\n`;
        }

        fs.writeFileSync(tempFilePath, fileContent);
        console.log('📝 Concat file created at:', tempFilePath);
        console.log('📄 Concat content:\n', fileContent);



        console.log('Using FFmpeg Path:', ffmpegPath);
        let command = ffmpeg();

        command
            .input(tempFilePath)
            .inputOptions(['-f', 'concat', '-safe', '0'])
            .outputOptions([
                '-pix_fmt', 'yuv420p',
                '-vf', 'scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2',
                '-r', '24',
                '-movflags', '+faststart'
            ]);

        if (audio && fs.existsSync(audio)) {
            command.input(audio).outputOptions([
                '-shortest',
                '-c:a', 'aac',
                '-b:a', '128k'
            ]);
        }

        command
            .on('start', (cmd) => console.log('FFMPEG started:', cmd))
            .on('stderr', (stderrLine) => console.log('FFMPEG Stderr:', stderrLine))
            .on('error', (err) => {
                console.error('FFMPEG error:', err);
                if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
                reject(err);
            })
            .on('end', () => {
                console.log('FFMPEG finished generating video.');
                if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
                resolve(outputVideoPath);
            })
            .save(outputVideoPath);
    });
}

/**
 * Generates a thumbnail from the first image or video.
 * @param {string} videoPath - Absolute path to the video file.
 * @param {string} outputThumbPath - Path to save the generated thumbnail.
 * @returns {Promise<string>}
 */
async function generateThumbnail(videoPath, outputThumbPath) {
    return new Promise((resolve, reject) => {
        ffmpeg(videoPath)
            .screenshots({
                timestamps: [0],
                filename: path.basename(outputThumbPath),
                folder: path.dirname(outputThumbPath),
                size: '720x1280'
            })
            .on('end', () => resolve(outputThumbPath))
            .on('error', reject);
    });
}

module.exports = {
    generateVideoFromImages,
    generateThumbnail
};