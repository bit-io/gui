# Funkcje dla launcherów i aplikacji „konsolowych” (0.2)

Opis rozszerzeń dodanych w wersji 0.2: grafika rastrowa, gamepady, nawigacja przestrzenna, wirtualizacja, zadania w tle, transformacje i animacje.
Działający przykład: `examples/launcher` (okładki, karuzela, siatka 320 gier, modal, szuflada, pad).

## 1. Obrazy rastrowe

```hcs
image("/home/u/covers/zelda.jpg").size_px(150.0, 200.0).fit_cover().radius(12.0)
image_tex(id)            // id z gui_image_open / gui_image_open_b64 / gui_image_gradient
image("data:image/png;base64,....")   // lub "base64:...."
```

* Formaty: JPEG, PNG, WebP (crate `image`, rozpoznawanie po zawartości, nie po rozszerzeniu).
* Dopasowanie: `.fit_cover()` (domyślne), `.fit_contain()`, `.fit_fill()`, `.fit_none()`, `.fit_scale_down()`; `.focal(x, y)` – punkt kotwiczenia (0..1), `.aspect(2.0/3.0)` – proporcje, `.radius()` – zaokrąglenie (z antyaliasingiem), `.border()`.
* Bez rozmiaru obraz ma rozmiar naturalny (z nagłówka pliku), z `fill_width()` zachowuje proporcje.
* **Cache tekstur**: obraz jest dekodowany raz (w puli wątków roboczych, UI się nie blokuje), przechowywany jako tekstura przemnożona + łańcuch mipmap
  (ostre skalowanie okładki 600×900 do 150×225). Limit pamięci domyślnie 256 MB, nadmiar wypierany metodą LRU (obraz wraca przy następnym rysowaniu). Obraz pojawia się z płynnym fade-in.
* Brakujący plik: element rysuje tło (`surface2`), a `gui_image_open` ponawia próbę co 2 s – wystarczy pobrać okładkę w tle.
* Operacja rendererów: `OP_IMAGE = 16` (`id x y w h radius fit alpha fx fy`).

Funkcje natywne: `gui_image_open(path)`, `gui_image_open_b64(data)`, `gui_image_gradient(w,h,c1,c2,kąt)`, `gui_image_load(id)` (synchronicznie), `gui_image_prefetch(id)` (w tle,
po zakończeniu zdarzenie `image`), `gui_image_state(id)` (0 nie załadowany, 1 w trakcie, 2 gotowy, 3 błąd), `gui_image_width/height`, `gui_image_unload/free/reload`,
`gui_image_budget(mb)`, `gui_image_max_size(px)`, `gui_image_stats()`, `gui_image_save(id, path)` (png/jpg/webp), `gui_image_sync(on)` (testy).

## 2. Gamepady

Osobny wątek czyta `/dev/input/event*` (evdev) – bez libudev i bez zależności C; wykrywa podłączanie/odłączanie w trakcie pracy.
Wymaga dostępu do `/dev/input` (zwykle nadaje go udev/logind dla zalogowanego użytkownika lub grupa `input`). Wyłączenie: `GUI_GAMEPAD=0`.

Komunikaty (`Message`):

| `id` | pola |
|---|---|
| `pad_button` | `text` = `A B X Y LB RB LT RT Back Start Guide L3 R3 Up Down Left Right`, `flag` = wciśnięty, `idx` = numer pada |
| `pad_axis` | `text` = `lx ly rx ry` (−1..1, w dół dodatnie, strefa martwa 15%) lub `lt rt` (0..1), `num` = wartość |
| `pad_connected` / `pad_disconnected` | `text` = nazwa, `idx` = numer pada |

Układ osi dla padów Sony (PS4/PS5) jest korygowany (prawa gałka = `ABS_Z/RZ`, triggery = `ABS_RX/RY`). `app.enable_gamepad(false)` wyłącza nasłuch.

## 3. Nawigacja przestrzenna i pułapki fokusu

* `.focusable()` – dowolny element (kafelek, kontener, obraz) wchodzi do nawigacji; fokus rysuje pierścień (wyłączenie: `.focus_ring(false)`); Enter/Spacja/A aktywuje `on_press`.
* Strzałki (włącz: `app.set_key_nav(true)`) oraz D-pad / lewa gałka (domyślnie włączone, `app.set_pad_nav(false)` wyłącza) przenoszą fokus do elementu leżącego
  geometrycznie w danym kierunku (odległość krawędzi + przesunięcie boczne, preferowane nakładanie się rzutów). Gałka ma auto-powtarzanie (380 ms, potem co 110 ms).
  `A` = aktywuj, `B` = wstecz (zamyka modal albo wysyła `Message("back")`). `app.set_nav_wrap(true)` zawija na krawędziach.
* Każda zmiana fokusu wysyła `Message("focus")` z `text` = id elementu, a przewijane kontenery same przewijają się (animowanie), żeby element był widoczny.
* **Pułapka fokusu**: `.focus_trap(true)` na kontenerze albo `modal(...)` / `drawer(...)` w stanie otwartym – Tab, strzałki i pad nie wychodzą poza niego.
* Wartość suwaka i otwarta lista rozwijana dostają Lewo/Prawo oraz Góra/Dół zamiast nawigacji, pole tekstowe – Lewo/Prawo.
* Używaj własnych `.id("…")` – id generowane z pozycji zmieniają się przy zmianie listy.

`modal(treść, otwarty).on_dismiss("close")` – scrim z płynnym zanikaniem, blokada klików pod spodem, klik poza treścią / Esc / `B` wysyła komunikat.
`drawer(treść, otwarty, strona)` (1 lewa, 2 prawa, 3 góra, 4 dół) – to samo, ale panel wysuwa się z krawędzi.

## 4. Wirtualizacja

```hcs
let vr = app.vrange(app.main, "grid", n, 150.0, 232.0, 14.0, 0)       // [first, koniec, kolumny]
... tylko kafelki first..koniec ...
virtual_grid(n, 150.0, 232.0, items).first_index(vr[0]).spacing(14.0).id("grid")
virtual_scrollable(n, 48.0, items)       // lista jednokolumnowa; .horizontal() = poziomo
```

Układ liczony jest z `count`, rozmiaru kafelka i odstępu; do drzewa `Box` trafiają wyłącznie wiersze widoczne + 1 wiersz bufora, więc 3000 kafelków
to ok. 28 węzłów (resolve+layout ≈ 40 ms zamiast liczenia wszystkiego, a przy częściowej liście – jeszcze mniej). Można też przekazać pełną listę – layout i tak odetnie niewidoczne.
`app.scroll_to_item(win, id, index)` przewija animacją do elementu. Zaszyty koszt rysowania tekstu pod clipem został dodatkowo zmniejszony (glify nie kopiują już maski clipu).
Przewijanie poziome: `scrollable_x(treść)` (karuzela; kółko + Shift / gest poziomy, scrollbar poziomy).

## 5. Zadania w tle i kolejka komunikatów

`gui_inject_message(id, text, text2, text3, num, idx, flag)` jest bezpieczne wątkowo (można wołać z koroutyn HackerScript / wątków natywnych) i budzi pętlę główną
(pętla czeka na gnieździe kompozytora i na dodatkowym deskryptorze – bez odpytywania). Wynik trafia do `app.frame` jako zwykły `Message` z podanym `id`.

Gotowe zadania w tle (pula 4 wątków, wynik jako `Message`):

| metoda `App` / funkcja | wynik |
|---|---|
| `app.task_run(id, cmd, args)` | `text` stdout, `text2` stderr, `idx` kod wyjścia, `flag` sukces |
| `app.task_http_get(id, url)` / `gui_task_http(id, metoda, url, nagłówki, ciało, timeout)` | `text` ciało, `idx` kod HTTP, `flag` 2xx (przez `curl`, bez ciężkich zależności TLS) |
| `app.task_scan(id, katalogi, końcówki, głębokość)` | `text` ścieżki rozdzielone `\n`, `idx` liczba (np. `appmanifest_*.acf`) |
| `gui_task_read(id, ścieżka)` / `gui_task_write(id, ścieżka, dane)` | zawartość / sukces |
| `app.task_after(id, ms)` | timer / debounce |
| `app.task_cancel(id)`, `gui_task_pending()` | anulowanie (wynik nie zostanie dostarczony), liczba zadań w toku |

Skanowanie dysku lub zapytanie do ProtonDB nie blokuje więc UI: wystarczy `app.task_http_get("proton:730", url)` i obsłużyć `m.id == "proton:730"` w `update`.

## 6. Transformacje i animacje

* `.scale(1.0)`, `.offset(x, y)` – skala wokół środka elementu i przesunięcie (jednolita skala; dotyczy też tekstu, cieni, obrazów); CSS: `transform: scale(1.1) translate(4px, 0)`.
* `.hover_scale(1.05)`, `.focus_scale(1.08)` (CSS: `:hover { transform: scale(…) }`, `:focus { … }`) – płynne powiększanie aktywnego kafelka; element powiększany jest rysowany nad sąsiadami.
* `modal`/`drawer` – animowane zanikanie scrimu, skalowanie / wysuwanie panelu.
* Animowane przewijanie (`app.scroll_to`, `scroll_to_item`, auto-przewijanie za fokusem), `app.scroll_set` (natychmiast), `app.scroll_offset`.
* `app.tween("klucz", cel)` – wartość płynnie dążąca do celu (~120 ms); wołaj w `view` i podstaw np. do `.offset(app.tween("x", cel), 0.0)` – karuzele, slajdy.
* Operacje renderera: `OP_XFORM = 17` (`skala cx cy tx ty`), `OP_ENDXFORM = 18`.
