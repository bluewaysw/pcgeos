## Integration des FreeType Frameworks in den FreeGEOS TrueType Font-Treiber

Der Treiber wird in 3 Schichten realisiert:
- die Treiberschicht  
  + ist in Assembler geschrieben
  + implementiert die Strategiefunktionen des Treibers
  + delegiert an die Funktionen der Adapterschicht
  + der Code liegt unter /Main
- die Adapterschicht
  + ist in c geschrieben
  + implementiert eine Funktion je Strategiefunktion
  + eigene Logik und delegieren an die FreeType Engine
  + der Code liegt unter /Adapter
- die FreeType Schicht
  + die angepasste Implementierung der FreeType Engine
  + der Code liegt unter /FreeType

### Speicherverwaltung
- auf MemHandle/ChunkHandle umstellen
  - TT_Engine
  - TT_Stream
  - TT_Face
  - TT_Instance
  - TT_Glyph
  - TT_CharMap
- Hilfsfunktionen TT_Alloc, TT_ReAlloc und TT_Free auf MemHandles/ChunkHandles umstellen
- Speicherverwaltungsmakros auf MemHandles/ChunkHandles umstellen
- Nutzer der Speicherverwaltungsmakros auf MemHandles/ChunkHandles umstellen

**Wie soll die Speicherverwaltung aussehen?**

~~**Variante a)**~~
- ~~alle Pointer werden zu MemHandles~~
- ~~vor/nach dem Zugriff muss gelock/geunlockt werden~~

**Variante b)**
- die Pointer werden zu ChunkHandles
- unklar ob ein LMemBlock genügt oder eine Aufteillung notwendig/sinnvoll ist  
-> währen der gesamten Lebenszeit des Treibers ist nur TT_Engine im Speicher notwendig  
-> die anderen FreeType Objekte (TT_Face, TT_Glyph ...) können durch die Adapterfunktionen angelegt und abgeräumt werden (das ist ev. eine sinnvolle Trennung)

***Entscheidung:***
- es wird 2 LMem Blöcke geben (Variante b):
  - ein Block für die Engine (benötigt nach Analyse ca. 10kb)
    - bleibt die ganze Laufzeit des Treibers erhalten
    - enthält genau 8 Chunks
    - wird durch die Adapterfunktion aufgebaut/abgebaut
  - ein zweiter Block ist für die TrueTypeVars (Face, Instance, Glyph usw.)
    - kann, je nach Font, bis zu 54kb anwachsen 
    - enthält bis zu 100 Chunks
    - wird nur für das Rendern eines Glyphs aufgebaut und danach abgebaut
    - wird durch die Adapterfunktionen aufgebaut/abgebaut

~~**Klären:**~~
  - ~~wieviel Speicher und wieviele Blocks werden beim Rendervorgang belegt?~~  
  - ~~gibt es bei der Speicherbelegung große Unterschieden bei versch. Fonts?~~

### DR_INIT
~~- Adapterfunktion für DR_INIT schreiben~~
~~- Aufruf in truetypeInit.asm~~
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_EXIT
~~- Adapter für DR_EXIT schreiben~~
~~- Aufruf in truetypeInit.asm~~
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_FONT_GEN_CHAR
- Adapterfunktion für DR_FONT_GEN_CHAR schreiben
- Kerning implementieren
- Aufruf in truetypeChars.asm
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_FONT_GEN_WIDTHS
- Adapterfunktion für DR_FONT_GEN_WIDTHS schreiben
- Aufruf in truetypeWidts.asm
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_FONT_CHAR_METRICS
- Adapterfunktion für DR_FONT_CHAR_METRICS schreiben
- Aufruf in truetypeMetrics.asm
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_FONT_INIT_FONTS (geringe Priorität)
Die bisherigen Implementierung in Assembler kann auf die FreeType Engine umgestellt werden, somit vermeiden wir Redundanzen. Die akt. Implementierung scheint nicht korrekt zu funktionieren, das wird gleich mit behoben.
- Adapterfunktion für DR_FONT_INIT_FONTS schreiben
- Aufruf in truetypeInit.asm
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_FONT_GEN_PATH
- Adapterfunktion für DR_FONT_GEN_PATH schreiben
- Aufruf in truetypePath.asm
- hier ist die Behandlung der Transformationsmatrizen noch unklar
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### DR_FONT_GEN_IN_REGION
- Adapterfunktion für DR_FONT_GEN_REGION schreiben
- Aufruf in truetypePath.asm
- hier ist die Behandlung der Transformationsmatrizen noch unklar
- prüfen ob die Adapterfunktion sauber durchlaufen wird

### sonstiges
- laden eines Fonts auf FileHandle umstellen
- diverse Segmente sind noch sehr groß (ttraster und ttinterp) -> prüfen wie diese verkleinert werden können
- diverse Strukturen prüfen ob diese noch verkleinert werden können

### Aufräumarbeiten
- Abhängigkeit von Ansic auflösen (**sehr wichtig da jetzt im Sourcetree Codefragmente aus ansic liegen**)
- nicht genutzte Funktionen ausklammern
- Initalisierung des Graustufenarrays in TT_Init_FreeType entfernen
- das Graustufenarray kann aus TT_Engine entfernt werden
- Warnungen entfernen
- Makros vereinen:
  - HANDLE_Engine und GHANDLE_Engine
  - UNHANDLE_Engine und -/-
- Strukturen vereinen:
  - GTT_Engine und TT_Engine
  - GTT_Stream und TT_Stream
  - GTT_Face und TT_Face
  - GTT_Instance und TT_Instance
  - GTT_Glyph und TT_Glyph
  - GTT_CharMap und TT_CharMap

### Funktionen die ausgeklammert werden können
- TT_Open_Collection()
- TT_Set_Face_Pointer()
- TT_Get_Face_Pointer()
- TT_Set_Instance_Pointer()
- TT_Get_Instance_Pointer()
