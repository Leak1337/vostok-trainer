# Vostok Trainer 0.6.0

Ein In-Game-Trainer für den Einzelspieler von **Road to Vostok 0.2.3.1** mit Metro Mod Loader 3.5.x.

**F6** öffnet das Trainer-Menü. Das Spiel pausiert, solange das Menü offen ist. **F6** oder **Esc** schließen es. Die Hauptschalter für ESP und Spielerfunktionen starten ausgeschaltet. ESP-Einstellungen und Merkliste werden automatisch gespeichert.

## Spieler

- **Unbegrenzte Ausdauer** hält Lauf- und Armausdauer voll.
- **Unbegrenzte Munition** ersetzt abgefeuerte Patronen. Lade die Waffe einmal. Bei manuell repetierenden Waffen bleibt das Repetieren erforderlich.
- **Kein Waffenverschleiß** hält den aktuellen Waffenzustand beim Schießen konstant.
- **Keine Ladehemmungen** verhindert neue Ladehemmungen und löst bestehende, sobald die Waffe wieder bedienbar ist. Der Schalter funktioniert unabhängig vom Waffenverschleiß.
- **Godmode** blockiert regulären Schaden und hält Gesundheit und Sauerstoff voll.
- **Energie und Flüssigkeit auffüllen** hält beide Werte voll.
- **Nachtsicht** hellt dunkle Bildbereiche auf und färbt das Bild grün.

## Personen-ESP

**Gegner anzeigen**, **Händler anzeigen** und **Andere NPCs anzeigen** sind unabhängig schaltbar. Aktive Händler werden türkis markiert, aktive Nomaden und die Katze hellgrün. **Skelett anzeigen** folgt den aktuellen Knochenpositionen von Gegnern und umherziehenden Nomaden. Die Skelettlinien werden mit zunehmender Entfernung dünner. Linien zur Bildschirmmitte und Entfernungsangaben sind separat einstellbar. Die gemeinsame Personen-Reichweite ist von 10 bis 400 m einstellbar. Standard sind 150 m.

**Radar anzeigen** zeigt Gegner, Händler und NPCs rund um dich, auch seitlich und hinter dir. Das Radar sitzt unten links, dreht sich mit der Blickrichtung und nutzt die Personen-Reichweite sowie die jeweiligen ESP-Farben. Du kannst es ohne die einzelnen Personenmarker einschalten.

## Loot-ESP und Loot-Filter

- **Lose Gegenstände anzeigen** markiert Bodenloot im Sichtfeld auch hinter Wänden.
- **Behälter und Lager anzeigen** zeigt eine Vorschau der verfügbaren Inhalte von Kisten, Schränken und Lagern vor dem Öffnen. Verschlossene Behälter sind gekennzeichnet. Leere Behälter lassen sich zuschalten.
- **Loot in Blickrichtung auflisten** sammelt Marker rund um die Bildschirmmitte. Richte den Blick auf ein Gebäude, um Loot im Sichtfeld zu sehen, und auf einen Behältermarker, um mehr von seinem Inhalt zu lesen. Die Übersicht kann auch Loot hinter dem Gebäude erfassen, wenn er in derselben Blickrichtung und Reichweite liegt.
- **Nahe Loot-Marker bündeln** fasst eng beieinanderliegende Marker zu einer Gruppe zusammen und zeigt die Zahl der Quest-Treffer. Richte das Fadenkreuz auf die Gruppe, um bis zu fünf Einzelziele und die Anzahl weiterer Treffer zu sehen.
- **Loot-Filter** bietet eine Mehrfachauswahl für Waffen, Munition, Zubehör, Essen und Trinken, Medizin, Ausrüstung, Elektronik, Schlüssel, Quest-Gegenstände und Sonstiges. Die Filter gelten für Bodenloot und Behälterinhalte. Quest-Gegenstände sind gelb und mit **[Quest]** beschriftet. Für Händleraufgaben zählt, was auf deiner Aufgabenliste notiert ist.
- Die Seltenheit steht am Gegenstandsnamen. Normale Waffen sind orange, seltene Gegenstände blau und legendäre violett. Bei Waffen mit höherer Seltenheit gilt die Seltenheitsfarbe. Quest-Gegenstände behalten ihre gelbe Markierung und zeigen ihre Seltenheit zusätzlich als Text.
- Linien, Entfernungsangaben und ein Seltenheitsfilter sind separat einstellbar. Die Loot-Reichweite ist unabhängig von der Personen-Reichweite und auf 10 bis 400 m einstellbar. Standard sind 150 m.

Das ESP aktualisiert die Zielliste und Loot-Infos ungefähr zehnmal pro Sekunde. Die Bildschirmpositionen und Skelette sichtbarer Ziele werden pro Bild neu berechnet.

## Item-Suche und Merkliste

Aktiviere Bodenloot oder Behälter unter **Loot-ESP** und öffne **Item-Suche**. Die Suche findet Teile des Namens oder der internen Item-ID. In die Merkliste passen bis zu 24 Begriffe und insgesamt 512 Zeichen. Trenne Begriffe mit Kommas oder Zeilenumbrüchen.

Suchtreffer sind mit **[Suche]** oder **[Merkliste]** gekennzeichnet. Behälter mit passenden Gegenständen tragen **[Treffer]**. Treffer erscheinen auch bei ausgefilterten Kategorien. Mit **Nur Suchtreffer und Merkliste anzeigen** blendest du übrigen Loot aus, solange mindestens ein Suchbegriff vorhanden ist.

## ESP-Profile

Unter **Profile** findest du die Vorlagen **Standard**, **Quest**, **Waffen** und **Alles**. Gib einen eigenen Namen ein und klicke auf **Speichern**, um die aktuellen Reichweiten, Loot-Kategorien, Anzeigeoptionen und Farben zu sichern. Unter demselben Namen kannst du das Profil aktualisieren.

Suche, Merkliste und die letzten ESP-Einstellungen bleiben beim Spielneustart erhalten. Beim Profilwechsel bleiben die Suche und Merkliste bestehen. Die Hauptschalter für ESP und Spielerfunktionen werden separat bedient.

## Welt

In einer geladenen Karte kannst du unter **Welt** die Uhrzeit in Fünf-Minuten-Schritten setzen oder den normalen Zeitlauf anhalten. Schlaf und Reisen nutzen weiterhin ihre eigenen Zeitsprünge. **Wetter setzen** bietet unter anderem Klar, Regen, Nebel und Sturm. Draußen wechselt das Spiel zu diesem Wetter, danach läuft die normale Wettersimulation weiter. Uhrzeit und Wetter können beim nächsten regulären Speichern in den Spielstand übernommen werden.

## Installieren oder aktualisieren

1. Falls nötig, installiere [Metro Mod Loader 3.5.x](https://github.com/ametrocavich/vostok-mod-loader/releases). Lege `override.cfg` und `modloader.gd` aus dem Release in den Spielordner neben `RTV.exe`.
2. Lade [`VostokTrainer.vmz`](./VostokTrainer.vmz?raw=true) herunter und lege die Datei in den Unterordner `mods` neben `RTV.exe`. Erstelle den Ordner, falls er fehlt. Ersetze bei einem Update die bisherige `VostokTrainer.vmz` bei geschlossenem Spiel.
3. Starte das Spiel, aktiviere **Vostok Trainer** im Mod Loader und lade einen Spielstand. Drücke **F6**.

## Aus dem Quellcode bauen

Packe `mod.txt` und den Ordner `VostokTrainer` zusammen in ein ZIP-Archiv. `mod.txt` muss auf der obersten Ebene des Archivs liegen. Verwende Schrägstriche für die Pfade im ZIP und benenne das Archiv in `VostokTrainer.vmz` um.
