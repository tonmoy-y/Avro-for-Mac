# Avro-for-Mac

Avro Phonetic Bangla input method for macOS, rebuilt to run natively on **Apple Silicon (arm64)**. The old Intel-only builds stop working on Macs without Rosetta.

Type romanized Bangla (`ami banglay gan gai`) and press Space to get Bangla (আমি বাংলায় গান গাই).

## Download

Get the latest installer from the [Releases page](https://github.com/tonmoy-y/Avro-for-Mac/releases/latest):

1. Download `Avro-Keyboard-for-Mac-arm64.pkg` and open it (right-click → Open if macOS warns about an unidentified developer).
2. Log out and back in.
3. System Settings → Keyboard → Input Sources → Edit → + → Bangla → **Avro Keyboard**.

Prefer no installer? Download the `.zip` and move `Avro Keyboard.app` into `~/Library/Input Methods`.

## If typing stops working

If Avro disappears from the input menu or nothing types, re-enable it:

```bash
./enable-avro.sh
```

(Or add it again in System Settings → Keyboard → Input Sources.)

## Based on

This is a fork of [omicronlab/iAvro](https://github.com/omicronlab/iAvro) (iAvro / Avro Keyboard for Mac) by Rifat Nabi and OmicronLab. All original copyright notices are kept in the source files. Upstream describes the project as open source (listed as MPL 1.1 by [Wikipedia](https://en.wikipedia.org/wiki/Avro_Keyboard)); this repository is distributed under MPL 1.1, see [LICENSE](LICENSE).

## Fixes in this fork

- Builds and runs natively on arm64.
- **Space always commits** the chosen Bangla word and a space. Previously the word could freeze with the English text still showing, because the selected candidate was read from the candidate panel and often came back empty.
- Up/Down/Left/Right move through suggestions, Esc keeps the typed English text, Backspace edits the word, Enter/Tab commit it.
- Pending text is committed when you switch apps or windows.
- Suggestion list is reset for every word instead of carrying over old entries.
- Removed use of a stale client pointer.

## Build and install

Requires Xcode.

```bash
./install.sh
```

Then log out and back in, and add it under System Settings → Keyboard → Input Sources → Edit → + → Bangla → Avro Keyboard.

The app is ad-hoc signed, not notarized. If macOS blocks it, open System Settings → Privacy & Security and choose "Allow anyway".

## Known limitations

- Based on the 2012 source, so newer features of the 2016 v1.3 build may be missing.
- Enter commits the word but does not insert a newline (`CommitNewLineOnEnter` in `preferences.plist`).

Contributions and bug reports are welcome.
