![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/gpu-screen-recorder-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/gpu-screen-recorder-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/gpu-screen-recorder-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/gpu-screen-recorder-debian?display_date=published_at)

<h1>
   <p align="center">
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/gpu-screen-recorder-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104"></a>
     <br>GPU Screen Recorder for Debian
   </p>
</h1>
<p align="center">
 A shadowplay-like screen recorder for Linux that records using the GPU only.
</p>

# GPU Screen Recorder for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [GPU Screen Recorder](https://git.dec05eba.com/gpu-screen-recorder/about/)
hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Jammy (22.04) is not supported: its FFmpeg (4.4) and Vulkan headers are too old
to build GPU Screen Recorder.

Supported architectures:
- amd64 (x86_64)

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the GPU Screen Recorder source code, see
[gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/).

## What's in the package

The package is `gpu-screen-recorder-cli`, the same name Debian uses. Releases up
to 6.1.3+1 called it `gpu-screen-recorder`; that name is now a transitional
package that pulls in `gpu-screen-recorder-cli`, so `apt upgrade` moves you over.

- `gpu-screen-recorder`, `gsr-cli` and `gsr-kms-server`. The package grants
  `gsr-kms-server` `cap_sys_admin` on install, as upstream does, so recording a
  monitor on AMD/Intel (or NVIDIA on Wayland) doesn't ask for a password.
- Upstream's helper scripts in `/usr/share/gpu-screen-recorder/scripts`.
- A systemd user service, `gpu-screen-recorder.service`, **not enabled**. It
  records while it runs; enable it yourself with
  `systemctl --user enable --now gpu-screen-recorder` and configure it in
  `~/.config/gpu-screen-recorder.env`.

Not included: upstream's NVIDIA modprobe file (`gsr-nvidia.conf`), which changes
the NVIDIA driver's suspend behaviour for the whole system. It replaces Debian's
`gpu-screen-recorder-dev`, `-scripts` and `-service` packages, whose files are
all in this one.

## Install/Update

### The Debian way

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y gpu-screen-recorder-cli
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/gpu-screen-recorder-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo apt install ./<filename>.deb
```

## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## How releases are made

Upstream has no GitHub releases, tarballs or signed tags, only git tags at
`https://repo.dec05eba.com/gpu-screen-recorder`. So:

- `check-upstream.yml` polls the tags hourly and dispatches a build for the
  newest `X.Y.Z` once it is 6 hours old (upstream often ships quick patch releases).
- `fetch_source.sh` checks the tag against `upstream-tags.lock` (a tag that has
  moved stops the build; a new one is pinned on first use), checks `LICENSE` is
  still GPL-3.0, and archives the tagged commit as a reproducible `.orig.tar.gz`.
- Each distribution is compiled from that tarball in its own container.

## Building

Requires Docker, git and dpkg-dev.

```sh
./build.sh <version> <build_version>
# Example: ./build.sh 6.1.3 1
```

Or step by step, for a single distribution:

```sh
./fetch_source.sh 6.1.3
./build_deb.sh 6.1.3 1 trixie
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [ ] arm64 support
- [ ] GPU Screen Recorder UI

## Disclaimer

- This repo is not open for issues related to GPU Screen Recorder. This repo is only for _unofficial_ Debian packaging.
