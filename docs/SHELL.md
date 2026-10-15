# Pisanie powłoki (panel, launcher, blokada, powiadomienia)

Cała powłoka to zwykły program `gui` z kilkoma oknami typu `layer`. Przykład: `examples/shell`, `examples/lock`.

## Wiele okien (wzór jak `iced::daemon`)
```hcs
let app = app_new_headless_shell()        // bez okna startowego
app.set_theme(theme_glass())
app.set_tick(1000)                        // co sekundę komunikat "tick" (zegar)
let bar = app.open_window("layer", "bar", 0, 40, bar_opts("top", 40, "moj-panel"))
while app.running() [
    let uis: List<Element> = []
    for id in app.window_ids() [          // jedno drzewo na okno, w kolejności window_ids()
        uis.push(widok_dla(id))
    ]
    for m in app.frame(uis) [ s = update(s.clone(), m) ]
]
```
Okna otwierasz i zamykasz w pętli głównej (`app.open_window`, `app.close_window(id)`), na podstawie stanu — tak jak w przykładzie launchera.

## Opcje okien layer-shell
`layer_opts(layer, anchor, exclusive, margin, kb, ns)` oraz gotowe: `bar_opts("top"|"bottom", px, ns)`, `side_bar_opts("left"|"right", px, ns)`,
`dock_opts(margines_dolny, ns)`, `overlay_opts(ns)` (pełny ekran + wyłączny fokus klawiatury), `wallpaper_opts(ns)`, `toast_opts(góra, prawo, ns)`, `osd_opts(dół, ns)`.
`layer`: `background|bottom|top|overlay`; `kb`: `none|ondemand|exclusive`; `exclusive` > 0 rezerwuje miejsce na krawędzi.

## Komunikaty globalne (z kompozytora)
`output` (monitor: `m.args`), `toplevel` / `toplevel_closed` (okna: `m.idx` uchwyt, `m.text` tytuł, `m.text2` app_id, `m.text3` stany),
`lock` (`m.text` = `locked|finished`), `idle` (`m.idx` próg ms, `m.flag` = bezczynny), `clip_changed`, `tick`, `close`, `resize`, `key` (klawisz bez fokusu na widgecie).

## Klocki (`gui::shell`)
* pasek zadań: `taskbar_update(lista, m)` + `taskbar_view(lista, motyw)`; przyciski mają id `tl:<uchwyt>` → `tl_handle_of(m)`, `toplevel_action(h, "activate"|"close"|"minimize"…)`
* monitory: `outputs_update(lista, m)` → `OutputInfo{name,x,y,w,h,scale}`
* system: `clock_hm()`, `clock_date()`, `battery_percent()`, `battery_charging()`, `volume_percent()` (wpctl), `sh_out(polecenie, args)`
* launcher: `apps_load()` (pliki `.desktop`), `apps_filter(lista, zapytanie)`, `launcher_view(...)`, `app_launch(exec)`
* widoki: `bar_layout(lewo, środek, prawo)`, `toast(...)`, `osd(...)`, `lock_view(...)`
* blokada: `gui_session_lock(1)` → okna `"lock"` (po jednym na monitor) → `gui_session_lock(0)`; w przykładzie hasło jest atrapą — prawdziwy locker musi sprawdzać PAM
* bezczynność: `gui_idle_watch(ms)`; `gui_inhibit_idle(okno, 1)` (np. podczas wideo)

## Kompozytory
Panele/blokada wymagają `wlr-layer-shell` / `ext-session-lock` (sway, Hyprland, river, labwc, wayfire, niri; GNOME/Mutter nie wspiera layer-shell).
Pod X11 panel działa jako okno `DOCK` z rezerwacją miejsca, ale bez blokady sesji.
