obj_files = buf.obj getopt.obj hash.obj list.obj option.obj strtod.obj strtol.obj sys.obj

.c.obj
	wcc386 -d_LINUX -i="$(WATCOM)/h" -i="$(WATCOM)/h/nt" -i="../../src/lib/include" -i="../../../include" -i="../../src/lib/lst" -i="c:\g6_\pcgeos\include" -fo=$*.obj $<

sprite.lib: $(obj_files)
  wlib $@ +buf.obj +getopt.obj +hash.obj +list.obj +option.obj +strtod.obj +strtol.obj +sys.obj
