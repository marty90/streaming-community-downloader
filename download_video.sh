#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Uso: $0 <url_watch> <file_output>" >&2
    echo "Esempio: $0 'https://streamingcommunityz.style/it/watch/6835?e=43400' output.mp4" >&2
    exit 1
fi

WATCH_URL="$1"
OUTFILE="$2"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# 1. Scarica la pagina di watch e cerca l'episode_id (pattern "?episode_id=X&amp")
curl -s -L "$WATCH_URL" -o "$TMPDIR/watch.html"

EPISODE_ID=$(sed -n -E 's/.*\?episode_id=([0-9]+)&amp.*/\1/p' "$TMPDIR/watch.html" | head -1)

if [ -z "$EPISODE_ID" ]; then
    echo "Errore: episode_id non trovato in $WATCH_URL" >&2
    exit 1
fi
echo "Episode ID: $EPISODE_ID"

# 2. Costruisce e scarica la URL iframe (stesso path di watch, ma /iframe/ ed episode_id trovato)
IFRAME_URL=$(echo "$WATCH_URL" | sed -E 's#/watch/#/iframe/#; s/\?.*$//')"?episode_id=${EPISODE_ID}"
echo "URL iframe: $IFRAME_URL"

curl -s -L "$IFRAME_URL" -o "$TMPDIR/iframe.html"

# 3. Trova la riga con src="https://vixcloud.co/..." ed estrae il valore, poi HTML-decodifica
SRC_URL=$(sed -n -E 's/.*src="(https:\/\/vixcloud\.co\/[^"]*)".*/\1/p' "$TMPDIR/iframe.html" | head -1 \
    | sed 's/&amp;/\&/g; s/&quot;/"/g; s/&#039;/'"'"'/g; s/&lt;/</g; s/&gt;/>/g')

if [ -z "$SRC_URL" ]; then
    echo "Errore: src vixcloud.co non trovato in $IFRAME_URL" >&2
    exit 1
fi
echo "URL vixcloud: $SRC_URL"

# 4. Scarica la URL trovata
curl -s -L "$SRC_URL" -o "$TMPDIR/playlist.html"

# 5. Estrae token, expires e url dal contenuto scaricato
TOKEN=$(sed -n -E "s/.*'token':[[:space:]]*'([^']*)'.*/\1/p" "$TMPDIR/playlist.html" | head -1)
EXPIRES=$(sed -n -E "s/.*'expires':[[:space:]]*'([^']*)'.*/\1/p" "$TMPDIR/playlist.html" | head -1)
VIDEO_URL=$(sed -n -E "s/.*'?url'?:[[:space:]]*'([^']*)'.*/\1/p" "$TMPDIR/playlist.html" | head -1)

if [ -z "$TOKEN" ] || [ -z "$EXPIRES" ] || [ -z "$VIDEO_URL" ]; then
    echo "Errore: impossibile estrarre token/expires/url da $SRC_URL" >&2
    exit 1
fi

# 6. Costruisce la URL finale
FINAL_URL="${VIDEO_URL}?token=${TOKEN}&expires=${EXPIRES}&h=1&scz=1&lang=it"
echo "URL finale: $FINAL_URL"

# 7. Scarica il video con ffmpeg
ffmpeg -i "$FINAL_URL" "$OUTFILE"
