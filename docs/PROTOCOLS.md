# Protokoły i backendy

`gui` wybiera backend przy starcie (`GUI_BACKEND=wayland|x11|headless|auto`, domyślnie `auto`):
Wayland (gdy jest `WAYLAND_DISPLAY`) → X11 (gdy jest `DISPLAY`; działa także pod XWayland) → headless.

## Wayland (czysty Rust, bez libwayland)

Status: **T** = sprawdzone w teście na prawdziwym kompozytorze (sway 1.9, tryb headless), **Z** = zaimplementowane i skompilowane,
ale nie wywołane w testach (brak okazji w środowisku testowym), **—** = brak.

| Protokół | Do czego | Status |
|---|---|---|
| `wl_compositor`, `wl_shm`, `wl_buffer` | powierzchnie i bufory pamięci współdzielonej (podwójne buforowanie, rysowanie wprost do `mmap`) | T |
| `xdg_wm_base` / `xdg_surface` / `xdg_toplevel` | zwykłe okna | T |
| `zxdg_decoration_manager_v1` | dekoracje po stronie kompozytora | T |
| `zwlr_layer_shell_v1` | panele, doki, launchery, tapety, powiadomienia, OSD | T |
| `ext_session_lock_v1` | ekran blokady (okno na monitor) | T (blokada i powierzchnia; odblokowanie `unlock_and_destroy` — Z) |
| `zwlr_foreign_toplevel_manager_v1` | lista okien, aktywacja/zamknięcie/minimalizacja | T (zdarzenia listy); akcje — Z |
| `wl_seat`: pointer, keyboard | mysz, klawiatura (xkb przez `dlopen libxkbcommon`, powtarzanie klawiszy, zapasowy układ US+PL AltGr) | T |
| `wl_seat`: touch | dotyk | Z |
| `wl_data_device_manager` | schowek tekstowy (odczyt i zapis) | T |
| `wp_fractional_scale_v1` + `wp_viewporter` | ostre skalowanie ułamkowe (np. 1.25×, 1.5×) | Z (sway headless raportuje skalę 1) |
| `wp_cursor_shape_manager_v1` | kształt kursora bez motywów kursorów | Z |
| `ext_idle_notifier_v1` | wykrywanie bezczynności | T |
| `zwp_idle_inhibit_manager_v1` | blokada wygaszania ekranu (np. wideo) | Z |
| `wl_output` | lista monitorów (nazwa, pozycja, rozmiar, skala) | T |

## Jeszcze nie ma (plan)

`xdg_popup` (menu kontekstowe poza oknem; na razie listy rozwijane rysowane są w obrębie okna),
`zwp_text_input_v3` / `zwp_input_method_v2` (IME), `zwlr_screencopy_v1` / `ext_image_copy_capture`,
`zwlr_output_management_v1`, `ext_workspace_v1`, `zwlr_gamma_control_v1`, `zwlr_data_control_v1`,
`zwlr_virtual_pointer_v1` / `zwp_virtual_keyboard_v1`, `xdg_activation_v1`, drag&drop (`wl_data_device` DnD),
`xdg_toplevel_icon`. Powłoka z README (panel, launcher, blokada, pasek zadań) obywa się bez nich.

## X11 / XWayland

Backend `x11rb` (czysty Rust): okna `_NET_WM_WINDOW_TYPE_*`, panele jako `DOCK` z `_NET_WM_STRUT_PARTIAL`,
tapeta jako `DESKTOP`, schowek `CLIPBOARD`/`UTF8_STRING`, klawiatura z `GetKeyboardMapping` (łącznie z AltGr i polskimi literami),
skala z `Xft.dpi` lub `GUI_SCALE`. Brak: przezroczystość okien (wymaga wizualu ARGB), `session-lock`, `layer-shell`
(emulowane przez typy okien EWMH).

Status: **T** na Xvfb (okno, panel dock, mysz, klawiatura z polskimi znakami, schowek). **Pod XWayland nie testowano osobno**
— backend X11 rozmawia z serwerem X11 tak samo, ale pełny test z `Xwayland` pozostaje do zrobienia.

## Headless

`GUI_BACKEND=headless`: okna w pamięci, zdarzenia wstrzykiwane przez `gui_inject("ptr_down\t1\t0\tx\ty")`, zrzuty PNG przez
`gui_screenshot(id, "plik.png")`. Na tym stoi cały zestaw testów (`tests/`).

## Format zdarzeń natywnych (pola rozdzielone tabulatorem)

```
resize  <okno> <w> <h> <skala>      ready <okno>          frame <okno>        close <okno>
ptr_move <okno> <x> <y>             ptr_down|ptr_up <okno> <przycisk> <x> <y>   ptr_leave <okno>
scroll <okno> <dx> <dy> <x> <y>     key <okno> <1|0> <powtorzenie> <nazwa> <tekst> <mods>
focus <okno> <1|0>                  output <nazwa> <x> <y> <w> <h> <skala>
toplevel <uchwyt> <tytul> <app_id> <stany>      toplevel_closed <uchwyt>
lock locked|finished                idle <ms> <1|0>       clip_changed
```
`mods`: 1 Shift, 2 Ctrl, 4 Alt, 8 Super, 16 CapsLock. Nazwy klawiszy: `Enter Backspace Tab Escape Delete Home End ArrowLeft…`, litery jako znak.
