# Microsoft Developer Studio Generated NMAKE File, Based on swat.dsp
!IF "$(CFG)" == ""
CFG=swat - Win32 Debug
!MESSAGE No configuration specified. Defaulting to swat - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "swat - Win32 Release" && "$(CFG)" != "swat - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "swat.mak" CFG="swat - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "swat - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "swat - Win32 Debug" (based on "Win32 (x86) Console Application")
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

#MSDEV_ROOT=d:\Progra~1\Visual~1\vc98

#STANDARD_INCLUDE_FLAGS=-I$(MSDEV_ROOT)\include -I$(MSDEV_ROOT)\MFC\Include -I$(MSDEV_ROOT)\ATL\Include

C_INCLUDES=-I$(ROOT_DIR)\Tools\Include -I$(ROOT_DIR)\Tools\Utils -I$(ROOT_DIR)\Tools\vc++\include $(STANDARD_INCLUDE_FLAGS) -I$(ROOT_DIR)\Tools\PMAKE\Src\Lib\Include -I$(ROOT_DIR)\Tools\Swat\Tcl -I$(ROOT_DIR)\Tools\Swat\NTCurses -I$(ROOT_DIR)\Tools\PMAKE\Src\Lib\Lst -I. 
LIB_INCLUDES=-LIBPATH:$(ROOT_DIR)\Tools\vc++\lib

!IF  "$(CFG)" == "swat - Win32 Release"

LIB_INCLUDES=-LIBPATH:$(ROOT_DIR)\Tools\vc++\lib

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

ALL : "$(OUTDIR)\swat.exe"


CLEAN :
	-@erase "$(INTDIR)\break.obj"
	-@erase "$(INTDIR)\buf.obj"
	-@erase "$(INTDIR)\cache.obj"
	-@erase "$(INTDIR)\cmd.obj"
	-@erase "$(INTDIR)\cmdAM.obj"
	-@erase "$(INTDIR)\cmdNZ.obj"
	-@erase "$(INTDIR)\curses.obj"
	-@erase "$(INTDIR)\event.obj"
	-@erase "$(INTDIR)\expr.obj"
	-@erase "$(INTDIR)\file.obj"
	-@erase "$(INTDIR)\gc.obj"
	-@erase "$(INTDIR)\handle.obj"
	-@erase "$(INTDIR)\help.obj"
	-@erase "$(INTDIR)\i86Opc.obj"
	-@erase "$(INTDIR)\ibm.obj"
	-@erase "$(INTDIR)\ibm86.obj"
	-@erase "$(INTDIR)\ibmCache.obj"
	-@erase "$(INTDIR)\ibmCmd.obj"
	-@erase "$(INTDIR)\ibmXms.obj"
	-@erase "$(INTDIR)\mouse.obj"
	-@erase "$(INTDIR)\netware.obj"
	-@erase "$(INTDIR)\npipe.obj"
	-@erase "$(INTDIR)\ntserial.obj"
	-@erase "$(INTDIR)\patient.obj"
	-@erase "$(INTDIR)\rpc.obj"
	-@erase "$(INTDIR)\shell.obj"
	-@erase "$(INTDIR)\src.obj"
	-@erase "$(INTDIR)\swat.obj"
	-@erase "$(INTDIR)\sym.obj"
	-@erase "$(INTDIR)\table.obj"
	-@erase "$(INTDIR)\tclDebug.obj"
	-@erase "$(INTDIR)\type.obj"
	-@erase "$(INTDIR)\ui.obj"
	-@erase "$(INTDIR)\value.obj"
	-@erase "$(INTDIR)\var.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vector.obj"
	-@erase "$(INTDIR)\version.obj"
	-@erase "$(OUTDIR)\swat.exe"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /Fp"$(INTDIR)\swat.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\swat.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib /nologo /subsystem:console /incremental:no /pdb:"$(OUTDIR)\swat.pdb" /machine:I386 /out:"$(OUTDIR)\swat.exe" $(LIB_INCLUDES)
LINK32_OBJS= \
	"$(INTDIR)\break.obj" \
	"$(INTDIR)\buf.obj" \
	"$(INTDIR)\cache.obj" \
	"$(INTDIR)\cmd.obj" \
	"$(INTDIR)\cmdAM.obj" \
	"$(INTDIR)\cmdNZ.obj" \
	"$(INTDIR)\curses.obj" \
	"$(INTDIR)\event.obj" \
	"$(INTDIR)\expr.obj" \
	"$(INTDIR)\file.obj" \
	"$(INTDIR)\gc.obj" \
	"$(INTDIR)\handle.obj" \
	"$(INTDIR)\help.obj" \
	"$(INTDIR)\i86Opc.obj" \
	"$(INTDIR)\ibm.obj" \
	"$(INTDIR)\ibm86.obj" \
	"$(INTDIR)\ibmCache.obj" \
	"$(INTDIR)\ibmCmd.obj" \
	"$(INTDIR)\ibmXms.obj" \
	"$(INTDIR)\mouse.obj" \
	"$(INTDIR)\netware.obj" \
	"$(INTDIR)\npipe.obj" \
	"$(INTDIR)\ntserial.obj" \
	"$(INTDIR)\patient.obj" \
	"$(INTDIR)\rpc.obj" \
	"$(INTDIR)\shell.obj" \
	"$(INTDIR)\src.obj" \
	"$(INTDIR)\swat.obj" \
	"$(INTDIR)\sym.obj" \
	"$(INTDIR)\table.obj" \
	"$(INTDIR)\tclDebug.obj" \
	"$(INTDIR)\type.obj" \
	"$(INTDIR)\ui.obj" \
	"$(INTDIR)\value.obj" \
	"$(INTDIR)\var.obj" \
	"$(INTDIR)\vector.obj" \
	"$(INTDIR)\version.obj"

"$(OUTDIR)\swat.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "swat - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

ALL : "$(OUTDIR)\swat.exe"


CLEAN :
	-@erase "$(INTDIR)\break.obj"
	-@erase "$(INTDIR)\buf.obj"
	-@erase "$(INTDIR)\cache.obj"
	-@erase "$(INTDIR)\cmd.obj"
	-@erase "$(INTDIR)\cmdAM.obj"
	-@erase "$(INTDIR)\cmdNZ.obj"
	-@erase "$(INTDIR)\curses.obj"
	-@erase "$(INTDIR)\event.obj"
	-@erase "$(INTDIR)\expr.obj"
	-@erase "$(INTDIR)\file.obj"
	-@erase "$(INTDIR)\gc.obj"
	-@erase "$(INTDIR)\handle.obj"
	-@erase "$(INTDIR)\help.obj"
	-@erase "$(INTDIR)\i86Opc.obj"
	-@erase "$(INTDIR)\ibm.obj"
	-@erase "$(INTDIR)\ibm86.obj"
	-@erase "$(INTDIR)\ibmCache.obj"
	-@erase "$(INTDIR)\ibmCmd.obj"
	-@erase "$(INTDIR)\ibmXms.obj"
	-@erase "$(INTDIR)\mouse.obj"
	-@erase "$(INTDIR)\netware.obj"
	-@erase "$(INTDIR)\npipe.obj"
	-@erase "$(INTDIR)\ntserial.obj"
	-@erase "$(INTDIR)\patient.obj"
	-@erase "$(INTDIR)\rpc.obj"
	-@erase "$(INTDIR)\shell.obj"
	-@erase "$(INTDIR)\src.obj"
	-@erase "$(INTDIR)\swat.obj"
	-@erase "$(INTDIR)\sym.obj"
	-@erase "$(INTDIR)\table.obj"
	-@erase "$(INTDIR)\tclDebug.obj"
	-@erase "$(INTDIR)\type.obj"
	-@erase "$(INTDIR)\ui.obj"
	-@erase "$(INTDIR)\value.obj"
	-@erase "$(INTDIR)\var.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(INTDIR)\vector.obj"
	-@erase "$(INTDIR)\version.obj"
	-@erase "$(OUTDIR)\swat.exe"
	-@erase "$(OUTDIR)\swat.ilk"
	-@erase "$(OUTDIR)\swat.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /w /W0 /Gm /GX /Zi /Od /I "." /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /Fp"$(INTDIR)\swat.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\swat.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib libc.lib /nologo /subsystem:console /incremental:yes /pdb:"$(OUTDIR)\swat.pdb" /debug /machine:I386 /nodefaultlib:"library" /nodefaultlib:"libcd" /out:"$(OUTDIR)\swat.exe" /pdbtype:sept $(LIB_INCLUDES)
LINK32_OBJS= \
	"$(INTDIR)\break.obj" \
	"$(INTDIR)\buf.obj" \
	"$(INTDIR)\cache.obj" \
	"$(INTDIR)\cmd.obj" \
	"$(INTDIR)\cmdAM.obj" \
	"$(INTDIR)\cmdNZ.obj" \
	"$(INTDIR)\curses.obj" \
	"$(INTDIR)\event.obj" \
	"$(INTDIR)\expr.obj" \
	"$(INTDIR)\file.obj" \
	"$(INTDIR)\gc.obj" \
	"$(INTDIR)\handle.obj" \
	"$(INTDIR)\help.obj" \
	"$(INTDIR)\i86Opc.obj" \
	"$(INTDIR)\ibm.obj" \
	"$(INTDIR)\ibm86.obj" \
	"$(INTDIR)\ibmCache.obj" \
	"$(INTDIR)\ibmCmd.obj" \
	"$(INTDIR)\ibmXms.obj" \
	"$(INTDIR)\mouse.obj" \
	"$(INTDIR)\netware.obj" \
	"$(INTDIR)\npipe.obj" \
	"$(INTDIR)\ntserial.obj" \
	"$(INTDIR)\patient.obj" \
	"$(INTDIR)\rpc.obj" \
	"$(INTDIR)\shell.obj" \
	"$(INTDIR)\src.obj" \
	"$(INTDIR)\swat.obj" \
	"$(INTDIR)\sym.obj" \
	"$(INTDIR)\table.obj" \
	"$(INTDIR)\tclDebug.obj" \
	"$(INTDIR)\type.obj" \
	"$(INTDIR)\ui.obj" \
	"$(INTDIR)\value.obj" \
	"$(INTDIR)\var.obj" \
	"$(INTDIR)\vector.obj" \
	"$(INTDIR)\version.obj"

"$(OUTDIR)\swat.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
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
!IF EXISTS("swat.dep")
!INCLUDE "swat.dep"
!ELSE 
!MESSAGE Warning: cannot find "swat.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "swat - Win32 Release" || "$(CFG)" == "swat - Win32 Debug"
SOURCE=.\break.c

"$(INTDIR)\break.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\buf.c

"$(INTDIR)\buf.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\cache.c

"$(INTDIR)\cache.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\cmd.c

"$(INTDIR)\cmd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\cmdAM.c

"$(INTDIR)\cmdAM.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\cmdNZ.c

"$(INTDIR)\cmdNZ.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\curses.c

"$(INTDIR)\curses.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\event.c

"$(INTDIR)\event.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\expr.c

"$(INTDIR)\expr.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\file.c

"$(INTDIR)\file.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\gc.c

"$(INTDIR)\gc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\handle.c

"$(INTDIR)\handle.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\help.c

"$(INTDIR)\help.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\i86Opc.c

"$(INTDIR)\i86Opc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ibm.c

"$(INTDIR)\ibm.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ibm86.c

"$(INTDIR)\ibm86.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ibmCache.c

"$(INTDIR)\ibmCache.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ibmCmd.c

"$(INTDIR)\ibmCmd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ibmXms.c

"$(INTDIR)\ibmXms.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\mouse.c

"$(INTDIR)\mouse.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\netware.c

"$(INTDIR)\netware.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\win32.md\npipe.c

"$(INTDIR)\npipe.obj" : $(SOURCE) "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


SOURCE=.\win32.md\ntserial.c

"$(INTDIR)\ntserial.obj" : $(SOURCE) "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


SOURCE=.\patient.c

"$(INTDIR)\patient.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\rpc.c

"$(INTDIR)\rpc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\shell.c

"$(INTDIR)\shell.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\src.c

"$(INTDIR)\src.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\swat.c

"$(INTDIR)\swat.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\sym.c

"$(INTDIR)\sym.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\table.c

"$(INTDIR)\table.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tclDebug.c

"$(INTDIR)\tclDebug.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\type.c

"$(INTDIR)\type.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ui.c

"$(INTDIR)\ui.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\value.c

"$(INTDIR)\value.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\var.c

"$(INTDIR)\var.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vector.c

"$(INTDIR)\vector.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\version.c

"$(INTDIR)\version.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

