pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * A service for fetching Reddit posts using Reddit's public JSON API
 */
Singleton {
    id: root

    property bool loading: false
    property string lastError: ""
    property list<var> posts: []
    property string currentSubreddit: ""
    property string currentSort: "hot"
    
    readonly property string userAgent: Config.options?.networking?.userAgent ?? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

    signal postsUpdated()

    /**
     * Fetch posts from a subreddit
     * @param subreddit - The subreddit name (without r/)
     * @param sort - Sort type: "hot", "new", "top", "rising"
     */
    function fetchPosts(subreddit, sort) {
        if (!subreddit || subreddit.length === 0) {
            root.lastError = "Invalid subreddit"
            return
        }

        root.loading = true
        root.lastError = ""
        root.currentSubreddit = subreddit
        root.currentSort = sort || "hot"

        const url = `https://www.reddit.com/r/${subreddit}/${sort}.json?limit=25`
        
        const process = new Process({
            command: ["curl", "-s", "-A", root.userAgent, url],
            stdout: new StdioCollector({}),
            stderr: new StdioCollector({})
        })

        process.stdout.streamFinished.connect(() => {
            try {
                const response = JSON.parse(process.stdout.text)
                
                if (response.error) {
                    root.lastError = `Error ${response.error}: ${response.message || 'Failed to fetch posts'}`
                    root.posts = []
                } else if (response.data && response.data.children) {
                    root.posts = response.data.children
                        .filter(child => child.data)
                        .map(child => {
                            const data = child.data
                            return {
                                id: data.id,
                                title: data.title,
                                author: data.author,
                                subreddit: data.subreddit,
                                score: data.score,
                                numComments: data.num_comments,
                                created: data.created_utc,
                                permalink: data.permalink,
                                url: data.url,
                                thumbnail: (data.thumbnail && data.thumbnail.startsWith('http')) ? data.thumbnail : "",
                                isSelf: data.is_self,
                                isNsfw: data.over_18,
                                domain: data.domain
                            }
                        })
                    root.lastError = ""
                } else {
                    root.lastError = "Invalid response format"
                    root.posts = []
                }
            } catch (e) {
                root.lastError = `Failed to parse response: ${e.message}`
                root.posts = []
            }
            root.loading = false
            root.postsUpdated()
        })

        process.stderr.streamFinished.connect(() => {
            if (process.stderr.text.length > 0) {
                root.lastError = "Network error: " + process.stderr.text
                root.posts = []
                root.loading = false
            }
        })

        process.onExited.connect((exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.lastError = `Request failed with exit code ${exitCode}`
                root.posts = []
                root.loading = false
            }
        })

        process.running = true
    }

    /**
     * Open a Reddit post in the default browser
     */
    function openPost(post) {
        if (!post || !post.permalink) return
        const url = `https://www.reddit.com${post.permalink}`
        Quickshell.execDetached(["xdg-open", url])
    }

    /**
     * Open the post's linked content (for image/video posts)
     */
    function openImage(post) {
        if (!post || !post.url) return
        Quickshell.execDetached(["xdg-open", post.url])
    }

    /**
     * Format a score number (e.g., 1234 -> 1.2k)
     */
    function formatScore(score) {
        if (score >= 1000000) {
            return (score / 1000000).toFixed(1) + "M"
        } else if (score >= 1000) {
            return (score / 1000).toFixed(1) + "k"
        }
        return score.toString()
    }

    /**
     * Format a Unix timestamp to relative time (e.g., "2h ago")
     */
    function formatTime(timestamp) {
        const now = Date.now() / 1000
        const diff = now - timestamp

        if (diff < 60) {
            return "just now"
        } else if (diff < 3600) {
            const minutes = Math.floor(diff / 60)
            return minutes + "m ago"
        } else if (diff < 86400) {
            const hours = Math.floor(diff / 3600)
            return hours + "h ago"
        } else if (diff < 604800) {
            const days = Math.floor(diff / 86400)
            return days + "d ago"
        } else {
            const weeks = Math.floor(diff / 604800)
            return weeks + "w ago"
        }
    }
}
