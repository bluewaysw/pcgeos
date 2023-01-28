## 1 TODOs
- ~~FontHeader füllen und im FontInfoBlock ablegen~~
- ~~FontBuf auf Basis des FontHeaders füllen (Gen_Widths)~~
- CharTableEntries füllen (Gen_Widths)
- KernPairs und KernValues füllen (Achtung: sie offene Probleme)
- Transformationsmatrix berechnen und im FontBlock halten (die FakeStyles sind in der Matrix 'enthalten')(Gen_Widths)
- in Gen_Char eine Bitmap erzeugen (notfalls eine Fake Bitmap damit endlich etwas zu sehen ist)

## 2 Refactorings

### 2.1 ttinit.c
- Hilfsfunktionen auslagern
- lokale Variablen reduzieren

### 2.2 ttwidths.c
- Ermittlung stylesToImplement in ASM-Teil verschieben (Kernel-Routine FontDrFindOutlineData)

### 2.3 FreeType
- FreeType Strukturen zusammenführen (Strukturen die eine 1:1 Kardinalität zu TT_Engine haben in TT_Engine integrieren)

### 2.4 Sonstiges
- bessere Lösung für das Mappen GeosChar -> UniCode finden

## Optimierungen
- prüfen: ob TT_Error in tterrid.h von long auf word reduziert werden kann
- prüfen: ob in ttraster.c traceG, gTarget entfernt werden kann
- prüfen: ob in ttraster.c in TRasterInstance für lastX, lastY, minX, minY, TraceOfs und TraceOfsLastLine ein word genügt
- in ttobj.h kann in T_Font_Input_ ->fontIndex entfernt werden (Überbleibsel der TTCollections die wir nicht brauchen)
- in ttraster.c (Set_Hight_Precision) kann gesteuert werden wie 'genau' ein Glyph gerendert wird; falls wir noch Performanceprobleme haben kann hier auch angesetzt werden (ggf. auch mehrstufig)
- prüfen: kann die AvgWidth aus der OS/2 übernommen werden kann

## offene Probleme
- klären: der Aufruf von TT_Init_Kerning lässt swat crashen

