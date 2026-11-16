# Notwendige Änderungen im Code

## 1. Datei- und Verzeichnisnamen

- Die Dateiendungen `.goc` und `.goh` müssen kleingeschrieben werden.
- Am besten werden die vollständigen Namen der Code-Dateien kleingeschrieben.
- Haupt- und Unterordner sollten als Substantive benannt werden, zum Beispiel:

  ```text
  Instf/Main
  Instf/Art
  ```

- Nur `UI` wird vollständig großgeschrieben:

  ```text
  Instf/UI
  ```

## 2. GP-Datei

- Die Groß- und Kleinschreibung der Ressourcennamen muss angepasst werden.
- Möglicherweise muss auch die Groß- und Kleinschreibung exportierter Routinen
  angepasst werden.
- Bei Libraries werden exportierte Routinen großgeschrieben.
- Laut Falk soll kein `platform`-Statement verwendet werden.
- Falls der Fehler `Programm nicht kompatibel mit BBX 4.1.3` auftritt, kann
  beispielsweise folgende Angabe verwendet werden:

  ```text
  platform geos21
  ```

  Möglicherweise funktioniert auch eine andere passende Plattformangabe.

## 3. `local.mk`

### Copyright-Hinweis in `LINKFLAGS`

- Den Copyright-Hinweis in Anführungszeichen setzen.
- `\20` durch normale Leerzeichen ersetzen.

### `XCCOMFLAGS`

`XCCOMFLAGS` auskommentieren, insbesondere die Optionen `-d` und `-dc`.

### Nützliche Compiler-Flags

- **`-zc`** – legt konstante Daten im Code-Segment ab.

  Diese Option ersetzt `-dc`. Strings werden damit im Code-Segment statt in
  `dgroup` abgelegt.

  > **Hinweis:** Die Option funktioniert. Issue `#165` ist offenbar gelöst.

- **`-zu`** – verwendet `SS != DGROUP`. Der Compiler nimmt also nicht an, dass
  der Stack im Datensegment liegt.

  Diese Option ersetzt `-WDE` und wird nur für Libraries verwendet.

- **`-1` bis `-6`** – Prozessor-Spezifikation.

## 4. GOC-Dateien

### Umlaute und GEOS-Zeichen

Umlaute in `visMoniker` müssen durch ihre Hexadezimaldarstellung ersetzt werden.

Sicherheitshalber sollte dies für alle GEOS-Zeichen ab `0x80` gemacht werden.

Folgt auf eine Hexadezimaldarstellung ein Zeichen, das selbst eine
Hexadezimalziffer ist, muss dieses Zeichen ebenfalls als Hexadezimalcode
geschrieben werden.

Das betrifft beispielsweise:

- `Schließen`, wenn nach dem Escape-Code ein `e` folgt,
- `Zurück`, wenn nach dem Escape-Code ein `c` folgt.

### Assembler-Definitionen

Bei Assembler-Definitionen darf kein Semikolon am Ende stehen:

```c
#define PUSHDS __asm push ds /* push ds */
```

### Eingebundene Header-Dateien

- Die Groß- und Kleinschreibung eingebundener Header-Dateien muss exakt stimmen.
- In Pfaden müssen Schrägstriche (`/`) statt umgekehrter Schrägstriche (`\`)
  verwendet werden, damit der Code unter Linux kompatibel ist.

### Gleitkommazahlen

`long double` wird nicht mehr unterstützt. Stattdessen muss `FloatNum`, eine
Struktur, verwendet werden.

Alle `Float~`-Routinen erwarten `FloatNum`.

Für Berechnungen können folgende Datentypen verwendet werden:

- `double`: 8 Byte, ungefähr 12 Nachkommastellen,
- `float`: 4 Byte.

Konvertierung von `double` zu `FloatNum` auf dem Stack:

```c
FloatIEEE64ToGeos80()
```

Konvertierung von `FloatNum` auf dem Stack zu `double`:

```c
FloatGeos80ToIEEE64()
```

Für `float` mit 4 Byte erfolgt die Konvertierung analog über die
`IEEE32`-Routinen.

## 5. REV-Datei

Der vollständige Name der REV-Datei muss kleingeschrieben werden:

```text
instc.rev
```

`glue` erwartet diese Schreibweise.

## 6. LDF-Dateien eigener Libraries

Die LDF-Dateien eigener Libraries müssen **nicht** in das Original-Repository
kopiert werden.

Sie gehören in folgendes Verzeichnis:

```text
LOCAL_ROOT/Include
```

`pmake full` erledigt dies automatisch.

> Siehe auch die Datei `Wichtiges - Coding.txt`.

---

# Übersetzungsdatei bei der Umstellung auf Englisch

1. Die aktuelle Übersetzung von Deutsch nach Englisch exportieren, damit die
   englischen und deutschen Texte gesichert sind.

2. Eine neue Übersetzungsdatei anlegen. Die deutschen Texte stehen zunächst
   links und rechts.

   > Vorher eine Sicherheitskopie erstellen!

3. Alle Chunks in der Übersetzungsdatei modifizieren. Dazu beispielsweise ein
   Leerzeichen oder einen Zeilenumbruch einfügen und anschließend wieder
   entfernen.

   Andernfalls wird beim Update auch der deutsche Text auf der rechten Seite
   durch die englische Version ersetzt.

4. Die deutschen Texte im Code durch die englischen Texte aus Schritt 1
   ersetzen. Bei Problemen sollte dies schrittweise erfolgen.

   Werden die Texte aus dem exportierten Übersetzer verwendet, müssen die
   Platzhalter wie folgt ersetzt werden:

   ```text
   @1 → \01
   @2 → \02
   ```

   Aktuell dürfen Texte die Platzhalter `\01` und `\02` jeweils nur einmal
   enthalten. Eine zweifache Verwendung von `\01` funktioniert nicht.

5. Nach jedem Schritt die Übersetzungsdatei aktualisieren. Aufgrund der
   Änderungen aus Schritt 3 sollten die deutschen Texte auf der rechten Seite
   erhalten bleiben.

---

# Aktuelle Probleme

**Stand: Mai 2023**

Keine.

---

# Ungewöhnliche Fehlermeldungen und ihre Lösungen

## Fehler in `graphics.h`

```text
D:\G6\PCGEOS\CInclude\graphics.h(992): Error! E1009:
Expecting , but found 1

D:\G6\PCGEOS\CInclude\graphics.h(992): Error! E1127:
Type required in parameter list
```

**Ursache:** `XCOMPFLAGS -dc` wurde in `local.mk` nicht auskommentiert.

**Lösung:** Die Option `-dc` in `local.mk` auskommentieren.

## Speicherfehler bei `nclean`

```text
nclean: The memory could not be read.
Exception fielded by 0x0040a0f0
```

Anschließend folgt ein Stack-Dump.

**Ursache:** `XCOMPFLAGS -d` wurde in `local.mk` nicht auskommentiert.

**Lösung:** Die Option `-d` in `local.mk` auskommentieren.

## Assertion in `RenameFileSrcMapEntry`

```text
Assertion Failed: FALSE, function RenameFileSrcMapEntry,
file D:\G6\PCGEOS\Tools\glue\main.c, line 271.
```

**Ursache:** Eine Datei endet nicht mit einer Leerzeile beziehungsweise einem
abschließenden Zeilenumbruch.

**Lösung:** Sicherstellen, dass alle betroffenen Dateien mit einem Zeilenumbruch
enden.

## Ungültiges Objektmodul

```text
Error MUSIC.obj: invalid object module (not VM or MS format)
Error PROCESS.eobj: invalid object module (not VM or MS format)
```

**Ursache:** Die Dateiendungen und möglicherweise auch die Dateinamen wurden
nicht kleingeschrieben.

**Lösung:** Die Dateiendungen und gegebenenfalls die vollständigen Dateinamen
kleinschreiben.

## Fehler bei `const` und dem Flag `-zc`

```text
Error mAppl.eobj:
non-data FIXUPP record may only contain THREAD definitions
```

Bei Verwendung des Flags `-zc` können Konstrukte der folgenden Form unter
Umständen nicht kompiliert werden:

```c
static const GenAppUsabilityTuple * const vfar usabilityTable[] = {
    DesignModeList,
    GraphicsLayerList,
    ...
};
```

```c
static const GenAppUsabilityTuple vfar GraphicsLayerList[] = {
    ...
};
```

Ein `const` muss entfernt werden:

```c
static const GenAppUsabilityTuple * vfar usabilityTable[] = {
    ...
};
```

```c
static GenAppUsabilityTuple vfar GraphicsLayerList[] = {
    ...
};
```

## Assertion in `GeoWrite`

```text
Assertion Failed:
ssd->nodata ||
ssd->roff == sd->foff + ((int)(sd->size+15) & (int)~15) +
(nrel + ssd->nrel) * fileOps->rtrelsize,
function GeoWrite,
file D:\G6\PCGEOS\Tools\glue\geo.c,
line 1881.

ABNORMAL TERMINATION
```

**Ursache:** Es gibt eine leere Datenressource.

**Lösung:** Der leeren Ressource einen Dummy-Chunk hinzufügen.

## Erforderliche Libraries nicht gefunden

```text
Error sprite.gp 60:
Cant find required library geos in any of the platform files

Error sprite.gp 60:
Cant find required library ansic in any of the platform files
```

**Ursache:** Eine Library wurde als `exempt` angegeben.

**Lösung:** In diesem Fall muss ein `platform`-Statement verwendet werden.

## Fehlende Konstante in einem EC-Makro

```text
Document/database.goc(326): Error! E1149:
Expecting constant but found ppnumber
```

**Ursache:** In einem EC-Makro fehlt eine schließende Klammer `)`.

**Lösung:** Die fehlende Klammer ergänzen.
markdown