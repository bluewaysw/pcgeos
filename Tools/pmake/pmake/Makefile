obj_files = arch.obj compat.obj cond.obj customslib.obj dir.obj job.obj main.obj make.obj parse.obj rmt.obj rpc.obj str.obj suff.obj targ.obj var.obj
o_files = arch.o compat.o cond.o customslib.o dir.o job.o main.o make.o parse.o rmt.o rpc.o str.o suff.o targ.o var.o

.c.obj
	wcc386 -bt=nt-i="$(%WATCOM)/h/nt" -i="$(%WATCOM)/h" -i="../../include" -i="../src/lib/include" -i="../src/lib/lst" -i="../customs" -fo=$*.obj $<

.c.o
	wcc386 -bt=linux -D_LINUX -i="$(%WATCOM)/lh" -i="$(%WATCOM)/h" -i="../../include" -i="../src/lib/include" -i="../src/lib/lst" -i="../customs" -fo=$*.o $<

lst.lib:	.procedure
!ifdef __LINUX__
		cd ../lib/lst
!else
		cd ..\lib\lst
!endif
		wmake lst.lib all
!ifdef __LINUX__
		cd ../../pmake
!else
		cd ..\..\pmake
!endif

liblst.so:	.procedure
!ifdef __LINUX__
		cd ../lib/lst
!else
		cd ..\lib\lst
!endif
		wmake liblst.a all
!ifdef __LINUX__
		cd ../../pmake
!else
		cd ..\..\pmake
!endif

sprite.lib:	.procedure
!ifdef __LINUX__
		cd ../lib/sprite
!else
		cd ..\lib\sprite
!endif
		wmake sprite.lib all
!ifdef __LINUX__
		cd ../../pmake
!else
		cd ..\..\pmake
!endif

libsprite.so:	.procedure
!ifdef __LINUX__
		cd ../lib/sprite
!else
		cd ..\lib\sprite
!endif
		wmake libsprite.a all
!ifdef __LINUX__
		cd ../../pmake
!else
		cd ..\..\pmake
!endif

pmake.exe: $(obj_files) sprite.lib lst.lib
		  %write pmake.lnk NAME   $@
		  %write pmake.lnk SYSTEM NT_WIN
		  %write pmake.lnk RU CON
		  %write pmake.lnk libfile ../lib/sprite/sprite.lib
		  %write pmake.lnk libfile ../lib/lst/lst.lib
		  %write pmake.lnk library kernel32
		  %write pmake.lnk FILE   {$(obj_files)}
		  wlink  @pmake.lnk

pmake.e: $(o_files)
	%write pmake.lnk NAME   $@
	%write pmake.lnk FORMAT ELF
	%write pmake.lnk libfile ../lib/sprite/libsprite.a
	%write pmake.lnk libfile ../lib/lst/liblst.a
	%write pmake.lnk library $(%WATCOM)/lib386/linux/clib3r.lib
	%write pmake.lnk library $(%WATCOM)/lib386/emu387.lib
	%write pmake.lnk library $(%WATCOM)/lib386/math387r.lib
	%write pmake.lnk FILE   {$(o_files)}
	wlink  @pmake.lnk

install: pmake.exe pmake.e .procedure
!ifdef __LINUX__
  cp pmake.exe ../../../bin/pmake.exe
  cp pmake.e ../../../bin/pmake
!else
	copy pmake.exe ..\..\..\bin\pmake.exe
	copy pmake.e ..\..\..\bin\pmake
!endif
