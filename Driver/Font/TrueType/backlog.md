## TODOs
- ~~FontHeader füllen und im FontInfoBlock ablegen~~
- FontBuf auf Basis des FontHeaders füllen (Gen_Widths)
- CharTableEntries füllen (Gen_Widths)
- KernPairs und KernValues füllen (Achtung: sie offene Probleme)
- Transformationsmatrix berechnen und im FontBlock halten (die FakeStyles sind in der Matrix 'enthalten')(Gen_Widths)
- in Gen_Char eine Bitmap erzeugen (notfalls eine Fake Bitmap damit entlich etwas zu sehen ist)

## Refactorings
- ttinit.c refactorn (Hilfsfunktionen auslagern, lokale Variablen reduzieren)
- FreeType Strukturen zusammenführen (Strukturen die eine 1:1 Kardinalität zu TT_Engine haben in TT_Engine integrieren)
- bessere Lösung für das Mappen GeosChar -> UniCode finden

## Optimierungen
- prüfen: ob TT_Error in tterrid.h von long auf word reduziert werden kann
- prüfen: ob in ttraster.c traceG, gTarget, traceLastLine entfernt werden kann
- in ttobj.h kann in T_Font_Input_ ->fontIndex entfernt werden (Überbleibsel der TTCollections die wir nicht brauchen)
- in ttraster.c (Set_Hight_Precision) kann gesteuert werden wie 'genau' ein Glyph gerendert wird; falls wir noch Performanceprobleme haben kann hier auch angesetzt werden (ggf. auch mehrstufig)

## offene Probleme
- klären: der Aufruf von TT_Init_Kerning lässt swat crachen

