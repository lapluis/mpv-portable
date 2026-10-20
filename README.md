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

Close mpv before updating. Run the following commands from the `mpv` directory:

```powershell
git pull
.\update-mpv.ps1
```

`git pull` updates the configuration and scripts. `update-mpv.ps1` downloads and installs the latest matching mpv build.

Existing matching files are overwritten during the update. Other files, including `portable_config`, are preserved.