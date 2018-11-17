# Microsoft Developer Studio Generated NMAKE File, Based on utils.dsp
!IF "$(CFG)" == ""
CFG=utils - Win32 Debug
!MESSAGE No configuration specified. Defaulting to utils - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "utils - Win32 Release" && "$(CFG)" != "utils - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "utils.mak" CFG="utils - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "utils - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "utils - Win32 Debug" (based on "Win32 (x86) Static Library")
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

!IF  "$(CFG)" == "utils - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(ROOT_DIR)\Tools\vc++\lib\Release\utils.lib"


CLEAN :
	-@erase "$(INTDIR)\fileargs.obj"
	-@erase "$(INTDIR)\fileUtil.obj"
	-@erase "$(INTDIR)\geode.obj"
	-@erase "$(INTDIR)\hash.obj"
	-@erase "$(INTDIR)\localize.obj"
	-@erase "$(INTDIR)\malErr.obj"
	-@erase "$(INTDIR)\malloc.obj"
	-@erase "$(INTDIR)\memAl.obj"
	-@erase "$(INTDIR)\memAlLkd.obj"
	-@erase "$(INTDIR)\memFree.obj"
	-@erase "$(INTDIR)\memInfo.obj"
	-@erase "$(INTDIR)\memLock.obj"
	-@erase "$(INTDIR)\memRAl.obj"
	-@erase "$(INTDIR)\memRAlLk.obj"
	-@erase "$(INTDIR)\memUtils.obj"
	-@erase "$(INTDIR)\objSwap.obj"
	-@erase "$(INTDIR)\printf.obj"
	-@erase "$(INTDIR)\stClose.obj"
	-@erase "$(INTDIR)\stCreate.obj"
	-@erase "$(INTDIR)\stDest.obj"
	-@erase "$(INTDIR)\stDup.obj"
	-@erase "$(INTDIR)\stEnt.obj"
	-@erase "$(INTDIR)\stEntNL.obj"
	-@erase "$(INTDIR)\stHash.obj"
	-@erase "$(INTDIR)\stIndex.obj"
	-@erase "$(INTDIR)\stLook.obj"
	-@erase "$(INTDIR)\stLookNL.obj"
	-@erase "$(INTDIR)\stReloc.obj"
	-@erase "$(INTDIR)\stSearch.obj"
	-@erase "$(INTDIR)\sttab.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vmAl.obj"
	-@erase "$(INTDIR)\vmAlRd.obj"
	-@erase "$(INTDIR)\vmAlUnas.obj"
	-@erase "$(INTDIR)\vmAttach.obj"
	-@erase "$(INTDIR)\vmAttr.obj"
	-@erase "$(INTDIR)\vmClose.obj"
	-@erase "$(INTDIR)\vmDetach.obj"
	-@erase "$(INTDIR)\vmDirty.obj"
	-@erase "$(INTDIR)\vmEmpty.obj"
	-@erase "$(INTDIR)\vmFAl.obj"
	-@erase "$(INTDIR)\vmFFree.obj"
	-@erase "$(INTDIR)\vmFind.obj"
	-@erase "$(INTDIR)\vmFree.obj"
	-@erase "$(INTDIR)\vmGVers.obj"
	-@erase "$(INTDIR)\vmHeader.obj"
	-@erase "$(INTDIR)\vmInfo.obj"
	-@erase "$(INTDIR)\vmLock.obj"
	-@erase "$(INTDIR)\vmMapBlk.obj"
	-@erase "$(INTDIR)\vmModUID.obj"
	-@erase "$(INTDIR)\vmOpen.obj"
	-@erase "$(INTDIR)\vmSetRel.obj"
	-@erase "$(INTDIR)\vmUpdate.obj"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\Release\utils.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\utils.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\utils.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\Release\utils.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\fileargs.obj" \
	"$(INTDIR)\fileUtil.obj" \
	"$(INTDIR)\geode.obj" \
	"$(INTDIR)\hash.obj" \
	"$(INTDIR)\localize.obj" \
	"$(INTDIR)\malErr.obj" \
	"$(INTDIR)\malloc.obj" \
	"$(INTDIR)\memAl.obj" \
	"$(INTDIR)\memAlLkd.obj" \
	"$(INTDIR)\memFree.obj" \
	"$(INTDIR)\memInfo.obj" \
	"$(INTDIR)\memLock.obj" \
	"$(INTDIR)\memRAl.obj" \
	"$(INTDIR)\memRAlLk.obj" \
	"$(INTDIR)\memUtils.obj" \
	"$(INTDIR)\objSwap.obj" \
	"$(INTDIR)\printf.obj" \
	"$(INTDIR)\stClose.obj" \
	"$(INTDIR)\stCreate.obj" \
	"$(INTDIR)\stDest.obj" \
	"$(INTDIR)\stDup.obj" \
	"$(INTDIR)\stEnt.obj" \
	"$(INTDIR)\stEntNL.obj" \
	"$(INTDIR)\stHash.obj" \
	"$(INTDIR)\stIndex.obj" \
	"$(INTDIR)\stLook.obj" \
	"$(INTDIR)\stLookNL.obj" \
	"$(INTDIR)\stReloc.obj" \
	"$(INTDIR)\stSearch.obj" \
	"$(INTDIR)\sttab.obj" \
	"$(INTDIR)\vmAl.obj" \
	"$(INTDIR)\vmAlRd.obj" \
	"$(INTDIR)\vmAlUnas.obj" \
	"$(INTDIR)\vmAttach.obj" \
	"$(INTDIR)\vmAttr.obj" \
	"$(INTDIR)\vmClose.obj" \
	"$(INTDIR)\vmDetach.obj" \
	"$(INTDIR)\vmDirty.obj" \
	"$(INTDIR)\vmEmpty.obj" \
	"$(INTDIR)\vmFAl.obj" \
	"$(INTDIR)\vmFFree.obj" \
	"$(INTDIR)\vmFind.obj" \
	"$(INTDIR)\vmFree.obj" \
	"$(INTDIR)\vmGVers.obj" \
	"$(INTDIR)\vmHeader.obj" \
	"$(INTDIR)\vmInfo.obj" \
	"$(INTDIR)\vmLock.obj" \
	"$(INTDIR)\vmMapBlk.obj" \
	"$(INTDIR)\vmModUID.obj" \
	"$(INTDIR)\vmOpen.obj" \
	"$(INTDIR)\vmSetRel.obj" \
	"$(INTDIR)\vmUpdate.obj"

"$(ROOT_DIR)\Tools\vc++\lib\Release\utils.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "utils - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(ROOT_DIR)\Tools\vc++\lib\utils.lib"


CLEAN :
	-@erase "$(INTDIR)\fileargs.obj"
	-@erase "$(INTDIR)\fileUtil.obj"
	-@erase "$(INTDIR)\geode.obj"
	-@erase "$(INTDIR)\hash.obj"
	-@erase "$(INTDIR)\localize.obj"
	-@erase "$(INTDIR)\malErr.obj"
	-@erase "$(INTDIR)\malloc.obj"
	-@erase "$(INTDIR)\memAl.obj"
	-@erase "$(INTDIR)\memAlLkd.obj"
	-@erase "$(INTDIR)\memFree.obj"
	-@erase "$(INTDIR)\memInfo.obj"
	-@erase "$(INTDIR)\memLock.obj"
	-@erase "$(INTDIR)\memRAl.obj"
	-@erase "$(INTDIR)\memRAlLk.obj"
	-@erase "$(INTDIR)\memUtils.obj"
	-@erase "$(INTDIR)\objSwap.obj"
	-@erase "$(INTDIR)\printf.obj"
	-@erase "$(INTDIR)\stClose.obj"
	-@erase "$(INTDIR)\stCreate.obj"
	-@erase "$(INTDIR)\stDest.obj"
	-@erase "$(INTDIR)\stDup.obj"
	-@erase "$(INTDIR)\stEnt.obj"
	-@erase "$(INTDIR)\stEntNL.obj"
	-@erase "$(INTDIR)\stHash.obj"
	-@erase "$(INTDIR)\stIndex.obj"
	-@erase "$(INTDIR)\stLook.obj"
	-@erase "$(INTDIR)\stLookNL.obj"
	-@erase "$(INTDIR)\stReloc.obj"
	-@erase "$(INTDIR)\stSearch.obj"
	-@erase "$(INTDIR)\sttab.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(INTDIR)\vmAl.obj"
	-@erase "$(INTDIR)\vmAlRd.obj"
	-@erase "$(INTDIR)\vmAlUnas.obj"
	-@erase "$(INTDIR)\vmAttach.obj"
	-@erase "$(INTDIR)\vmAttr.obj"
	-@erase "$(INTDIR)\vmClose.obj"
	-@erase "$(INTDIR)\vmDetach.obj"
	-@erase "$(INTDIR)\vmDirty.obj"
	-@erase "$(INTDIR)\vmEmpty.obj"
	-@erase "$(INTDIR)\vmFAl.obj"
	-@erase "$(INTDIR)\vmFFree.obj"
	-@erase "$(INTDIR)\vmFind.obj"
	-@erase "$(INTDIR)\vmFree.obj"
	-@erase "$(INTDIR)\vmGVers.obj"
	-@erase "$(INTDIR)\vmHeader.obj"
	-@erase "$(INTDIR)\vmInfo.obj"
	-@erase "$(INTDIR)\vmLock.obj"
	-@erase "$(INTDIR)\vmMapBlk.obj"
	-@erase "$(INTDIR)\vmModUID.obj"
	-@erase "$(INTDIR)\vmOpen.obj"
	-@erase "$(INTDIR)\vmSetRel.obj"
	-@erase "$(INTDIR)\vmUpdate.obj"
	-@erase "$(ROOT_DIR)\Tools\vc++\lib\utils.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /Fp"$(INTDIR)\utils.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c $(C_INCLUDES)
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\utils.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
LIB32_FLAGS=/nologo /out:"$(ROOT_DIR)\Tools\vc++\lib\utils.lib" $(LIB_INCLUDE)
LIB32_OBJS= \
	"$(INTDIR)\fileargs.obj" \
	"$(INTDIR)\fileUtil.obj" \
	"$(INTDIR)\geode.obj" \
	"$(INTDIR)\hash.obj" \
	"$(INTDIR)\localize.obj" \
	"$(INTDIR)\malErr.obj" \
	"$(INTDIR)\malloc.obj" \
	"$(INTDIR)\memAl.obj" \
	"$(INTDIR)\memAlLkd.obj" \
	"$(INTDIR)\memFree.obj" \
	"$(INTDIR)\memInfo.obj" \
	"$(INTDIR)\memLock.obj" \
	"$(INTDIR)\memRAl.obj" \
	"$(INTDIR)\memRAlLk.obj" \
	"$(INTDIR)\memUtils.obj" \
	"$(INTDIR)\objSwap.obj" \
	"$(INTDIR)\printf.obj" \
	"$(INTDIR)\stClose.obj" \
	"$(INTDIR)\stCreate.obj" \
	"$(INTDIR)\stDest.obj" \
	"$(INTDIR)\stDup.obj" \
	"$(INTDIR)\stEnt.obj" \
	"$(INTDIR)\stEntNL.obj" \
	"$(INTDIR)\stHash.obj" \
	"$(INTDIR)\stIndex.obj" \
	"$(INTDIR)\stLook.obj" \
	"$(INTDIR)\stLookNL.obj" \
	"$(INTDIR)\stReloc.obj" \
	"$(INTDIR)\stSearch.obj" \
	"$(INTDIR)\sttab.obj" \
	"$(INTDIR)\vmAl.obj" \
	"$(INTDIR)\vmAlRd.obj" \
	"$(INTDIR)\vmAlUnas.obj" \
	"$(INTDIR)\vmAttach.obj" \
	"$(INTDIR)\vmAttr.obj" \
	"$(INTDIR)\vmClose.obj" \
	"$(INTDIR)\vmDetach.obj" \
	"$(INTDIR)\vmDirty.obj" \
	"$(INTDIR)\vmEmpty.obj" \
	"$(INTDIR)\vmFAl.obj" \
	"$(INTDIR)\vmFFree.obj" \
	"$(INTDIR)\vmFind.obj" \
	"$(INTDIR)\vmFree.obj" \
	"$(INTDIR)\vmGVers.obj" \
	"$(INTDIR)\vmHeader.obj" \
	"$(INTDIR)\vmInfo.obj" \
	"$(INTDIR)\vmLock.obj" \
	"$(INTDIR)\vmMapBlk.obj" \
	"$(INTDIR)\vmModUID.obj" \
	"$(INTDIR)\vmOpen.obj" \
	"$(INTDIR)\vmSetRel.obj" \
	"$(INTDIR)\vmUpdate.obj"

"$(ROOT_DIR)\Tools\vc++\lib\utils.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
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
!IF EXISTS("utils.dep")
!INCLUDE "utils.dep"
!ELSE 
!MESSAGE Warning: cannot find "utils.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "utils - Win32 Release" || "$(CFG)" == "utils - Win32 Debug"
SOURCE=.\fileargs.c

"$(INTDIR)\fileargs.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\fileUtil.c

"$(INTDIR)\fileUtil.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\geode.c

"$(INTDIR)\geode.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\hash.c

"$(INTDIR)\hash.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\localize.c

"$(INTDIR)\localize.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\malErr.c

"$(INTDIR)\malErr.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\malloc.c

"$(INTDIR)\malloc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memAl.c

"$(INTDIR)\memAl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memAlLkd.c

"$(INTDIR)\memAlLkd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memFree.c

"$(INTDIR)\memFree.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memInfo.c

"$(INTDIR)\memInfo.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memLock.c

"$(INTDIR)\memLock.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memRAl.c

"$(INTDIR)\memRAl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memRAlLk.c

"$(INTDIR)\memRAlLk.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\memUtils.c

"$(INTDIR)\memUtils.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\objSwap.c

"$(INTDIR)\objSwap.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\printf.c

"$(INTDIR)\printf.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stClose.c

"$(INTDIR)\stClose.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stCreate.c

"$(INTDIR)\stCreate.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stDest.c

"$(INTDIR)\stDest.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stDup.c

"$(INTDIR)\stDup.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stEnt.c

"$(INTDIR)\stEnt.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stEntNL.c

"$(INTDIR)\stEntNL.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stHash.c

"$(INTDIR)\stHash.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stIndex.c

"$(INTDIR)\stIndex.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stLook.c

"$(INTDIR)\stLook.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stLookNL.c

"$(INTDIR)\stLookNL.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stReloc.c

"$(INTDIR)\stReloc.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\stSearch.c

"$(INTDIR)\stSearch.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\sttab.c

"$(INTDIR)\sttab.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmAl.c

"$(INTDIR)\vmAl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmAlRd.c

"$(INTDIR)\vmAlRd.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmAlUnas.c

"$(INTDIR)\vmAlUnas.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmAttach.c

"$(INTDIR)\vmAttach.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmAttr.c

"$(INTDIR)\vmAttr.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmClose.c

"$(INTDIR)\vmClose.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmDetach.c

"$(INTDIR)\vmDetach.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmDirty.c

"$(INTDIR)\vmDirty.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmEmpty.c

"$(INTDIR)\vmEmpty.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmFAl.c

"$(INTDIR)\vmFAl.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmFFree.c

"$(INTDIR)\vmFFree.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmFind.c

"$(INTDIR)\vmFind.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmFree.c

"$(INTDIR)\vmFree.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmGVers.c

"$(INTDIR)\vmGVers.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmHeader.c

"$(INTDIR)\vmHeader.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmInfo.c

"$(INTDIR)\vmInfo.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmLock.c

"$(INTDIR)\vmLock.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmMapBlk.c

"$(INTDIR)\vmMapBlk.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmModUID.c

"$(INTDIR)\vmModUID.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmOpen.c

"$(INTDIR)\vmOpen.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmSetRel.c

"$(INTDIR)\vmSetRel.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\vmUpdate.c

"$(INTDIR)\vmUpdate.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

