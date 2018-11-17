[defcmd js-init {} {js}
{Usage:
}
{
    swi gpcbrow
    brk pset js::GeosDebugPrintf+4 {js-printf}
    brk pset gpcbrow::browserDisplayAlertDialog+4 {js-alert}
    brk pset gpcbrow::ErrorFunction+7 {js-error}
}]

[defcmd js-free-init {} {js}
{Usage:
}
{
    brk pset ansic::_Free+3 {js-free}
}]

[defsubr js-printf {} {
    echo -n {*** JS: }
    [pstring *buffer]
    return 0
}]

[defsubr js-alert {} {
    echo -n {*** JS Alert: }
    [pstring *msg]
    return 0
}]

[defsubr js-error {} {
    echo -n {*** JS Error: }
    [pstring *ErrorString]
    return 0
}]

[defsubr js-free {} {
    echo [frame function [frame next [frame top]]] [value fetch *(blockPtr-2) word]
    return 0
}]
