pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common

Singleton {
    id: root

    // Availability check
    property bool available: false
    property bool mpvAvailable: false
    
    // Search
    property bool searching: false
    property var searchResults: []
    property list<string> recentSearches: []
    property var currentArtistInfo: null
    
    // Playback
    property bool isPlaying: false
    property string currentVideoId: ""
    property var currentTrack: null
    property var queue: []
    property int queueIndex: 0
    property bool shuffleMode: false
    property int repeatMode: 0  // 0: off, 1: one, 2: all
    
    // Playlists
    property var playlists: []
    property var likedSongs: []
    property var ytMusicPlaylists: []
    
    // Google account
    property bool googleConnected: false
    readonly property bool isLoggedIn: googleConnected
    property bool googleChecking: false
    property string googleError: ""
    property string googleBrowser: ""
    property string userName: ""
    property string userAvatar: ""
    property bool syncingLiked: false
    property var detectedBrowsers: []
    property string customCookiesPath: ""
    property bool usingCustomCookies: false
    
    // Browser info for UI display
    readonly property var browserInfo: ({
        "firefox": { name: "Firefox", icon: "🦊" },
        "chrome": { name: "Chrome", icon: "🌐" },
        "chromium": { name: "Chromium", icon: "⭕" },
        "brave": { name: "Brave", icon: "🦁" },
        "edge": { name: "Edge", icon: "🔵" }
    })
    
    // Error handling
    property string error: ""
    
    function setCustomCookiesPath(path) {
        root.customCookiesPath = path
    }
    
    Timer {
        id: googleConnectTimer
        interval: 2000
        repeat: false
        onTriggered: {
            root.googleChecking = false
            root.googleError = "Google account integration not yet implemented"
        }
    }
    
    Component.onCompleted: {
        console.log("[YtMusic] Service initializing...")
        // Start availability checks
        availabilityCheckTimer.start()
        loadPlaylists()
        loadLikedSongs()
        loadRecentSearches()
        detectBrowsers()
    }
    
    // Delay availability check slightly to ensure component is ready
    Timer {
        id: availabilityCheckTimer
        interval: 100
        repeat: false
        onTriggered: {
            console.log("[YtMusic] Running availability checks...")
            ytdlpCheckProcess.running = true
            mpvCheckProcess.running = true
        }
    }
    
    // Process to check yt-dlp availability
    Process {
        id: ytdlpCheckProcess
        command: ["/usr/bin/which", "yt-dlp"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0)
            console.log("[YtMusic] yt-dlp check exit code:", exitCode, "available:", root.available)
        }
    }
    
    // Process to check mpv availability
    Process {
        id: mpvCheckProcess
        command: ["/usr/bin/which", "mpv"]
        onExited: (exitCode, exitStatus) => {
            root.mpvAvailable = (exitCode === 0)
            console.log("[YtMusic] mpv check exit code:", exitCode, "available:", root.mpvAvailable)
        }
    }
    
    function checkAvailability() {
        console.log("[YtMusic] Manual availability check triggered")
        ytdlpCheckProcess.running = true
        mpvCheckProcess.running = true
    }
    
    function search(query) {
        if (!root.available || !query.trim()) return
        
        root.searching = true
        root.error = ""
        root.searchResults = []
        
        // Add to recent searches
        let recent = root.recentSearches
        recent = recent.filter(s => s !== query)
        recent.unshift(query)
        if (recent.length > 10) recent = recent.slice(0, 10)
        root.recentSearches = recent
        saveRecentSearches()
        
        // Execute search via yt-dlp
        searchProcess.command = [
            "/usr/bin/yt-dlp",
            "--dump-json",
            "--flat-playlist",
            "--skip-download",
            `ytsearch10:${query}`
        ]
        searchProcess.running = true
    }
    
    Process {
        id: searchProcess
        property var results: []
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                let parsed = []
                for (let line of lines) {
                    if (!line.trim()) continue
                    try {
                        let obj = JSON.parse(line)
                        parsed.push({
                            id: obj.id || "",
                            videoId: obj.id || "",
                            title: obj.title || "",
                            artist: obj.channel || obj.uploader || "",
                            duration: obj.duration || 0,
                            thumbnail: obj.thumbnail || obj.thumbnails?.[0]?.url || "",
                            url: obj.url || `https://youtube.com/watch?v=${obj.id}`,
                            isVideo: true
                        })
                    } catch (e) {
                        console.warn("Failed to parse search result:", e)
                    }
                }
                searchProcess.results = parsed
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            root.searching = false
            if (exitCode === 0) {
                root.searchResults = searchProcess.results
            } else {
                root.error = "Search failed. Check your internet connection."
            }
        }
    }
    
    function playFromSearch(index) {
        if (index < 0 || index >= root.searchResults.length) return
        let items = [...root.searchResults]
        playFromPlaylist(items, index, "search")
    }
    
    function playFromLiked(index) {
        if (index < 0 || index >= root.likedSongs.length) return
        playFromPlaylist([...root.likedSongs], index, "liked")
    }
    
    function playFromPlaylist(items, startIndex, source) {
        if (!items || items.length === 0) return
        root.queue = items
        root.queueIndex = startIndex
        playQueue()
    }
    
    function playQueue() {
        if (root.queue.length === 0 || root.queueIndex >= root.queue.length) return
        let track = root.queue[root.queueIndex]
        playTrack(track)
    }
    
    function playTrack(track) {
        if (!root.mpvAvailable || !track) return
        
        root.currentTrack = track
        root.currentVideoId = track.videoId || track.id || ""
        root.isPlaying = true
        
        // Play with mpv
        Quickshell.execDetached([
            "/usr/bin/mpv",
            "--no-video",
            "--ytdl-format=bestaudio",
            `https://youtube.com/watch?v=${root.currentVideoId}`
        ])
    }
    
    function playPlaylist(playlistIndex, shuffle) {
        if (playlistIndex < 0 || playlistIndex >= root.playlists.length) return
        let playlist = root.playlists[playlistIndex]
        let items = [...(playlist.items || [])]
        if (items.length === 0) return
        
        let startIndex = 0
        if (shuffle) {
            for (let i = items.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1))
                const temp = items[i]
                items[i] = items[j]
                items[j] = temp
            }
        }
        playFromPlaylist(items, startIndex, `playlist:${playlist.name}`)
    }
    
    function addToQueue(track) {
        let q = [...root.queue]
        q.push(track)
        root.queue = q
    }
    
    function removeFromQueue(index) {
        if (index < 0 || index >= root.queue.length) return
        let q = [...root.queue]
        q.splice(index, 1)
        root.queue = q
        if (root.queueIndex >= q.length) root.queueIndex = Math.max(0, q.length - 1)
    }
    
    function clearQueue() {
        root.queue = []
        root.queueIndex = 0
    }
    
    function toggleShuffle() {
        root.shuffleMode = !root.shuffleMode
    }
    
    function cycleRepeatMode() {
        root.repeatMode = (root.repeatMode + 1) % 3
    }
    
    function nextTrack() {
        if (root.queue.length === 0) return
        if (root.repeatMode === 1) {
            playQueue()
            return
        }
        root.queueIndex++
        if (root.queueIndex >= root.queue.length) {
            if (root.repeatMode === 2) {
                root.queueIndex = 0
            } else {
                root.isPlaying = false
                return
            }
        }
        playQueue()
    }
    
    function previousTrack() {
        if (root.queue.length === 0) return
        root.queueIndex = Math.max(0, root.queueIndex - 1)
        playQueue()
    }
    
    // Playlist management
    function createPlaylist(name) {
        if (!name.trim()) return
        let p = [...root.playlists]
        p.push({
            name: name.trim(),
            items: [],
            created: Date.now()
        })
        root.playlists = p
        savePlaylists()
    }
    
    function deletePlaylist(index) {
        if (index < 0 || index >= root.playlists.length) return
        let p = [...root.playlists]
        p.splice(index, 1)
        root.playlists = p
        savePlaylists()
    }
    
    function addToPlaylist(playlistIndex, track) {
        if (playlistIndex < 0 || playlistIndex >= root.playlists.length) return
        let p = [...root.playlists]
        if (!p[playlistIndex].items) p[playlistIndex].items = []
        p[playlistIndex].items.push(track)
        root.playlists = p
        savePlaylists()
    }
    
    function removeFromPlaylist(playlistIndex, trackIndex) {
        if (playlistIndex < 0 || playlistIndex >= root.playlists.length) return
        let p = [...root.playlists]
        if (!p[playlistIndex].items || trackIndex < 0 || trackIndex >= p[playlistIndex].items.length) return
        p[playlistIndex].items.splice(trackIndex, 1)
        root.playlists = p
        savePlaylists()
    }
    
    // Liked songs
    function toggleLike(track) {
        let liked = [...root.likedSongs]
        let index = liked.findIndex(t => t.videoId === track.videoId || t.id === track.id)
        if (index >= 0) {
            liked.splice(index, 1)
        } else {
            liked.unshift(track)
        }
        root.likedSongs = liked
        saveLikedSongs()
    }
    
    function isLiked(track) {
        if (!track) return false
        return root.likedSongs.some(t => t.videoId === track.videoId || t.id === track.id)
    }
    
    // Google integration stubs
    function quickConnect() {
        if (root.detectedBrowsers.length > 0) {
            connectGoogle(root.detectedBrowsers[0])
        } else {
            root.googleError = "No supported browsers found"
        }
    }
    
    function connectGoogle(browser) {
        if (!browser) return
        root.googleChecking = true
        root.googleError = ""
        root.googleBrowser = browser
        root.usingCustomCookies = false
        // Test connection by fetching a simple video that requires login to view liked status
        googleConnectProcess.command = [
            "/usr/bin/yt-dlp",
            "--cookies-from-browser", browser.toLowerCase(),
            "--simulate",
            "--no-warnings",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ]
        googleConnectProcess.running = true
    }
    
    function connectWithCookiesFile(cookiesPath) {
        if (!cookiesPath) return
        root.googleChecking = true
        root.googleError = ""
        root.customCookiesPath = cookiesPath
        root.usingCustomCookies = true
        root.googleBrowser = "cookies.txt"
        // Test connection with the cookies file
        googleConnectProcess.command = [
            "/usr/bin/yt-dlp",
            "--cookies", cookiesPath,
            "--simulate",
            "--no-warnings",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ]
        googleConnectProcess.running = true
    }

    Process {
        id: googleConnectProcess

        onExited: (exitCode, exitStatus) => {
            root.googleChecking = false
            if (exitCode === 0) {
                root.googleConnected = true
                root.userName = "YouTube User"
                root.userAvatar = "" 
                console.log("[YtMusic] Successfully connected! Fetching library...")
                fetchYtMusicPlaylists()
                fetchLikedSongs()
            } else {
                root.googleConnected = false
                if (root.usingCustomCookies) {
                    root.googleError = "Failed to authenticate with cookies file. Make sure you're logged in to YouTube Music and the file is valid."
                } else {
                    root.googleError = "Failed to connect to " + getBrowserDisplayName(root.googleBrowser) + ". Snap/Flatpak browsers require 'Custom Cookies File' instead."
                }
                console.warn("[YtMusic] Connection failed with exit code:", exitCode)
            }
        }
    }

    function disconnectGoogle() {
        root.googleConnected = false
        root.googleBrowser = ""
        root.userName = ""
        root.userAvatar = ""
        root.ytMusicPlaylists = []
    }

    function fetchLikedSongs() {
        if (!root.googleConnected) return
        root.syncingLiked = true
        if (root.usingCustomCookies) {
            likedSongsProcess.command = [
                "/usr/bin/yt-dlp",
                "--cookies", root.customCookiesPath,
                "--dump-json",
                "--flat-playlist",
                "https://music.youtube.com/playlist?list=LM"
            ]
        } else {
            likedSongsProcess.command = [
                "/usr/bin/yt-dlp",
                "--cookies-from-browser", root.googleBrowser.toLowerCase(),
                "--dump-json",
                "--flat-playlist",
                "https://music.youtube.com/playlist?list=LM"
            ]
        }
        likedSongsProcess.running = true
    }

    Process {
        id: likedSongsProcess
        property var results: []
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                let parsed = []
                for (let line of lines) {
                    if (!line.trim()) continue
                    try {
                        let obj = JSON.parse(line)
                        if (obj._type === 'playlist') continue; // Skip playlist info itself
                        parsed.push({
                            id: obj.id || "",
                            videoId: obj.id || "",
                            title: obj.title || "",
                            artist: obj.channel || obj.uploader || "",
                            duration: obj.duration || 0,
                            thumbnail: obj.thumbnail || obj.thumbnails?.[0]?.url || "",
                            url: obj.url || `https://youtube.com/watch?v=${obj.id}`,
                            isVideo: true
                        })
                    } catch (e) {
                        console.warn("Failed to parse liked song:", e)
                    }
                }
                likedSongsProcess.results = parsed
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            root.syncingLiked = false
            if (exitCode === 0) {
                root.likedSongs = likedSongsProcess.results
                saveLikedSongs()
            } else {
                root.error = "Failed to fetch liked songs."
            }
        }
    }

    function fetchYtMusicPlaylists() {
        if (!root.googleConnected) return
        if (root.usingCustomCookies) {
            ytMusicPlaylistsProcess.command = [
                "/usr/bin/yt-dlp",
                "--cookies", root.customCookiesPath,
                "--dump-json",
                "--flat-playlist",
                "https://music.youtube.com/library/playlists"
            ]
        } else {
            ytMusicPlaylistsProcess.command = [
                "/usr/bin/yt-dlp",
                "--cookies-from-browser", root.googleBrowser.toLowerCase(),
                "--dump-json",
                "--flat-playlist",
                "https://music.youtube.com/library/playlists"
            ]
        }
        ytMusicPlaylistsProcess.running = true
    }

    Process {
        id: ytMusicPlaylistsProcess
        property var results: []
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                let parsed = []
                for (let line of lines) {
                    if (!line.trim()) continue
                    try {
                        let obj = JSON.parse(line)
                        if (obj._type === 'playlist' && obj.entries) {
                            // This is the main playlist container, extract the entries
                            for (let entry of obj.entries) {
                                parsed.push({
                                    id: entry.id,
                                    title: entry.title,
                                    url: entry.url,
                                    itemCount: entry.playlist_count,
                                });
                            }
                        }
                    } catch (e) {
                        console.warn("Failed to parse YT Music playlist:", e)
                    }
                }
                ytMusicPlaylistsProcess.results = parsed
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.ytMusicPlaylists = ytMusicPlaylistsProcess.results
            } else {
                root.error = "Failed to fetch YouTube Music playlists."
            }
        }
    }

    function openYtMusicInBrowser() {
        Qt.openUrlExternally("https://music.youtube.com")
    }
    
    function getBrowserDisplayName(browser) {
        switch (browser) {
            case "firefox": return "Firefox"
            case "chrome": return "Chrome"
            case "chromium": return "Chromium"
            case "brave": return "Brave"
            case "edge": return "Edge"
            default: return browser
        }
    }
    
    function detectBrowsers() {
        root.detectedBrowsers = [] // Clear previous results
        browserDetectProcess.running = true
    }
    
    Process {
        id: browserDetectProcess
        command: ["sh", "-c", "which firefox && echo 'firefox'; which google-chrome && echo 'chrome'; which chromium-browser && echo 'chromium'; which brave && echo 'brave'; which microsoft-edge && echo 'edge'"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                let browsers = []
                // The output is interleaved (path then name), so we take every second line
                for (let i = 1; i < lines.length; i += 2) {
                    if (lines[i] && !browsers.includes(lines[i])) {
                        browsers.push(lines[i])
                    }
                }
                root.detectedBrowsers = browsers
                console.log("[YtMusic] Detected browsers:", JSON.stringify(browsers))
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[YtMusic] Browser detection script finished with exit code:", exitCode)
            }
        }
    }
    
    function clearRecentSearches() {
        root.recentSearches = []
        saveRecentSearches()
    }
    
    // Persistence
    property string playlistsPath: `${Directories.configPath}/ytmusic_playlists.json`
    property string likedSongsPath: `${Directories.configPath}/ytmusic_liked.json`
    property string recentSearchesPath: `${Directories.configPath}/ytmusic_recent.json`
    
    function savePlaylists() {
        FileView.writeTextFile(root.playlistsPath, JSON.stringify(root.playlists))
    }
    
    function loadPlaylists() {
        try {
            let data = FileView.readTextFile(root.playlistsPath)
            if (data) root.playlists = JSON.parse(data)
        } catch (e) {
            root.playlists = []
        }
    }
    
    function saveLikedSongs() {
        FileView.writeTextFile(root.likedSongsPath, JSON.stringify(root.likedSongs))
    }
    
    function loadLikedSongs() {
        try {
            let data = FileView.readTextFile(root.likedSongsPath)
            if (data) root.likedSongs = JSON.parse(data)
        } catch (e) {
            root.likedSongs = []
        }
    }
    
    function saveRecentSearches() {
        FileView.writeTextFile(root.recentSearchesPath, JSON.stringify(root.recentSearches))
    }
    
    function loadRecentSearches() {
        try {
            let data = FileView.readTextFile(root.recentSearchesPath)
            if (data) root.recentSearches = JSON.parse(data)
        } catch (e) {
            root.recentSearches = []
        }
    }
}
