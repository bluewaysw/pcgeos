# Microsoft Developer Studio Generated NMAKE File, Based on ntcurses.dsp
!IF "$(CFG)" == ""
CFG=ntcurses - Win32 Debug
!MESSAGE No configuration specified. Defaulting to ntcurses - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "ntcurses - Win32 Release" && "$(CFG)" != "ntcurses - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "ntcurses.mak" CFG="ntcurses - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "ntcurses - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "ntcurses - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

CPP=cl.exe
RSC=rc.exe

C_INCLUDES=-I$(ROOT_DIR)\Tools\Include -I$(ROOT_DIR)\Tools\Utils -I$(ROOT_DIR)\Tools\PMAKE\Src\Lib\Include -I$(ROOT_DIR)\Tools\Swat\Tcl -I$(ROOT_DIR)\Tools\Swat\NTCurses
LIB_INCLUDES=-LIBPATH:$(ROOT_DIR)\Tools\vc++\lib

!IF  "$(CFG)" == "ntcurses - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(ROOT_DIR)\Tools\vc++\lib\Release\ntcurses.lib"


CLEAN :
	-@erase "$(INTDIR)\attrib.obj"
	-@erase "$(INTDIR)\beep.obj"
	-@erase "$(INTDIR)\charadd.obj"
	-@erase "$(INTDIR)\chardel.obj"
	-@erase "$(INTDIR)\charget.obj"
	-@erase "$(INTDIR)\charins.obj"
	-@erase "$(INTDIR)\charpick.obj"
	-@erase "$(INTDIR)\clrtobot.obj"
	-@erase "$(INTDIR)\clrtoeol.obj"
	-@erase "$(INTDIR)\endwin.obj"
	-@erase "$(INTDIR)\initscr.obj"
	-@erase "$(INTDIR)\linedel.obj"
	-@erase "$(INTDIR)\lineins.obj"
	-@erase "$(INTDIR)\longname.obj"
	-@erase "$(INTDIR)\move.obj"
	-@erase "$(INTDIR)\mvcursor.obj"
	-@erase "$(INTDIR)\newwin.obj"
	-@erase "$(INTDIR)\ntio.obj"
	-@erase "$(INTDIR)\options.obj"
	-@erase "$(INTDIR)\overlay.obj"
	-@erase "$(INTDIR)\prntscan.obj"
	-@erase "$(INTDIR)\refresh.obj"
	-@erase "$(INTDIR)\setmode.obj"
	-@erase "$(INTDIR)\setterm.obj"
	-@erase "$(INTDIR)\stradd.obj"
	-@erase "$(INTDIR)\strget.obj"
	-@erase "$(INTDIR)\tabsize.obj"
	-@erase "$(INTDIR)\termmisc.obj"
	-@erase "$(INTDIR)\unctrl.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\winclear.obj"
	-@erase "$(INTDIR)\windel.obj"
	-@erase "$(INTDIR)\winerase.obj"
	-@erase "$(INTDIR)\winmove.obj"
	-@erase "$(INTDIR)\winscrol.obj"
	-@erase "$(INTDIR)\wintouch.obj"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\Release\ntcurses.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\ntcurses.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\ntcurses.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\Release\ntcurses.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\attrib.obj" \
	"$(INTDIR)\beep.obj" \
	"$(INTDIR)\charadd.obj" \
	"$(INTDIR)\chardel.obj" \
	"$(INTDIR)\charget.obj" \
	"$(INTDIR)\charins.obj" \
	"$(INTDIR)\charpick.obj" \
	"$(INTDIR)\clrtobot.obj" \
	"$(INTDIR)\clrtoeol.obj" \
	"$(INTDIR)\endwin.obj" \
	"$(INTDIR)\initscr.obj" \
	"$(INTDIR)\linedel.obj" \
	"$(INTDIR)\lineins.obj" \
	"$(INTDIR)\longname.obj" \
	"$(INTDIR)\move.obj" \
	"$(INTDIR)\mvcursor.obj" \
	"$(INTDIR)\newwin.obj" \
	"$(INTDIR)\ntio.obj" \
	"$(INTDIR)\options.obj" \
	"$(INTDIR)\overlay.obj" \
	"$(INTDIR)\prntscan.obj" \
	"$(INTDIR)\refresh.obj" \
	"$(INTDIR)\setmode.obj" \
	"$(INTDIR)\setterm.obj" \
	"$(INTDIR)\stradd.obj" \
	"$(INTDIR)\strget.obj" \
	"$(INTDIR)\tabsize.obj" \
	"$(INTDIR)\termmisc.obj" \
	"$(INTDIR)\unctrl.obj" \
	"$(INTDIR)\winclear.obj" \
	"$(INTDIR)\windel.obj" \
	"$(INTDIR)\winerase.obj" \
	"$(INTDIR)\winmove.obj" \
	"$(INTDIR)\winscrol.obj" \
	"$(INTDIR)\wintouch.obj"

"$(ROOT_DIR)\Tools\vc++\lib\Release\ntcurses.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "ntcurses - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(ROOT_DIR)\Tools\vc++\lib\ntcurses.lib"


CLEAN :
	-@erase "$(INTDIR)\attrib.obj"
	-@erase "$(INTDIR)\beep.obj"
	-@erase "$(INTDIR)\charadd.obj"
	-@erase "$(INTDIR)\chardel.obj"
	-@erase "$(INTDIR)\charget.obj"
	-@erase "$(INTDIR)\charins.obj"
	-@erase "$(INTDIR)\charpick.obj"
	-@erase "$(INTDIR)\clrtobot.obj"
	-@erase "$(INTDIR)\clrtoeol.obj"
	-@erase "$(INTDIR)\endwin.obj"
	-@erase "$(INTDIR)\initscr.obj"
	-@erase "$(INTDIR)\linedel.obj"
	-@erase "$(INTDIR)\lineins.obj"
	-@erase "$(INTDIR)\longname.obj"
	-@erase "$(INTDIR)\move.obj"
	-@erase "$(INTDIR)\mvcursor.obj"
	-@erase "$(INTDIR)\newwin.obj"
	-@erase "$(INTDIR)\ntio.obj"
	-@erase "$(INTDIR)\options.obj"
	-@erase "$(INTDIR)\overlay.obj"
	-@erase "$(INTDIR)\prntscan.obj"
	-@erase "$(INTDIR)\refresh.obj"
	-@erase "$(INTDIR)\setmode.obj"
	-@erase "$(INTDIR)\setterm.obj"
	-@erase "$(INTDIR)\stradd.obj"
	-@erase "$(INTDIR)\strget.obj"
	-@erase "$(INTDIR)\tabsize.obj"
	-@erase "$(INTDIR)\termmisc.obj"
	-@erase "$(INTDIR)\unctrl.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(INTDIR)\winclear.obj"
	-@erase "$(INTDIR)\windel.obj"
	-@erase "$(INTDIR)\winerase.obj"
	-@erase "$(INTDIR)\winmove.obj"
	-@erase "$(INTDIR)\winscrol.obj"
	-@erase "$(INTDIR)\wintouch.obj"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\ntcurses.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\ntcurses.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\ntcurses.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\ntcurses.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\attrib.obj" \
	"$(INTDIR)\beep.obj" \
	"$(INTDIR)\charadd.obj" \
	"$(INTDIR)\chardel.obj" \
	"$(INTDIR)\charget.obj" \
	"$(INTDIR)\charins.obj" \
	"$(INTDIR)\charpick.obj" \
	"$(INTDIR)\clrtobot.obj" \
	"$(INTDIR)\clrtoeol.obj" \
	"$(INTDIR)\endwin.obj" \
	"$(INTDIR)\initscr.obj" \
	"$(INTDIR)\linedel.obj" \
	"$(INTDIR)\lineins.obj" \
	"$(INTDIR)\longname.obj" \
	"$(INTDIR)\move.obj" \
	"$(INTDIR)\mvcursor.obj" \
	"$(INTDIR)\newwin.obj" \
	"$(INTDIR)\ntio.obj" \
	"$(INTDIR)\options.obj" \
	"$(INTDIR)\overlay.obj" \
	"$(INTDIR)\prntscan.obj" \
	"$(INTDIR)\refresh.obj" \
	"$(INTDIR)\setmode.obj" \
	"$(INTDIR)\setterm.obj" \
	"$(INTDIR)\stradd.obj" \
	"$(INTDIR)\strget.obj" \
	"$(INTDIR)\tabsize.obj" \
	"$(INTDIR)\termmisc.obj" \
	"$(INTDIR)\unctrl.obj" \
	"$(INTDIR)\winclear.obj" \
	"$(INTDIR)\windel.obj" \
	"$(INTDIR)\winerase.obj" \
	"$(INTDIR)\winmove.obj" \
	"$(INTDIR)\winscrol.obj" \
	"$(INTDIR)\wintouch.obj"

"$(ROOT_DIR)\Tools\vc++\lib\ntcurses.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ENDIF 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<


!IF "$(NO_EXTERNAL_DEPS)" != "1"
!IF EXISTS("ntcurses.dep")
!INCLUDE "ntcurses.dep"
!ELSE 
!MESSAGE Warning: cannot find "ntcurses.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "ntcurses - Win32 Release" || "$(CFG)" == "ntcurses - Win32 Debug"
SOURCE=.\attrib.c

"$(INTDIR)\attrib.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\beep.c

"$(INTDIR)\beep.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\charadd.c

"$(INTDIR)\charadd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\chardel.c

"$(INTDIR)\chardel.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\charget.c

"$(INTDIR)\charget.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\charins.c

"$(INTDIR)\charins.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\charpick.c

"$(INTDIR)\charpick.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\clrtobot.c

"$(INTDIR)\clrtobot.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\clrtoeol.c

"$(INTDIR)\clrtoeol.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\endwin.c

"$(INTDIR)\endwin.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\initscr.c

"$(INTDIR)\initscr.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\linedel.c

"$(INTDIR)\linedel.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lineins.c

"$(INTDIR)\lineins.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\longname.c

"$(INTDIR)\longname.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\move.c

"$(INTDIR)\move.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\mvcursor.c

"$(INTDIR)\mvcursor.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\newwin.c

"$(INTDIR)\newwin.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ntio.c

"$(INTDIR)\ntio.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\options.c

"$(INTDIR)\options.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\overlay.c

"$(INTDIR)\overlay.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\prntscan.c

"$(INTDIR)\prntscan.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\refresh.c

"$(INTDIR)\refresh.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\setmode.c

"$(INTDIR)\setmode.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\setterm.c

"$(INTDIR)\setterm.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stradd.c

"$(INTDIR)\stradd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\strget.c

"$(INTDIR)\strget.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tabsize.c

"$(INTDIR)\tabsize.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\termmisc.c

"$(INTDIR)\termmisc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\unctrl.c

"$(INTDIR)\unctrl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\winclear.c

"$(INTDIR)\winclear.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\windel.c

"$(INTDIR)\windel.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\winerase.c

"$(INTDIR)\winerase.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\winmove.c

"$(INTDIR)\winmove.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\winscrol.c

"$(INTDIR)\winscrol.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\wintouch.c

"$(INTDIR)\wintouch.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

