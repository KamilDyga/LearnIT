# Tabela zachowań usługi HTTP

Cel: czytać odpowiedzi HTTP i rozumieć, co mówią o konfiguracji serwera.
Metoda: `curl -I` (żądanie HEAD — same nagłówki) do pięciu publicznych adresów, w tym co najmniej jednego przekierowującego z HTTP na HTTPS; dla przekierowań `curl -L` pokazuje pełny łańcuch. Wszystkie poniższe wyjścia pochodzą z 2026-09-28.

---

## 1. Polecenia i wyjścia

### 1.1 `http://github.com` — przekierowanie HTTP → HTTPS

```console
$ curl -sSI -m 12 http://github.com
HTTP/1.1 301 Moved Permanently
Content-Length: 0
Location: https://github.com/
```

**Komentarz:** serwer w ogóle nie zwraca treści — od razu odsyła pod `https://github.com/` kodem `301 Moved Permanently` („przeniesione na stałe"). Zwraca uwagę **brak nagłówka `Server`** — warstwa brzegowa (CDN/WAF) celowo nie ujawnia, jakie oprogramowanie działa z tyłu. `Content-Length: 0` potwierdza, że odpowiedź to sam sygnał przekierowania.

### 1.2 `http://httpbin.org/redirect/2` — przekierowanie tymczasowe (łańcuch)

```console
$ curl -sSI -m 12 http://httpbin.org/redirect/2
HTTP/1.1 302 FOUND
Date: Mon, 28 Sep 2026 18:01:35 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 247
Connection: keep-alive
Server: gunicorn/19.9.0
Location: /relative-redirect/1
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
```

**Komentarz:** odpowiedź `302 FOUND` („znalezione" — przekierowanie tymczasowe) z nagłówkiem `Location: /relative-redirect/1`. Cel jest **względny** (zaczyna się od `/`) — klient dopisuje bieżącą domenę. `Server: gunicorn/19.9.0` zdradza, że z tyłu jest aplikacja Pythona (serwer WSGI), a nagłówki `Access-Control-Allow-Origin: *` mówią, że to API otwarte na wywołania z dowolnej domeny (CORS). `Content-Type: text/html` + `Content-Length: 247` — tym razem odpowiedź ma ciało (stronkę z linkiem), mimo że to tylko przekierowanie.

### 1.3 `http://info.cern.ch` — zwykły serwer HTTP bez TLS

```console
$ curl -sSI -m 12 http://info.cern.ch
HTTP/1.1 200 OK
Date: Mon, 28 Sep 2026 17:57:44 GMT
Server: Apache
Last-Modified: Wed, 05 Feb 2014 16:00:31 GMT
ETag: "286-4f1aadb3105c0"
Accept-Ranges: bytes
Content-Length: 646
Connection: close
Content-Type: text/html
```

**Komentarz:** `200 OK` — żadnego przekierowania, mimo czystego HTTP. To pierwsza strona WWW w historii (CERN), serwowana przez prostego **Apache** w wersji HTTP/1.1 (brak `HTTP/2`, brak nagłówka HSTS — bo TLS-a tu w ogóle nie ma). `Last-Modified` z 2014 roku i `ETag` mówią, że to statyczny plik; `Connection: close` — serwer zamyka połączenie po każdej odpowiedzi (starszy, zachowawczy styl).

### 1.4 `https://example.com` — odpowiedź przez TLS/HTTP2 za CDN-em

```console
$ curl -sSI -m 12 https://example.com
HTTP/2 200
date: Mon, 28 Sep 2026 17:57:45 GMT
content-type: text/html; charset=utf-8
server: cloudflare
last-modified: Mon, 28 Sep 2026 16:19:23 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 5209
cf-cache-status: HIT
cf-ray: a424a1dcbea21846-SEA
```

**Komentarz:** `200` od razu, bez przekierowania — ten adres działa i po HTTP, i po HTTPS. `server: cloudflare` + `cf-cache-status: HIT` oznaczają, że odpowiedź **nie wyszła z serwera źródłowego**, tylko z pamięci podręcznej Cloudflare’a (CDN przed stroną). `allow: GET, HEAD` to deklaracja serwera, które metody obsługuje; nagłówki są pisane małymi literami — typowe dla HTTP/2, które traktuje nagłówki case-insensitive.

### 1.5 `https://www.wikipedia.org` — serwer aplikacyjny za wielowarstwowym cache’em

```console
$ curl -sSI -m 12 https://www.wikipedia.org
HTTP/2 200
date: Mon, 28 Sep 2026 16:06:26 GMT
server: mw-web.codfw.main-7975f7f879-shbjt
last-modified: Mon, 28 Sep 2026 15:41:33 GMT
cache-control: s-maxage=86400, must-revalidate, max-age=3600
content-type: text/html
etag: W/"16f03-65c8ce6864540"
age: 6678
accept-ranges: bytes
vary: Accept-Encoding
x-cache: cp4041 miss, cp4041 hit/39616
x-cache-status: hit-front
strict-transport-security: max-age=106384710; includeSubDomains; preload
```

**Komentarz:** `200` bez przekierowania, ale nagłówki opisują rozbudowaną konfigurację. `server: mw-web.codfw.main-…` to nazwa poda/aplikacji MediaWiki w klastrze (region `codfw` = serwerownia Wikimedia w Dallas) — tu identyfikator nie jest „ukryty", jak u GitHuba. `strict-transport-security` z `includeSubDomains; preload` = **HSTS**: przeglądarki mają przez lata wchodzić na Wikipedię wyłącznie przez HTTPS, i to dotyczy też wszystkich poddomen. `cache-control`, `age`, `x-cache` i `x-cache-status` pokazują wielowarstwowy cache (warstwa frontująca trzyma treść ~24 h dla serwerów pośrednich i 1 h dla klientów).

---

## 2. Tabela zbiorcza

| Adres | Kod odpowiedzi | Serwer | Typ treści | Przekierowanie | Cel przekierowania |
|---|---|---|---|---|---|
| `http://github.com` | 301 Moved Permanently | brak nagłówka `Server` | brak (pusta odpowiedź, `Content-Length: 0`) | **tak** | `https://github.com/` |
| `http://httpbin.org/redirect/2` | 302 FOUND | gunicorn/19.9.0 | `text/html; charset=utf-8` | **tak** (2 skoki) | `/relative-redirect/1` → `/get` |
| `http://info.cern.ch` | 200 OK | Apache | `text/html` | nie | — |
| `https://example.com` | 200 (HTTP/2) | cloudflare | `text/html; charset=utf-8` | nie | — |
| `https://www.wikipedia.org` | 200 (HTTP/2) | mw-web.codfw.main-7975f7f879-shbjt | `text/html` | nie | — |

---

## 3. Pełne łańcuchy przekierowań (`curl -L`)

### 3.1 `http://github.com` — łańcuch z kodem pośrednim `301`

```console
$ curl -sSIL -m 15 http://github.com | grep -Ei '^(HTTP/|location:)'
HTTP/1.1 301 Moved Permanently
Location: https://github.com/
HTTP/2 200
```

**Kod końcowy: 200.** Łańcuch: `301` → `200`. Komentarz: pierwszy skok to trwałe przeniesienie z HTTP na HTTPS (kod pośredni `301`), po dopisaniu `https://` serwer zwraca już zwykłe `200` z treścią. To typowy sposób wymuszania HTTPS na poziomie serwera.

### 3.2 `http://httpbin.org/redirect/2` — łańcuch z dwoma kodami pośrednimi `302`

```console
$ curl -sSIL -m 15 http://httpbin.org/redirect/2 | grep -Ei '^(HTTP/|location:)'
HTTP/1.1 302 FOUND
Location: /relative-redirect/1
HTTP/1.1 302 FOUND
Location: /get
HTTP/1.1 200 OK
```

**Kod końcowy: 200.** Łańcuch: `302` → `302` → `200` — dwa kody pośrednie. Komentarz: `/redirect/2` to endpoint celowo skaczący dwa razy: najpierw do `/relative-redirect/1`, potem do `/get`, gdzie dopiero ląduje odpowiedź z treścią (JSON-em). Cel podawany względnie — dopiero klient rozwija go do pełnego adresu. Przy okazji widać różnicę wobec GitHuba: tu przekierowania są **techniczne i jednorazowe** (302), tam — **polityka stała** (301).

---

## 4. Czym różni się kod 301 od 302

- **301 Moved Permanently** („przeniesione na stałe") — stary adres *już zawsze* żyje pod nowym. Klient (przeglądarka, cache) **może zapamiętać** nowy cel i kolejne żądania kierować od razu pod niego, pomijając stary URL. Typowe zastosowanie: trwała zmiana domeny albo wymuszenie HTTPS (jak u GitHuba). Skutek uboczny: 301 bywa agresywnie cache’owany, więc „cofnięcie" takiego przekierowania u użytkowników trwa długo.
- **302 Found** (dawniej „Moved Temporarily", „znalezione") — przekierowanie **tymczasowe**. Klient powinien za każdym razem odpytywać stary adres, bo cel może się zmienić; nie wolno go trwale zapamiętywać. Typowe zastosowania: przekierowanie na stronę logowania, wersję testową, koszyk, A/B (jak skoki w httpbinie).
- **W skrócie:** 301 = „przepnij się na stałe", 302 = „tymczasowo idź tutaj".
- **Uzupełnienie:** historycznie 301 i 302 powodowały, że część klientów zamieniała metodę `POST` na `GET`. Rozwiązano to kodami **307 Temporary Redirect** (odpowiednik 302) i **308 Permanent Redirect** (odpowiednik 301), które gwarantują zachowanie metody i ciała żądania.

---

## 5. Co odpowiedzi mówią o konfiguracji serwerów (podsumowanie)

- **github.com** — 301 do HTTPS jako stała polityka; brak nagłówka `Server` = brzeg sieci (CDN/WAF) nie ujawnia technologii zaplecza.
- **httpbin.org** — 302 jako mechanizm techniczny; `gunicorn/19.9.0` = aplikacja Pythona za serwerem WSGI; otwarty CORS = publiczne API.
- **info.cern.ch** — klasyczny Apache na samym HTTP/1.1, statyczne pliki, bez HSTS i HTTP/2 — minimalna, „muzealna" konfiguracja.
- **example.com** — Cloudflare z trafieniem w cache (`cf-cache-status: HIT`), ograniczona lista metod (`allow: GET, HEAD`).
- **www.wikipedia.org** — HSTS z preload (wymuszony HTTPS wszędzie), wielowarstwowy cache z regułami czasów życia (`cache-control`, `age`, `x-cache`), backend MediaWiki w klastrze (nazwa poda w `Server`).
