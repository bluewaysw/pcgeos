defcommand print-dp {} {silly little function to print out DebugProcess calls} {
var t [sym find type DebugProcessFunctions]
echo DebugProcess([type emap [read-reg al] $t])
return 0
}