# Dziennik problemów i wniosków (Mycelium)

Zapis wszystkiego, co poszło nie tak podczas budowy projektu 11.10.2026: co było widać, jak to
diagnozowałem, co okazało się przyczyną, co zadziałało, a co nie, i jaki z tego wniosek.
Problemy są ułożone mniej więcej w kolejności, w jakiej wychodziły.

Każdy wpis ma ten sam układ:

> **Objaw** → **Diagnoza** (konkretne komendy) → **Przyczyna** → **Rozwiązanie** →
> **Co nie zadziałało** → **Wniosek**

---

## Spis

**A. Infrastruktura i konfiguracja**
1. [Konflikt portów z planet-pulse](#1-konflikt-portów-z-planet-pulse)
2. [Tempo 3 nie startuje: usunięte pola konfiguracji](#2-tempo-3-nie-startuje-usunięte-pola-konfiguracji)
3. [Parser logów Dockera w kolektorze wywraca się na `attrs`](#3-parser-logów-dockera-wywraca-się-na-attrs)
4. [Przestarzałe nazwy komponentów w OTel Collector 0.162](#4-przestarzałe-nazwy-komponentów-w-otel-collector-0162)
5. [Dwa joby o tej samej nazwie](#5-dwa-joby-o-tej-samej-nazwie)
6. [Etykieta `instance` = `json-exporter:7979` dla wszystkich celów](#6-etykieta-instance--json-exporter7979-dla-wszystkich-celów)
7. [Liczniki kolektora bez `_total`](#7-liczniki-kolektora-bez-_total)
8. [Sloth wywraca się przy starcie](#8-sloth-wywraca-się-przy-starcie)

**B. Dane z API**
9. [iNaturalist nie przyjmuje względnych dat](#9-inaturalist-nie-przyjmuje-względnych-dat)
10. [Bluesky: brak publicznego API wyszukiwania](#10-bluesky-brak-publicznego-api-wyszukiwania)
11. [Artykuł z zerem odsłon w środku sezonu (przekierowania)](#11-artykuł-z-zerem-odsłon-przekierowania)
12. [API Wikimedii pomija dni z zerem odsłon](#12-api-wikimedii-pomija-dni-z-zerem-odsłon)

**C. SLI, SLO i PromQL**
13. [Stara seria „200” maskuje awarię (OTLP nie ma staleness markers)](#13-stara-seria-200-maskuje-awarię)
14. [`NaN` zatruwa 30-dniowy budżet](#14-nan-zatruwa-30-dniowy-budżet)
15. [Fałszywe „złe” próbki po restarcie (kolejność grup reguł)](#15-fałszywe-złe-próbki-po-restarcie)
16. [Zimny start wysłał page'a](#16-zimny-start-wysłał-pagea)
17. [`increase()` na gaugu kłamie 6×](#17-increase-na-gaugu-kłamie-6)
18. [pint: 1507 ostrzeżeń](#18-pint-1507-ostrzeżeń)
19. [Testy, które oblały… bo to ja się myliłem](#19-testy-które-oblały-bo-to-ja-się-myliłem)

**D. Grafana**
20. [„No data” na dashboardach Forest](#20-no-data-na-dashboardach-forest)
21. [Linki do gatunków prowadzą na ogólną stronę](#21-linki-do-gatunków-prowadzą-na-ogólną-stronę)
22. [Tabela „Species overview” skacze](#22-tabela-species-overview-skacze)
23. [Mapa w jednym kolorze i myląca legenda](#23-mapa-w-jednym-kolorze-i-myląca-legenda)
24. [Infinity + JSONata: puste wyniki](#24-infinity--jsonata-puste-wyniki)
25. [Wykres faz HTTP pokazywał bzdury](#25-wykres-faz-http-pokazywał-bzdury)
26. [Oś burn rate skalowana do 100×](#26-oś-burn-rate-skalowana-do-100)

**E. Game day (kontrolowana awaria)**
27. [Przebieg game day](#27-przebieg-game-day)
28. [Nasza awaria spalała budżet dostawcy](#28-nasza-awaria-spalała-budżet-dostawcy)
29. [„Kac” alertów po naprawie](#29-kac-alertów-po-naprawie)

**F. Narzędzia i własne błędy**
30. [Heredoc w Bashu i znaki ucieczki](#30-heredoc-w-bashu-i-znaki-ucieczki)
31. [Złe założenia o czasie i dacie](#31-złe-założenia-o-czasie-i-dacie)

**G. Debugowanie platformy jej własnymi sygnałami**
32. [Zapytanie LogQL wysłane do Prometheusa (znalezione w śladzie)](#32-zapytanie-logql-wysłane-do-prometheusa)
33. [Pluginy Grafany udają Prometheusa na mapie serwisów](#33-pluginy-grafany-udają-prometheusa-na-mapie-serwisów)
34. [Prometheus generował 300 spanów na sekundę](#34-prometheus-generował-300-spanów-na-sekundę)
35. [Metryka pamięci kolektora zmieniła nazwę](#35-metryka-pamięci-kolektora-zmieniła-nazwę)
36. [Dwa zapytania z tym samym `refId`](#36-dwa-zapytania-z-tym-samym-refid)

**H. Zgłoszenia z użytkowania dashboardów**
37. [Dashboard Forest migocze](#37-dashboard-forest-migocze)
38. [Słupki zamieniają się miejscami przy każdym odświeżeniu](#38-słupki-zamieniają-się-miejscami)
39. [Nowa etykieta `name_en` zdublowała gatunki](#39-nowa-etykieta-name_en-zdublowała-gatunki)

[Skrzynka z narzędziami do troubleshootingu](#skrzynka-z-narzędziami) · [Najważniejsze wnioski](#najważniejsze-wnioski-w-10-zdaniach)

---

## A. Infrastruktura i konfiguracja

### 1. Konflikt portów z planet-pulse

- **Objaw:** `docker compose up -d` → `Bind for 127.0.0.1:9090 failed: port is already allocated`.
- **Diagnoza:** komunikat mówi wprost. `docker ps` pokazał działający stos planet-pulse.
- **Przyczyna:** oba projekty chciały porty 3000/9090/9093.
- **Rozwiązanie:** mycelium dostał własne porty: Grafana **3030**, Prometheus **9091**,
  Alertmanager **9094**, Mailpit 8025, Sloth 8082. Opisane w README.
- **Co nie zadziałało / odrzucone:** zatrzymanie planet-pulse. Przerwałoby zbieranie danych, a jego
  30-dniowe okna SLO dostałyby dziurę.
- **Wniosek:** przy kilku lokalnych stosach od razu planuj porty. Zatrzymanie czegoś, co zbiera
  dane historyczne, ma koszt, który wychodzi dopiero po tygodniach.

### 2. Tempo 3 nie startuje: usunięte pola konfiguracji

- **Objaw:** kontener `tempo` w pętli restartów.
- **Diagnoza:** `docker compose logs tempo` →
  `field traces_storage not found in type generator.Config`, `field compactor not found in type app.Config`.
- **Przyczyna:** Tempo 3.x zmieniło architekturę (live-store, backend-worker). Moja konfiguracja
  pochodziła z wiedzy o Tempo 2.
- **Rozwiązanie:** przeczytałem release notes 3.1 i oficjalny przykład
  `example/docker-compose/single-binary/tempo.yaml` z tagu `v3.1.0`. Retencja jest teraz
  w `backend_worker.compaction.block_retention`.
- **Wniosek:** przy nowej wersji głównej (2 → 3) **zawsze** zaczynaj od release notes i przykładu
  z repo dokładnie dla tego taga, a nie od pamięci czy starego bloga.

### 3. Parser logów Dockera wywraca się na `attrs`

- **Objaw:** w logach kolektora co chwilę stack trace:
  `failed to process the docker log: expected { character for map value`.
- **Diagnoza:** błąd pojawił się dopiero po dodaniu w compose `logging.options.labels`, które
  dopisuje do każdej linii pole `"attrs":{...}`.
- **Przyczyna:** operator `container` (format docker) nie radzi sobie z polem `attrs`.
- **Rozwiązanie:** zamiast `container` zwykły `json_parser` (z parsowaniem `time`) plus dwa
  operatory `move` (`log` → body, `stream` → `log.iostream`). Nazwę serwisu biorę w OTTL
  z `attributes["attrs"]["com.docker.compose.service"]`.
- **Co nie zadziałało:** gotowy parser `container`.
- **Wniosek:** gotowe „magiczne” parsery są wygodne, dopóki dane wyglądają standardowo. Prosty
  `json_parser` jest przewidywalny i łatwy do zdebugowania.

### 4. Przestarzałe nazwy komponentów w OTel Collector 0.162

- **Objaw:** ostrzeżenia `"otlphttp" alias is deprecated; use "otlp_http" instead` (podobnie
  `otlp` → `otlp_grpc`, `spanmetrics` → `span_metrics`, `servicegraph` → `service_graph`,
  `filelog` → `file_log`).
- **Rozwiązanie:** zmiana nazw w całej konfiguracji i ponowna walidacja `otelcol-validate`.
- **Wniosek:** **czytaj ostrzeżenia, nie tylko błędy.** Za kilka wersji aliasy znikną i konfiguracja
  przestanie działać.

### 5. Dwa joby o tej samej nazwie

- **Objaw:** `otelcol validate` → `found multiple scrape configs with job name "inaturalist"`.
- **Rozwiązanie:** drugi job nazywa się `inaturalist-aggregates`. Wspólna etykieta `provider`
  łączy je w SLO.
- **Wniosek:** `job_name` musi być unikalny. Do grupowania używaj własnych etykiet, a nie nazwy joba.

### 6. Etykieta `instance` = `json-exporter:7979` dla wszystkich celów

- **Objaw:** wszystkie gatunki miały `instance="json-exporter:7979"`.
- **Diagnoza:** `curl .../api/v1/query?query=up` i porównanie etykiet.
- **Przyczyna:** `instance` przyjmuje wartość `__address__` **po** relabelingu, a ja nadpisywałem
  `__address__` adresem exportera.
- **Rozwiązanie:** reguła `source_labels: [__address__] → target_label: instance` **przed**
  podmianą adresu.
- **Wniosek:** przy OTLP ma to dodatkowe znaczenie, bo `job` + `instance` stają się
  `service.name` + `service.instance.id`, czyli tożsamością serii. Kolejność reguł relabelingu ma
  znaczenie.

### 7. Liczniki kolektora bez `_total`

- **Objaw:** pod panelami ikonka z komunikatem
  `PromQL info: metric might not be a counter, name does not end in _total`.
- **Diagnoza:** podejrzałem surowe `/metrics` kolektora z kontenera w tej samej sieci:
  `docker run --rm --network mycelium_default curlimages/curl -s http://otel-collector:8888/metrics`.
  Typ `counter`, ale nazwa bez sufiksu.
- **Rozwiązanie:** `without_type_suffix: false` w `service.telemetry.metrics.readers[].pull.exporter.prometheus`,
  potem `perl`-owa podmiana nazw we wszystkich regułach, SLO i dashboardach.
- **Efekt uboczny:** zmieniły się też nazwy etykiet (`server.address` → `server_address`).
- **Wniosek:** po zmianie formatu ekspozycji sprawdź **wszystkie** miejsca, które używają metryki:
  reguły, specyfikacje SLO, dashboardy i testy.

### 8. Sloth wywraca się przy starcie

- **Objaw:** UI Slotha pokazywał „No services found”.
- **Diagnoza:** `docker compose logs sloth` →
  `could not warm caches ... server error: 503`.
- **Przyczyna:** Sloth wystartował, zanim Prometheus był gotowy. Restart policy go podniosła, ale
  z pustym cache.
- **Rozwiązanie:** `healthcheck` dla Prometheusa (`wget /-/ready`) i
  `depends_on: prometheus: condition: service_healthy` w Slothu.
- **Wniosek:** `depends_on` bez `condition` czeka tylko na *start* kontenera, a nie na *gotowość*
  usługi.

---

## B. Dane z API

### 9. iNaturalist nie przyjmuje względnych dat

- **Objaw:** chciałem liczyć „obserwacje z ostatnich 24 h” parametrem `created_d1=24 hours ago`.
- **Diagnoza:** przetestowałem `today`, `1 day ago`, `-1d`, `P1D`. Wszystkie zwracały **ten sam**
  wynik co brak filtra, czyli parametr był po cichu ignorowany.
- **Rozwiązanie:** pobieram całkowitą liczbę obserwacji (`total_results`), a „nowe w 24 h” liczy
  PromQL: `delta(inat_observations[24h])`. W Grafanie (Infinity) można użyć
  `${__from:date:YYYY-MM-DD}`, bo tam data jest podstawiana przy każdym zapytaniu.
- **Wniosek:** API, które ignoruje nieznany parametr zamiast zwrócić błąd, jest podstępne.
  Sprawdzaj, czy filtr **naprawdę** zmienia wynik.

### 10. Bluesky: brak publicznego API wyszukiwania

- **Objaw:** `public.api.bsky.app/xrpc/app.bsky.feed.searchPosts` → `403 Forbidden`.
- **Rozwiązanie:** Mastodon, który ma publiczne statystyki hashtagów (`/api/v1/tags/<tag>`, 7 dni
  historii) bez logowania.
- **Wniosek:** zanim zaprojektujesz projekt wokół źródła, zrób `curl`. Kilka sekund oszczędza
  przepisywania.

### 11. Artykuł z zerem odsłon (przekierowania)

- **Objaw:** „Zatrucie grzybami” miało ok. 0 odsłon dziennie w szczycie sezonu, a „Opieńka” 0–2.
- **Diagnoza:** `curl` do API odsłon (dużo brakujących dni), a potem do MediaWiki API:
  `action=query&titles=Zatrucie_grzybami&redirects` → przekierowanie na „Grzyby trujące”.
- **Przyczyna:** API liczy odsłony **strony przekierowania**, a czytelnicy lądują na stronie docelowej.
- **Rozwiązanie:** używam artykułów docelowych („Grzyby trujące”, „Opieńka miodowa”) i dopisałem
  w konfiguracji komentarz, dlaczego.
- **Wniosek:** **status 200 nie znaczy, że mierzysz to, co myślisz.** Sprawdzaj tożsamość źródła,
  zwłaszcza gdy liczby wyglądają podejrzanie.

### 12. API Wikimedii pomija dni z zerem odsłon

- **Objaw:** artykuł miał 143 punkty danych zamiast 283 (dni od 1 stycznia).
- **Skutek:** pierwsza wersja SLI świeżości wymagała, żeby **każdy** artykuł miał świeże dane
  (`min()`). Cichy artykuł wyglądał na „przestarzały”, mimo że zbiór był aktualny.
- **Rozwiązanie:** `max()` po artykułach, bo świeżość to cecha zbioru danych, a nie najcichszego
  elementu. Dodany test jednostkowy.
- **Wniosek:** zanim wybierzesz agregację (`min`/`max`/`avg`), zapytaj, **czego dotyczy** właściwość.

---

## C. SLI, SLO i PromQL

### 13. Stara seria „200” maskuje awarię

- **Objaw (wykryty na etapie projektowania, zanim wyrządził szkodę):** receiver `http_check`
  emituje `httpcheck.status` z osobną serią dla każdego kodu HTTP.
- **Diagnoza:** przeczytałem kod receivera (`scraper.go`). Po błędzie seria `code="200"` nie
  dostaje nowej próbki, ale Prometheus pokazuje jej ostatnią wartość przez 5 minut (lookback).
  Przy scrape'owaniu przychodzi znacznik „stale”, ale **OTLP push go nie ma**.
- **Skutek:** `max()` po seriach pokazywałby „OK” jeszcze przez 5 minut po awarii.
- **Rozwiązanie:** OTTL `copy_metric` tworzy `httpcheck.success`, czyli **jedną** serię z **jednym**
  punktem na sondę (1 albo 0). Na tym oparłem SLI dostępności oparty na zdarzeniach.
- **Co nie zadziałało:** `copy_metric(..., desc=...)`. Parametr nazywa się `description`, co
  wyszło w walidacji.
- **Wniosek:** przy przejściu z pull na push (OTLP) znika mechanizm staleness. Seria, która
  przestała przychodzić, „żyje” jeszcze 5 minut.

### 14. `NaN` zatruwa 30-dniowy budżet

- **Objaw:** `slo:sli_error:ratio_rate5m{sloth_slo="alert-delivery"}` = `NaN`.
- **Przyczyna:** w 5 minutach bez żadnego e-maila `failed/total = 0/0`. Sloth liczy 30-dniowe SLI
  jako średnią 5-minutowych współczynników, więc **jeden NaN psuje średnią na miesiąc**.
- **Rozwiązanie:** `(ratio) and on () (total > 0)`. Gdy nie ma zdarzeń, nie ma próbki. Test
  sprawdza, że wynik jest pusty, a nie `NaN`.
- **Wniosek:** każdy współczynnik z mianownikiem, który może być zerem, potrzebuje strażnika.
  Szczególnie przy SLO na małym ruchu.

### 15. Fałszywe „złe” próbki po restarcie

- **Objaw:** zaraz po starcie SLI świeżości Wikimedii = 0, a alert się zapalił.
- **Diagnoza:** `wiki:freshness_cutoff` liczył się w innej grupie reguł (co 1 min) niż SLI (co 30 s).
  Przy pierwszej ewaluacji stałej jeszcze nie było, więc wchodziło `or vector(0)` = „źle”.
- **Rozwiązanie:** stałe i reguły, które ich używają, są w **jednej grupie**. Reguły w grupie liczą
  się po kolei.
- **Wniosek:** między grupami reguł nie ma gwarantowanej kolejności.

### 16. Zimny start wysłał page'a

- **Objaw:** 90 sekund po pierwszym czystym `docker compose up` przyszedł e-mail do `oncall@`:
  `DashboardFreshnessBudgetBurn` (zrzut: [`docs/img/coldstart-page.png`](img/coldstart-page.png)).
- **Diagnoza:** SLI świeżości celowo traktują „brak danych” jako „nieświeże”, a zaraz po starcie
  danych po prostu jeszcze nie ma. Wikimedia była wtedy odpytywana co 15 minut.
- **Rozwiązanie:** 20-minutowa rozgrzewka: `platform:prometheus_uptime:seconds > 1200` jako warunek
  w regułach świeżości. Przez ten czas SLI nie emitują próbek. Dodany test zimnego startu.
  Sprawdzone ponownie: po kolejnym czystym starcie przez 6 minut odpalał tylko Watchdog.
- **Koszt rozwiązania:** prawdziwa awaria w pierwszych 20 minutach po starcie nie zostanie
  wykryta przez SLO świeżości (inne alerty, np. `TelemetryPipelineDown`, działają).
- **Wniosek:** **każdy restart musi przejść przez alerting po cichu.** Testuj zimny start, nie
  tylko stan ustalony.

### 17. `increase()` na gaugu kłamie 6×

- **Objaw (wykryty testem):** liczba obserwacji to gauge, który „zwykle rośnie”. Usunięcie jednej
  obserwacji powoduje spadek o 1.
- **Diagnoza:** test w `forest_test.yml`: `resets(...) = 1`, `increase() = 1376`, a prawda to **229**.
- **Przyczyna:** `increase()`/`rate()` traktują każdy spadek jak reset licznika i dodają całą wartość.
- **Rozwiązanie:** `delta()` dla „ile przybyło” i `deriv()` dla tempa. Test zostawiony jako
  dokumentacja.
- **Wniosek:** `rate`/`increase` tylko dla prawdziwych liczników (`_total`). Dla gauge: `delta`,
  `deriv`.

### 18. pint: 1507 ostrzeżeń

- **Objaw:** `pint` zgłosił 1507 ostrzeżeń `rule/dependency`.
- **Diagnoza:** wszystkie dotyczyły reguł używających metryk z innej grupy, co jest zamierzonym
  układem Slotha.
- **Rozwiązanie:** wyłączenie tej jednej kontroli w `.pint.hcl` **z komentarzem, dlaczego**,
  i `# pint disable alerts/comparison` przy celowo zawsze-odpalającym Watchdogu.
- **Co odrzuciłem:** wyłączenie całego pint albo puszczenie ostrzeżeń mimo uszu.
- **Wniosek:** szum w linterze ukrywa prawdziwe problemy. Wyłączaj konkretne kontrole świadomie
  i opisuj powód.

### 19. Testy, które oblały… bo to ja się myliłem

Część testów oblała nie przez błąd w regułach, tylko przez moje błędne oczekiwania:

| Test | Moje założenie | Rzeczywistość |
|---|---|---|
| Mastodon freshness | sprawdzałem o 1h, a dane udawały „dzień 5” | czas ewaluacji musi pasować do danych |
| ProviderUnreachable | „po 12 min jeszcze nie” | bez zdrowego okresu na początku warunek był prawdziwy od zera |
| burn rate = 200 | dokładnie 200 | `199.99999999999983`, czyli arytmetyka zmiennoprzecinkowa, więc `round()` |
| spadek o 2 % | 2.143 % | `delta()` ekstrapoluje do brzegów okna, więc 2.187 % |
| `increase()` | ~1327 | 1376 |

- **Wniosek:** test, który oblewa, uczy tak samo dobrze jak test, który przechodzi. Zapisuj
  oczekiwania z rozumowania, a nie przepisuj wyniku, i dopiero potem weryfikuj. Gdy różnica wynika
  z semantyki PromQL (ekstrapolacja, float), opisz to w komentarzu testu.

---

## D. Grafana

### 20. „No data” na dashboardach Forest

- **Objaw:** po wyczyszczeniu danych wiele paneli Forest i Interest pokazywało „No data”, choć
  `curl` do Prometheusa zwracał dane.
- **Diagnoza:**
  1. Napisałem audyt, który wykonuje **każde zapytanie każdego panelu** przez API Grafany
     (`POST /api/ds/query`) i raportuje puste wyniki.
  2. Pierwsze wyniki były fałszywe. Błąd w moim audycie: `\b` w regexie zamienił się na znak
     backspace (patrz [30](#30-heredoc-w-bashu-i-znaki-ucieczki)). Wyszło to dopiero po wypisaniu
     wysyłanego zapytania (`cat -A` pokazał `^H`).
  3. Prawdziwy trop: **to samo zapytanie dawało dane dla 1 h, a nic dla 7 dni.**
- **Przyczyna:** Grafana wyrównuje zakres i zapytania *instant* do kroku zapytania. Dla 7 dni krok
  wynosi ok. 20 minut. Wszystkie dane miały mniej niż 20 minut (świeży start), więc wypadały za
  ostatnim wyrównanym krokiem. Do tego Wikipedia i GBIF były odpytywane co 15–30 minut, więc
  pierwsze dane przychodziły późno.
- **Rozwiązanie:**
  - zapytania instant dostały własny krok (`interval: 1m`), niezależny od zakresu dashboardu,
  - domyślny zakres Forest to 24 h zamiast 7 dni,
  - Wikipedia i GBIF są odpytywane co 10 minut,
  - rzadkie serie dzienne mają `last_over_time(...[$__interval])`, więc żaden krok ich nie zgubi.
- **Wniosek:** „No data” nie zawsze znaczy brak danych. Sprawdź to samo zapytanie przy innym
  zakresie i kroku. Audyt przez `/api/ds/query` jest szybszy niż klikanie po panelach.

### 21. Linki do gatunków prowadzą na ogólną stronę

- **Objaw:** kliknięcie gatunku w „Top species” otwierało `https://www.inaturalist.org/taxa/`, bez ID.
- **Przyczyna:** link używał `${__data.fields.taxon}`, a kolumnę `taxon` **usunąłem** transformacją
  *Organize* (żeby jej nie pokazywać). Usunięte pole nie istnieje też dla linków.
- **Rozwiązanie:** zamiast usuwać, ukrywam override'em `custom.hidden: true`. Pole jest niewidoczne,
  ale dostępne dla linków. To samo dla `id` na stronie głównej. Dodałem też linki w tabeli „Species
  overview” (nazwa → strona gatunku w iNaturalist, odsłony → artykuł w Wikipedii), na słupkach
  i na mapie.
- **Wniosek:** *ukryć* ≠ *usunąć*. Transformacja usuwa dane, override zmienia tylko wygląd.

### 22. Tabela „Species overview” skacze

- **Objaw:** wiersze zmieniały kolejność przy każdym odświeżeniu.
- **Przyczyna:** sortowanie po „new · 24 h”, gdzie wiele gatunków ma tę samą wartość (remisy).
  6 zapytań wraca w różnej kolejności, więc remisy układały się losowo. Szerokości kolumn zmieniały
  się, gdy dochodziły kolejne zapytania.
- **Rozwiązanie:** sortowanie po wartości unikalnej (łączna liczba obserwacji) i stałe szerokości
  kolumn.
- **Wniosek:** sortuj po kluczu bez remisów albo dodaj drugi klucz sortowania.

### 23. Mapa w jednym kolorze i myląca legenda

- **Objaw:** na stronie głównej wszystkie punkty były żółte, a legenda pokazywała „< 80 / 80+”.
- **Przyczyna:** mapowanie wartości było w domyślnych ustawieniach pól, a kolor w trybie „fixed”.
  Legenda pokazywała domyślne progi.
- **Rozwiązanie:** override na polu koloru (mapowanie + tryb `thresholds`) i wyłączona legenda progów.

### 24. Infinity + JSONata: puste wyniki

- **Objaw:** histogram iNaturalist (obiekt `{"1": n, "2": n, ...}`) nie dawał się zamienić na wiersze.
- **Co nie zadziałało:**
  - `parser: "jsonata"`, który zwracał puste ramki bez błędu,
  - `{{ ... }}` w wyrażeniu, czyli zły nawias,
  - `function($v,$k) {"m": ...}`, bo ciało funkcji w JSONata to blok, a obiekt musi być w środku.
- **Rozwiązanie:** `parser: "backend"` i `function($v, $k) { {"m": $number($k), ...} }`.
- **Wniosek:** testuj zapytania datasource'ów przez `/api/ds/query`, wtedy od razu widać błąd
  kompilacji, którego panel nie pokaże.

### 25. Wykres faz HTTP pokazywał bzdury

- **Objaw:** dla Wikimedii „2 ms” całego czasu, a „server + transfer” = 0.
- **Diagnoza:** odpytałem każdą fazę osobno. `httpcheck.response.duration` to tylko **odczyt ciała
  odpowiedzi** (~0.08 ms), a nie czas serwera.
- **Rozwiązanie:** „server + transfer” = czas całkowity − (DNS + TCP + TLS). Wtedy wyszło, że dla
  iNaturalist sam handshake TLS do USA to ok. 330 ms.
- **Wniosek:** zanim narysujesz metrykę, sprawdź w dokumentacji, co dokładnie mierzy.

### 26. Oś burn rate skalowana do 100×

- **Objaw:** linie burn rate przy 0, a oś do 100× (czerwony obszar).
- **Przyczyna:** styl progów `dashed+area` rozciągał oś do obszaru progów.
- **Rozwiązanie:** same linie przerywane i `axisSoftMax: 16` (nieco ponad próg 14.4×).

---

## E. Game day (kontrolowana awaria)

### 27. Przebieg game day

Scenariusz: po zakończeniu rozgrzewki zatrzymuję `json-exporter` na 20 minut (symulacja awarii
kolektora danych) i obserwuję alerty oraz skrzynkę.

| Czas | Zdarzenie |
|---|---|
| 14:36:07 | `docker compose stop json-exporter` |
| 14:40:04 | `PlatformComponentDown{job="json-exporter"}` (ticket, po `for: 3m`) |
| **14:44:15** | **e-mail do `oncall@`: `DashboardFreshnessBudgetBurn` (page)**, 8 minut od awarii |
| 14:44 | poziom slow-burn tego samego SLO wyciszony inhibicją (`sloth_severity`) |
| 14:44 | ticket `PlatformComponentDown` **nie** poszedł mailem: niedziela, tickety tylko pn–pt 8–18 |
| 14:52 | `InaturalistFreshnessBudgetBurn`, czyli problem opisany w [28](#28-nasza-awaria-spalała-budżet-dostawcy) |
| 14:56:15 | `docker compose start json-exporter` |
| 15:01 | `ConsumerScrapesFailing` odpala **po** naprawie, patrz [29](#29-kac-alertów-po-naprawie) |
| **15:30:49** | **e-mail `[RESOLVED]`**: alert zgasł ok. 15:28, gdy krótkie okno 30 m poziomu 6× spadło poniżej 3 % błędów |
| 15:30 → ~17:00 | po zgaszeniu page'a aktywny zostaje **ticket** (slow burn): jego krótkie okno ma 2 h, więc gaśnie ok. 17:00; w niedzielę nie idzie mailem |

**Co zadziałało:** wykrycie w 8 minut (próg świeżości 10 min + MWMBR), page tylko dla tego, co
nasze, inhibicja slow-burn, routing zależny od czasu, szablon e-maila z linkami do dashboardu
i runbooka.

### 28. Nasza awaria spalała budżet dostawcy

- **Objaw:** podczas awarii *naszego* json-exportera zapalił się alert świeżości **iNaturalist**.
- **Przyczyna:** świeżość dostawcy mierzyłem *przez nasz własny exporter*. Gdy on leży, dane
  „przestają się zmieniać” i wygląda to jak problem iNaturalist.
- **Rozwiązanie (dwie warstwy):**
  1. w SLI: `platform:collection_path_up:bool`. Gdy kolektor albo json-exporter nie działa, SLI
     świeżości dostawców nie emitują próbek. **Mierzę dostawcę, nie siebie.** Dodany test.
  2. w Alertmanagerze: inhibicja `PlatformComponentDown{job="json-exporter"}` i
     `TelemetryPipelineDown` → alerty `tier="upstream"` i `category="data-quality"`.
- **Wniosek:** dla każdego SLI zapytaj: *czyja awaria może go zepsuć?* Jeśli Twoja, to SLI mierzy
  częściowo Ciebie. Taki błąd wychodzi dopiero przy prawdziwej awarii, a nie w stanie ustalonym.

### 29. „Kac” alertów po naprawie

- **Objaw:** po przywróceniu exportera:
  - `ConsumerScrapesFailing` **zapalił się dopiero po naprawie** (warunek na oknie 1 h był prawdziwy
    od dawna, `for: 15m` minęło już po fakcie) i wisiałby do godziny,
  - page dla świeżości dashboardu wisiał jeszcze ok. 30 minut.
- **Diagnoza:** porównałem okna. Alert konsumenta ma okno 1 h. Szybki poziom MWMBR 6h/30m gaśnie
  dopiero, gdy krótkie okno (30 m) „wyczyści się” z błędów.
- **Rozwiązanie:**
  - `ConsumerScrapesFailing` wymaga teraz błędów w ostatnich 30 minutach
    (`min_over_time(up[30m]) == 0`) i jest wyciszany, gdy leży json-exporter. Dodany test „alert
    gaśnie wkrótce po naprawie”.
  - Page dla dashboardu zostawiłem. To zamierzone zachowanie MWMBR: **czas wygaszenia wyznacza krótkie
    okno**. SRE Workbook właśnie dlatego wprowadza krótkie okna (bez nich alert z oknem 6 h wisiałby
    godzinami).
- **Wniosek:** testuj także *zakończenie* incydentu. Alert, który odpala po naprawie albo wisi
  godzinę po niej, uczy ludzi go ignorować.

---

## F. Narzędzia i własne błędy

### 30. Heredoc w Bashu i znaki ucieczki

- **Objawy:**
  - `unexpected EOF while looking for matching '` przy długich skryptach w heredocu,
  - Pythonowy patch nie znajdował tekstu, bo `\\.` w YAML-u vs `\\\\.` w Pythonie,
  - `\b` w regexie zamienione na znak backspace (0x08), co popsuło audyt dashboardów.
- **Diagnoza:** `cat -A plik` pokazuje niewidoczne znaki (`^H` = backspace).
- **Rozwiązanie:** dłuższe skrypty zapisuję do pliku i uruchamiam z pliku. Do pojedynczych podmian
  używam edycji z dokładnym dopasowaniem tekstu.
- **Wniosek:** każda warstwa (Bash → Python → regex → YAML → JSON) ma własne ucieczki. Im mniej
  warstw w jednym poleceniu, tym mniej niespodzianek.

### 31. Złe założenia o czasie i dacie

- **Pomyłka 1:** chciałem zrobić game day „po rozgrzewce”, a Prometheus był restartowany kilka
  minut wcześniej (zmiana healthchecka), więc rozgrzewka jeszcze trwała. Sprawdziłem to metryką
  `platform:prometheus_uptime:seconds`, zamiast zgadywać.
- **Pomyłka 2:** odczytałem z osi wykresu szczyt odsłon jako 28.09 (poniedziałek), a w surowych
  danych było `2026092700`, czyli 27.09, niedziela. Wniosek „niedziela = dzień grzybobrania” się
  obronił, ale dopiero po sprawdzeniu surowych danych.
- **Wniosek:** czas sprawdzaj metryką (`time()`, uptime), a wnioski z wykresu weryfikuj surowymi
  danymi. Etykiety osi kłamią przy strefach czasowych i wyrównaniu.

---

## G. Debugowanie platformy jej własnymi sygnałami

### 32. Zapytanie LogQL wysłane do Prometheusa

- **Objaw:** panel „Log lines per minute” na dashboardzie Platform pokazywał ikonę błędu. Gdy to
  samo zapytanie wysyłałem ręcznie do Loki, działało.
- **Diagnoza:**
  1. W logach Grafany: `vector cannot contain metrics with the same labelset` (status 422),
     **z `traceID`**.
  2. Tail sampling zawsze zachowuje błędy, więc ślad był w Tempo. Otworzyłem go przez API:
     span `datasource.prometheus` miał atrybut `expr` z moim zapytaniem **LogQL**, a span
     `promqlRangeQuery` zwrócił błąd.
- **Przyczyna:** target miał datasource Loki, ale **panel** miał domyślnie Prometheusa (mój
  generator ustawiał go wszystkim panelom czasowym). Bez trybu „Mixed” Grafana używa datasource
  panelu. Prometheus potraktował `{service_namespace="mycelium", ...}` jako selektor PromQL, trafił
  na wiele różnych metryk z tymi etykietami, a `sum by` ich nie rozróżnił.
- **Rozwiązanie:** datasource panelu = Loki.
- **Wniosek:** **ślady to najszybsza droga do przyczyny**, także w samym stosie obserwowalności.
  Bez śladu zgadywałbym, który z 22 paneli wysłał to zapytanie.

### 33. Pluginy Grafany udają Prometheusa na mapie serwisów

- **Objaw:** mapa serwisów pełna węzłów `elasticsearch`, `opentsdb`, `mysql`… i krawędź
  `prometheus → prometheus`.
- **Diagnoza:** w surowym śladzie (Tempo API, `resourceSpans`) widać, że każdy plugin datasource'a
  Grafany to osobny proces, który raportuje spany z `service.name` = id pluginu. Plugin
  Prometheusa nazywa się więc `prometheus`, tak samo jak prawdziwy serwer. Odróżnia je tylko
  `service.version` (13.2.3 vs 3.15.0) i instrumentation scope.
- **Rozwiązanie:**
  - OTTL: zmiana nazwy na `grafana-plugin:<id>` dla zasobów, które mają spany `pluginv2.*`,
    `sdk.*`, `datasource.*`. Teraz ślad pokazuje `grafana → grafana-plugin:prometheus → prometheus`;
  - filtr odrzuca spany `plugin.GRPC*` (start i stop każdego zainstalowanego pluginu, zero wartości).
- **Co nie zadziałało (dwa razy):**
  1. instrukcja z `context: span` i ścieżkami bez prefiksów (`name`) **niczego nie zmieniała i nie
     zgłaszała błędu**, nawet z `error_mode: propagate`. Zadziałała dopiero po przepisaniu na jawne
     ścieżki (`span.name`, `resource.attributes[...]`) bez klucza `context`. Kolektor 0.162 i tak
     logował prośbę o prefiksy, więc przepisałem tak wszystkie instrukcje OTTL. Do końca nie
     ustaliłem, dlaczego stara forma była ignorowana;
  2. `"^(pluginv2\.|...)"`: walidacja zwracała `invalid quoted string`, bo backslash przechodzi
     przez YAML, OTTL i regex. Rozwiązanie bez żadnego backslasha: klasa znaków `[.]`.
- **Wniosek:** gdy transformacja „nic nie robi”, sprawdź wynik w backendzie (tu: nazwy serwisów
  w Tempo), a nie tylko brak błędów. Regex w kilku warstwach konfiguracji pisz bez backslashy:
  `[.]`, `[$]`.

### 34. Prometheus generował 300 spanów na sekundę

- **Objaw:** `Spans / s in` ≈ 300, z czego prawie wszystko z `service_name="prometheus"`.
- **Diagnoza:** `sum by (service_name) (rate(traces_span_metrics_calls_total[1m]))`, czyli metryki
  RED ze spanów odpowiadają na pytanie, *kto* generuje ruch.
- **Przyczyna:** `sampling_fraction: 1.0` śledził każdą ewaluację ok. 360 reguł co 30 s.
- **Rozwiązanie:** `sampling_fraction: 0.02`. Sampler jest parent-based, więc żądania z Grafany
  (z flagą „sampled” w nagłówku W3C) nadal mają pełny ślad. Sprawdziłem w Tempo, że ślad
  `grafana → grafana-plugin:prometheus → prometheus` jest kompletny. Spadek z ok. 300 do 5 spanów/s.
- **Wniosek:** tracing „wszystkiego” w systemie z regułami czy cronami potrafi zalać kolektor.
  Próbkuj korzenie, a ufaj decyzji rodzica.

### 35. Metryka pamięci kolektora zmieniła nazwę

- **Objaw:** panel „Collector memory” → „No data”.
- **Przyczyna:** po `without_type_suffix: false` (problem [7](#7-liczniki-kolektora-bez-_total))
  metryki dostały też sufiks jednostki: `otelcol_process_memory_rss` → `otelcol_process_memory_rss_bytes`.
  Przy pierwszej poprawce zamieniłem tylko liczniki.
- **Wniosek:** po zmianie konwencji nazw wylistuj **wszystkie** nazwy metryk
  (`/api/v1/label/__name__/values`) i porównaj z każdym miejscem użycia. Nie zakładaj, że zmiana
  dotyczy tylko jednego typu metryk.

### 36. Dwa zapytania z tym samym `refId`

- **Objaw:** po poprawce nazwy metryki panel „Collector memory” nadal miał ikonę błędu.
- **Przyczyna:** oba zapytania w panelu miały `refId: "A"` (domyślna wartość w moim generatorze).
  Grafana odrzuca taki panel. Mój audyt tego nie widział, bo wysyłał zapytania **pojedynczo**.
- **Rozwiązanie:** generator sam numeruje duplikaty (A, B, C…), a CI sprawdza `jq`-iem, że w żadnym
  panelu `refId` się nie powtarzają. Sprawdziłem też test negatywny: sztuczny dashboard z dwoma „A”
  daje exit 1.
- **Wniosek:** narzędzie diagnostyczne ma własne ślepe plamki: audyt „zapytanie po zapytaniu” nie
  widzi błędów na poziomie panelu. Każdy naprawiony błąd, który da się wykryć automatycznie, warto
  zamienić w kontrolę CI, żeby nie wrócił.

---

## H. Zgłoszenia z użytkowania dashboardów

### 37. Dashboard Forest migocze

- **Objaw (zgłoszony przez użytkownika):** dashboard „Forest · what is growing” ciągle skakał.
  Po lekkiej zmianie wysokości panelu migotanie ustawało.
- **Diagnoza:**
  - logi Grafany: brak pętli odświeżania (przeglądarka pytała rzadko), provisioning nie nadpisywał
    dashboardu (stała wersja);
  - Playwright + headless Chrome: pozycje paneli przez 40 s, przy przewijaniu oraz porównanie
    pikseli zrzutów co sekundę przez 60 s w dwóch rozdzielczościach. **Nie dało się odtworzyć.**
  - Rozwiązanie podsunął użytkownik: zmiana rozmiaru zatrzymuje migotanie. To klasyczna pętla
    **legenda-tabela „na styk”**: brakuje kilku pikseli → pojawia się pasek przewijania → wykres
    się zwęża → legenda przelicza się i mieści → pasek znika → od nowa. Zależy od dokładnego
    rozmiaru okna, dlatego mój headless Chrome go nie widział.
- **Rozwiązanie:** wyższe panele z 10-wierszowymi legendami (Forest 9 → 12, „Total observations”
  8 → 12, Interest 9 → 13 z legendą po prawej), w Platform legenda w formie listy. Skrypt w
  Playwright sprawdza, czy żadna legenda nie ma mniej niż 12 px zapasu, w szerokościach 1366
  i 1920 px. Tak samo potraktowałem tabelę „Species overview”, gdy nagłówki zawinęły się w dwie
  linie.
- **Wniosek:** gdy problemu nie da się odtworzyć, **zapytaj, co go zmienia** („po zmianie rozmiaru
  znika” to najcenniejsza wskazówka). Nie projektuj paneli na styk: legenda czy tabela powinny
  albo wyraźnie się mieścić, albo wyraźnie przewijać.

### 38. Słupki zamieniają się miejscami

- **Objaw:** w wykresie „New observations · 24 h” słupki z równą wartością zmieniały kolejność.
- **Przyczyna:** `sort_desc()` przy remisach (dużo gatunków ma 0, 1 albo 2) nie gwarantuje
  kolejności, a sortowanie w Grafanie (dwie transformacje *Sort by*) też nie okazało się stabilne.
- **Rozwiązanie:** remis rozstrzyga PromQL:
  `wartość + łączna_liczba_obserwacji / 1e9`. Wartości są unikalne, a dodatek (≤ 0,000004) jest
  niewidoczny przy 0 miejscach po przecinku. Sprawdzone trzema kolejnymi zapytaniami: ta sama
  kolejność.
- **Co nie zadziałało:** dwa kolejne *Sort by* w Grafanie (alfabetycznie, potem po wartości).
- **Wniosek:** każde sortowanie, które ma remisy, potrzebuje klucza rozstrzygającego.

### 39. Nowa etykieta `name_en` zdublowała gatunki

- **Kontekst:** dodałem angielskie nazwy do katalogu `species.yml` (etykieta `name_en`).
- **Objaw:** zdublowane wiersze w „Species overview”, podwójne linie w legendzie „Total
  observations”, brakujące słupki. Potem, po dodaniu osobnego zapytania z `name_en`, **puste
  kolumny GBIF i Wikipedia**.
- **Przyczyna:**
  1. nowa etykieta = **nowa seria**. Stara (bez `name_en`) żyje dalej: 5 min w zapytaniach chwilowych,
     cały zakres na wykresach i **24 h w `delta(...[24h])`**. Reguły sumujące po gatunkach liczyłyby
     gatunek podwójnie przez dobę;
  2. transformacja *Merge* łączy wiersze po **wszystkich** wspólnych kolumnach. Gdy zapytanie
     z `name_en` miało inny zestaw etykiet, wiersze się rozjechały.
- **Rozwiązanie:**
  - reguły: `max by (species, ...)` **przed** sumowaniem (`forest:inat_new_observations_by_edibility:24h`,
    hype index), w dashboardach `max by (name_pl)` na wykresach. Nowy test jednostkowy: dwie
    serie tego samego gatunku liczą się raz;
  - tabela: *Join by field* po `species` zamiast *Merge*.
- **Wniosek:** zmiana etykiet to migracja danych, nawet gdy wygląda na kosmetykę. Agregacje
  po kluczu biznesowym (`species`) zamiast „po wszystkim” są odporne na takie zmiany. Łącz tabele
  po jawnym kluczu.

---

## Skrzynka z narzędziami

| Pytanie | Narzędzie |
|---|---|
| Czy konfiguracja jest poprawna? | `otelcol-contrib validate`, `promtool check config`, `amtool check-config`, `loki -verify-config`, `sloth validate` |
| Czy reguła liczy to, co myślę? | `promtool test rules`, czyli testy z syntetycznymi seriami i czasem od 1970-01-01 |
| Gdzie trafi ten alert? | `amtool config routes test --verify.receivers=...` |
| Czy PromQL jest zdrowy? | `pint lint` |
| Co naprawdę jest w Prometheusie? | `curl /api/v1/query`, `/api/v1/label/__name__/values` |
| Co widzi panel Grafany? | `POST /api/ds/query` z tym samym zapytaniem i zakresem |
| Co płynie przez kolektor? | zPages `/debug/pipelinez`, metryki `otelcol_*`, `docker compose logs otel-collector` |
| Co wystawia komponent? | `docker run --rm --network mycelium_default curlimages/curl -s http://<serwis>:<port>/metrics` |
| Jakie atrybuty mają spany? | Tempo API: `/api/v2/search/tags`, `/api/search?q={...}` |
| Jak wygląda dashboard? | `grafana-image-renderer` (`/render/d/...`), headless Chrome dla innych UI |
| Który panel wysłał złe zapytanie? | `traceID` z logu Grafany → ślad w Tempo → atrybut `expr` spanu datasource'a |
| Kto generuje najwięcej spanów? | `sum by (service_name) (rate(traces_span_metrics_calls_total[1m]))` |
| Czy coś na dashboardzie się rusza? | Playwright: pozycje paneli w czasie, porównanie pikseli zrzutów, zapas legend |
| Niewidoczne znaki? | `cat -A` |
| Czy API zrobi to, czego chcę? | `curl` **zanim** napiszesz konfigurację |

## Najważniejsze wnioski w 10 zdaniach

1. Zrób `curl` do API, zanim zaprojektujesz wokół niego cokolwiek.
2. Przy nowej wersji głównej zacznij od release notes i przykładu z repo dla tego taga.
3. Status 200 nie znaczy, że mierzysz to, co myślisz: sprawdzaj tożsamość i semantykę danych.
4. Przy push (OTLP) nie ma staleness markers: seria, która ucichła, żyje jeszcze 5 minut.
5. Każdy współczynnik z mianownikiem, który może być zerem, potrzebuje strażnika przed `NaN`.
6. `rate`/`increase` tylko dla liczników; dla gauge `delta`/`deriv`.
7. Testuj zimny start i koniec incydentu, a nie tylko stan ustalony.
8. Dla każdego SLI zapytaj, czyja awaria może go zepsuć. Mierz dostawcę, nie siebie.
9. W Grafanie *ukryj* (override), a nie *usuwaj* (transformacja) pól potrzebnych linkom; sortuj po
   kluczu bez remisów.
10. Game day znalazł dwa błędy, których nie wykryły 25 testów jednostkowych. Testy sprawdzają to,
    co przewidziałeś, a awaria pokazuje to, czego nie przewidziałeś.
