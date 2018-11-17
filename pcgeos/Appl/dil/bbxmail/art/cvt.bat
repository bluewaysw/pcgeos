cvtpcx -f -G -t -x1 -y1 -m13 -nMail PCX\mail.pcx
cvtpcx -f -G -t -z -x49 -y0 -dTM,TCGA -w48 -h30 -m13 -nTinyMail PCX\mail.pcx
cvtpcx -f -G -t -z -g -x49 -y0 -dTM,TCGA -m13 -nAttach PCX\ATTACH.PCX

REM New Message DB
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -ncomposeAttach PCX\ge014-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -ncomposeSend PCX\ge015-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -ncomposeSendLater PCX\ge042-8.pcx

REM Main Toolbar
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nsendReceiveTool PCX\ge001-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -ncreateNewMessageTool PCX\ge002-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nreadMessageTool PCX\ge003-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -neditMessageTool PCX\ge040-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nmoveMessageTool PCX\ge004-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nthrowAwayTool PCX\ge005-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nrecoverTool PCX\ge006-8.pcx

cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nreceiveTool PCX\ge044-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nsendTool PCX\ge045-8.pcx
cvtpcx -f -G -t -x0 -y0 -w30 -h30 -m13 -nmainPrintTool PCX\ge046-8.pcx

REM read message toolbar
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -naddressTool PCX\ge016-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nreplyTool PCX\ge017-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nreplyAllTool PCX\ge018-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nforwardTool PCX\ge019-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nprintTool PCX\ge020-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -npreviousTool PCX\ge021-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13 -nnextTool PCX\ge022-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13  -nreadThrowAwayTool PCX\ge041-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h20 -m13  -nreadRecoverTool PCX\ge043-8.pcx

REM folder icons
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ndraftsFolder PCX\ge007-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ninboxFolder PCX\ge008-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -noutboxFolder PCX\ge009-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -nsentFolder PCX\ge010-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ntrashFolder PCX\ge011-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ngenericFolder PCX\ge012-8.pcx

REM message icons
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nunreadNoAttach PCX\ge030-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nreadNoAttach PCX\ge031-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nunreadAttach PCX\ge032-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nreadAttach PCX\ge033-8.pcx

