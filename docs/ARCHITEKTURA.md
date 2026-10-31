# Architektura

```
Twój program (State, view, update)
        │  Element (drzewo widgetów, style „nieustawione")
        ▼
resolve.hcs   kaskada: motyw → arkusz CSS (css.hcs) → style inline; id, kolory stanów
layout.hcs    flex: shrink/fixed/fill(portion), padding/margin/spacing, zawijanie tekstu, scrollable  →  drzewo Box
render.hcs    Box + stan (hover/press/focus/animacje) → lista poleceń rysowania (List<Float> + List<Str>)
app.hcs       pętla: trafienia, fokus, edycja tekstu, animacje, wiele okien, komunikaty (Message)
shell.hcs     klocki powłoki (opcje layer-shell, pasek zadań, launcher, blokada, zegar…)
─────────────────────────────── granica HackerScript / native ───────────────────────────────
native.hcs    paint (tiny-skia + ttf-parser) · wl (Wayland) · x11 (x11rb) · plat (wybór backendu, headless, gui_*)
```

Każda klatka: `frame(uis)` → dla zabrudzonych okien `resolve → layout → render → gui_win_draw` → `gui_poll` (blokuje do zdarzenia, animacji,
mrugnięcia kursora lub `tick`) → zdarzenia przeliczane na `Message`. Bez zdarzeń proces śpi w `poll` (pomiar: 0 tyknięć CPU w 6 s); z kursorem w polu tekstowym budzi się co 530 ms (ok. 0,7% CPU); animacje liczone są co ok. 8 ms tylko wtedy, gdy coś się zmienia.

## Pliki

| Plik | Zawartość |
|---|---|
| `lib/mod.hcs` | fasada: `get <bit:gui>` wciąga wszystko |
| `lib/native.hcs` | warstwa systemowa (blok `native {Rust}`), ok. 160 KB tekstu |
| `lib/fonts.hcs` | Inter Regular/SemiBold (base64) i tabela 67 ikon Lucide |
| `lib/util.hcs` | `fmax/fclamp/lerp…`, `slen`, `s_find/s_split/s_replace/s_sub`, `parse_f/parse_i`, `fmt_float` |
| `lib/color.hcs` | kolor `Int 0xRRGGBBAA`: `rgb rgba mix lighten darken parse_color` |
| `lib/theme.hcs` | `Palette`, `Theme`, 6 motywów |
| `lib/element.hcs` | `Length`, `Style`, `Element`, `Message`, konstruktory widgetów, metody łańcuchowe |
| `lib/css.hcs` | parser i dopasowanie podzbioru CSS |
| `lib/resolve.hcs` | style domyślne widgetów + kaskada + propagacja `Fill` |
| `lib/layout.hcs` | `size_of`, `place`, `layout_root`, `Box` |
| `lib/render.hcs` | `Ops` (lista poleceń) + rysowanie widgetów i nakładek |
| `lib/app.hcs` | `App`, `WinState`, zdarzenia, edycja tekstu |
| `lib/shell.hcs` | powłoka |

## Lista poleceń rysowania (`Ops` → `paint::run_ops`)
Strumień `Float`: kod operacji i argumenty (kolory jako `0xRRGGBBAA` w `Float`):
`1 RRECT` · `2 STROKE` · `3 LGRAD` · `4 RGRAD` · `5 SHADOW(blur,spread,dx,dy,inset)` · `6 TEXT` · `7 CLIP`/`8 UNCLIP` · `9 ICON` · `10 BACKDROP(rozmycie tła)` ·
`11 LAYER(alfa)`/`12 ENDLAYER` · `13 LINE` · `14 PATH(SVG)` · `15 CLEAR` · `16 IMAGE(id,x,y,w,h,r,fit,alfa,fx,fy)` · `17 XFORM(skala,cx,cy,tx,ty)`/`18 ENDXFORM`. Bufor jest BGRA (premultiplied), rysowany wprost w `mmap` bufora `wl_shm`
(Wayland) lub w pamięci i wysyłany `PutImage` (X11) — bez kopiowania i konwersji kanałów (R↔B zamieniane przy tworzeniu koloru).
Tekst: glify z konturów `ttf-parser` rastrowane `tiny-skia` z pozycjonowaniem podpikselowym (4 pozycje) i kerningiem z GPOS, cache masek glifów.

## Funkcje natywne (`gui_*`)
`gui_init gui_backend_name gui_globals gui_poll gui_inject gui_fonts_init` · okna: `gui_win_create gui_win_draw gui_win_title gui_win_close gui_win_resize gui_cursor` ·
tekst: `gui_text_measure gui_text_wrap gui_font_ascent gui_font_descent gui_str_len gui_lower` · schowek: `gui_clip_set gui_clip_get` ·
powłoka: `gui_session_lock gui_idle_watch gui_inhibit_idle gui_toplevel_action gui_run gui_spawn gui_list_apps gui_read_file gui_write_file` ·
obrazy: `gui_image_*` · gamepad: `gui_pad_*` · zadania w tle i kolejka: `gui_inject_message gui_msg_take gui_task_*` ·
testy: `gui_pixel gui_screenshot gui_set_scale gui_exit gui_file_size gui_now_ms gui_env`. Wywołuje się je z HackerScript po `get <bit:gui::native>` (lub `get <bit:gui>`);
argumenty przekazywane są **przez wartość** (`String`, `Vec<f64>`, `Vec<String>`).

## Edycja `native.hcs`
Kompilator `hackerc` wycina blok `native {Rust} [ … ]` licząc nawiasy `[` i `]` **naiwnie** (także w literałach i komentarzach), dlatego w kodzie Rust:
nawiasy kwadratowe w ciągach/znakach muszą być zbalansowane (zamiast `'['` użyj `0x5b`), nie wolno pisać sekwencji `!>`, `<!` i `!!`,
a słowo `native` nie powinno występować poza blokiem w komentarzach przed `[`. Moduły (`paint`, `wl`, `x11`, `plat`) są zagnieżdżone jako `pub mod`,
a `pub use plat::*;` udostępnia `gui_*`. Zależności zadeklarowane są `get <crates:…>` na początku pliku.

## Wydajność i rozmiar (pomiar w środowisku testowym)
* binarka przykładu z wszystkimi backendami: 2,07–2,27 MB (`opt-level=3`, LTO, strip), dynamicznie tylko libc/libm/libgcc_s
* pamięć (X11, Xvfb): 6,2 MB RSS w spoczynku (licznik), ok. 7,6 MB (galeria), ok. 12 MB po interakcji
* 300+ elementów: `resolve` 1 ms, `layout` 10 ms, polecenia 5 ms, rasteryzacja 600×800 z cieniami 23 ms (nieoptymalizowane; cienie i rozmycie liczone na CPU)
* kompilacja programu z `gui`: transpilacja ok. 2 min w moim środowisku (`hackerc` 0.5 zbudowany bez LTO, `opt-level=1`) + ok. 45–75 s `cargo` — pierwsze
  budowanie zależności trwa dłużej; główny koszt to parsowanie 160 KB bloku natywnego i 140 KB czcionek w base64 przez `hackerc`


## Rozszerzenia 0.2
Obrazy, gamepad, nawigacja 2D, wirtualizacja, zadania w tle i animacje: **docs/LAUNCHER.md**. Wątki (obrazy, gamepad, zadania) komunikują się z pętlą przez kolejkę z deskryptorem budzącym `poll` (`bg::push_line`), więc `gui_poll` nadal śpi bez zdarzeń.
