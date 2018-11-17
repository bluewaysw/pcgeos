REM Main CUI Window

cvtpcx -f -G -t -x0 -y0 -w66 -h42 -m225 -ncuiAddress pcx\main_addressBook.pcx
cvtpcx -f -G -t -x0 -y0 -w71 -h50 -m225 -ncuiRead pcx\main_readEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w58 -h49 -m225 -ncuiWrite pcx\main_writeEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w68 -h52 -m225 -ncuiSend pcx\main_sendEmail.pcx

cvtpcx -f -G -t -x0 -y0 -w26 -h24 -m225 -ncuiBack pcx\back.pcx

cvtpcx -f -G -t -x0 -y0 -w27 -h25 -m225 -ncuiWriteNew pcx\write_writeNewEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w29 -h27 -m225 -ncuiEdit pcx\write_openUnfinishedEmail.pcx

cvtpcx -f -G -t -x0 -y0 -w31 -h29 -m225 -ncuiCheck pcx\read_checkForNewEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w22 -h29 -m225 -ncuiDiscard pcx\read_discardEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w28 -h27 -m225 -ncuiOpen pcx\read_openEmail.pcx

cvtpcx -f -G -t -x0 -y0 -w29 -h27 -m225 -ncuiEdit2 pcx\queue_openEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w35 -h15 -m225 -ncuiSend2 pcx\queue_sendEmail.pcx
cvtpcx -f -G -t -x0 -y0 -w39 -h29 -m225 -ncuiSendAll pcx\queue_sendAllEmail.pcx

cvtpcx -f -G -t -x0 -y0 -w35 -h16 -m225 -ncomposeSendLater pcx\writeMessage_sendLater.pcx

cvtpcx -f -G -t -x0 -y0 -w22 -h29 -m225 -ncuiDiscardUnf pcx\read_discardEmail.pcx

cvtpcx -f -G -t -x0 -y0 -w28 -h19 -m225 -ncuiSendTo pcx\sendto.pcx
cvtpcx -f -G -t -x0 -y0 -w22 -h29 -m225 -ncuiDiscardNew pcx\read_discardEmail.pcx

cvtpcx -f -G -t -x0 -y0 -w18 -h12 -m37  -nheaderTo pcx\writeMessage_sendTo.pcx

