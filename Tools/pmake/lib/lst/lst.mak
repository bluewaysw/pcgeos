# Microsoft Developer Studio Generated NMAKE File, Based on lst.dsp
!IF "$(CFG)" == ""
CFG=lst - Win32 Debug
!MESSAGE No configuration specified. Defaulting to lst - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "lst - Win32 Release" && "$(CFG)" != "lst - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "lst.mak" CFG="lst - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "lst - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "lst - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
\
CPP=cl.exe
RSC=rc.exe

C_INCLUDES=-I$(ROOT_DIR)\Tools\Include -I$(ROOT_DIR)\Tools\Utils -I$(ROOT_DIR)\Tools\PMAKE\Src\Lib\Include -I$(ROOT_DIR)\Tools\Swat\Tcl -I$(ROOT_DIR)\Tools\Swat\NTCurses
LIB_INCLUDES=-LIBPATH:$(ROOT_DIR)\Tools\vc++\lib

!IF  "$(CFG)" == "lst - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(ROOT_DIR)\Tools\vc++\lib\Release\lst.lib"


CLEAN :
	-erase "$(INTDIR)\lstAppnd.obj"
	-erase "$(INTDIR)\lstAtEnd.obj"
	-erase "$(INTDIR)\lstAtFnt.obj"
	-erase "$(INTDIR)\lstCat.obj"
	-erase "$(INTDIR)\lstClose.obj"
	-erase "$(INTDIR)\lstCur.obj"
	-erase "$(INTDIR)\lstDatum.obj"
	-erase "$(INTDIR)\lstDeQ.obj"
	-erase "$(INTDIR)\lstDest.obj"
	-erase "$(INTDIR)\lstDupl.obj"
	-erase "$(INTDIR)\lstEnQ.obj"
	-erase "$(INTDIR)\lstFake.obj"
	-erase "$(INTDIR)\lstFind.obj"
	-erase "$(INTDIR)\lstFindF.obj"
	-erase "$(INTDIR)\lstFirst.obj"
	-erase "$(INTDIR)\lstForE.obj"
	-erase "$(INTDIR)\lstForEF.obj"
	-erase "$(INTDIR)\lstIndex.obj"
	-erase "$(INTDIR)\lstInit.obj"
	-erase "$(INTDIR)\lstIns.obj"
	-erase "$(INTDIR)\lstIsEnd.obj"
	-erase "$(INTDIR)\lstIsMT.obj"
	-erase "$(INTDIR)\lstLast.obj"
	-erase "$(INTDIR)\lstLnth.obj"
	-erase "$(INTDIR)\lstMembr.obj"
	-erase "$(INTDIR)\lstMove.obj"
	-erase "$(INTDIR)\lstNext.obj"
	-erase "$(INTDIR)\lstOpen.obj"
	-erase "$(INTDIR)\lstPred.obj"
	-erase "$(INTDIR)\lstPrev.obj"
	-erase "$(INTDIR)\lstRem.obj"
	-erase "$(INTDIR)\lstRepl.obj"
	-erase "$(INTDIR)\lstSetC.obj"
	-erase "$(INTDIR)\lstSucc.obj"
	-erase "$(INTDIR)\vc60.idb"
	-erase "$(ROOT_DIR)\Tools\vc++\lib\Release\lst.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\lst.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\lst.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\Release\lst.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\lstAppnd.obj" \
	"$(INTDIR)\lstAtEnd.obj" \
	"$(INTDIR)\lstAtFnt.obj" \
	"$(INTDIR)\lstCat.obj" \
	"$(INTDIR)\lstClose.obj" \
	"$(INTDIR)\lstCur.obj" \
	"$(INTDIR)\lstDatum.obj" \
	"$(INTDIR)\lstDeQ.obj" \
	"$(INTDIR)\lstDest.obj" \
	"$(INTDIR)\lstDupl.obj" \
	"$(INTDIR)\lstEnQ.obj" \
	"$(INTDIR)\lstFake.obj" \
	"$(INTDIR)\lstFind.obj" \
	"$(INTDIR)\lstFindF.obj" \
	"$(INTDIR)\lstFirst.obj" \
	"$(INTDIR)\lstForE.obj" \
	"$(INTDIR)\lstForEF.obj" \
	"$(INTDIR)\lstIndex.obj" \
	"$(INTDIR)\lstInit.obj" \
	"$(INTDIR)\lstIns.obj" \
	"$(INTDIR)\lstIsEnd.obj" \
	"$(INTDIR)\lstIsMT.obj" \
	"$(INTDIR)\lstLast.obj" \
	"$(INTDIR)\lstLnth.obj" \
	"$(INTDIR)\lstMembr.obj" \
	"$(INTDIR)\lstMove.obj" \
	"$(INTDIR)\lstNext.obj" \
	"$(INTDIR)\lstOpen.obj" \
	"$(INTDIR)\lstPred.obj" \
	"$(INTDIR)\lstPrev.obj" \
	"$(INTDIR)\lstRem.obj" \
	"$(INTDIR)\lstRepl.obj" \
	"$(INTDIR)\lstSetC.obj" \
	"$(INTDIR)\lstSucc.obj"

"$(ROOT_DIR)\Tools\vc++\lib\Release\lst.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "lst - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(ROOT_DIR)\Tools\vc++\lib\lst.lib"


CLEAN :
	-erase "$(INTDIR)\lstAppnd.obj"
	-erase "$(INTDIR)\lstAtEnd.obj"
	-erase "$(INTDIR)\lstAtFnt.obj"
	-erase "$(INTDIR)\lstCat.obj"
	-erase "$(INTDIR)\lstClose.obj"
	-erase "$(INTDIR)\lstCur.obj"
	-erase "$(INTDIR)\lstDatum.obj"
	-erase "$(INTDIR)\lstDeQ.obj"
	-erase "$(INTDIR)\lstDest.obj"
	-erase "$(INTDIR)\lstDupl.obj"
	-erase "$(INTDIR)\lstEnQ.obj"
	-erase "$(INTDIR)\lstFake.obj"
	-erase "$(INTDIR)\lstFind.obj"
	-erase "$(INTDIR)\lstFindF.obj"
	-erase "$(INTDIR)\lstFirst.obj"
	-erase "$(INTDIR)\lstForE.obj"
	-erase "$(INTDIR)\lstForEF.obj"
	-erase "$(INTDIR)\lstIndex.obj"
	-erase "$(INTDIR)\lstInit.obj"
	-erase "$(INTDIR)\lstIns.obj"
	-erase "$(INTDIR)\lstIsEnd.obj"
	-erase "$(INTDIR)\lstIsMT.obj"
	-erase "$(INTDIR)\lstLast.obj"
	-erase "$(INTDIR)\lstLnth.obj"
	-erase "$(INTDIR)\lstMembr.obj"
	-erase "$(INTDIR)\lstMove.obj"
	-erase "$(INTDIR)\lstNext.obj"
	-erase "$(INTDIR)\lstOpen.obj"
	-erase "$(INTDIR)\lstPred.obj"
	-erase "$(INTDIR)\lstPrev.obj"
	-erase "$(INTDIR)\lstRem.obj"
	-erase "$(INTDIR)\lstRepl.obj"
	-erase "$(INTDIR)\lstSetC.obj"
	-erase "$(INTDIR)\lstSucc.obj"
	-erase "$(INTDIR)\vc60.idb"
	-erase "$(INTDIR)\vc60.pdb"
	-erase "$(ROOT_DIR)\Tools\vc++\lib\lst.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\lst.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\lst.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\lst.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\lstAppnd.obj" \
	"$(INTDIR)\lstAtEnd.obj" \
	"$(INTDIR)\lstAtFnt.obj" \
	"$(INTDIR)\lstCat.obj" \
	"$(INTDIR)\lstClose.obj" \
	"$(INTDIR)\lstCur.obj" \
	"$(INTDIR)\lstDatum.obj" \
	"$(INTDIR)\lstDeQ.obj" \
	"$(INTDIR)\lstDest.obj" \
	"$(INTDIR)\lstDupl.obj" \
	"$(INTDIR)\lstEnQ.obj" \
	"$(INTDIR)\lstFake.obj" \
	"$(INTDIR)\lstFind.obj" \
	"$(INTDIR)\lstFindF.obj" \
	"$(INTDIR)\lstFirst.obj" \
	"$(INTDIR)\lstForE.obj" \
	"$(INTDIR)\lstForEF.obj" \
	"$(INTDIR)\lstIndex.obj" \
	"$(INTDIR)\lstInit.obj" \
	"$(INTDIR)\lstIns.obj" \
	"$(INTDIR)\lstIsEnd.obj" \
	"$(INTDIR)\lstIsMT.obj" \
	"$(INTDIR)\lstLast.obj" \
	"$(INTDIR)\lstLnth.obj" \
	"$(INTDIR)\lstMembr.obj" \
	"$(INTDIR)\lstMove.obj" \
	"$(INTDIR)\lstNext.obj" \
	"$(INTDIR)\lstOpen.obj" \
	"$(INTDIR)\lstPred.obj" \
	"$(INTDIR)\lstPrev.obj" \
	"$(INTDIR)\lstRem.obj" \
	"$(INTDIR)\lstRepl.obj" \
	"$(INTDIR)\lstSetC.obj" \
	"$(INTDIR)\lstSucc.obj"

"$(ROOT_DIR)\Tools\vc++\lib\lst.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
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
!IF EXISTS("lst.dep")
!INCLUDE "lst.dep"
!ELSE 
!MESSAGE Warning: cannot find "lst.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "lst - Win32 Release" || "$(CFG)" == "lst - Win32 Debug"
SOURCE=.\lstAppnd.c

"$(INTDIR)\lstAppnd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstAtEnd.c

"$(INTDIR)\lstAtEnd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstAtFnt.c

"$(INTDIR)\lstAtFnt.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstCat.c

"$(INTDIR)\lstCat.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstClose.c

"$(INTDIR)\lstClose.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstCur.c

"$(INTDIR)\lstCur.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstDatum.c

"$(INTDIR)\lstDatum.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstDeQ.c

"$(INTDIR)\lstDeQ.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstDest.c

"$(INTDIR)\lstDest.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstDupl.c

"$(INTDIR)\lstDupl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstEnQ.c

"$(INTDIR)\lstEnQ.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstFake.c

"$(INTDIR)\lstFake.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstFind.c

"$(INTDIR)\lstFind.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstFindF.c

"$(INTDIR)\lstFindF.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstFirst.c

"$(INTDIR)\lstFirst.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstForE.c

"$(INTDIR)\lstForE.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstForEF.c

"$(INTDIR)\lstForEF.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstIndex.c

"$(INTDIR)\lstIndex.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstInit.c

"$(INTDIR)\lstInit.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstIns.c

"$(INTDIR)\lstIns.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstIsEnd.c

"$(INTDIR)\lstIsEnd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstIsMT.c

"$(INTDIR)\lstIsMT.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstLast.c

"$(INTDIR)\lstLast.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstLnth.c

"$(INTDIR)\lstLnth.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstMembr.c

"$(INTDIR)\lstMembr.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstMove.c

"$(INTDIR)\lstMove.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstNext.c

"$(INTDIR)\lstNext.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstOpen.c

"$(INTDIR)\lstOpen.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstPred.c

"$(INTDIR)\lstPred.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstPrev.c

"$(INTDIR)\lstPrev.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstRem.c

"$(INTDIR)\lstRem.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstRepl.c

"$(INTDIR)\lstRepl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstSetC.c

"$(INTDIR)\lstSetC.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\lstSucc.c

"$(INTDIR)\lstSucc.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

