
.SUFFIXES       : ec.geo gcm.geo .geo ec.exe .exe .com .vm .fnt .ldf \
		  .eobj .gobj .obj .lobj .asm .def .rdf .grdf .ui .uih \
		  .rasm .gp .temp .bin .c .goc .egc .gc _g.c _e.c .goh .h \
		  .lib .exp

SUFFS           = {eobj,obj}

# .PATH.h         : . t:\highc\inc t:\highc\inc\sys t:\src\include \
		    t:\src\lib\include t:\src\utils
.PATH.c         : .
# .PATH.lib       : t:\src\utils
.PATH.obj       : .

CCOM            = hc386
CCOMFLAGS       = -fsoft -g -DYYDEBUG -DLEXDEBUG -I..\include -IT:\phar51\includes -IT:\src\utils -IT:\src\include -Heol=10
LIBS            = ..\utils\dos\utils.lib ..\compat\dos\compat.lib T:\HIGHC\SMALL\HCNA.LIB T:\HIGHC\SMALL\HC386.LIB T:\HIGHC\SMALL\HCSOFT.LIB
LINK            = 386link
LINKFLAGS       = -cvsym -twocase
LINK            : .USE
	$(LINK) $(LINKFLAGS) -exe $(.TARGET) $(.ALLSRC:N*.GP:N*.LDF) -lib $(LIBS)

.c.obj          :
	$(CCOM) -c $(CCOMFLAGS) -o $(.TARGET)  $(.IMPSRC)


glue.exe        : glue.exp
	t:\tnt\bin\rebindb glue.exp
	t:\tnt\bin\cfig386 glue.exe -maxv 0
glue.exp        : $(OBJS) $(LIBS)
