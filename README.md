![Windows](https://img.shields.io/badge/Windows-0079d5?style=flat&logo=windows&logoColor=white) ![LICENSE](https://img.shields.io/github/license/FelipeCalliari/WindowsRamdisk)

# Windows RAMDisk

Move several cache folders to a RAMDisk to either speed things up and save your SSD.

The current version creates symbolic links for cache folders of some applications, such as:

+ Google Chorme (stable, beta, dev)
+ Opera and Opera GX (stable)
+ Mozilla Firefox
+ Microsoft Edge
+ VS Code
+ Discord
+ Steam

After the RAMDisk is created you can store anything inside it, however all the files inside it are removed on shutdown/reboot. 

As Windows doesn't have native support for RAMDisks, the `install.bat` batch script installs `OSFMount` through the use of `winget`. However, you can download `OSFMount` from here: https://www.osforensics.com/tools/mount-disk-images.html

This tools has some **persistent** features (if enabled), i.e., the `cookies` of some browsers can be placed inside the RAMDisk. It means that some folders/files are stored so you won't lose them amoung reboots. To do so, the `install.bat` script creates two tasks:

1. RAMDisk_OnLogon: which create the ramdisk and copy persistent files from the SDD to the RAMDisk
2. RAMDisk_SavePersistent: to save persistent files every 30 minutes, on session logout or shutdown events.

**Important**: This tool does not create a symbolic link to %TEMP% or %TMP%, as during installation of software or Windows updates, they may fail due to lack of space (memory) on the RAMDisk.

## **Settings**

This batch script read the configurations from `settings.ini` and then creates the RAMDisk as letter

```
; install settings
[install]
useUserProfile=true
folder=

; general settings
[settings]
autosave=true
persistent=true

; ramdisk settings
[ramdisk]
letter=B:
size=2G
```

+ letter: the letter which will be assigned to the RAMDisk.
+ size: the amount of memory will be used for the RAMDisk.
+ useUserProfile: this tool is installed on `"%LOCALAPPDATA%\WRamdisk"` by default this variable is set to *TRUE*.
+ autosave: will create a persistent folder inside the program's folder.
+ persistent: means you wanna create symlinks for some persistent files and if set to *TRUE* the windows task `RAMDisk_SavePersistent` will copy this files from the RAMDisk to the SSD. By default, the persistent files are stored on `"%LOCALAPPDATA%\WRamdisk\persistent"`.

## **Contribution**

This is an open-source project. If you like this scripts and wanna help improve it, feel free to contribute! 😎
