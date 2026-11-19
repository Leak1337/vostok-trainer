# Vostok Trainer 0.4.0

Ein In-Game-Trainer für den Einzelspieler von **Road to Vostok 0.2.3.1** mit Metro Mod Loader 3.5.x.

**F6** öffnet das Trainer-Menü. Das Spiel pausiert, solange das Menü offen ist. **F6** oder **Esc** schließen es. Alle Trainer-Funktionen starten ausgeschaltet. Die Auswahl der Loot-Kategorien bleibt beim Ausschalten erhalten, bis du das Spiel beendest.

## Spieler

- **Unbegrenzte Ausdauer** hält Lauf- und Armausdauer voll.
- **Unbegrenzte Munition** ersetzt abgefeuerte Patronen. Lade die Waffe einmal. Bei manuell repetierenden Waffen bleibt das Repetieren erforderlich.
- **Godmode** blockiert regulären Schaden und hält Gesundheit und Sauerstoff voll.
- **Energie und Flüssigkeit auffüllen** hält beide Werte voll.
- **Nachtsicht** hellt dunkle Bildbereiche auf und färbt das Bild grün.

## Gegner-ESP

Aktiviere **Gegner anzeigen** und schalte **Skelett anzeigen** und **Linien zu Gegnern** nach Wunsch dazu. Das Skelett folgt den aktuellen Knochenpositionen. Nomaden lassen sich zusätzlich einschalten. Die Gegner-Reichweite ist von 10 bis 400 m einstellbar. Standard sind 150 m.

## Loot-ESP und Loot-Filter

- **Lose Gegenstände anzeigen** markiert Bodenloot im Sichtfeld auch hinter Wänden.
- **Behälter und Lager anzeigen** zeigt eine Vorschau der verfügbaren Inhalte von Kisten, Schränken und Lagern vor dem Öffnen. Verschlossene Behälter sind gekennzeichnet. Leere Behälter lassen sich zuschalten.
- **Loot in Blickrichtung auflisten** sammelt Marker rund um die Bildschirmmitte. Richte den Blick auf ein Gebäude, um Loot im Sichtfeld zu sehen, und auf einen Behältermarker, um mehr von seinem Inhalt zu lesen. Die Übersicht kann auch Loot hinter dem Gebäude erfassen, wenn er in derselben Blickrichtung und Reichweite liegt.
- **Loot-Filter** bietet eine Mehrfachauswahl für Waffen, Munition, Zubehör, Essen und Trinken, Medizin, Ausrüstung, Elektronik, Schlüssel, Quest-Gegenstände und Sonstiges. Die Filter gelten für Bodenloot und Behälterinhalte. Quest-Gegenstände sind gelb und mit **[Quest]** beschriftet. Für Händleraufgaben zählt, was auf deiner Aufgabenliste notiert ist.
- Linien, Entfernungsangaben und ein Seltenheitsfilter sind separat einstellbar. Die Loot-Reichweite ist unabhängig von der Gegner-Reichweite und auf 10 bis 400 m einstellbar. Standard sind 150 m.

## Installieren oder aktualisieren

1. Falls nötig, installiere [Metro Mod Loader 3.5.x](https://github.com/ametrocavich/vostok-mod-loader/releases). Lege `override.cfg` und `modloader.gd` aus dem Release in den Spielordner neben `RTV.exe`.
2. Lade [`VostokTrainer.vmz`](./VostokTrainer.vmz?raw=true) herunter und lege die Datei in den Unterordner `mods` neben `RTV.exe`. Erstelle den Ordner, falls er fehlt. Ersetze bei einem Update die bisherige `VostokTrainer.vmz` bei geschlossenem Spiel.
3. Starte das Spiel, aktiviere **Vostok Trainer** im Mod Loader und lade einen Spielstand. Drücke **F6**.

## Aus dem Quellcode bauen

Packe `mod.txt` und den Ordner `VostokTrainer` zusammen in ein ZIP-Archiv. `mod.txt` muss auf der obersten Ebene des Archivs liegen. Verwende Schrägstriche für die Pfade im ZIP und benenne das Archiv in `VostokTrainer.vmz` um.
