PC/GEOS – Entwicklungsnotizen

Die folgenden Hinweise beziehen sich auf das Repository bluewaysw/pcgeos.

Compiler- und Build-Konfiguration
Falsches Compiler-Flag in Local.mk

Die folgende Einstellung in Local.mk verursacht schwer verständliche Fehlermeldungen:

XCCOMFLAGS += -dc
makefile

Beispiel:

..\pcgeos\CInclude\graphics.h Error! E1009: Expecting , but found 1
..\pcgeos\CInclude\graphics.h Error! E1127: type required in parameter list
plain text

Stattdessen muss das folgende Flag verwendet werden:

XCCOMFLAGS += -zc
makefile
Probleme mit const bei Verwendung von -zc

Hinweis: Dieses Problem sollte möglicherweise bereits von Falk behoben worden sein. Der aktuelle Status sollte überprüft werden.

In Verbindung mit dem Flag -zc können Konstrukte wie die folgenden nicht kompiliert werden:

static const GenAppUsabilityTuple * const vfar usabilityTable[] = {
    DesignModeList,
    GraphicsLayerList,
    ...
};
c
static const GenAppUsabilityTuple vfar GraphicsLayerList[] = {
    ...
};
c

Dabei kann folgende Fehlermeldung auftreten:

Error mAppl.eobj: non-data FIXUPP record may only contain THREAD definitions
plain text

Als Problemumgehung muss der betroffene const-Qualifizierer entfernt werden:

static const GenAppUsabilityTuple * vfar usabilityTable[] = {
    ...
};
c
static GenAppUsabilityTuple vfar GraphicsLayerList[] = {
    ...
};
c
Mindest-Include für Code-Dateien

Code-Dateien müssen mindestens die folgende Include-Anweisung enthalten:

@include <stdapp.goh>
c

Andernfalls können sie „wegoptimiert“ werden, was zu Problemen beim Kompilieren führen kann.

Copyright-Notiz des Linkers

Folgende Schreibweise sollte nicht verwendet werden:

LINKFLAGS += -N (c)\20by\20RABE-Soft\208/99-03/2016
makefile

Stattdessen sollte der Text als Zeichenkette in Anführungszeichen angegeben werden:

LINKFLAGS += -N "(c) by RABE-Soft 8/99-03/2016"
makefile
Plattformkompatibilität
Programme unter BBX

Wenn ein Programm aufgrund einer Inkompatibilität mit der Systemsoftware nicht unter BBX läuft, kann in der GP-Datei die folgende Plattform eingetragen werden:

platform geos21
plain text

Möglicherweise funktionieren auch andere geeignete Plattformangaben.

Include-Dateien und Pfade
Pfadtrennzeichen

In Include-Anweisungen müssen immer Schrägstriche verwendet werden:

@include <objects/gViewCC.goh>
c
Vollständige relative Pfade

Der vollständige relative Pfad muss angegeben werden. Befindet sich die einbindende Datei beispielsweise unter UI/Appui.goc, kann eine Datei im übergeordneten Verzeichnis so eingebunden werden:

@include "../sprite.goh"
c
Groß- und Kleinschreibung bei Header-Dateien

Bei eingebundenen Header-Dateien ist die Groß- und Kleinschreibung wichtig.

Beispielsweise können die folgenden Namen als unterschiedliche Dateien behandelt werden:

Info.goh
INFO.GOH
plain text
Datei- und Verzeichnisnamen
Schreibweise der GOC-Dateierweiterung

Bei GOC-Dateien muss die Dateierweiterung .goc kleingeschrieben werden.

Zulässig sind beispielsweise:

CODE.goc
code.goc
plain text

Nicht verwendet werden sollte:

CODE.GOC
plain text

Die Groß- und Kleinschreibung des eigentlichen Dateinamens ist weniger problematisch; die Erweiterung muss jedoch .goc lauten.

Umbenennen bei reinen Änderungen der Schreibweise

Wird beim Umbenennen einer Datei nur die Groß- und Kleinschreibung geändert, sollte dies mit TortoiseGit durchgeführt werden.

Beim Umbenennen über den Windows Explorer kann Git die Änderung zwar erkennen, aber TortoiseGit zeigt anschließend möglicherweise seine Overlays nicht mehr korrekt an. Beim Übertragen der Änderung zu GitHub können weitere Probleme auftreten.

Benennung von Verzeichnissen

Verzeichnisnamen sollten grundsätzlich Substantive sein, zum Beispiel:

Instf/Main
plain text

Eine Ausnahme bilden etablierte Bezeichnungen wie UI:

Instf/UI
plain text
Zeichenkodierung und Sonderzeichen
GEOS-Zeichen mit gesetztem Bit 7

GEOS-Zeichen mit gesetztem Bit 7 müssen in bestimmten Kontexten in Hexadezimaldarstellung angegeben werden.

Beispiel für Ä:

\x80
c

Die Ursache liegt in GOC, konkret in der Funktion Scan_ScanSJISChar():

Tools/goc/scan.c
plain text

Die Funktion interpretiert die meisten Zeichen mit gesetztem Bit 7 als japanische Zwei-Byte-Zeichen. Dadurch kann beispielsweise folgende Fehlermeldung entstehen:

Illegal SJIS character 0x806e
plain text

Deutsche Umlaute sind in diesem Konzept nicht vorgesehen. Sie müssen daher über eine geeignete Escape-Darstellung eingebunden werden.

Scan_ScanSJISChar() wird nur für visMoniker aufgerufen. In normalen Texten können laut der ursprünglichen Notiz außerdem folgende Darstellungen funktionieren:

\200
plain text

Dabei handelt es sich um eine oktale Darstellung. In der ursprünglichen Notiz wird außerdem € als mögliche Darstellung für Ä genannt. Dieses Verhalten sollte vor der Verwendung überprüft werden.

Eine ähnliche Fehlermeldung lautet:

Error dpconfig.goc 541:
SJIS characters beyond 0xEAA4 not supported (0xefbf)
plain text
Assembler und Manager-Dateien
Assembler-Anweisungen in Makros

Bei Makros mit eingebetteten Assembler-Anweisungen darf am Zeilenende kein Semikolon stehen. Andernfalls kann die Fehlermeldung missing } auftreten.

Richtig:

#define PUSHDS __asm push ds /* push ds */
#define POPDS  __asm pop ds  /* pop ds */
c
Manager-Dateien für Assembler-Untermodulverzeichnisse

Assembler-Untermodulverzeichnisse benötigen eine Manager-Datei. Deren Name richtet sich nach dem Namen des Moduls beziehungsweise Verzeichnisses:

<Modul- oder Verzeichnisname>Manager.asm
plain text

Diese Datei ist der Einstiegspunkt des Moduls und bindet die übrigen Assembler-Dateien ein.

Für das Verzeichnis AsmCalc wird daher folgende Datei benötigt:

asmcalcManager.asm
plain text

Im beschriebenen Stand des Repositorys heißt die Datei dagegen:

acManager.asm
plain text

Als Referenz kann die MSET-Bibliothek verwendet werden.

Die Groß- und Kleinschreibung des Namens asmcalcManager.asm ist wichtig.

Bibliotheken und LDF-Dateien
Zugriff auf globale Variablen einer Bibliothek

Bei Watcom muss für eine Bibliothek dgroup über DS erreichbar sein, damit auf globale Variablen der Bibliothek zugegriffen werden kann. Früher wurde dies mit der Option -WDE behandelt.

Sowohl extern als auch EXPORT, inzwischen RS_EXPORT, müssen in der Header-Datei und in der Implementierung berücksichtigt werden.

Die Exportdefinition lautet:

#define RS_EXPORT _export _pascal
c
Ablageorte für LDF-Dateien

Allgemeine LDF-Dateien gehören in folgendes Verzeichnis:

pcgeos/Installed/Include
plain text

LDF-Dateien eigener Bibliotheken aus dem LOCAL_ROOT-Verzeichnisbaum, die nicht Teil des Repositorys sind, gehören in:

LOCAL_ROOT/Include
plain text
Werkzeuge kompilieren und debuggen
Werkzeuge neu kompilieren

Beim Kompilieren von Werkzeugen, beispielsweise für Debugging-Zwecke, darf das Makefile nicht verändert werden.

Insbesondere sollten folgende Befehle nicht ausgeführt werden:

clean
mkmf
pmake depend
plain text

Stattdessen genügt im jeweiligen Werkzeugverzeichnis unter Installed/Tools/...:

pmake install
shell

Um sicherzustellen, dass Änderungen übernommen werden, sollten gegebenenfalls vorher alle *.obj-Dateien im entsprechenden Plattformverzeichnis gelöscht werden:

Installed/Tools/.../win32.md
plain text
Ausgabe auf der Fehlerkonsole

Ausgaben auf der Fehlerkonsole können beispielsweise folgendermaßen erzeugt werden:

fprintf(stderr, "grev: no command specified\n");
c
Speicherort von swat.rc

Die Datei swat.rc muss sich in dem Verzeichnis befinden, aus dem target aufgerufen wird.

Alternativ kann ein allgemeiner Speicherort verwendet werden, zum Beispiel:

C:\user\Rainer
plain text

Ein Verzeichnis wie das folgende funktioniert nach der ursprünglichen Notiz nicht:

D:\G6\pcgeos\Installed
plain text
Git und Zeilenenden
Git-Konfiguration anzeigen

Mit folgendem Befehl wird die Git-Konfiguration aufgelistet:

git config --list
shell

Für das Repository ist insbesondere die Einstellung core.autocrlf relevant.

Aktuellen Wert abfragen
git config --get core.autocrlf
shell
Einstellung für das aktuelle Repository setzen
git config core.autocrlf true
shell
Bedeutung von core.autocrlf

Bei der Einstellung:

core.autocrlf=true
plain text

werden Dateien im Repository mit LF-Zeilenenden gespeichert. In der lokalen Arbeitskopie unter Windows werden dagegen CRLF-Zeilenenden verwendet.

Bei der Einstellung:

core.autocrlf=false
plain text

findet keine entsprechende automatische Umwandlung der Zeilenenden statt.

Wegen Problemen mit JOKES.TXT wurde core.autocrlf in der ursprünglichen Arbeitsumgebung auf true gesetzt. Dabei bleibt zu prüfen, ob Werkzeuge oder Linker, die ausschließlich LF-Zeilenenden erwarten, dadurch beeinträchtigt werden.

Programmende, Herunterfahren und Neustart
Ressourcen vollständig freigeben

Bei Problemen während des Herunterfahrens oder Neustarts muss geprüft werden, ob alle Ressourcen ordnungsgemäß freigegeben wurden. Dazu gehören insbesondere:

dynamisch reservierter Speicher,
Semaphoren,
geöffnete Dateien,
Dateihandles und
sonstige Systemressourcen.

Nach der Freigabe sollten Pointer und Dateihandles auf null beziehungsweise einen geeigneten ungültigen Wert gesetzt werden.

Reihenfolge der Document Messages

Document Messages wie DETACH_UI oder WRITE_CACHED_DATA können teilweise noch aufgerufen werden, nachdem CLOSE_APPLICATION bereits abgeschlossen ist.

Deshalb müssen vor dem Zugriff folgende Werte geprüft werden:

Dateihandles,
Pointer auf reservierten Speicher und
andere bereits freigegebene Ressourcen.

Mit der folgenden Nachricht können verschiedene Vorgänge unterschieden werden:

MSG_GEN_DOCUMENT_GET_OPERATION
plain text

Als Beispiel für das Process-Document-Modell kann der SplashView-Code herangezogen werden.

Kommentare zur Gliederung

Die Build- und Compilerprobleme stehen am Anfang, weil sie bereits das Übersetzen des Repositorys verhindern und daher üblicherweise zuerst gelöst werden müssen.

Plattformangaben wurden von den eigentlichen Compiler-Flags getrennt, da sie nicht das Übersetzen, sondern die Kompatibilität der erzeugten Anwendung betreffen.

Include-Regeln, Groß- und Kleinschreibung sowie Dateinamen wurden in benachbarte Abschnitte eingeordnet. Diese Themen hängen zusammen, wurden aber getrennt, damit Pfadprobleme und Benennungsregeln leichter auffindbar sind.

Die Hinweise zur Zeichenkodierung bilden einen eigenen Abschnitt, weil die SJIS-Behandlung ein spezielles Verhalten des GOC-Scanners darstellt und nicht nur eine allgemeine Coding-Konvention ist.

Assembler-Makros und Manager-Dateien wurden zusammengefasst, da beide den Aufbau und die Übersetzung von Assembler-Code betreffen.

Bibliotheksexporte und LDF-Dateien stehen gemeinsam in einem Abschnitt, weil beide für die Bereitstellung und Einbindung von Bibliotheken relevant sind.

Hinweise zu pmake, Debug-Ausgaben und swat.rc wurden unter Werkzeugentwicklung und Debugging zusammengeführt.

Git-Einstellungen und Umbenennungen wurden nicht vollständig zusammengefasst: core.autocrlf betrifft Zeilenenden, während das Umbenennen nur bei Änderungen der Groß- und Kleinschreibung zu den Dateinamensregeln gehört.

Die Hinweise zum Herunterfahren und Neustart wurden ans Ende der technischen Themen gesetzt, da sie das Laufzeitverhalten und den Lebenszyklus einer bereits übersetzten Anwendung betreffen.

Unsichere oder möglicherweise veraltete Aussagen wurden nicht als gesicherte Fakten dargestellt. Dazu gehören insbesondere der mögliche Fix von Falk, die Verwendung von € für Ä und einzelne umgebungsspezifische Pfade.
