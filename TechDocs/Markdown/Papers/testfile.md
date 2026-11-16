Thema Papers
An einer exponierten Stelle (im Repository Top-Ordner) gibt es eine Datei mit Coding-Tips. Auf diese Datei wird in der Readme.md am Ende verwiesen. Hinein gehören u.a. (alles Sachen, über die ich gestolpert bin):
- Codefilenamen: Groß/Kleinschreibung ist relevant, z.B. für includete Header, die Extensions (goc und goh) sind klein zu schreiben. 
- GEOS-Sonderzeichen > 0x7E sind in ihrer hexadezimalen Entsprechung (z.B. \x080) anzugeben. Folgt ein hex-tauglicher Buchstabe, ist dieser auch als \x-Code zu codieren.
- Assembler-Module benötigen eine <name_of_module/dir>Manager.asm, in der die benötigten Dateien included werden. Siehe library/SDK_C/MSet Beispiel.
- Die Tab-Schrittweite ist 8, Einrückungen erfolgen in 4er-Schritten

- MarkDonw files: Code duch Einrücken, nicht Fences
	4 Spaces für normalen text, 6 Spaces für liste obere Ebene, 8 Spces für 2. Ebene usw.
