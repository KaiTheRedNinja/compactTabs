# Orion Compact Tabs
My Technical Task for Orion

## How it works + Interesting things to note
// Todo

## Difficulties
- No SF Symbols due to version requirement (instead I just added the sf images to assets)

## Potential Bugs
- Due to "hard coding" the SF Symbols in the toolbar, light mode does not work
- Due to how the compact tab bar works, currently toolbar customisation does not work.

## Rough Order of Development
1. Add web view
2. Add back/forward buttons
3. Add URL Bar
4. Add tabbing + temporary buttons to switch left/right a tab
5. Allow URL Bar to automatically resize to fill the space
6. Design tabs
7. Implement tabs view (dummy favicon + dummy titles)
8. Implement clicking to switch tabs
9. On web view refresh, update tabs titles (no favicon yet)
10. Implement shrinking of non-main tabs if not enough space
11. Implement hiding of tab title, center aligning favicon if the tab is smaller than a certain width
12. Implement scrolling of tab bar if non-main tabs are minimum width but theres still not enough space
13. Allow all tabs (both selected and non-selected) to expand in width if theres excess space
14. Allow closing of tabs
15. Allow middle click to close tab
16. Implement favicons
17. Implement animations for when tabs go from no title to with title
18. Implement animations for when tabs resize (eg. when main tab changed, tab added or removed)

## Todo:
- Tab reordering
- Re-enable Toolbar Customisation
