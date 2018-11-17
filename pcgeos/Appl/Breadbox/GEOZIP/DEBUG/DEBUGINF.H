/**************************************************************************
 *
 *      File DebuInf.H
 *
 *      Extern-Deklaration aller Debug-Routinen
 *
 **************************************************************************/

// Ausgabe von Texten auf das Debug-Window

void DebugInfo (char *i ) ;
void DebugInfoOptr( optr text) ;
void DebugInfo1 (char *i, int arg);

// Ausgabe von Infos in der unteren Statuszeile

void DebugShowText(char *t );
void DebugShowValue1(int v);
void DebugShowValue2(int v);
void DebugShowValue3(int v);


// Ausgabe von Informationen Åber ein Message-Window



