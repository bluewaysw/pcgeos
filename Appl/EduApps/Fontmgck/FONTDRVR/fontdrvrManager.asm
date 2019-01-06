include geos.def        ; standard macros

; externals
geos            segment library
  global GrCallFontDriver:far
geos            ends

; routines defined in this module
global FONT_GEN_PATH:far

        SetGeosConvention               ; set calling convention

FONTDRVR_TEXT   segment resource
FONT_GEN_PATH   proc far      _gs:word, _ch:word, _flags:word

        uses    ax,bx,cx,dx,di,ds
        .enter
                mov ax,16               ; DR_FONT_GEN_PATH
                mov bx,_gs              ; GState
                mov di,_gs
                mov cx,_flags           ; FontGenPathFlags
                mov dx,_ch              ; Character to generate
                call GrCallFontDriver   ; do it!
        .leave
	ret

FONT_GEN_PATH   endp
FONTDRVR_TEXT   ends

        SetDefaultConvention             ;restores calling conventions

