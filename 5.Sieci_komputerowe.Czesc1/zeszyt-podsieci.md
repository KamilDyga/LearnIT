# Zeszyt podsieci

Cel: policzyć podsieci szybko i bez narzędzi. Poniżej sześć zadań rozwiązanych **z pokazaniem toku obliczeń**, plus ściąga z reguł.

## Ściąga — reguły, z których korzystam

| Kroki | Zasada |
|---|---|
| Maska z prefiksu | każdy oktet maski = `256 − 2^(8 − bity_sieci_w_oktecie)`; `/26` → w ostatnim oktecie 2 bity sieci → `256 − 2^6 = 192` |
| Liczba bitów hosta | `32 − prefiks` |
| Rozmiar puli | `2^(32 − prefiks)`; hostów użytecznych = `rozmiar − 2` (minus sieć i broadcast) |
| Adres sieci | `adres AND maska` (bitowo; wystarczy ostatni oktet, w którym maska nie jest pełna) |
| Broadcast | `adres_sieci + rozmiar_puli − 1` |
| Zakres hostów | od `adres_sieci + 1` do `broadcast − 1` |
| Podział na *n* równych podsieci | dodajemy `log2(n)` bitów sieci: nowy prefiks = stary + `log2(n)`; podsiecie idą co `2^(32 − nowy_prefiks)` |
| Kontrola | `n × rozmiar_podsieci = rozmiar_puli_wejściowej`; żadne dwie podsieci się nie nakładają |

---

## Zadanie 2.1 — komplet parametrów dla `192.168.50.77/26`

**Tok obliczeń:**

1. Prefiks `/26` → bitów hosta: `32 − 26 = 6` → rozmiar puli: `2^6 = 64` adresy, z czego użytecznych `64 − 2 = 62`.
2. Maska: w ostatnim oktecie 2 bity sieci → `256 − 2^6 = 192`, czyli **255.255.255.192**.
3. Adres sieci — w ostatnim oktecie: `77 = 0100 1101₂`, maska `1100 0000₂` (192). Iloczyn bitowy: `0100 1101 AND 1100 0000 = 0100 0000 = 64`. Konto „na sucho": blok = 64, a `64 × 1 = 64 ≤ 77 < 128 = 64 × 2` → sieć to `.64`.
4. Broadcast: `64 + 64 − 1 = 127`.

| Parametr | Wartość |
|---|---|
| Adres sieci | **192.168.50.64/26** |
| Maska | 255.255.255.192 |
| Broadcast | 192.168.50.127 |
| Pierwszy host | 192.168.50.65 |
| Ostatni host | 192.168.50.126 |
| Hosty użyteczne | 62 |
| Rozmiar puli | 64 |
| Uwagi | klasa C; 192.168.0.0/16 to sieć prywatna (RFC 1918) |

---

## Zadanie 2.2 — komplet parametrów dla `10.10.10.200/25`

**Tok obliczeń:**

1. Prefiks `/25` → bitów hosta: `32 − 25 = 7` → rozmiar puli: `2^7 = 128` adresów, użytecznych `126`.
2. Maska: w ostatnim oktecie 1 bit sieci → `256 − 2^7 = 128`, czyli **255.255.255.128**.
3. Adres sieci — ostatni oktet: `200 = 1100 1000₂`, maska `1000 0000₂` (128). Iloczyn: `1100 1000 AND 1000 0000 = 1000 0000 = 128`. Inaczej: `/25` dzieli oktet na pół — 200 leży w górnej połówce (128–255), więc sieć to `.128`.
4. Broadcast: `128 + 128 − 1 = 255`.

| Parametr | Wartość |
|---|---|
| Adres sieci | **10.10.10.128/25** |
| Maska | 255.255.255.128 |
| Broadcast | 10.10.10.255 |
| Pierwszy host | 10.10.10.129 |
| Ostatni host | 10.10.10.254 |
| Hosty użyteczne | 126 |
| Rozmiar puli | 128 |
| Uwagi | klasa A; 10.0.0.0/8 to sieć prywatna (RFC 1918) |

---

## Zadanie 2.3 — komplet parametrów dla `172.16.5.130/23`

**Tok obliczeń:**

1. Prefiks `/23` → bitów hosta: `32 − 23 = 9` → rozmiar puli: `2^9 = 512` adresów, użytecznych `510`.
2. Maska: `/23` to 7 bitów sieci w trzecim oktecie → `256 − 2^7 = 254`, czyli **255.255.254.0**. Prefiks „schodzi" do trzeciego oktetu, bo `23 > 16` a `23 < 24`.
3. Adres sieci — trzeci oktet: `5 = 0000 0101₂`, maska `1111 1110₂` (254). Iloczyn: `0000 0101 AND 1111 1110 = 0000 0100 = 4`. Zatem sieć to `172.16.4.0`. Intuicyjnie: maska `/23` obejmuje zawsze parzystą liczbę w trzecim oktecie (blok = 2), a 5 należy do bloku 4–5.
4. Broadcast: `172.16.4.0 + 512 − 1 = 172.16.5.255` (ostatni adres bloku 4–5).

| Parametr | Wartość |
|---|---|
| Adres sieci | **172.16.4.0/23** |
| Maska | 255.255.254.0 |
| Broadcast | 172.16.5.255 |
| Pierwszy host | 172.16.4.1 |
| Ostatni host | 172.16.5.254 |
| Hosty użyteczne | 510 |
| Rozmiar puli | 512 |
| Uwagi | klasa B; 172.16.0.0/12 to sieć prywatna (RFC 1918); `/23` skleja dwa pełne `/24`: 172.16.4.0/24 i 172.16.5.0/24 |

---

## Zadanie 2.4 — komplet parametrów dla `192.0.2.9/30`

**Tok obliczeń:**

1. Prefiks `/30` → bitów hosta: `32 − 30 = 2` → rozmiar puli: `2^2 = 4` adresy, użyteczne `2`.
2. Maska: w ostatnim oktecie 6 bitów sieci → `256 − 2^2 = 252`, czyli **255.255.255.252**.
3. Adres sieci — ostatni oktet: `9 = 0000 1001₂`, maska `1111 1100₂` (252). Iloczyn: `0000 1001 AND 1111 1100 = 0000 1000 = 8`. Blok = 4, a `8 ≤ 9 < 12` → sieć to `.8`.
4. Broadcast: `8 + 4 − 1 = 11`. Hosty: `.9` i `.10` — nasz adres `192.0.2.9` to dokładnie pierwszy host tej sieci.

| Parametr | Wartość |
|---|---|
| Adres sieci | **192.0.2.8/30** |
| Maska | 255.255.255.252 |
| Broadcast | 192.0.2.11 |
| Pierwszy host | 192.0.2.9 |
| Ostatni host | 192.0.2.10 |
| Hosty użyteczne | 2 |
| Rozmiar puli | 4 |
| Uwagi | klasa C; `192.0.2.0/24` to TEST-NET-1 (RFC 5737) — zakres dokumentacyjny, niewystępujący w internecie; `/30` to standardowy „kawałek" na łącza punkt-punkt (dwa routery po obu stronach) |

---

## Zadanie 2.5 — `192.168.200.0/24` podzielone na **osiem** równych podsieci

**Tok obliczeń:**

1. Potrzebujemy 8 podsieci → `log2(8) = 3` dodatkowe bity sieci → nowy prefiks: `24 + 3 = /27`.
2. Nowa maska: w ostatnim oktecie 3 bity sieci → `256 − 2^5 = 224`, czyli **255.255.255.224**.
3. Rozmiar jednej podsieci: `2^(32 − 27) = 32` adresy → `30` hostów użytecznych.
4. Krok między podsieciami: 32 w ostatnim oktecie → adresy sieci: `.0, .32, .64, .96, .128, .160, .192, .224`.
5. **Suma kontrolna:** `8 × 32 = 256` = rozmiar puli `/24`. ✓ Żadne dwie podsieci się nie nakładają (idą co 32) i razem pokrywają całą pulę wyjściową.

| # | Adres sieci | Zakres hostów | Broadcast |
|---|---|---|---|
| 1 | 192.168.200.0/27 | 192.168.200.1 – 192.168.200.30 | 192.168.200.31 |
| 2 | 192.168.200.32/27 | 192.168.200.33 – 192.168.200.62 | 192.168.200.63 |
| 3 | 192.168.200.64/27 | 192.168.200.65 – 192.168.200.94 | 192.168.200.95 |
| 4 | 192.168.200.96/27 | 192.168.200.97 – 192.168.200.126 | 192.168.200.127 |
| 5 | 192.168.200.128/27 | 192.168.200.129 – 192.168.200.158 | 192.168.200.159 |
| 6 | 192.168.200.160/27 | 192.168.200.161 – 192.168.200.190 | 192.168.200.191 |
| 7 | 192.168.200.192/27 | 192.168.200.193 – 192.168.200.222 | 192.168.200.223 |
| 8 | 192.168.200.224/27 | 192.168.200.225 – 192.168.200.254 | 192.168.200.255 |

Kontrola granic: pierwsza podsieć startuje od `.0`, broadcast ósmej to `.255` — czyli dokładnie dolna i górna granica puli `/24`; pomiędzy sąsiednimi wierszami nie ma luk ani nakładek (broadcast *n*-tej + 1 = adres sieci *(n+1)*-szej).

---

## Zadanie 2.6 — `10.50.0.0/16` podzielony na **cztery** równe podsieci

**Tok obliczeń:**

1. Potrzebujemy 4 podsieci → `log2(4) = 2` dodatkowe bity sieci → nowy prefiks: `16 + 2 = /18`.
2. Nowa maska: `/18` to 2 bity sieci w trzecim oktecie → `256 − 2^6 = 192`, czyli **255.255.192.0**.
3. Rozmiar jednej podsieci: `2^(32 − 18) = 2^14 = 16 384` adresy → `16 382` hostów użytecznych.
4. Krok między podsieciami: `2^(24 − 18) = 64` w trzecim oktecie → adresy sieci: `10.50.0.0, 10.50.64.0, 10.50.128.0, 10.50.192.0`.
5. **Suma kontrolna:** `4 × 16 384 = 65 536` = rozmiar puli `/16` (`2^16`). ✓ Podsieci nie zachodzą na siebie i pokrywają całą pulę.

| # | Adres sieci | Zakres hostów | Broadcast |
|---|---|---|---|
| 1 | 10.50.0.0/18 | 10.50.0.1 – 10.50.63.254 | 10.50.63.255 |
| 2 | 10.50.64.0/18 | 10.50.64.1 – 10.50.127.254 | 10.50.127.255 |
| 3 | 10.50.128.0/18 | 10.50.128.1 – 10.50.191.254 | 10.50.191.255 |
| 4 | 10.50.192.0/18 | 10.50.192.1 – 10.50.255.254 | 10.50.255.255 |

Kontrola granic: pierwsza podsieć startuje od `10.50.0.0`, broadcast ostatniej to `10.50.255.255` — pokrywają cały zakres `10.50.0.0/16`, bez luk i nakładek. Uwaga: `10.0.0.0/8` to sieć prywatna (RFC 1918), więc te podsieci nadają się wyłącznie do użytku wewnętrznego.
