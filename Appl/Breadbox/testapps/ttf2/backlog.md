## TODO
- ft_conf.h aus /FreeType/arch/geos nutzen und unter /FreeType löschen
- ~~Speicherbedarf begrenzen (ttraster.c RASTER_RENDER_POOL)~~

## Meilensteine
- ~~Gerüst für Testprogramm erstellen~~
- ~~Gerüst für Testprogramm übersetzbar und lauffähig~~
- ~~TT-Engine Objekt anlegen, übersetzbar und lauffähig~~
- ~~Aufruf TT_Init_FreeType, übersetzbar und lauffähig~~
- ~~Dateihandling auf FileHandle umstellen, übersetzbar und lauffähig~~
- ~~Font öffnen mit TT_Open_Face, übersetzbar und lauffähig~~
- ~~Font Properties abfragen mit TT_Get_Face_Properties, übersetzbar und lauffähig~~
- ~~Instanz eines Face Objekts erzeugen, übersetzbar und lauffähig~~
- ~~Pointsize mit TT_Set_Instance_CharSize setzen, übersetbar und lauffähig~~
- ~~Metriken eines Glyphs lesen und anzeigen, übersetzbar und lauffähig~~
- ~~Glyph als Bitmap erzeugen, übersetzbar und lauffähig~~
- ~~Bitmap im Testprogramm anzeigen, übersetzbar und lauffähig~~
- ~~Zeichensatz im Testprogramm anzeigen, übersetzbar und lauffähig~~
- Memorymanagement auf Geos Spezifika (hugemem.c könnte genügen) umstellen, übersetzbar und lauffähig
- ~~Extension für Kerning aktivieren~~
- angepasstes FreeType in Treibersourcen verschieben
- Funktionen für DR_FONT_GEN_IN_REGION, DR_FONT_GEN_PATH
- FreeType in Treiber integrieren
- Registrierung eines Fonts anpassen (FontID, TTC???) 
- Darstellung kleiner PUnktgrößen weiter verbessern (bspw. high precision & scond pass)

## Fehler
- ~~freigeben von resiervierten Resoucen führt zum einfrieren~~
- ~~Teile eines Zeichens die unter der Basislinie liegen werden nicht angezeigt~~

## Bemerkungen
- die Darstellung keiner Punktgröße ist jetzt wesentlich besser aber stark vom Font abhänging; das ist bei der Font-Selektion zu beachten