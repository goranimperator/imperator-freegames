# Mac Desktop App Integration Guide

Dokumentation för att bygga en macOS desktop-app som speglar
free-games-systemet med native push-notifications när nya spel dyker upp.

## TL;DR

Sajten exponerar redan publik JSON på
`https://www.goranimperator.com/data/free-games.json`. En desktop-app
kan polla den (eller bygga egen fetcher direkt mot ITAD), diff:a mot
föregående snapshot, och visa native notification per nytt spel.

---

## Två arkitektur-alternativ

### Alternativ 1: Polla sajtens JSON (REKOMMENDERAT)

Enklast och kostnadsfritt. Sajten redan kör cron varje timme; appen läser
samma fil och slipper ITAD API-nyckel.

```
[Mac App]
   │ var 30 min: GET https://www.goranimperator.com/data/free-games.json
   ▼
[Diff mot localStorage/disk]
   │ nya id:n?
   ▼
[Native macOS Notification per nytt spel]
```

**Fördelar:**
- Ingen ITAD-key behövs
- Samma data som sajten — alltid synkat
- Ingen rate-limit-risk (1 request per intervall mot statisk fil)
- Cloudflare cachar — snabbt svar

**Nackdelar:**
- Pollar med 1h fördröjning som värst (server cron-intervall)
- Beroende av att sajten är uppe

### Alternativ 2: Egen fetcher direkt mot ITAD

App pollar ITAD API själv med egen API-nyckel.

**Fördelar:**
- Helt fristående, ingen sajt-koppling
- Kan polla oftare än servern

**Nackdelar:**
- Behöver egen ITAD API-nyckel (gratis, men registrering krävs)
- Mer kod att underhålla
- Behöver replikera enrichment-logiken (description, year, developer)

Resten av detta dokument fokuserar på **Alternativ 1**.

---

## Data-format

Sajten servar denna JSON-struktur på `/data/free-games.json`:

```json
{
  "updatedAt": "2026-05-20T14:00:00.123Z",
  "platforms": {
    "steam": [
      {
        "id": "018d937f-e5db-7245-90e6-d2c5b51fe19b",
        "title": "Game Title",
        "description": "Short description from Steam.",
        "year": 2020,
        "developer": "Studio Name",
        "url": "https://store.steampowered.com/app/12345/",
        "regularPrice": "19.99 USD",
        "addedAt": "2026-05-20T14:00:00.123Z"
      }
    ],
    "epic": [ /* samma format */ ],
    "gog":  [ /* samma format */ ]
  }
}
```

### Fält-beskrivning

| Fält           | Typ      | Innehåll                                       |
|----------------|----------|------------------------------------------------|
| `id`           | string   | ITAD UUID — **unik identifierare**, använd för diff |
| `title`        | string   | Spelnamn                                       |
| `description`  | string   | Kort beskrivning (Steam-spel har det, Epic/GOG saknar oftast) |
| `year`         | number   | Release-år                                     |
| `developer`    | string   | Förste utvecklaren                             |
| `url`          | string   | Direktlänk till store-sidan                    |
| `regularPrice` | string   | Pris före rabatt, t.ex. `"19.99 USD"`           |
| `addedAt`      | string   | ISO-timestamp när spelet först sågs som fritt   |

**Viktigt:** `id` är garanterat stabil och unik per spel. Använd den för
diff:en — INTE titel (kan ändras) och INTE url (Epic-URL:er kan flyttas).

### Max antal entries

JSON:en innehåller upp till **10 spel per plattform** (max 30 totalt).
Servern roterar ut spel när de inte längre är fria, så listan är alltid
"de 10 senaste fortfarande-fria per plattform".

---

## Polling-strategi

```
1. Vid app start:
   - Läs ditt sparade `seenIds` set från disk (eller skapa nytt)
   - Fetch JSON → spara `lastSeenPayload`
   - Lägg ALLA aktuella id:n i seenIds (initial run skickar inga notiser)

2. Varje 30 minuter (eller intervall du väljer):
   - Fetch JSON
   - För varje plattform, för varje game:
     - Om game.id NOT IN seenIds → NYTT SPEL → skicka notification
     - Lägg game.id i seenIds
   - Spara seenIds till disk
```

### Rekommenderat intervall

- **30 min**: balans mellan snabb upptäckt och energiförbrukning
- **15 min**: snabbare men onödigt (servern uppdaterar varje timme)
- **60 min+**: kan missa kortvariga giveaways (t.ex. Epic 24h-spel)

### Cache-busting

JSON-filen får cache-headers från Cloudflare. För att alltid få färsk
data, lägg till en query-param som ändras varje request:

```
https://www.goranimperator.com/data/free-games.json?t=1716210000
```

Eller använd `Cache-Control: no-cache` request-header.

---

## State-hantering (på Mac-appen)

Spara ett enkelt JSON-objekt på disk i appens support-dir:

```
~/Library/Application Support/FreeGamesWatcher/state.json
```

```json
{
  "seen": {
    "steam": ["018d937f-...", "018e042a-..."],
    "epic": ["..."],
    "gog": ["..."]
  },
  "lastFetched": "2026-05-20T14:00:00.000Z"
}
```

Begränsa varje array till ~50 senaste id:n (FIFO) för att hålla filen
liten. Samma pattern som servern använder (`HISTORY_LIMIT = 50` i
`lib/state.js`).

---

## Notification-format

Per nytt spel, visa en native macOS notification:

```
Title:    🎮 Free on Steam
Subtitle: Game Title (was $19.99)
Body:     Short description if available
Action:   Click → öppna game.url i default browser
```

Eller en summerande notification om flera nya samtidigt:

```
Title:    🎮 3 new free games
Body:     2 on Steam, 1 on Epic — tap to view
Action:   Click → öppna https://www.goranimperator.com/free-games
```

### macOS Notification APIs

- **Swift/AppKit**: `UNUserNotificationCenter` (kräver permission-prompt
  vid första körning via `requestAuthorization`)
- **Electron**: `new Notification(title, { body, icon })` — funkar utan
  prompt om appen är signed/notarized
- **Tauri**: `tauri-plugin-notification`
- **Bun/Node CLI**: `osascript -e 'display notification ...'` som
  fallback (begränsad, ingen interactivity)

---

## Tech stack-förslag

### A. Native Swift / SwiftUI (rekommenderat för Mac-only)
- Liten binär, native känsla, system-integration (menubar, login items)
- `URLSession` för fetch, `UserDefaults` för state, `UNUserNotificationCenter`
  för notifications
- Background fetch via `NSBackgroundActivityScheduler` (kan polla även
  när appen är "stängd" men har inloggad bakgrundsdel)

### B. Tauri (Rust + WebView)
- Liten binär (~10 MB), cross-platform om du senare vill ha Win/Linux
- Återanvänd React-komponenter om du vill matcha sajtens look

### C. Electron
- Större (100 MB+) men enklast — bara JS, samma kod som sajten
- Native notifications via `Notification` API

### D. Menubar-app via Bun + osascript
- Snabb prototyp, kör som launchd-tjänst
- Mindre polerat men funkar

---

## Pseudo-kod (språk-agnostisk)

```
const FEED_URL = "https://www.goranimperator.com/data/free-games.json"
const POLL_MS = 30 * 60 * 1000
const PLATFORMS = ["steam", "epic", "gog"]

let state = loadStateFromDisk()  // { seen: { steam: [], epic: [], gog: [] } }

async function tick() {
  const res = await fetch(`${FEED_URL}?t=${Date.now()}`)
  const data = await res.json()

  const newGames = []
  for (const platform of PLATFORMS) {
    const seen = new Set(state.seen[platform])
    for (const game of data.platforms[platform]) {
      if (!seen.has(game.id)) {
        newGames.push({ ...game, platform })
        state.seen[platform].push(game.id)
        // FIFO-trim
        if (state.seen[platform].length > 50) {
          state.seen[platform] = state.seen[platform].slice(-50)
        }
      }
    }
  }

  if (newGames.length > 0) {
    saveStateToDisk(state)
    for (const game of newGames) {
      showNotification({
        title: `🎮 Free on ${capitalize(game.platform)}`,
        subtitle: `${game.title}${game.regularPrice ? ` (was ${game.regularPrice})` : ""}`,
        body: game.description || "Free to claim now",
        actionUrl: game.url,
      })
    }
  }
}

// Initial run: prime seen-set utan notiser
await fetch(FEED_URL).then(seedSeen)
setInterval(tick, POLL_MS)
```

---

## Edge cases att tänka på

1. **Första körningen**: prime `seen`-setet med alla nuvarande id:n så
   du inte spammar med ~30 notiser direkt vid install.

2. **Spel återkommer**: ett spel som var fritt → inte fritt → fritt igen
   kommer ha samma `id`. Din `seen`-historik gör att det inte triggar
   igen. Om du vill ha det, rensa det specifika id:t från `seen` när
   det faller ur den aktuella listan.

3. **Offline / fel**: fail silently (eller logga lokalt). Polla nästa
   intervall. Visa inte error-notifications.

4. **Rate limits**: Cloudflare cachar JSON:en. Pollar du < 1 gång per
   minut är det helt OK.

5. **Många nya samtidigt**: gruppera istället för att skicka 10 notiser
   i rad. macOS slår ihop dem ändå men din UX blir bättre om du själv
   skickar en "5 new free games"-notification.

6. **App-ikon**: använd ett av våra sigil-favicons i `/public/` — t.ex.
   `gi-sigil-180.png` eller bygg en `.icns` (vi har redan en på
   `/public/GISigil.icns`).

---

## Servern (om du vill verifiera live)

```sh
# Hämta nuvarande data
curl -s https://www.goranimperator.com/data/free-games.json | jq .

# Bara titlar per plattform
curl -s https://www.goranimperator.com/data/free-games.json | \
  jq -r '.platforms | to_entries[] | "\(.key):\n" + (.value | map("  - \(.title)") | join("\n"))'

# Bara antal
curl -s https://www.goranimperator.com/data/free-games.json | \
  jq '.platforms | to_entries | map({(.key): (.value | length)}) | add'
```

`updatedAt`-fältet visar när servern senast skrev filen — om den är >2h
gammal är det sannolikt något fel på cronjobbet.

---

## Sammanfattning av data-flödet

```
ITAD API
   │ var timme
   ▼
[cron på server → check.js → /var/lib/free-games/data.json]
   │
   ▼ servas av nginx som /data/free-games.json
   │
   ├──→ React-frontend (sajten)
   └──→ Mac desktop-app (din)
            │
            ├─ läser JSON med 30 min intervall
            ├─ diff mot lokalt state
            ├─ visar native notification per nytt spel
            └─ klick → öppnar game.url i browser
```
