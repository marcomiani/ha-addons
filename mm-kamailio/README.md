# Kamailio — SIP Gateway Add-on per Home Assistant

Add-on per Home Assistant che funge da **gateway SIP** tra client WebRTC/WSS
(es. [sipcore-hass-integration](https://github.com/TECH7Fox/sipcore-hass-integration))
e server SIP con protocollo plain UDP/TCP (es. videocitofoni Dahua).

---

## Problema e motivazione

I videocitofoni Dahua espongono un server SIP su UDP/5060, non cifrato e senza
supporto WebSocket. L'integrazione
[sipcore-hass-integration](https://github.com/TECH7Fox/sipcore-hass-integration)
(basata su JsSIP/WebRTC) richiede invece una connessione **WSS** (SIP over Secure
WebSocket) e gestisce il media come **SRTP con ICE e DTLS**.

I due mondi sono quindi incompatibili senza un intermediario. Questo add-on risolve
il problema senza richiedere un PBX completo (es. Asterisk): il citofono rimane il
server SIP della rete, Kamailio fa solo da traduttore al bordo.

---

## Architettura

```
┌──────────────────────────────────────┐
│  Tablet / App HA Companion           │
│  JsSIP  ·  WebRTC  ·  SRTP + ICE     │
└────────────────┬─────────────────────┘
                 │  SIP over WSS  (TLS, porta wss_port default 8443)
                 ▼
┌────────────────────────────────────────────────────┐
│  Kamailio Add-on  (host network, stesso IP di HA)   │
│                                                    │
│  Kamailio                                          │
│  ├─ WSS listener   :  tls:0.0.0.0:<wss_port>       │
│  └─ SIP/UDP listener: udp:0.0.0.0:5060             │
│                                                    │
│  rtpengine  (media relay locale)                   │
│  ├─ binding RTP su IP LAN rilevato                 │
│  └─ controllo via socket udp:127.0.0.1:2223        │
└───────────────┬────────────────────────────────────┘
                │  SIP/UDP  (porta 5060)
                ▼
┌─────────────────────────────┐
│  Videocitofono Dahua        │
│  SIP server  ·  plain RTP   │
└─────────────────────────────┘
```

### Flusso segnalazione (SIP)

| Direzione                   | Cosa fa Kamailio                                                                                               |
| --------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **REGISTER** tablet → Dahua | Codifica l'endpoint WSS nell'alias del Contact; riscrive il Contact con l'IP UDP di Kamailio; forwarda a Dahua |
| **INVITE** tablet → Dahua   | Stripping ICE/DTLS dall'SDP (via rtpengine); relay UDP verso Dahua                                             |
| **INVITE** Dahua → tablet   | Lookup dell'alias WSS in htable; aggiunta ICE + DTLS all'SDP (via rtpengine); relay sulla connessione WSS      |
| **In-dialog** (ACK, BYE, …) | Loose routing via Record-Route                                                                                 |

### Flusso media (RTP)

rtpengine fa da proxy per il traffico audio/video:

- **Lato WSS** (tablet): accetta SRTP con negoziazione DTLS e candidati ICE
- **Lato UDP** (Dahua): forwarda plain RTP, senza ICE né DTLS
- Risolve i problemi di NAT traversal anche quando tablet e citofono si trovano su
  segmenti di rete diversi

---

## Requisiti

| Requisito                                                                        | Note                                                                         |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Home Assistant con Supervisor                                                    | Richiesto per il sistema add-on                                              |
| HTTPS attivo su HA                                                               | Obbligatorio per WSS; il browser blocca WebSocket non sicuri su pagine HTTPS |
| Certificato TLS valido                                                           | Generato ad es. dall'add-on **DuckDNS**; i file devono trovarsi in `/ssl/`   |
| Videocitofono Dahua (o SIP/UDP compatibile)                                      | Configurato con account SIP (interni) registrabili dall'esterno              |
| [sipcore-hass-integration](https://github.com/TECH7Fox/sipcore-hass-integration) | Installato tramite HACS nel frontend di HA                                   |

---

## Installazione

1. Aggiungere questo repository come **add-on repository** nel Supervisor di HA.
2. Installare l'add-on **Kamailio SIP Gateway**.
3. Configurare le opzioni (vedi sezione seguente).
4. Avviare l'add-on e verificare i log.

---

## Configurazione add-on

Le opzioni si impostano nella scheda _Configurazione_ dell'add-on.

| Opzione      | Default         | Descrizione                                                      |
| ------------ | --------------- | ---------------------------------------------------------------- |
| `dahua_ip`   | `192.168.1.92`  | Indirizzo IP del videocitofono / server SIP Dahua sulla LAN      |
| `dahua_port` | `5060`          | Porta UDP del server SIP Dahua                                   |
| `wss_port`   | `8443`          | Porta TCP/TLS su cui Kamailio accetta connessioni WSS dal tablet |
| `certfile`   | `fullchain.pem` | Nome del file certificato TLS nella directory `/ssl/`            |
| `keyfile`    | `privkey.pem`   | Nome del file chiave privata TLS nella directory `/ssl/`         |

Esempio `options` in YAML:

```yaml
dahua_ip: "192.168.1.92"
dahua_port: 5060
wss_port: 8443
certfile: "fullchain.pem"
keyfile: "privkey.pem"
```

---

## Configurazione sipcore-hass-integration

> **Importante** — questo add-on **non** implementa il path
> `/api/sip-core/asterisk-ingress` che sipcore usa per rilevare automaticamente
> l'URL WebSocket dell'add-on Asterisk. È necessario impostare `custom_wss_url`
> esplicitamente nella configurazione JSON di sipcore.

Il campo `custom_wss_url` deve puntare all'IP (o dominio) di Home Assistant sulla
porta `wss_port` configurata nell'add-on:

```json
{
  "custom_wss_url": "wss://<indirizzo-ha>:<wss_port>",
  "pbx_server": "",
  "users": [{ "ha_username": "mario", "extension": "901", "password": "secret" }]
}
```

### Esempi

**Accesso locale (LAN):**

```json
{ "custom_wss_url": "wss://192.168.1.11:8443" }
```

**Accesso tramite dominio DuckDNS:**

```json
{ "custom_wss_url": "wss://home.miodominio.it:8443" }
```

> `pbx_server` può essere lasciato vuoto: è `custom_wss_url` a determinare il
> gateway SIP a cui JsSIP si connette.  
> Gli `extension` e `password` degli utenti devono corrispondere agli account SIP
> configurati sul Dahua.

---

## Architettura tecnica (componenti interni)

| Componente      | Versione / pacchetto Alpine                             | Ruolo                                           |
| --------------- | ------------------------------------------------------- | ----------------------------------------------- |
| **Kamailio**    | `kamailio` 5.7.x (Alpine 3.19)                          | Proxy SIP: signaling WSS ↔ UDP                  |
| **rtpengine**   | `rtpengine` (Alpine 3.19 community)                     | Media relay: SRTP/ICE ↔ plain RTP               |
| Moduli Kamailio | `kamailio-tls`, `kamailio-websocket`, `kamailio-extras` | TLS, WebSocket, htable, nathelper, rtpengine.so |

L'add-on gira in **host network** (`host_network: true`) per ricevere correttamente
il traffico UDP/SIP proveniente dal citofono e per permettere a rtpengine di fare
binding sull'IP LAN reale.

rtpengine viene avviato dallo stesso entrypoint (`run.sh`) prima di Kamailio,
con binding sull'IP LAN rilevato automaticamente tramite `ip route get <dahua_ip>`.
Il socket di controllo (NG protocol) è `udp:127.0.0.1:2223`, utilizzato
esclusivamente da Kamailio in loopback.

---

## Architetture supportate

`aarch64` · `amd64` · `armhf` · `armv7` · `i386`
