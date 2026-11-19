# Vostok Trainer 0.3.0

Ein In-Game-Trainer für den Einzelspieler von **Road to Vostok 0.2.3.1** mit Metro Mod Loader 3.5.x.

Öffne das Trainer-Menü mit **F6**. Das Spiel pausiert, solange das Menü offen ist. **F6** oder **Esc** schließen das Menü und stellen den vorherigen Spielzustand für Pause und Mauszeiger wieder her. Alle Schalter starten ausgeschaltet. **Alles ausschalten** setzt sie während der Sitzung zurück.

| Schalter | Funktion |
| --- | --- |
| Unbegrenzte Ausdauer | Hält Lauf- und Armausdauer voll. |
| Unbegrenzte Munition | Ersetzt abgefeuerte Patronen. Lade die Waffe einmal. Bei manuell repetierenden Waffen bleibt das Repetieren erforderlich. |
| Godmode | Blockiert die regulären Schadens- und Todesroutinen des Spielers und hält Gesundheit und Sauerstoff voll. |
| Energie und Flüssigkeit auffüllen | Hält Energie und Flüssigkeit voll. |
| Gegner-ESP | Rote Marker mit Name und Entfernung für aktive Gegner. Nomaden werden ausgelassen. |
| Gegenstands-ESP | Grüne Marker mit Name und Entfernung für lose Gegenstände. Behälterinhalte werden nicht erfasst. |
| Boxen | Zeichnet Rahmen um markierte Ziele. |
| Linien | Zeichnet Linien von der unteren Bildschirmmitte zu markierten Zielen. |
| ESP-Distanz | Begrenzt beide ESP-Kategorien auf 10 bis 400 m. Der Startwert ist 150 m. |
| Nachtsicht | Hellt dunkle Bildbereiche auf und färbt das Bild grün. Benötigt keine Ausrüstung im Spiel. |

ESP zeigt die Marker im Sichtfeld auch hinter Wänden. Aktiviere mindestens eine ESP-Kategorie, um Boxen und Linien zu sehen. Beide Darstellungen sind unabhängig schaltbar. Wenn sich Beschriftungen überlagern, werden nahe Ziele bevorzugt.

## Installieren oder aktualisieren

1. Falls nötig, installiere [Metro Mod Loader 3.5.x](https://github.com/ametrocavich/vostok-mod-loader/releases). Lege `override.cfg` und `modloader.gd` aus dem Release in den Spielordner neben `RTV.exe`.
2. Lade [`VostokTrainer.vmz`](./VostokTrainer.vmz?raw=true) herunter und lege die Datei in den Unterordner `mods` neben `RTV.exe`. Erstelle den Ordner, falls er fehlt. Ersetze bei einem Update die bisherige `VostokTrainer.vmz` bei geschlossenem Spiel.
3. Starte das Spiel, aktiviere **Vostok Trainer** im Mod Loader und lade einen Spielstand. Drücke **F6**.

Das Paket ist ein ZIP-Archiv und enthält den GDScript-Quellcode zum Weiterbauen. Zum Entfernen deaktiviere den Trainer im Mod Loader oder entferne die VMZ aus `mods`.

## Aus dem Quellcode bauen

Packe `mod.txt` und den Ordner `VostokTrainer` zusammen in ein ZIP-Archiv. `mod.txt` muss auf der obersten Ebene des Archivs liegen. Die Dateipfade im ZIP verwenden Schrägstriche. Benenne das Archiv in `VostokTrainer.vmz` um.
