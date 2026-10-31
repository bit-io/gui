# Wygląd: motywy, style, CSS

Kaskada (jak w CSS): **motyw → arkusz CSS → style inline**. Każde pole stylu może być „nieustawione"; wygrywa najbardziej szczegółowe źródło.

## Motywy
`theme_dark()` (Catppuccin Mocha), `theme_light()` (Latte), `theme_nord()`, `theme_dracula()`, `theme_tokyo()`, `theme_glass()` (półprzezroczyste
powierzchnie + rozmycie tła — do paneli i launcherów), `theme_by_name("nord")`. Zmiana w locie: `app.set_theme(theme_light())`.
Paleta (`theme.p`): `bg surface surface2 surface3 overlay text subtext muted primary primary_text success warning danger info border shadow`.
Kolor to `Int` `0xRRGGBBAA`: `rgb(137,180,250)`, `rgba(0,0,0,120)`, `parse_color("#89b4fa")`, `mix(a,b,t)`, `lighten`, `darken`, `with_alpha`.

## Klasy wbudowane
`button`: `primary` `danger` `success` `ghost` `icon` · `text`: `heading` `subheading` `caption` `muted` `primary` `danger` `success` ·
`container`: `card` `badge` `panel` `glass`. Klasy łączysz spacją: `.class("ghost icon")`.

## Style inline (metody łańcuchowe)
`padding` `padding_xy` `padding_4` `margin` `spacing` `width` `height` `size_px` `fill_width` `fill_height` `fill_all` `min_width` `max_width`
`min_height` `max_height` `align_x` `align_y` `center` `center_x` `center_y` `background` `gradient(od, do, kąt)` `color` `size` `bold`
`letter_spacing` `line_height` `text_align` `no_wrap` `radius` `border(grubość, kolor)` `shadow(blur, dy, kolor)` `glass(blur)` `opacity` `clip` `disabled`.
Długości jak w iced: `shrink()`, `fixed(px)`, `fill()`, `portion(n)`. Wyrównanie: `0` start, `1` środek, `2` koniec.
Kontener, który ma dziecko `Fill`, sam staje się `Fill` (jak w iced), więc `row([a, space().fill_width(), b])` rozpycha elementy do krawędzi.

## CSS (podzbiór)
```hcs
app.set_css(".card { border-radius: 18px; box-shadow: 0 10px 28px rgba(0,0,0,0.4); }
button.primary { background: linear-gradient(90deg, #89b4fa, #cba6f7); border-radius: 999px; padding: 10px 22px; }
button:hover { box-shadow: 0 6px 18px rgba(0,0,0,0.5); }
#bar, .glass { backdrop-filter: blur(24px); background: rgba(30,30,46,0.5); }")
```
Selektory: `typ`, `.klasa`, `#id`, `typ.klasa`, lista po przecinku, pseudo-klasy `:hover` `:active` `:focus`. Typy = nazwy widgetów
(`button`, `text`, `text_input`, `container`, `column`, `row`, …). Właściwości: `background(-color)` (kolor lub `linear-gradient(kąt, c1, c2)`), `color`,
`border-radius`, `border` (`1px solid #fff`), `border-color`, `padding`, `margin`, `gap`, `font-size`, `font-weight`, `width`/`height`
(`240px`, `fill`, `auto`), `min/max-width/height`, `opacity`, `letter-spacing`, `line-height`, `text-align`, `overflow: hidden`,
`box-shadow: dx dy blur kolor`, `backdrop-filter: blur(px)`.
Brak: `@media`, zmienne `var()`, selektory potomków (`a b`), animacje `@keyframes` (przejścia stanów hover/press/focus są wbudowane, ~140 ms).

## Ikony
67 ikon Lucide: `icon("wifi")`, `button("Zapisz").with_icon("check")`. Lista: `arrow-down arrow-left arrow-right arrow-up battery-charging battery bell-off bell bluetooth calendar camera check chevron-down chevron-left chevron-right chevron-up circle-check clock copy cpu download external-link eye-off eye file folder globe hard-drive heart house image info layout-grid lock-open lock log-out maximize menu mic minimize minus monitor moon music pause pencil play plus power refresh-cw search settings skip-back skip-forward sliders-horizontal star sun terminal trash triangle-alert upload user volume-2 volume-x wifi-off wifi x`.
Własny rysunek: `canvas("M4 4 L20 20", 24.0)` (ścieżka SVG: `M L H V C S Q T A Z`).


## Transformacje (0.2)
`transform: scale(1.1)` i `translate(x, y)` oraz warianty `:hover` / `:focus` (np. `.tile:focus { transform: scale(1.08); }`) — patrz docs/LAUNCHER.md, sekcja 6.
