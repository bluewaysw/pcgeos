obj_files = arch.obj compat.obj cond.obj customslib.obj dir.obj job.obj main.obj make.obj parse.obj rmt.obj rpc.obj str.obj suff.obj targ.obj var.obj

.c.obj
	wcc386 -i="$(WATCOM)/h" -i="$(WATCOM)/h/nt" -i="../../include" -i="../src/lib/include" -i="../src/lib/lst" -i="c:\g6_\pcgeos\include" -i="../customs" -fo=$*.obj $<

pmake.exe: $(obj_files)
  %write pmake.lnk NAME   $@
#  %write pmake.lnk FORMAT ELF
  %write pmake.lnk SYSTEM NT_WIN
  %write pmake.lnk RU CON
  %write pmake.lnk libfile ../lib/sprite/sprite.lib
  %write pmake.lnk libfile ../lib/lst/lst.lib
#	%write pmake.lnk library $(WATCOM)/lib386/linux/clib3r.lib
#	%write pmake.lnk library $(WATCOM)/lib386/linux/emu387.lib
#	%write pmake.lnk library $(WATCOM)/lib386/math387r.lib
  %write pmake.lnk library kernel32
  %write pmake.lnk FILE   {$(obj_files)}

  wlink  @pmake.lnk

install: pmake.exe .procedure
	cp pmake.exe ../../../bin/pmake
