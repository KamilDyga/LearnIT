# Paszport sieciowy maszyny

**Maszyna:** `e2b.local` · Linux 6.1.158+ x86_64 · data zebrania danych: 2026-09-28
**Zakres dokumentu:** interfejsy z adresami i MAC-ami, tabela routingu (z opisem każdej linii), bramka domyślna, adres publiczny, tabela nasłuchujących gniazd, wniosek o dostępności usług.
**Konwencja:** każde polecenie wraz z jego wyjściem jest w bloku kodu, a interpretacja znajduje się **pod** blokiem. W dokumencie nie ma wyjścia bez komentarza.

---

## 1. Interfejsy sieciowe, adresy i MAC-i

```console
$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host proto kernel_lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 02:fc:00:00:00:05 brd ff:ff:ff:ff:ff:ff
    inet 169.254.0.21/30 brd 169.254.0.23 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::fc:ff:fe00:5/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
```

**Komentarz:** maszyna ma dwa interfejsy.

- **`lo`** — pętla zwrotna. MAC `00:00:00:00:00:00` jest tu wartością symboliczną (to nie karta fizyczna), a adresy `127.0.0.1/8` (IPv4) i `::1` (IPv6) służą wyłącznie do komunikacji z samą sobą — ruch stąd nigdy nie wychodzi na kabel.
- **`eth0`** — jedyna karta sieciowa. MAC `02:fc:00:00:00:05` (bajt `02` = adres „lokalnie administrowany", typowy dla kart wirtualnych). Adres IPv4 `169.254.0.21/30` — maska `/30` to `255.255.255.252`, czyli w sieci są tylko 4 adresy: `.20` (adres sieci), `.21` (ta maszyna), `.22` (bramka) i `.23` (broadcast). Zakres `169.254.0.0/16` to adresy *link-local* (RFC 3927), nadawane automatycznie, gdy w łączu nie ma DHCP.
- Adres IPv6 `fe80::fc:ff:fe00:5/64` to również *link-local* (zawsze zaczyna się od `fe80::`), wyprowadzony z MAC-a metody EUI-64 (widać w środku `fc:ff:fe00`). Służy do komunikacji w obrębie tego samego łącza (np. NDP), nie jest routowany dalej.

## 2. Tabela routingu

```console
$ ip route show
default via 169.254.0.22 dev eth0
169.254.0.20/30 dev eth0 proto kernel scope link src 169.254.0.21
```

**Komentarz — opis każdej linii własnymi słowami:**

1. `default via 169.254.0.22 dev eth0` — **trasa domyślna**. Każdy pakiet, którego cel nie pasuje do żadnej bardziej szczegółowej trasy, wychodzi kartą `eth0` do bramki `169.254.0.22`. Dzięki tej jednej linii maszyna ma dostęp do całego internetu — bez niej działałaby tylko sieć lokalna.
2. `169.254.0.20/30 dev eth0 proto kernel scope link src 169.254.0.21` — **trasa do sieci bezpośrednio podłączonej**, wyznaczona samoczynnie przez jądro (`proto kernel`) w chwili nadania adresu karcie. `scope link` oznacza, że cel jest w zasięgu tego łącza — pakiety wysyłamy wprost, bez pośrednictwa bramki. `src 169.254.0.21` mówi, że w tej sieci pakiety wychodzące z tej maszyny będą miały właśnie ten adres źródłowy. Linia opisuje tę samą sieć co adres karty: `169.254.0.20/30`.

## 3. Bramka domyślna

```console
$ ip route show default
default via 169.254.0.22 dev eth0
```

**Komentarz:** bramka domyślna to `169.254.0.22` — sąsiad z naszej sieci `/30` (jedyny sensowny kandydat poza nami samymi), osiągalny bezpośrednio przez `eth0`. Cały ruch „w świat" przechodzi przez to urządzenie.

```console
$ ip route get 8.8.8.8
8.8.8.8 via 169.254.0.22 dev eth0 src 169.254.0.21 uid 1000
    cache
```

**Komentarz:** to test ścieżki — zapytałem jądro, jak konkretnie poleci pakiet do publicznego serwera DNS `8.8.8.8`. Odpowiedź potwierdza praktyczne działanie trasy domyślnej: przez bramkę `169.254.0.22`, kartą `eth0`, z adresem źródłowym `169.254.0.21`.

## 4. Adres publiczny

```console
$ curl -s https://api.ipify.org
136.66.43.179
$ curl -s https://ipinfo.io/ip
136.66.43.179
```

**Komentarz:** świat zewnętrzny widzi tę maszynę pod adresem **`136.66.43.179`** — dwa niezależne serwisy podają tę samą wartość, więc wynik jest wiarygodny. Co ważne, tego adresu **nie ma na żadnym interfejsie** (por. sekcja 1): to adres publiczny bramy NAT, za którą siedzi maszyna. Wewnątrz pracujemy na prywatnym/link-local `169.254.0.21`, a NAT podmienia adres źródłowy przy wychodzeniu na zewnątrz.

## 5. Konfiguracja DNS (uzupełnienie)

```console
$ cat /etc/resolv.conf
nameserver 8.8.8.8
```

**Komentarz:** jedynym wskazanym resolverem jest `8.8.8.8` — publiczny DNS Google. Maszyna nie prowadzi własnego serwera DNS ani nie korzysta z DNS-a w sieci lokalnej; każde odpytanie nazwy (np. przy `curl`) wychodzi przez bramkę domyślną właśnie tam.

## 6. Nasłuchujące gniazda (porty)

```console
$ sudo ss -tulnp
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
udp   UNCONN 0      0            0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=336,fd=5),("systemd",pid=1,fd=39))
udp   UNCONN 0      0                  *:111              *:*    users:(("rpcbind",pid=336,fd=7),("systemd",pid=1,fd=41))
tcp   LISTEN 0      100        127.0.0.1:35769      0.0.0.0:*    users:(("python3.13",pid=475,fd=11))
tcp   LISTEN 0      5       169.254.0.21:47945      0.0.0.0:*    users:(("socat",pid=513,fd=6))
tcp   LISTEN 0      5       169.254.0.21:34675      0.0.0.0:*    users:(("socat",pid=514,fd=6))
tcp   LISTEN 0      4096         0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=336,fd=4),("systemd",pid=1,fd=38))
tcp   LISTEN 0      5       169.254.0.21:35769      0.0.0.0:*    users:(("socat",pid=512,fd=6))
tcp   LISTEN 0      100        127.0.0.1:47945      0.0.0.0:*    users:(("python3.13",pid=475,fd=35))
tcp   LISTEN 0      100        127.0.0.1:34675      0.0.0.0:*    users:(("python3.13",pid=475,fd=27))
tcp   LISTEN 0      128        127.0.0.1:8888       0.0.0.0:*    users:(("jupyter-server",pid=437,fd=6))
tcp   LISTEN 0      5       169.254.0.21:8888       0.0.0.0:*    users:(("socat",pid=470,fd=6))
tcp   LISTEN 0      100        127.0.0.1:44461      0.0.0.0:*    users:(("python3.13",pid=475,fd=13))
tcp   LISTEN 0      5       169.254.0.21:35105      0.0.0.0:*    users:(("socat",pid=521,fd=6))
tcp   LISTEN 0      100        127.0.0.1:39379      0.0.0.0:*    users:(("node",pid=490,fd=30))
tcp   LISTEN 0      100        127.0.0.1:41435      0.0.0.0:*    users:(("node",pid=490,fd=33))
tcp   LISTEN 0      100        127.0.0.1:43501      0.0.0.0:*    users:(("node",pid=490,fd=32))
tcp   LISTEN 0      100        127.0.0.1:35105      0.0.0.0:*    users:(("node",pid=490,fd=34))
tcp   LISTEN 0      5       169.254.0.21:44461      0.0.0.0:*    users:(("socat",pid=515,fd=6))
tcp   LISTEN 0      5       169.254.0.21:39379      0.0.0.0:*    users:(("socat",pid=516,fd=6))
tcp   LISTEN 0      5       169.254.0.21:41435      0.0.0.0:*    users:(("socat",pid=517,fd=6))
tcp   LISTEN 0      5       169.254.0.21:43501      0.0.0.0:*    users:(("socat",pid=518,fd=6))
tcp   LISTEN 0      5       169.254.0.21:60465      0.0.0.0:*    users:(("socat",pid=523,fd=6))
tcp   LISTEN 0      5       169.254.0.21:53335      0.0.0.0:*    users:(("socat",pid=525,fd=6))
tcp   LISTEN 0      5       169.254.0.21:60493      0.0.0.0:*    users:(("socat",pid=524,fd=6))
tcp   LISTEN 0      2048         0.0.0.0:49999      0.0.0.0:*    users:(("uvicorn",pid=463,fd=17))
tcp   LISTEN 0      100        127.0.0.1:60465      0.0.0.0:*    users:(("python3.13",pid=475,fd=22))
tcp   LISTEN 0      100        127.0.0.1:60493      0.0.0.0:*    users:(("node",pid=490,fd=31))
tcp   LISTEN 0      100        127.0.0.1:53335      0.0.0.0:*    users:(("python3.13",pid=475,fd=9))
tcp   LISTEN 0      4096            [::]:111           [::]:*    users:(("rpcbind",pid=336,fd=6),("systemd",pid=1,fd=40))
tcp   LISTEN 0      4096               *:22               *:*    users:(("sshd",pid=387,fd=3),("systemd",pid=1,fd=61))
tcp   LISTEN 0      128            [::1]:8888          [::]:*    users:(("jupyter-server",pid=437,fd=7))
tcp   LISTEN 0      4096               *:49983            *:*    users:(("envd",pid=359,fd=9))
```

**Komentarz:** polecenie `ss -tulnp` pokazuje wszystkie gniazda TCP/UDP w stanie nasłuchu (`-l`) wraz z procesami (`-p`; potrzebne uprawnienia roota, stąd `sudo`). Kluczowe jest to, **na jakim adresie** dane gniazdo nasłuchuje — to decyduje o dostępności z zewnątrz. Zestawienie:

| Protokół | Adres(y) nasłuchu | Proces | Co to jest | Dostępne spoza maszyny? |
|---|---|---|---|---|
| TCP + UDP | `0.0.0.0:111`, `*:111` | `rpcbind` | portmapper RPC (mapowanie usług NFS/RPC) | **tak** — nasłuch na wszystkich interfejsach |
| TCP | `*:22` | `sshd` | serwer SSH | **tak** — `*` = wszystkie adresy (IPv4+IPv6) |
| TCP | `*:49983` | `envd` | usługa agenta środowiska | **tak** |
| TCP | `0.0.0.0:49999` | `uvicorn` | API aplikacji (serwer ASGI/Python) | **tak** |
| TCP | `127.0.0.1:8888`, `[::1]:8888` | `jupyter-server` | Jupyter | nie wprost — **tak** przez `socat` na `169.254.0.21:8888` |
| TCP | `127.0.0.1:{35769,47945,34675,44461,60465,53335}` | `python3.13` | usługi pomocnicze | nie wprost — **tak** przez `socat` na tych samych portach na `169.254.0.21` |
| TCP | `127.0.0.1:{39379,41435,43501,35105,60493}` | `node` | agent Node.js | nie wprost — **tak** przez `socat` na `169.254.0.21` |

Widać wyraźny wzorzec: aplikacje (`jupyter-server`, `python3.13`, `node`) są celowo dowiązane wyłącznie do pętli zwrotnej, a na karcie sieciowej na tych samych portach stoi `socat`, który przekierowuje ruch do wersji lokalnych. To klasyczny trik „wystawienia" usługi bez przepinania jej na `0.0.0.0`.

## 7. Wniosek — które usługi są dostępne spoza maszyny i dlaczego

O dostępności z zewnątrz decyduje **adres, na którym gniazdo nasłuchuje**, a nie sam numer portu:

- **Dostępne spoza maszyny:** SSH na porcie 22 (`sshd`), `rpcbind` na 111 (TCP i UDP), `envd` na 49983 i `uvicorn` na 49999 — wszystkie nasłuchują na `0.0.0.0` albo `*`, czyli „złapią" pakiet przychodzący na każdy adres maszyny. Dodatkowo usługi z pętli zwronej są pośrednio wystawione na zewnątrz przez `socat` (porty 8888, 35769, 47945, 34675, 44461, 35105, 39379, 41435, 43501, 53335, 60465, 60493 na `169.254.0.21`) — de facto więc także one są osiągalne z sieci.
- **Niedostępne spoza maszyny:** to, co nasłuchuje wyłącznie na `127.0.0.1` / `[::1]`. Pętla zwrotna nie jest routowana — pakiet przychodzący z zewnątrz nigdy nie zostanie dostarczony pod 127.0.0.1, więc „surowe" gniazda tych aplikacji są widoczne tylko lokalnie.
- **Zastrzeżenie praktyczne:** maszyna ma adres prywatny `169.254.0.21/30` i siedzi za NAT-em (publiczny `136.66.43.179` należy do bramy). Nawet usługi nasłuchujące na wszystkich interfejsach są z otwartego internetu osiągalne tylko wtedy, gdy operator przepuści ruch (firewall/NAT). Z punktu widzenia samej maszyny lista „otwartych" usług jest jednak dokładnie taka, jak w tabeli powyżej.
