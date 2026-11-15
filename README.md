# mpv-portable

Portable mpv configuration and updater for Windows.

## Install

Clone this repository into the `mpv` directory, then run the update script to download mpv.

```powershell
git clone git@github.com:lapluis/mpv-portable.git mpv
cd mpv
.\update-mpv.ps1
```

Alternatively, use HTTPS instead of SSH:

```powershell
git clone https://github.com/lapluis/mpv-portable.git mpv
```

## Update

Close mpv, then double-click `update-mpv.bat` in the `mpv` directory to download and install the latest matching mpv build. When the update finishes, press any key to close the window.

To update the repository and mpv together, run these commands from the `mpv` directory:

```powershell
git pull
.\update-mpv.ps1
```

`git pull` updates the configuration and scripts. `update-mpv.ps1` downloads and installs the latest matching mpv build.

Existing matching files are overwritten during the update. Other files, including `portable_config`, are preserved.