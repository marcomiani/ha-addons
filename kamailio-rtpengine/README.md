# Kamailio + rtpengine (SIP/WebRTC bridge) Add-on for Home Assistant

This add-on allows you to use the [SIP Hass Card](https://github.com/TECH7Fox/sip-hass-card) with Dahua doorbells (or any SIP devices that only support plain SIP/UDP).  
The card in the browser speaks **WebRTC (WSS + DTLS-SRTP)**, while Dahua devices use **SIP/UDP + RTP**.  
The add-on acts as a **transparent gateway**:

- towards the card it provides a **secure WSS endpoint** with TLS;
- towards the Dahua it registers as a regular SIP client and bridges the media using **rtpengine**.

---

## Features

- SIP **WSS ↔ UDP** proxy with Kamailio.
- Media conversion **SRTP ↔ RTP** with rtpengine.
- Automatic registration to the Dahua SIP server only for your extension (does not interfere with other users).
- Reuses TLS certificates already available in `/ssl` on Home Assistant (e.g. Let’s Encrypt).
- No dependency on Asterisk/FreePBX.

---

## Configuration

1. Install the add-on from this repository.
2. Configure the **Options** in the Home Assistant UI:

```yaml
ws_port: 7443 # TCP port for WSS (change if it conflicts)
advertised_ip: "192.168.1.114" # Local IP of Home Assistant
dahua_addr: "192.168.1.50:5060" # IP:port of Dahua SIP server
ext_kam: "1000" # Extension assigned to you on Dahua server
pwd_kam: "xxxxxxxx" # Corresponding password
ext_card: "2000" # User that the SIP Hass Card will use
pwd_card: "yyyyyyyy" # Password for the Card
```

3. Start the add-on. In the logs you should see:
   - `env ok: ...` with the configured values
   - Kamailio listening on `udp:5060` and `tls:<ws_port>`
   - rtpengine listening on `127.0.0.1:22222`
   - UAC registration to Dahua: `Registered`.

---

## SIP Hass Card Configuration

Example Lovelace card configuration:

```yaml
type: custom:sip-hass-card
server: wss://home.marcomiani.it:7443
display_name: "Doorbell"
uri: "sip:2000@home.marcomiani.it"
password: "yyyyyyyy"
ice_servers:
  - urls: stun:stun.l.google.com:19302
```

- `server`: WSS URL of the add-on (use your domain with a valid certificate).
- `uri`: user configured (`ext_card`).
- `password`: password for the card (`pwd_card`).
- `ice_servers`: optional on LAN, useful for remote access.

---

## Ports Used

- UDP **5060**: SIP to/from Dahua
- TCP **7443** (configurable): WSS to the card
- UDP **49000–50000**: RTP handled by rtpengine

On LAN no router changes are required.  
For remote access forward these ports to your Home Assistant host.

---

## Notes

- If the add-on is stopped, Home Assistant continues to work normally.
- If port 7443 is already used, change it in `ws_port` (e.g. 7444) and update the card config.
- This add-on is **scoped to a single extension**: it does not modify or interfere with other users on the Dahua SIP server.
