# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

!IF "$(CFG)" == ""
CFG=freetype - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to freetype - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "freetype - Win32 Release" && "$(CFG)" !=\
 "freetype - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "freetype.mak" CFG="freetype - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "freetype - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "freetype - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
################################################################################
# Begin Project
# PROP Target_Last_Scanned "freetype - Win32 Debug"
CPP=cl.exe

!IF  "$(CFG)" == "freetype - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(OUTDIR)\freetype.lib"

CLEAN : 
	-@erase ".\Release\freetype.lib"
	-@erase ".\Release\Ftxkern.obj"
	-@erase ".\Release\ftxpost.obj"
	-@erase ".\Release\ftxerr18.obj"
	-@erase ".\Release\Ftxcmap.obj"
	-@erase ".\Release\Freetype.obj"
	-@erase ".\Release\Ftxgasp.obj"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /O2 /I "." /I "..\.." /I "..\..\extend" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /O2 /I "." /I "..\.." /I "..\..\extend" /D "WIN32"\
 /D "NDEBUG" /D "_WINDOWS" /Fp"$(INTDIR)/freetype.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/freetype.bsc" 
BSC32_SBRS=
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo
LIB32_FLAGS=/nologo /out:"$(OUTDIR)/freetype.lib" 
LIB32_OBJS= \
	"$(INTDIR)/Ftxkern.obj" \
	"$(INTDIR)/ftxpost.obj" \
	"$(INTDIR)/ftxerr18.obj" \
	"$(INTDIR)/Ftxcmap.obj" \
	"$(INTDIR)/Freetype.obj" \
	"$(INTDIR)/Ftxgasp.obj"

"$(OUTDIR)\freetype.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "freetype - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(OUTDIR)\freetype.lib"

CLEAN : 
	-@erase ".\Debug\freetype.lib"
	-@erase ".\Debug\Freetype.obj"
	-@erase ".\Debug\Ftxkern.obj"
	-@erase ".\Debug\ftxpost.obj"
	-@erase ".\Debug\Ftxcmap.obj"
	-@erase ".\Debug\Ftxgasp.obj"
	-@erase ".\Debug\ftxerr18.obj"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /Z7 /Od /I "." /I "..\.." /I "..\..\extend" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /GX /Z7 /Od /I "." /I "..\.." /I "..\..\extend" /D\
 "WIN32" /D "_DEBUG" /D "_WINDOWS" /Fp"$(INTDIR)/freetype.pch" /YX\
 /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/freetype.bsc" 
BSC32_SBRS=
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo
LIB32_FLAGS=/nologo /out:"$(OUTDIR)/freetype.lib" 
LIB32_OBJS= \
	"$(INTDIR)/Freetype.obj" \
	"$(INTDIR)/Ftxkern.obj" \
	"$(INTDIR)/ftxpost.obj" \
	"$(INTDIR)/Ftxcmap.obj" \
	"$(INTDIR)/Ftxgasp.obj" \
	"$(INTDIR)/ftxerr18.obj"

"$(OUTDIR)\freetype.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ENDIF 

.c{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.c{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

################################################################################
# Begin Target

# Name "freetype - Win32 Release"
# Name "freetype - Win32 Debug"

!IF  "$(CFG)" == "freetype - Win32 Release"

!ELSEIF  "$(CFG)" == "freetype - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=\Freetype\Lib\Extend\ftxpost.c
DEP_CPP_FTXPO=\
	".\..\..\Extend\ftxpost.h"\
	".\..\..\tttypes.h"\
	".\..\..\ttobjs.h"\
	".\..\..\tttables.h"\
	".\..\..\ttload.h"\
	".\..\..\ttfile.h"\
	".\..\..\tttags.h"\
	".\..\..\ttmemory.h"\
	".\..\..\ttextend.h"\
	".\..\..\freetype.h"\
	"..\..\ttconfig.h"\
	".\ft_conf.h"\
	"..\..\ttengine.h"\
	"..\..\ttmutex.h"\
	"..\..\ttcache.h"\
	"..\..\ttcmap.h"\
	".\..\..\ttdebug.h"\
	

"$(INTDIR)\ftxpost.obj" : $(SOURCE) $(DEP_CPP_FTXPO) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=\Freetype\Lib\Extend\ftxerr18.c
DEP_CPP_FTXER=\
	".\..\..\Extend\ftxerr18.h"\
	".\..\..\Extend\ftxkern.h"\
	".\..\..\Extend\ftxpost.h"\
	".\..\..\freetype.h"\
	"..\..\ttconfig.h"\
	".\ft_conf.h"\
	

"$(INTDIR)\ftxerr18.obj" : $(SOURCE) $(DEP_CPP_FTXER) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=\Freetype\Lib\Extend\Ftxgasp.c
DEP_CPP_FTXGA=\
	".\..\..\Extend\ftxgasp.h"\
	".\..\..\tttypes.h"\
	".\..\..\ttobjs.h"\
	".\..\..\tttables.h"\
	".\..\..\freetype.h"\
	"..\..\ttconfig.h"\
	".\ft_conf.h"\
	"..\..\ttengine.h"\
	"..\..\ttmutex.h"\
	"..\..\ttcache.h"\
	"..\..\ttcmap.h"\
	

"$(INTDIR)\Ftxgasp.obj" : $(SOURCE) $(DEP_CPP_FTXGA) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=\Freetype\Lib\Extend\Ftxkern.c
DEP_CPP_FTXKE=\
	".\..\..\Extend\ftxkern.h"\
	".\..\..\ttextend.h"\
	".\..\..\tttypes.h"\
	".\..\..\ttdebug.h"\
	".\..\..\ttmemory.h"\
	".\..\..\ttfile.h"\
	".\..\..\ttobjs.h"\
	".\..\..\ttload.h"\
	".\..\..\tttags.h"\
	".\..\..\freetype.h"\
	"..\..\ttconfig.h"\
	".\ft_conf.h"\
	"..\..\ttengine.h"\
	"..\..\ttmutex.h"\
	"..\..\ttcache.h"\
	".\..\..\tttables.h"\
	"..\..\ttcmap.h"\
	

"$(INTDIR)\Ftxkern.obj" : $(SOURCE) $(DEP_CPP_FTXKE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=\Freetype\Lib\Extend\Ftxcmap.c
DEP_CPP_FTXCM=\
	".\..\..\Extend\ftxcmap.h"\
	".\..\..\tttypes.h"\
	".\..\..\ttobjs.h"\
	".\..\..\tttables.h"\
	".\..\..\freetype.h"\
	"..\..\ttconfig.h"\
	".\ft_conf.h"\
	"..\..\ttengine.h"\
	"..\..\ttmutex.h"\
	"..\..\ttcache.h"\
	"..\..\ttcmap.h"\
	

"$(INTDIR)\Ftxcmap.obj" : $(SOURCE) $(DEP_CPP_FTXCM) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Freetype.c
DEP_CPP_FREET=\
	".\..\..\ttapi.c"\
	".\..\..\ttcache.c"\
	".\..\..\ttcalc.c"\
	".\..\..\ttcmap.c"\
	".\..\..\ttgload.c"\
	".\..\..\ttinterp.c"\
	".\..\..\ttload.c"\
	".\..\..\ttobjs.c"\
	".\..\..\ttraster.c"\
	".\..\..\ttfile.c"\
	".\..\..\ttmemory.c"\
	".\..\..\ttmutex.c"\
	".\..\..\ttextend.c"\
	".\..\..\freetype.h"\
	"..\..\ttengine.h"\
	"..\..\ttcalc.h"\
	".\..\..\ttmemory.h"\
	"..\..\ttcache.h"\
	".\..\..\ttfile.h"\
	".\..\..\ttobjs.h"\
	".\..\..\ttload.h"\
	"..\..\ttgload.h"\
	"..\..\ttraster.h"\
	".\..\..\ttextend.h"\
	"..\..\ttconfig.h"\
	".\ft_conf.h"\
	"..\..\ttmutex.h"\
	".\..\..\tttypes.h"\
	".\..\..\ttdebug.h"\
	".\..\..\tttables.h"\
	"..\..\ttcmap.h"\
	".\..\..\tttags.h"\
	"..\..\ttinterp.h"\
	{$(INCLUDE)}"\unistd.h"\
	

"$(INTDIR)\Freetype.obj" : $(SOURCE) $(DEP_CPP_FREET) "$(INTDIR)"


# End Source File
# End Target
# End Project
################################################################################
