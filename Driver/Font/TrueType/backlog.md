# TTF-Treiber für FreeGEOS

## 1 Fehlende Features
- Support für Kerning
- Handler für GEN_IN_REGION
- Handler für GEN_PATH
- Refactoring des Speichermanagments
- Bytecodeinterpreter aktivieren

## 2 Bekannte Probleme
- Zeichen mit einer Pointsize > 400 werden oben und/oder unten abgeschnitten
- das Resizing des Fontbuffers ist noch fehlerhaft
- die Fontmatrix wird noch nicht genutzt (Dokument-Zoom, Rotation und Sklaierung gehen deshalb nicht)

## 3 Performance
Der TrueType-Treiber ist noch sehr träge. Hier einige Ideen wie das verbessert werden kann:
- Fonts (zumindest die, die wir initial in der Distribution mitliefern) auf die 224 Zeichen des GEOS-Zeichensatzes reduzieren
- Caching wie beim Nimbus-Treiber implementieren. D.h. ein Face bleibt im Speicher. Wird beim nächsten Rendern der gleiche Font angefordert wird das Face aus dem Cache genutzt ansonsten wird es verworfen und neu geladen.
- Im FreeType-Code wird an vielen Stellen long-Arithmetik genutzt. Hier gibt es sicher viel Stellen an denen ein word genügt. Siehe auch unter Optimierungen.
- FreeType Strukturen zusammenführen (Strukturen die eine 1:1 Kardinalität zu TT_Engine haben in TT_Engine integrieren)
- Wenn das Refactoring des Speichermanagements erfolgt ist, prüfen ober der Render-Cache (derzeit 4096 Bytes) vergrößert werden kann.

## 4 Optimierungen
- prüfen: ob in ttraster.c in TRasterInstance für lastX, lastY, minX, minY, TraceOfs und TraceOfsLastLine ein word genügt
- in ttraster.c (Set_Hight_Precision) kann gesteuert werden wie 'genau' ein Glyph gerendert wird; falls wir noch Performanceprobleme haben kann hier auch angesetzt werden (ggf. auch mehrstufig)
