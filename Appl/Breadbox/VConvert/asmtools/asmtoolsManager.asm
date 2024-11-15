include geos.def
include geode.def
include resource.def

include object.def
include graphics.def
include vm.def

UseLib ui.def
UseLib grobj.def

; public routines defined in this module
global MY_GB_CREATEGSTRINGTRANSFERFORMAT:far
global MY_GB_CREATEGROBJTRANSFERFORMAT:far

                SetGeosConvention               ; set calling convention

ASM_TEXT        segment resource

MY_GB_CREATEGSTRINGTRANSFERFORMAT proc far _body:optr, _vmf:word, _origin:fptr
                uses    bx,si,di,bp
                .enter

                movdw   bxsi,_body      ; optr of GrObjBody
                mov     di,mask MF_CALL
                mov     cx,_vmf
                mov     bp,{word}_origin
                mov     ax,MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT
                call    ObjMessage

                .leave
                ret
MY_GB_CREATEGSTRINGTRANSFERFORMAT endp

MY_GB_CREATEGROBJTRANSFERFORMAT proc far _body:optr, _vmf:word, _origin:fptr
                uses    bx,si,di,bp
                .enter

                movdw   bxsi,_body      ; optr of GrObjBody
                mov     di,mask MF_CALL
                mov     cx,_vmf
                mov     bp,{word}_origin
                mov     ax,MSG_GB_CREATE_GROBJ_TRANSFER_FORMAT
                call    ObjMessage

                .leave
                ret
MY_GB_CREATEGROBJTRANSFERFORMAT endp

ASM_TEXT        ends

                SetDefaultConvention             ;restore calling conventions

