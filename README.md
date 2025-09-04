# MM Add-ons for Home Assistant

This repository contains custom Home Assistant add-ons.

## Available Add-ons

### Kamailio + rtpengine (SIP/WebRTC bridge)

This add-on provides a WebRTC-to-SIP bridge that allows Home Assistant users to integrate the [SIP Hass Card](https://github.com/TECH7Fox/sip-hass-card) with SIP devices such as **Dahua doorbells**, which only support insecure SIP/UDP with plain RTP.

- Provides a secure **WSS (WebSocket Secure) endpoint** with TLS for browser clients.
- Registers to the Dahua SIP server as a standard SIP extension (scoped only to your extension, without affecting other users).
- Converts media streams between **SRTP (WebRTC)** and **RTP (Dahua/legacy SIP)** via rtpengine.
- Uses the existing TLS certificates from `/ssl` in Home Assistant (e.g., Let’s Encrypt).

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Open the menu (⋮) in the top right corner and select **Repositories**.
3. Add this repository URL:

   ```
   https://github.com/marcomiani/ha-addons
   ```

4. The add-ons from this repository will now appear in the store.

## Notes

- These add-ons are provided as-is, primarily for advanced users who want to integrate SIP devices into Home Assistant without deploying a full PBX such as Asterisk.
- They are designed to be minimal and focused on bridging functionality.

## Maintainer

Marco ( marco@marcomiani.it )
