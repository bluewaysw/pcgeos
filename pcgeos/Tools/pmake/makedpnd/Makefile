obj_files = fileargs.obj makedpnd.obj

.c.obj
	wcc386 -d_LINUX -i=/home/frehwagen/watcom-v2/lh -i=/home/frehwagen/watcom-v2/h -i=../../include -i=../src/lib/include -i../src/lib/lst -i=c:\g6_\pcgeos\include -i=../customs -fo=$*.obj $<

makedpnd.exe: $(obj_files)
  %write pmake.lnk NAME   $@
  %write pmake.lnk FORMAT ELF
  %write pmake.lnk libfile ../lib/sprite/sprite.lib
  %write pmake.lnk libfile ../lib/lst/lst.lib
	%write pmake.lnk library /home/frehwagen/watcom-v2/lib386/linux/clib3r.lib
	%write pmake.lnk library /home/frehwagen/watcom-v2/lib386/linux/emu387.lib
	%write pmake.lnk library /home/frehwagen/watcom-v2/lib386/math387r.lib
  %write pmake.lnk FILE   {$(obj_files)}

  wlink  @pmake.lnk

install: makedpnd.exe .procedure
	cp makedpnd.exe ../../../bin/makedpnd
