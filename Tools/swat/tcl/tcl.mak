# Microsoft Developer Studio Generated NMAKE File, Based on tcl.dsp
!IF "$(CFG)" == ""
CFG=tcl - Win32 Debug
!MESSAGE No configuration specified. Defaulting to tcl - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "tcl - Win32 Release" && "$(CFG)" != "tcl - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "tcl.mak" CFG="tcl - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "tcl - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "tcl - Win32 Debug" (based on "Win32 (x86) Static Library")
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

!IF  "$(CFG)" == "tcl - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(ROOT_DIR)\Tools\vc++\lib\Release\tcl.lib"


CLEAN :
	-@erase "$(INTDIR)\tclBasic.obj"
	-@erase "$(INTDIR)\tclBC.obj"
	-@erase "$(INTDIR)\tclCmdAH.obj"
	-@erase "$(INTDIR)\tclCmdIZ.obj"
	-@erase "$(INTDIR)\tclExpr.obj"
	-@erase "$(INTDIR)\tclNt.obj"
	-@erase "$(INTDIR)\tclProc.obj"
	-@erase "$(INTDIR)\tclUtil.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\Release\tcl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\tcl.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\tcl.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\Release\tcl.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\tclBasic.obj" \
	"$(INTDIR)\tclBC.obj" \
	"$(INTDIR)\tclCmdAH.obj" \
	"$(INTDIR)\tclCmdIZ.obj" \
	"$(INTDIR)\tclExpr.obj" \
	"$(INTDIR)\tclNt.obj" \
	"$(INTDIR)\tclProc.obj" \
	"$(INTDIR)\tclUtil.obj"

"$(ROOT_DIR)\Tools\vc++\lib\Release\tcl.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "tcl - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(ROOT_DIR)\Tools\vc++\lib\tcl.lib"


CLEAN :
	-@erase "$(INTDIR)\tclBasic.obj"
	-@erase "$(INTDIR)\tclBC.obj"
	-@erase "$(INTDIR)\tclCmdAH.obj"
	-@erase "$(INTDIR)\tclCmdIZ.obj"
	-@erase "$(INTDIR)\tclExpr.obj"
	-@erase "$(INTDIR)\tclNt.obj"
	-@erase "$(INTDIR)\tclProc.obj"
	-@erase "$(INTDIR)\tclUtil.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\tcl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /w /W0 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\tcl.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\tcl.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\tcl.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\tclBasic.obj" \
	"$(INTDIR)\tclBC.obj" \
	"$(INTDIR)\tclCmdAH.obj" \
	"$(INTDIR)\tclCmdIZ.obj" \
	"$(INTDIR)\tclExpr.obj" \
	"$(INTDIR)\tclNt.obj" \
	"$(INTDIR)\tclProc.obj" \
	"$(INTDIR)\tclUtil.obj"

"$(ROOT_DIR)\Tools\vc++\lib\tcl.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
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
!IF EXISTS("tcl.dep")
!INCLUDE "tcl.dep"
!ELSE 
!MESSAGE Warning: cannot find "tcl.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "tcl - Win32 Release" || "$(CFG)" == "tcl - Win32 Debug"
SOURCE=.\tclBasic.c

"$(INTDIR)\tclBasic.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tclBC.c

"$(INTDIR)\tclBC.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tclCmdAH.c

"$(INTDIR)\tclCmdAH.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tclCmdIZ.c

"$(INTDIR)\tclCmdIZ.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tclExpr.c

"$(INTDIR)\tclExpr.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\win32.md\tclNt.c

"$(INTDIR)\tclNt.obj" : $(SOURCE) "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


SOURCE=.\tclProc.c

"$(INTDIR)\tclProc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\tclUtil.c

"$(INTDIR)\tclUtil.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

