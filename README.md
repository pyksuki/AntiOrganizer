# AntiOrganizer

**Complete Multimedia File Organization Tool for Windows**

![Version](https://img.shields.io/badge/version-3.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows-lightgray)
![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue)

A powerful, automated PowerShell script that intelligently organizes your multimedia files across your system. AntiOrganizer scans multiple source folders, identifies media files by type (images, videos, audio), and automatically sorts them into organized directory structures using file format as the organizing principle.


## Features

- **Automatic User Detection**: Detects and uses the current Windows user profile automatically
- **Multi-Source Organization**: Scans Downloads, Documents, and Desktop folders simultaneously
- **Smart File Categorization**: Recognizes 60+ multimedia file formats across 3 categories
- **Format-Based Organization**: Creates subfolders organized by file format (JPG, MP4, MP3, etc.)
- **Duplicate Prevention**: Intelligently handles naming conflicts with automatic renaming
- **Comprehensive Logging**: Creates detailed logs of all operations with timestamps



## Supported File Types

### Images (22 formats)
JPG, JPEG, PNG, GIF, BMP, SVG, WebP, ICO, TIFF, TIF, HEIC, HEIF, RAW, CR2, NEF, ARW, DNG, PSD, AI, EPS

### Videos (18 formats)
MP4, AVI, MKV, MOV, WMV, FLV, WebM, M4V, MPEG, MPG, 3GP, OGV, VOB, MTS, TS, M2TS

### Audio (13 formats)
MP3, WAV, FLAC, AAC, OGG, WMA, M4A, Opus, ALAC, AIFF, APE, AC3, MP2


## Installation

### Prerequisites
- Windows 7 or later
- PowerShell 3.0 or later (PowerShell 7+ recommended)
- Administrator privileges (optional but recommended)

### Setup Steps

1. **Download the Script**
```powershell
   git clone https://github.com/yourusername/antiorganizer.git
   cd antiorganizer
```

2. **Check PowerShell Version**
```powershell
   $PSVersionTable.PSVersion
```

## Usage

### Basic Execution
```powershell
.\scripts\antiorganizer.ps1
```

### What the Script Does

The script operates in **4 distinct phases**:

#### Phase 1: Source Folder Organization
- Scans: Downloads, Documents, Desktop
- Moves all recognized multimedia files to appropriate folders

#### Phase 2: Video Organization
- Organizes videos in Videos folder by format
- Creates subfolders by extension (MP4, AVI, MKV, etc.)

#### Phase 3: Audio Organization
- Organizes audio files in Music folder

#### Phase 4: Image Organization
- Organizes images in Pictures folder

### Output

After execution, you see:
- **Files Moved**: Count of successfully organized files
- **Files Ignored**: Already in correct location
- **Errors Found**: Files that had issues
- **Execution Time**: How long it took

3. **Run the Script**
```powershell
   .\scripts\antiorganizer.ps1
```



## Usage

### Basic Execution
```powershell
.\scripts\antiorganizer.ps1
```

### What the Script Does

The script operates in **4 distinct phases**:

#### Phase 1: Source Folder Organization
- Scans: Downloads, Documents, Desktop
- Moves all recognized multimedia files to appropriate folders

#### Phase 2: Video Organization
- Organizes videos in Videos folder by format
- Creates subfolders by extension (MP4, AVI, MKV, etc.)

#### Phase 3: Audio Organization
- Organizes audio files in Music folder

#### Phase 4: Image Organization
- Organizes images in Pictures folder

### Output
After execution, you see:
- **Files Moved**: Count of successfully organized files
- **Files Ignored**: Already in correct location
- **Errors Found**: Files that had issues
- **Execution Time**: How long it took




After execution, you see:
- **Files Moved**: Count of successfully organized files
- **Files Ignored**: Already in correct location
- **Errors Found**: Files that had issues
- **Execution Time**: How long it took

<img width="1095" height="567" alt="Screenshot 2025-11-28 201239" src="https://github.com/user-attachments/assets/fc9edeff-b6d9-4a57-b266-1206fdf3e3d7" />


## Examples

### Example 1: Basic Organization

Before running:

<img width="1128" height="465" alt="image" src="https://github.com/user-attachments/assets/9afb4927-b88c-4ae9-8f81-668789209866" />

After running:

<img width="458" height="215" alt="image" src="https://github.com/user-attachments/assets/55d4b31e-0b8b-4633-9353-5317b41d429e" />

<img width="1138" height="403" alt="image" src="https://github.com/user-attachments/assets/4c1d71d5-d826-4aab-a829-389eccde6cab" />

### Example 2: Run on Schedule
```powershell
# Use Windows Task Scheduler to run daily at 10 PM
# Program: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# Arguments: -File "C:\Scripts\antiorganizer.ps1"
```
## Troubleshooting

### Issue: "cannot be loaded because running scripts is disabled"

**Cause**: PowerShell execution policy is too strict

**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Issue: "Permission Denied" errors

**Cause**: Insufficient file permissions

**Solution**: Run PowerShell as Administrator

### Issue: Files don't move

**Cause**: Could be several things - check the log file

**Debug**:
```powershell
Get-Content "$env:USERPROFILE\Documents\AntiOrganizer_Logs\*.txt" | Select-Object -Last 20
```


