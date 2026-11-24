# Design system

Rules used on every page of the Power BI report. The theme file is
`powerbi/theme.json` (View -> Themes -> Browse for themes).

## Colors

| Role | Color | Used for |
|---|---|---|
| Main data color | `#12937E` (teal) | Single-series lines and bars, entire homes, the selected neighbourhood |
| Highlight color | `#E4572E` (red-orange) | The one element a chart is about (e.g. Kadikoy, Beyoglu, professional hosts, missing licence) |
| Dark gray | `#5F5E5A` | Reference lines (city average, dashed), secondary text, private rooms |
| Mid gray | `#B4B2A9` | Context bars (all other categories) |
| Light gray | `#D3D1C7` | Card borders, "other" categories |
| Text | `#2C2C2A` | Titles, numbers |
| Background | `#FFFFFF` | Page and cards |
| Sequential (map) | `#D4EFEA` -> `#5BBFAE` -> `#0B5C4F` | Low to high median price |

Rules:
- One main color, one highlight, grays for context. No other colors.
- No red-green pairs. The main/highlight pair was checked for color-vision
  deficiency (protan, deutan, tritan) and passes.
- The highlighted element always carries a text label, so meaning never
  depends on color alone.

## Typography

Font: Segoe UI (Segoe UI Semibold for titles).

| Element | Size (pt) |
|---|---|
| Page title (finding sentence) | 20 |
| Subtitle | 11 |
| KPI value | 28 |
| KPI label | 10 |
| Visual title | 12 |
| Axis and data labels | 9-10 |
| Footer | 8 |

## Layout and cards

- Canvas 1280 x 720, 24 px margins, 16 px gaps, same grid on every page
  (see `docs/wireframe/`).
- White page, white cards with a 1 px `#D3D1C7` border and 6 px corner
  radius; no shadows.
- Each page: 4 KPI cards (Page 2: 3, Page 5: 5), 4 visuals, footer with at
  most two caveat lines.

## Measures

- Prices: medians (the price distribution is skewed).
- Ratings, review counts and rates: averages (bounded and compressed).
