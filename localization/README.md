# GBeat Localization

This directory contains translation files for GBeat.

## Supported Languages

| Code | Language | Status |
|------|----------|--------|
| en | English | Complete (Source) |
| ja | Japanese | Partial |
| es | Spanish | Stub |
| pt_BR | Portuguese (Brazil) | Stub |
| de | German | Stub |
| fr | French | Stub |
| ko | Korean | Stub |
| zh_CN | Chinese (Simplified) | Stub |
| ru | Russian | Stub |

## File Format

Translation files use the Gettext PO format (`.po`).

## Adding a New Language

1. Copy `en.po` as a template
2. Rename to the language code (e.g., `fr.po` for French)
3. Update the header metadata
4. Translate all `msgstr` entries

## Using Translations in Code

```gdscript
# Set the locale
TranslationServer.set_locale("ja")

# Get translated string
var text = tr("MENU_START")  # Returns "ゲームスタート" in Japanese
```

## Loading Translations

Add to project settings or load manually:

```gdscript
func _ready():
    var translation = load("res://localization/ja.po")
    TranslationServer.add_translation(translation)
```

## Translation Keys Convention

- Use SCREAMING_SNAKE_CASE
- Prefix by category:
  - `MENU_` - Main menu items
  - `PAUSE_` - Pause menu items
  - `OPTIONS_` - Options/settings
  - `COMBAT_` - Combat feedback
  - `RESULTS_` - Results screen
  - `TUTORIAL_` - Tutorial text
  - `ACCESS_` - Accessibility options

## Contributing Translations

1. Fork the repository
2. Add or update translation files
3. Test in-game
4. Submit a pull request
