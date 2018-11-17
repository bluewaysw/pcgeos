cvtpcx -f -G -t -x1 -y1 -m13 -nMail INTPCX\ge000-8.pcx
cvtpcx -f -G -t -z -x49 -y0 -dTM,TCGA -w48 -h30 -m13 -nTinyMail INTPCX\ge000-8.pcx
cvtpcx -f -G -t -z -g -x49 -y0 -dTM,TCGA -m13 -nAttach INTPCX\ATTACH.PCX

REM New Message DB
cvtpcx -f -G -t -x0 -y0 -w40 -h30 -m13 -ncomposeSign INTPCX\ge013-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h30 -m13 -ncomposeAttach INTPCX\ge014-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h30 -m13 -ncomposeSend INTPCX\ge015-8.pcx

REM Main Toolbar
cvtpcx -f -G -t -x0 -y0 -w140 -h19 -m13 -nsendReceiveTool INTPCX\ge001-8.pcx
cvtpcx -f -G -t -x0 -y0 -w98 -h19 -m13 -ncreateNewMessageTool INTPCX\ge002-8.pcx
cvtpcx -f -G -t -x0 -y0 -w55 -h19 -m13 -nreadMessageTool INTPCX\ge003-8.pcx
cvtpcx -f -G -t -x0 -y0 -w48 -h19 -m13 -neditMessageTool INTPCX\ge003a-8.pcx
cvtpcx -f -G -t -x0 -y0 -w76 -h19 -m13 -nmoveMessageTool INTPCX\ge004-8.pcx
cvtpcx -f -G -t -x0 -y0 -w89 -h19 -m13 -nthrowAwayTool INTPCX\ge005-8.pcx
cvtpcx -f -G -t -x0 -y0 -w91 -h19 -m13 -nrecoverTool INTPCX\ge006-8.pcx

REM read message toolbar
cvtpcx -f -G -t -x0 -y0 -w50 -h30 -m13 -naddressTool INTPCX\ge016-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h30 -m13 -nreplyTool INTPCX\ge017-8.pcx
cvtpcx -f -G -t -x0 -y0 -w50 -h30 -m13 -nreplyAllTool INTPCX\ge018-8.pcx
cvtpcx -f -G -t -x0 -y0 -w52 -h30 -m13 -nforwardTool INTPCX\ge019-8.pcx
cvtpcx -f -G -t -x0 -y0 -w40 -h30 -m13 -nprintTool INTPCX\ge020-8.pcx
cvtpcx -f -G -t -x0 -y0 -w52 -h30 -m13 -npreviousTool INTPCX\ge021-8.pcx
cvtpcx -f -G -t -x0 -y0 -w52 -h30 -m13 -nnextTool INTPCX\ge022-8.pcx
cvtpcx -f -G -t -x0 -y0 -w46 -h30 -m13 -nreadThrowAwayTool INTPCX\ge005a-8.pcx
cvtpcx -f -G -t -x0 -y0 -w50 -h30 -m13 -nreadRecoverTool INTPCX\ge006a-8.pcx

REM folder icons
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ndraftsFolder INTPCX\ge007-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ninboxFolder INTPCX\ge008-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -noutboxFolder INTPCX\ge009-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -nsentFolder INTPCX\ge010-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ntrashFolder INTPCX\ge011-8.pcx
cvtpcx -f -G -g -t -x42 -y1 -w20 -h16 -m13 -ngenericFolder INTPCX\ge012-8.pcx

REM message icons
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nunreadNoAttach INTPCX\ge030-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nreadNoAttach INTPCX\ge031-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nunreadAttach INTPCX\ge032-8.pcx
cvtpcx -f -G -g -t -x0 -y0 -w25 -h12 -m13 -nreadAttach INTPCX\ge033-8.pcx

REM CUI icons
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUIDraftsFolder INTPCX\ge007-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUIInboxFolder INTPCX\ge008-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUIOutboxFolder INTPCX\ge009-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUISentFolder INTPCX\ge010-8.pcx
cvtpcx -f -G -g -t -x1 -y1 -w40 -h20 -m13 -nCUITrashFolder INTPCX\ge011-8.pcx

