# Microsoft Developer Studio Generated NMAKE File, Based on compat.dsp
!IF "$(CFG)" == ""
CFG=compat - Win32 Debug
!MESSAGE No configuration specified. Defaulting to compat - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "compat - Win32 Release" && "$(CFG)" != "compat - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "compat.mak" CFG="compat - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "compat - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "compat - Win32 Debug" (based on "Win32 (x86) Static Library")
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

!IF  "$(CFG)" == "compat - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(ROOT_DIR)\Tools\vc++\lib\Release\compat.lib"


CLEAN :
	-@erase "$(INTDIR)\bcmp.obj"
	-@erase "$(INTDIR)\bcopy.obj"
	-@erase "$(INTDIR)\bzero.obj"
	-@erase "$(INTDIR)\compat.obj"
	-@erase "$(INTDIR)\dirent.obj"
	-@erase "$(INTDIR)\ffs.obj"
	-@erase "$(INTDIR)\getopt.obj"
	-@erase "$(INTDIR)\mkstemp.obj"
	-@erase "$(INTDIR)\pagesize.obj"
	-@erase "$(INTDIR)\queue.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\Release\compat.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /ML /W3 /GX /O2 /I "..\include" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /Fp"$(INTDIR)\compat.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\compat.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\Release\compat.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\bcmp.obj" \
	"$(INTDIR)\bcopy.obj" \
	"$(INTDIR)\bzero.obj" \
	"$(INTDIR)\compat.obj" \
	"$(INTDIR)\dirent.obj" \
	"$(INTDIR)\ffs.obj" \
	"$(INTDIR)\getopt.obj" \
	"$(INTDIR)\mkstemp.obj" \
	"$(INTDIR)\pagesize.obj" \
	"$(INTDIR)\queue.obj"

"$(ROOT_DIR)\Tools\vc++\lib\Release\compat.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "compat - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(ROOT_DIR)\Tools\vc++\lib\compat.lib"


CLEAN :
	-@erase "$(INTDIR)\bcmp.obj"
	-@erase "$(INTDIR)\bcopy.obj"
	-@erase "$(INTDIR)\bzero.obj"
	-@erase "$(INTDIR)\compat.obj"
	-@erase "$(INTDIR)\dirent.obj"
	-@erase "$(INTDIR)\ffs.obj"
	-@erase "$(INTDIR)\getopt.obj"
	-@erase "$(INTDIR)\mkstemp.obj"
	-@erase "$(INTDIR)\pagesize.obj"
	-@erase "$(INTDIR)\queue.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\compat.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /W3 /GX /Z7 /Od /I "..\include" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /Fp"$(INTDIR)\compat.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\compat.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\compat.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\bcmp.obj" \
	"$(INTDIR)\bcopy.obj" \
	"$(INTDIR)\bzero.obj" \
	"$(INTDIR)\compat.obj" \
	"$(INTDIR)\dirent.obj" \
	"$(INTDIR)\ffs.obj" \
	"$(INTDIR)\getopt.obj" \
	"$(INTDIR)\mkstemp.obj" \
	"$(INTDIR)\pagesize.obj" \
	"$(INTDIR)\queue.obj"

"$(ROOT_DIR)\Tools\vc++\lib\compat.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
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
!IF EXISTS("compat.dep")
!INCLUDE "compat.dep"
!ELSE 
!MESSAGE Warning: cannot find "compat.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "compat - Win32 Release" || "$(CFG)" == "compat - Win32 Debug"
SOURCE=.\bcmp.c

"$(INTDIR)\bcmp.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\bcopy.c

"$(INTDIR)\bcopy.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\bzero.c

"$(INTDIR)\bzero.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\compat.c

"$(INTDIR)\compat.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\dirent.c

"$(INTDIR)\dirent.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\ffs.c

"$(INTDIR)\ffs.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\getopt.c

"$(INTDIR)\getopt.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\mkstemp.c

"$(INTDIR)\mkstemp.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\pagesize.c

"$(INTDIR)\pagesize.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\queue.c

"$(INTDIR)\queue.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

