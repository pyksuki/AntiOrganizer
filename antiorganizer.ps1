# ========================================
# ANTIORGANIZER - COMPLETE MEDIA ORGANIZER
# Automatically organizes all multimedia files
# Automatically detects the current user
# Version 3.0
# Made by antikvn
# ========================================

# ========================================
# GLOBAL CONFIGURATION
# Defines error and progress behavior
# ErrorActionPreference: Continue on errors (non-fatal)
# ProgressPreference: Display operation progress
# ========================================
$ErrorActionPreference = "Continue"
$ProgressPreference = "Continue"

# ========================================
# USER INTERFACE
# Clears console and displays banner with application information
# ========================================
Clear-Host
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "           ANTIORGANIZER v3.0                      " -ForegroundColor Cyan
Write-Host "      Complete Multimedia Organizer               " -ForegroundColor Cyan
Write-Host "              Made by antikvn                     " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# AUTOMATIC USER DETECTION
# Obtains username and path of current user profile
# $env:USERNAME: Windows username
# $env:USERPROFILE: Complete profile path (C:\Users\UserName)
# ========================================
$CurrentUser = $env:USERNAME
$UserProfile = $env:USERPROFILE

Write-Host "Detected user: $CurrentUser" -ForegroundColor Green
Write-Host "Profile: $UserProfile" -ForegroundColor Gray
Write-Host ""

# ========================================
# SOURCE FOLDERS DEFINITION
# List of folders where multimedia files will be collected
# These are typical locations where users download/store files
# ========================================
$SourceFolders = @(
    "$UserProfile\Downloads",
    "$UserProfile\Documents",
    "$UserProfile\Desktop"
)

# ========================================
# DESTINATION FOLDERS DEFINITION
# Folders where files will be organized by type
# Pictures: Images (JPG, PNG, GIF, etc)
# Videos: Video files (MP4, AVI, MKV, etc)
# Music: Audio files (MP3, WAV, FLAC, etc)
# ========================================
$PicturesFolder = "$UserProfile\Pictures"
$VideosFolder = "$UserProfile\Videos"
$MusicFolder = "$UserProfile\Music"

# ========================================
# SUPPORTED EXTENSIONS - IMAGES
# Comprehensive list of recognized image file extensions
# Includes: common formats (JPG, PNG), vectors (SVG, AI), raw (CR2, NEF), editing (PSD)
# ========================================
$ImageExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp', '.ico', '.tiff', '.tif', '.heic', '.heif', '.raw', '.cr2', '.nef', '.arw', '.dng', '.psd', '.ai', '.eps')

# ========================================
# SUPPORTED EXTENSIONS - VIDEO
# Comprehensive list of recognized video file extensions
# Includes: container formats (MP4, MKV, MOV), legacy (AVI, WMV), streaming (WebM)
# ========================================
$VideoExtensions = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpeg', '.mpg', '.3gp', '.ogv', '.vob', '.mts', '.ts', '.m2ts')

# ========================================
# SUPPORTED EXTENSIONS - AUDIO
# Comprehensive list of recognized audio file extensions
# Includes: compressed (MP3, OGG, AAC), lossless (FLAC, WAV, ALAC), DTS (AC3)
# ========================================
$AudioExtensions = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a', '.opus', '.alac', '.aiff', '.ape', '.ac3', '.m4p', '.mp2')

# ========================================
# GLOBAL COUNTERS
# Control execution statistics:
# $TotalMoved: Number of successfully moved files
# $TotalSkipped: Ignored files (already in correct location)
# $TotalErrors: Files that caused errors during movement
# $StartTime: Execution start timestamp (for duration calculation)
# ========================================
$TotalMoved = 0
$TotalSkipped = 0
$TotalErrors = 0
$StartTime = Get-Date

# ========================================
# LOGGING SYSTEM CONFIGURATION
# Creates logs folder if it doesn't exist
# Log file contains timestamp to differentiate multiple executions
# Format: AntiOrganizer_YYYYMMDD_HHmmss.txt
# ========================================
$LogFolder = "$UserProfile\Documents\AntiOrganizer_Logs"
if (-not (Test-Path $LogFolder)) {
    Write-Host "Creating logs folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}
$LogFile = "$LogFolder\AntiOrganizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkGray
Write-Host ""

# ========================================
# FUNCTIONS
# ========================================

# ========================================
# FUNCTION: Write-Log
# Purpose: Writes messages to both log file and console
# Parameters:
#   -Message: Text to record
#   -Level: Message type (INFO, SUCCESS, WARN, ERROR)
# Behavior:
#   - Adds timestamp to each entry
#   - Displays in different colors based on level
#   - Handles write errors silently
# ========================================
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp [$Level] - $Message"
    
    try {
        $LogMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } catch {
        # Silently ignore log errors to prevent script blocking
    }
    
    # Display on console with appropriate formatting
    switch ($Level) {
        "ERROR"   { Write-Host "  [ERROR] $Message" -ForegroundColor Red }
        "WARN"    { Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "  [OK] $Message" -ForegroundColor Green }
        default   { Write-Host "  [INFO] $Message" -ForegroundColor White }
    }
}

# ========================================
# FUNCTION: Get-CategoryFolder
# Purpose: Determines destination folder based on file extension
# Parameters:
#   -Extension: File extension (e.g., .jpg, .mp4, .mp3)
# Returns: Tuple with (DestinationFolder, CategoryName, SubfolderName)
# Logic:
#   1. Converts extension to lowercase
#   2. Checks which category it belongs to
#   3. Returns destination info or $null if unknown
# ========================================
function Get-CategoryFolder {
    param([string]$Extension)
    
    $ExtLower = $Extension.ToLower()
    
    if ($ImageExtensions -contains $ExtLower) {
        return $PicturesFolder, "Image", $ExtLower.TrimStart('.').ToUpper()
    }
    elseif ($VideoExtensions -contains $ExtLower) {
        return $VideosFolder, "Video", $ExtLower.TrimStart('.').ToUpper()
    }
    elseif ($AudioExtensions -contains $ExtLower) {
        return $MusicFolder, "Audio", $ExtLower.TrimStart('.').ToUpper()
    }
    
    return $null, $null, $null
}

# ========================================
# FUNCTION: Get-UniqueFileName
# Purpose: Generates a unique filename to avoid conflicts
# Parameters:
#   -DestinationPath: Folder where file will be stored
#   -FileName: Original filename
#   -Extension: File extension
# Returns: Complete unique path (adds _1, _2, etc if needed)
# Logic:
#   1. Extracts base name without extension
#   2. Checks if file already exists
#   3. If it exists, increments counter and tries again
#   4. Returns valid complete path
# ========================================
function Get-UniqueFileName {
    param(
        [string]$DestinationPath,
        [string]$FileName,
        [string]$Extension
    )
    
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $FullPath = Join-Path $DestinationPath $FileName
    $Counter = 1
    
    while (Test-Path $FullPath) {
        $NewName = "${BaseName}_${Counter}${Extension}"
        $FullPath = Join-Path $DestinationPath $NewName
        $Counter++
    }
    
    return $FullPath
}

# ========================================
# FUNCTION: Move-MediaFile
# Purpose: Moves a multimedia file to the appropriate folder
# Parameters:
#   -File: File object to move
#   -SourceDescription: Source description (for logs)
# Returns: Operation status (SUCCESS, SKIP, ERROR)
# Process:
#   1. Determines category based on extension
#   2. If category unknown, returns SKIP
#   3. Creates destination subfolder if needed
#   4. If already in correct destination, returns SKIP
#   5. Generates unique name and moves file
#   6. Records result in log
#   7. Handles exceptions (file in use, permissions, etc)
# ========================================
function Move-MediaFile {
    param(
        [System.IO.FileInfo]$File,
        [string]$SourceDescription
    )
    
    try {
        $Extension = $File.Extension
        $CategoryFolder, $CategoryName, $SubFolderName = Get-CategoryFolder $Extension
        
        # If extension is not recognized, ignore file
        if ($null -eq $CategoryFolder) {
            return "SKIP"
        }

        $DestFolder = Join-Path $CategoryFolder $SubFolderName
        
        # Creates subfolder if it doesn't exist
        if (-not (Test-Path $DestFolder)) {
            New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
        }

        # Checks if file is already in correct destination
        if ($File.DirectoryName -eq $DestFolder) {
            return "SKIP"
        }

        # Generates unique name and gets complete destination path
        $DestinationPath = Get-UniqueFileName -DestinationPath $DestFolder -FileName $File.Name -Extension $Extension
        $DestinationName = [System.IO.Path]::GetFileName($DestinationPath)

        # Moves file to new location
        Move-Item -LiteralPath $File.FullName -Destination $DestinationPath -Force -ErrorAction Stop
        
        # Records operation in log
        $LogMsg = "$($File.Name) -> $CategoryName\$SubFolderName"
        if ($DestinationName -ne $File.Name) {
            $LogMsg += " (renamed: $DestinationName)"
        }
        
        Write-Log $LogMsg "SUCCESS"
        return "SUCCESS"
    }
    catch [System.IO.IOException] {
        # File may be in use by another application
        Write-Log "File in use: $($File.Name)" "WARN"
        return "ERROR"
    }
    catch {
        # Other errors (permissions, disk full, etc)
        Write-Log "Error moving $($File.Name): $($_.Exception.Message)" "ERROR"
        return "ERROR"
    }
}

# ========================================
# PHASE 1: ORGANIZE FROM DOWNLOADS/DESKTOP/DOCUMENTS
# Processes multimedia files found in common source folders
# Handles each folder sequentially and moves files to appropriate locations
# ========================================

Write-Host "PHASE 1: Organizing files from source folders" -ForegroundColor Cyan
Write-Host ""

# Combines all supported extensions
$AllExtensions = $ImageExtensions + $VideoExtensions + $AudioExtensions

foreach ($SourceFolder in $SourceFolders) {
    # Checks if folder exists
    if (-not (Test-Path $SourceFolder)) {
        Write-Host "Folder not found: $SourceFolder" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Analyzing: $SourceFolder" -ForegroundColor White
    
    try {
        # Gets only multimedia files (not folders)
        $Files = Get-ChildItem -LiteralPath $SourceFolder -File -ErrorAction SilentlyContinue | 
                 Where-Object { $AllExtensions -contains $_.Extension.ToLower() }
        
        $FileCount = ($Files | Measure-Object).Count
        
        # If no files found, skip to next folder
        if ($FileCount -eq 0) {
            Write-Host "  No multimedia files found" -ForegroundColor Gray
            Write-Host ""
            continue
        }
        
        Write-Host "  Found $FileCount file(s)" -ForegroundColor White
        
        # Process each file
        foreach ($File in $Files) {
            $Result = Move-MediaFile -File $File -SourceDescription "source"
            
            # Updates counters
            switch ($Result) {
                "SUCCESS" { $TotalMoved++ }
                "SKIP"    { $TotalSkipped++ }
                "ERROR"   { $TotalErrors++ }
            }
        }
    } catch {
        Write-Host "  Error processing folder: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "====================================================" -ForegroundColor DarkGray
Write-Host ""

# ========================================
# PHASE 2: ORGANIZE VIDEOS ALREADY IN VIDEOS FOLDER
# Organizes videos already in Videos folder by format type
# Creates subfolders by extension (MP4, AVI, MKV, etc)
# ========================================

Write-Host "PHASE 2: Organizing Videos by type" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $VideosFolder) {
    Write-Host "Analyzing: $VideosFolder" -ForegroundColor White
    
    # Gets video files directly in Videos folder root
    $VideoFiles = Get-ChildItem -LiteralPath $VideosFolder -File -ErrorAction SilentlyContinue | 
                  Where-Object { $VideoExtensions -contains $_.Extension.ToLower() }
    
    $VideoCount = ($VideoFiles | Measure-Object).Count
    
    if ($VideoCount -eq 0) {
        Write-Host "  Videos already organized!" -ForegroundColor Green
    } else {
        Write-Host "  Found $VideoCount video(s)" -ForegroundColor White
        
        # Process each video
        foreach ($File in $VideoFiles) {
            $Extension = $File.Extension.ToLower()
            $SubFolderName = $Extension.TrimStart('.').ToUpper()
            $DestFolder = Join-Path $VideosFolder $SubFolderName
            
            # Checks if already in correct subfolder
            if ($File.DirectoryName -ne $DestFolder) {
                # Creates subfolder if it doesn't exist
                if (-not (Test-Path $DestFolder)) {
                    New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
                }
                
                try {
                    $DestPath = Get-UniqueFileName -DestinationPath $DestFolder -FileName $File.Name -Extension $Extension
                    Move-Item -LiteralPath $File.FullName -Destination $DestPath -Force -ErrorAction Stop
                    Write-Log "$($File.Name) -> Videos\$SubFolderName" "SUCCESS"
                    $TotalMoved++
                } catch {
                    Write-Log "Error moving video: $($File.Name)" "ERROR"
                    $TotalErrors++
                }
            } else {
                $TotalSkipped++
            }
        }
    }
} else {
    Write-Host "Videos folder not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkGray
Write-Host ""

# ========================================
# PHASE 3: ORGANIZE AUDIO FILES ALREADY IN MUSIC FOLDER
# Organizes audio files already in Music folder by format type
# Creates subfolders by extension (MP3, WAV, FLAC, etc)
# ========================================

Write-Host "PHASE 3: Organizing Audio files by type" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $MusicFolder) {
    Write-Host "Analyzing: $MusicFolder" -ForegroundColor White
    
    # Gets audio files directly in Music folder root
    $MusicFiles = Get-ChildItem -LiteralPath $MusicFolder -File -ErrorAction SilentlyContinue | 
                  Where-Object { $AudioExtensions -contains $_.Extension.ToLower() }
    
    $MusicCount = ($MusicFiles | Measure-Object).Count
    
    if ($MusicCount -eq 0) {
        Write-Host "  Audio files already organized!" -ForegroundColor Green
    } else {
        Write-Host "  Found $MusicCount audio file(s)" -ForegroundColor White
        
        # Process each audio file
        foreach ($File in $MusicFiles) {
            $Extension = $File.Extension.ToLower()
            $SubFolderName = $Extension.TrimStart('.').ToUpper()
            $DestFolder = Join-Path $MusicFolder $SubFolderName
            
            # Checks if already in correct subfolder
            if ($File.DirectoryName -ne $DestFolder) {
                # Creates subfolder if it doesn't exist
                if (-not (Test-Path $DestFolder)) {
                    New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
                }
                
                try {
                    $DestPath = Get-UniqueFileName -DestinationPath $DestFolder -FileName $File.Name -Extension $Extension
                    Move-Item -LiteralPath $File.FullName -Destination $DestPath -Force -ErrorAction Stop
                    Write-Log "$($File.Name) -> Music\$SubFolderName" "SUCCESS"
                    $TotalMoved++
                } catch {
                    Write-Log "Error moving audio file: $($File.Name)" "ERROR"
                    $TotalErrors++
                }
            } else {
                $TotalSkipped++
            }
        }
    }
} else {
    Write-Host "Music folder not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkGray
Write-Host ""

# ========================================
# PHASE 4: ORGANIZE IMAGES ALREADY IN PICTURES FOLDER
# Organizes image files already in Pictures folder by format type
# Creates subfolders by extension (JPG, PNG, GIF, etc)
# ========================================

Write-Host "PHASE 4: Organizing Images by type" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $PicturesFolder) {
    Write-Host "Analyzing: $PicturesFolder" -ForegroundColor White
    
    # Gets image files directly in Pictures folder root
    $ImageFiles = Get-ChildItem -LiteralPath $PicturesFolder -File -ErrorAction SilentlyContinue | 
                  Where-Object { $ImageExtensions -contains $_.Extension.ToLower() }
    
    $ImageCount = ($ImageFiles | Measure-Object).Count
    
    if ($ImageCount -eq 0) {
        Write-Host "  Images already organized!" -ForegroundColor Green
    } else {
        Write-Host "  Found $ImageCount image(s)" -ForegroundColor White
        
        # Process each image file
        foreach ($File in $ImageFiles) {
            $Extension = $File.Extension.ToLower()
            $SubFolderName = $Extension.TrimStart('.').ToUpper()
            $DestFolder = Join-Path $PicturesFolder $SubFolderName
            
            # Checks if already in correct subfolder
            if ($File.DirectoryName -ne $DestFolder) {
                # Creates subfolder if it doesn't exist
                if (-not (Test-Path $DestFolder)) {
                    New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
                }
                
                try {
                    $DestPath = Get-UniqueFileName -DestinationPath $DestFolder -FileName $File.Name -Extension $Extension
                    Move-Item -LiteralPath $File.FullName -Destination $DestPath -Force -ErrorAction Stop
                    Write-Log "$($File.Name) -> Pictures\$SubFolderName" "SUCCESS"
                    $TotalMoved++
                } catch {
                    Write-Log "Error moving image: $($File.Name)" "ERROR"
                    $TotalErrors++
                }
            } else {
                $TotalSkipped++
            }
        }
    }
} else {
    Write-Host "Pictures folder not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkGray
Write-Host ""

# ========================================
# FINAL REPORT
# Displays consolidated execution statistics
# Shows: files moved, ignored, errors, total time
# ========================================

$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-Host "FINAL REPORT" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Files moved:       $TotalMoved" -ForegroundColor Green
Write-Host "  Files ignored:     $TotalSkipped" -ForegroundColor Gray
Write-Host "  Errors found:      $TotalErrors" -ForegroundColor Red
Write-Host "  Execution time:    $([math]::Round($Duration, 2))s" -ForegroundColor Cyan
Write-Host ""
Write-Host "Complete log: $LogFile" -ForegroundColor Gray
Write-Host ""

# ========================================
# OLD LOGS CLEANUP
# Removes log files older than 30 days
# Implements log retention to prevent accumulation
# ========================================
try {
    $OldLogs = Get-ChildItem -Path $LogFolder -Filter "AntiOrganizer_*.txt" -ErrorAction SilentlyContinue | 
               Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }

    if ($OldLogs) {
        $OldLogs | Remove-Item -Force
        Write-Host "Removed $($OldLogs.Count) old log(s)" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    # Ignore cleanup errors
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# ========================================
# EXIT CODE
# Returns 0 if everything ran successfully
# Returns 1 if errors occurred
# ========================================
if ($TotalErrors -gt 0) {
    exit 1
} else {
    exit 0
}
