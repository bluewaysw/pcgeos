# Microsoft Developer Studio Project File - Name="lst" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=lst - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "lst.mak".
!MESSAGE 
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

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "lst"
# PROP Scc_LocalPath "."
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "lst - Win32 Release"

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
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"..\..\..\vc++\lib\lst.lib"

!ELSEIF  "$(CFG)" == "lst - Win32 Debug"

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
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"..\..\..\vc++\lib\lstd.lib"

!ENDIF 

# Begin Target

# Name "lst - Win32 Release"
# Name "lst - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\lstAppnd.c
# End Source File
# Begin Source File

SOURCE=.\lstAtEnd.c
# End Source File
# Begin Source File

SOURCE=.\lstAtFnt.c
# End Source File
# Begin Source File

SOURCE=.\lstCat.c
# End Source File
# Begin Source File

SOURCE=.\lstClose.c
# End Source File
# Begin Source File

SOURCE=.\lstCur.c
# End Source File
# Begin Source File

SOURCE=.\lstDatum.c
# End Source File
# Begin Source File

SOURCE=.\lstDeQ.c
# End Source File
# Begin Source File

SOURCE=.\lstDest.c
# End Source File
# Begin Source File

SOURCE=.\lstDupl.c
# End Source File
# Begin Source File

SOURCE=.\lstEnQ.c
# End Source File
# Begin Source File

SOURCE=.\lstFake.c
# End Source File
# Begin Source File

SOURCE=.\lstFind.c
# End Source File
# Begin Source File

SOURCE=.\lstFindF.c
# End Source File
# Begin Source File

SOURCE=.\lstFirst.c
# End Source File
# Begin Source File

SOURCE=.\lstForE.c
# End Source File
# Begin Source File

SOURCE=.\lstForEF.c
# End Source File
# Begin Source File

SOURCE=.\lstIndex.c
# End Source File
# Begin Source File

SOURCE=.\lstInit.c
# End Source File
# Begin Source File

SOURCE=.\lstIns.c
# End Source File
# Begin Source File

SOURCE=.\lstIsEnd.c
# End Source File
# Begin Source File

SOURCE=.\lstIsMT.c
# End Source File
# Begin Source File

SOURCE=.\lstLast.c
# End Source File
# Begin Source File

SOURCE=.\lstLnth.c
# End Source File
# Begin Source File

SOURCE=.\lstMembr.c
# End Source File
# Begin Source File

SOURCE=.\lstMove.c
# End Source File
# Begin Source File

SOURCE=.\lstNext.c
# End Source File
# Begin Source File

SOURCE=.\lstOpen.c
# End Source File
# Begin Source File

SOURCE=.\lstPred.c
# End Source File
# Begin Source File

SOURCE=.\lstPrev.c
# End Source File
# Begin Source File

SOURCE=.\lstRem.c
# End Source File
# Begin Source File

SOURCE=.\lstRepl.c
# End Source File
# Begin Source File

SOURCE=.\lstSetC.c
# End Source File
# Begin Source File

SOURCE=.\lstSucc.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\lst.h
# End Source File
# Begin Source File

SOURCE=.\lstInt.h
# End Source File
# End Group
# End Target
# End Project
