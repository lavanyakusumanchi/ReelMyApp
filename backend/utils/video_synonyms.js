/**
 * Dictionary for Semantic Search & Synonym Expansion
 * Maps common user queries to related keywords/categories.
 */

const synonymDictionary = {
    // Categories
    "education": ["study", "learning", "school", "tutorial", "class", "exam", "course", "college", "university"],
    "fashion": ["style", "outfit", "clothing", "dress", "shopping", "wear", "trends", "model", "ootd"],
    "food": ["cooking", "recipe", "restaurant", "eating", "meal", "dinner", "lunch", "breakfast", "tasty", "yummy"],
    "tech": ["gadgets", "software", "coding", "programming", "computer", "mobile", "app", "developer", "hardware"],
    "travel": ["vacation", "trip", "holiday", "tourism", "flight", "hotel", "beach", "adventure", "explore"],
    "gaming": ["playing", "games", "streamer", "console", "pc", "playstation", "xbox", "nintendo", "entertainment"],
    "fitness": ["gym", "workout", "exercise", "health", "running", "yoga", "training", "diet"],
    "music": ["song", "concert", "singer", "band", "lyrics", "audio", "sound"],
    "pets": ["dog", "cat", "animals", "puppy", "kitten", "cute"],
    "business": ["marketing", "finance", "money", "startup", "entrepreneur", "career", "job"],

    // Common semantic mappings
    "job": ["career", "work", "hiring", "resume"],
    "funny": ["comedy", "laugh", "meme", "joke", "prank"],
    "scenery": ["nature", "landscape", "view", "sunset", "sunrise"],
    "love": ["romance", "couple", "wedding", "relationship"]
};

/**
 * Expands a search query by adding related synonyms.
 * @param {string} query - The user's search input.
 * @returns {string[]} - Array of unique keywords including synonyms.
 */
const expandQuery = (query) => {
    if (!query) return [];

    const words = query.toLowerCase().trim().split(/\s+/);
    let expandedTerms = new Set(words);

    words.forEach(word => {
        // Check if word matches a category key directly
        if (synonymDictionary[word]) {
            synonymDictionary[word].forEach(term => expandedTerms.add(term));
        }

        // Check reverse mapping (if word is a value in the dictionary)
        Object.keys(synonymDictionary).forEach(key => {
            if (synonymDictionary[key].includes(word)) {
                expandedTerms.add(key); // Add the category/root term
                // Optionally add sibling terms (might be too broad, kept simple for now)
            }
        });
    });

    return Array.from(expandedTerms);
}

module.exports = { expandQuery, synonymDictionary };
