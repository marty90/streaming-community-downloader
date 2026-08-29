# Download Video from streamingcommunityz.style

Script bash per scaricare un episodio da `streamingcommunityz.style` a partire dalla sua URL di visione (`watch`).
Fatto in parte con Claude.

La sola finalità di questo programma è la didattica.

## Requisiti

- `curl`
- `sed` / `grep` (di sistema, nessun pacchetto aggiuntivo)
- `ffmpeg`

## Uso

```
./download_video.sh <url_watch> <file_output>
```

Esempio:

```
./download_video.sh 'https://streamingcommunityz.style/it/watch/6835?e=43400' episodio.mp4
```

## Come funziona

1. Scarica la pagina `watch` e vi cerca l'`episode_id` (pattern `?episode_id=X&amp`).
2. Costruisce la URL `iframe` corrispondente e la scarica.
3. Estrae dal contenuto dell'iframe l'attributo `src="https://vixcloud.co/..."` e lo HTML-decodifica.
4. Scarica quella URL e ne estrae `token`, `expires` e `url` del player.
5. Costruisce la URL finale della playlist e la passa a `ffmpeg` per scaricare il video nel file di output.

## Nota

Lo script dipende dalla struttura HTML/JS attuale del sito (nomi di campo, formato degli attributi). Se il sito cambia layout, i pattern di estrazione in `download_video.sh` potrebbero necessitare di un aggiornamento. I token generati dal sito hanno una validità breve, quindi lo script va eseguito per intero senza pause tra i passaggi.
