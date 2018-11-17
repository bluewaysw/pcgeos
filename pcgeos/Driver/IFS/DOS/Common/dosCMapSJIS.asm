COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosCMapSJIS.asm

AUTHOR:		Gene Anderson, Jul 23, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/23/93		Initial revision


DESCRIPTION:
	Conversion tables for SJIS <-> Unicode.  Note that because neither
	character set is contiguous in the range that is being mapped,
	it is not reasonable to use a direct lookup table, as each would
	be about 40K in size.

	These tables were generated using:

	% unikanj -f2 -z16
	----------------------------------------
	section size = 16
	# sections = 1240
	maximum = 6464
	avg/max = 3000
	avg/scan = 2002
	# chars = 6355
	----------------------------------------

	$Id: dosCMapSJIS.asm,v 1.1 97/04/10 11:55:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

UnicodeToSJISTable	nptr \
	Section4e00Start,
	Section4e10Start,
	Section4e20Start,
	Section4e30Start,
	Section4e40Start,
	Section4e50Start,
	Section4e60Start,
	Section4e70Start,
	Section4e80Start,
	Section4e90Start,
	Section4ea0Start,
	Section4eb0Start,
	Section4ec0Start,
	Section4ed0Start,
	Section4ee0Start,
	Section4ef0Start,
	Section4f00Start,
	Section4f10Start,
	Section4f20Start,
	Section4f30Start,
	Section4f40Start,
	Section4f50Start,
	Section4f60Start,
	Section4f70Start,
	Section4f80Start,
	Section4f90Start,
	Section4fa0Start,
	Section4fb0Start,
	Section4fc0Start,
	Section4fd0Start,
	Section4fe0Start,
	Section4ff0Start,
	Section5000Start,
	Section5010Start,
	Section5020Start,
	Section5030Start,
	Section5040Start,
	Section5050Start,
	Section5060Start,
	Section5070Start,
	Section5080Start,
	Section5090Start,
	Section50a0Start,
	Section50b0Start,
	Section50c0Start,
	Section50d0Start,
	Section50e0Start,
	Section50f0Start,
	Section5100Start,
	Section5110Start,
	Section5120Start,
	Section5130Start,
	Section5140Start,
	Section5150Start,
	Section5160Start,
	Section5170Start,
	Section5180Start,
	Section5190Start,
	Section51a0Start,
	Section51b0Start,
	Section51c0Start,
	Section51d0Start,
	Section51e0Start,
	Section51f0Start,
	Section5200Start,
	Section5210Start,
	Section5220Start,
	Section5230Start,
	Section5240Start,
	Section5250Start,
	Section5260Start,
	Section5270Start,
	Section5280Start,
	Section5290Start,
	Section52a0Start,
	Section52b0Start,
	Section52c0Start,
	Section52d0Start,
	Section52e0Start,
	Section52f0Start,
	Section5300Start,
	Section5310Start,
	Section5320Start,
	Section5330Start,
	Section5340Start,
	Section5350Start,
	Section5360Start,
	Section5370Start,
	Section5380Start,
	Section5390Start,
	Section53a0Start,
	Section53b0Start,
	Section53c0Start,
	Section53d0Start,
	Section53e0Start,
	Section53f0Start,
	Section5400Start,
	Section5410Start,
	Section5420Start,
	Section5430Start,
	Section5440Start,
	Section5450Start,
	Section5460Start,
	Section5470Start,
	Section5480Start,
	Section5490Start,
	Section54a0Start,
	Section54b0Start,
	Section54c0Start,
	Section54d0Start,
	Section54e0Start,
	Section54f0Start,
	Section5500Start,
	Section5510Start,
	Section5520Start,
	Section5530Start,
	Section5540Start,
	Section5550Start,
	Section5560Start,
	Section5570Start,
	Section5580Start,
	Section5590Start,
	Section55a0Start,
	Section55b0Start,
	Section55c0Start,
	Section55d0Start,
	Section55e0Start,
	Section55f0Start,
	Section5600Start,
	Section5610Start,
	Section5620Start,
	Section5630Start,
	Section5640Start,
	Section5650Start,
	Section5660Start,
	Section5670Start,
	Section5680Start,
	Section5690Start,
	Section56a0Start,
	Section56b0Start,
	Section56c0Start,
	Section56d0Start,
	Section56e0Start,
	Section56f0Start,
	Section5700Start,
	Section5710Start,
	Section5720Start,
	Section5730Start,
	Section5740Start,
	Section5750Start,
	Section5760Start,
	Section5770Start,
	Section5780Start,
	Section5790Start,
	Section57a0Start,
	Section57b0Start,
	Section57c0Start,
	Section57d0Start,
	Section57e0Start,
	Section57f0Start,
	Section5800Start,
	Section5810Start,
	Section5820Start,
	Section5830Start,
	Section5840Start,
	Section5850Start,
	Section5860Start,
	Section5870Start,
	Section5880Start,
	Section5890Start,
	Section58a0Start,
	Section58b0Start,
	Section58c0Start,
	Section58d0Start,
	Section58e0Start,
	Section58f0Start,
	Section5900Start,
	Section5910Start,
	Section5920Start,
	Section5930Start,
	Section5940Start,
	Section5950Start,
	Section5960Start,
	Section5970Start,
	Section5980Start,
	Section5990Start,
	Section59a0Start,
	Section59b0Start,
	Section59c0Start,
	Section59d0Start,
	Section59e0Start,
	Section59f0Start,
	Section5a00Start,
	Section5a10Start,
	Section5a20Start,
	Section5a30Start,
	Section5a40Start,
	Section5a50Start,
	Section5a60Start,
	Section5a70Start,
	0,
	Section5a90Start,
	0,
	Section5ab0Start,
	Section5ac0Start,
	Section5ad0Start,
	Section5ae0Start,
	Section5af0Start,
	Section5b00Start,
	Section5b10Start,
	Section5b20Start,
	Section5b30Start,
	Section5b40Start,
	Section5b50Start,
	Section5b60Start,
	Section5b70Start,
	Section5b80Start,
	Section5b90Start,
	Section5ba0Start,
	Section5bb0Start,
	Section5bc0Start,
	Section5bd0Start,
	Section5be0Start,
	Section5bf0Start,
	Section5c00Start,
	Section5c10Start,
	Section5c20Start,
	Section5c30Start,
	Section5c40Start,
	Section5c50Start,
	Section5c60Start,
	Section5c70Start,
	Section5c80Start,
	Section5c90Start,
	Section5ca0Start,
	Section5cb0Start,
	Section5cc0Start,
	Section5cd0Start,
	Section5ce0Start,
	Section5cf0Start,
	Section5d00Start,
	Section5d10Start,
	Section5d20Start,
	0,
	Section5d40Start,
	Section5d50Start,
	Section5d60Start,
	Section5d70Start,
	Section5d80Start,
	Section5d90Start,
	Section5da0Start,
	Section5db0Start,
	Section5dc0Start,
	Section5dd0Start,
	Section5de0Start,
	Section5df0Start,
	Section5e00Start,
	Section5e10Start,
	Section5e20Start,
	Section5e30Start,
	Section5e40Start,
	Section5e50Start,
	Section5e60Start,
	Section5e70Start,
	Section5e80Start,
	Section5e90Start,
	Section5ea0Start,
	Section5eb0Start,
	Section5ec0Start,
	Section5ed0Start,
	Section5ee0Start,
	Section5ef0Start,
	Section5f00Start,
	Section5f10Start,
	Section5f20Start,
	Section5f30Start,
	Section5f40Start,
	Section5f50Start,
	Section5f60Start,
	Section5f70Start,
	Section5f80Start,
	Section5f90Start,
	Section5fa0Start,
	Section5fb0Start,
	Section5fc0Start,
	Section5fd0Start,
	Section5fe0Start,
	Section5ff0Start,
	Section6000Start,
	Section6010Start,
	Section6020Start,
	Section6030Start,
	Section6040Start,
	Section6050Start,
	Section6060Start,
	Section6070Start,
	Section6080Start,
	Section6090Start,
	Section60a0Start,
	Section60b0Start,
	Section60c0Start,
	Section60d0Start,
	Section60e0Start,
	Section60f0Start,
	Section6100Start,
	Section6110Start,
	Section6120Start,
	Section6130Start,
	Section6140Start,
	Section6150Start,
	Section6160Start,
	Section6170Start,
	Section6180Start,
	Section6190Start,
	Section61a0Start,
	Section61b0Start,
	Section61c0Start,
	Section61d0Start,
	Section61e0Start,
	Section61f0Start,
	Section6200Start,
	Section6210Start,
	Section6220Start,
	Section6230Start,
	Section6240Start,
	Section6250Start,
	Section6260Start,
	Section6270Start,
	Section6280Start,
	Section6290Start,
	Section62a0Start,
	Section62b0Start,
	Section62c0Start,
	Section62d0Start,
	Section62e0Start,
	Section62f0Start,
	Section6300Start,
	Section6310Start,
	Section6320Start,
	Section6330Start,
	Section6340Start,
	Section6350Start,
	Section6360Start,
	Section6370Start,
	Section6380Start,
	Section6390Start,
	Section63a0Start,
	Section63b0Start,
	Section63c0Start,
	Section63d0Start,
	Section63e0Start,
	Section63f0Start,
	Section6400Start,
	Section6410Start,
	Section6420Start,
	Section6430Start,
	Section6440Start,
	Section6450Start,
	Section6460Start,
	Section6470Start,
	Section6480Start,
	Section6490Start,
	Section64a0Start,
	Section64b0Start,
	Section64c0Start,
	Section64d0Start,
	Section64e0Start,
	Section64f0Start,
	Section6500Start,
	Section6510Start,
	Section6520Start,
	Section6530Start,
	Section6540Start,
	Section6550Start,
	Section6560Start,
	Section6570Start,
	Section6580Start,
	Section6590Start,
	Section65a0Start,
	Section65b0Start,
	Section65c0Start,
	Section65d0Start,
	Section65e0Start,
	Section65f0Start,
	Section6600Start,
	Section6610Start,
	Section6620Start,
	Section6630Start,
	Section6640Start,
	Section6650Start,
	Section6660Start,
	Section6670Start,
	Section6680Start,
	Section6690Start,
	Section66a0Start,
	Section66b0Start,
	Section66c0Start,
	Section66d0Start,
	Section66e0Start,
	Section66f0Start,
	Section6700Start,
	Section6710Start,
	Section6720Start,
	Section6730Start,
	Section6740Start,
	Section6750Start,
	Section6760Start,
	Section6770Start,
	Section6780Start,
	Section6790Start,
	Section67a0Start,
	Section67b0Start,
	Section67c0Start,
	Section67d0Start,
	Section67e0Start,
	Section67f0Start,
	Section6800Start,
	Section6810Start,
	Section6820Start,
	Section6830Start,
	Section6840Start,
	Section6850Start,
	Section6860Start,
	Section6870Start,
	Section6880Start,
	Section6890Start,
	Section68a0Start,
	Section68b0Start,
	Section68c0Start,
	Section68d0Start,
	Section68e0Start,
	Section68f0Start,
	Section6900Start,
	Section6910Start,
	Section6920Start,
	Section6930Start,
	Section6940Start,
	Section6950Start,
	Section6960Start,
	Section6970Start,
	Section6980Start,
	Section6990Start,
	Section69a0Start,
	Section69b0Start,
	Section69c0Start,
	Section69d0Start,
	Section69e0Start,
	Section69f0Start,
	Section6a00Start,
	Section6a10Start,
	Section6a20Start,
	Section6a30Start,
	Section6a40Start,
	Section6a50Start,
	Section6a60Start,
	Section6a70Start,
	Section6a80Start,
	Section6a90Start,
	Section6aa0Start,
	Section6ab0Start,
	Section6ac0Start,
	Section6ad0Start,
	Section6ae0Start,
	Section6af0Start,
	Section6b00Start,
	Section6b10Start,
	Section6b20Start,
	Section6b30Start,
	Section6b40Start,
	Section6b50Start,
	Section6b60Start,
	Section6b70Start,
	Section6b80Start,
	Section6b90Start,
	Section6ba0Start,
	Section6bb0Start,
	Section6bc0Start,
	Section6bd0Start,
	Section6be0Start,
	Section6bf0Start,
	Section6c00Start,
	Section6c10Start,
	Section6c20Start,
	Section6c30Start,
	Section6c40Start,
	Section6c50Start,
	Section6c60Start,
	Section6c70Start,
	Section6c80Start,
	Section6c90Start,
	Section6ca0Start,
	Section6cb0Start,
	Section6cc0Start,
	Section6cd0Start,
	Section6ce0Start,
	Section6cf0Start,
	Section6d00Start,
	Section6d10Start,
	Section6d20Start,
	Section6d30Start,
	Section6d40Start,
	Section6d50Start,
	Section6d60Start,
	Section6d70Start,
	Section6d80Start,
	Section6d90Start,
	Section6da0Start,
	Section6db0Start,
	Section6dc0Start,
	Section6dd0Start,
	Section6de0Start,
	Section6df0Start,
	Section6e00Start,
	Section6e10Start,
	Section6e20Start,
	Section6e30Start,
	Section6e40Start,
	Section6e50Start,
	Section6e60Start,
	Section6e70Start,
	Section6e80Start,
	Section6e90Start,
	Section6ea0Start,
	Section6eb0Start,
	Section6ec0Start,
	Section6ed0Start,
	Section6ee0Start,
	Section6ef0Start,
	Section6f00Start,
	Section6f10Start,
	Section6f20Start,
	Section6f30Start,
	Section6f40Start,
	Section6f50Start,
	Section6f60Start,
	Section6f70Start,
	Section6f80Start,
	Section6f90Start,
	Section6fa0Start,
	Section6fb0Start,
	Section6fc0Start,
	Section6fd0Start,
	Section6fe0Start,
	Section6ff0Start,
	Section7000Start,
	Section7010Start,
	Section7020Start,
	Section7030Start,
	Section7040Start,
	Section7050Start,
	Section7060Start,
	Section7070Start,
	Section7080Start,
	Section7090Start,
	Section70a0Start,
	Section70b0Start,
	Section70c0Start,
	Section70d0Start,
	0,
	Section70f0Start,
	Section7100Start,
	Section7110Start,
	Section7120Start,
	Section7130Start,
	Section7140Start,
	Section7150Start,
	Section7160Start,
	Section7170Start,
	Section7180Start,
	Section7190Start,
	Section71a0Start,
	Section71b0Start,
	Section71c0Start,
	Section71d0Start,
	Section71e0Start,
	Section71f0Start,
	Section7200Start,
	Section7210Start,
	Section7220Start,
	Section7230Start,
	Section7240Start,
	Section7250Start,
	Section7260Start,
	Section7270Start,
	Section7280Start,
	Section7290Start,
	Section72a0Start,
	Section72b0Start,
	Section72c0Start,
	Section72d0Start,
	Section72e0Start,
	Section72f0Start,
	Section7300Start,
	Section7310Start,
	Section7320Start,
	Section7330Start,
	Section7340Start,
	Section7350Start,
	Section7360Start,
	Section7370Start,
	Section7380Start,
	Section7390Start,
	Section73a0Start,
	Section73b0Start,
	Section73c0Start,
	Section73d0Start,
	Section73e0Start,
	Section73f0Start,
	Section7400Start,
	0,
	Section7420Start,
	Section7430Start,
	Section7440Start,
	Section7450Start,
	Section7460Start,
	Section7470Start,
	Section7480Start,
	Section7490Start,
	Section74a0Start,
	Section74b0Start,
	Section74c0Start,
	Section74d0Start,
	Section74e0Start,
	Section74f0Start,
	Section7500Start,
	Section7510Start,
	Section7520Start,
	Section7530Start,
	Section7540Start,
	Section7550Start,
	Section7560Start,
	Section7570Start,
	Section7580Start,
	Section7590Start,
	Section75a0Start,
	Section75b0Start,
	Section75c0Start,
	Section75d0Start,
	Section75e0Start,
	Section75f0Start,
	Section7600Start,
	Section7610Start,
	Section7620Start,
	Section7630Start,
	Section7640Start,
	Section7650Start,
	Section7660Start,
	Section7670Start,
	Section7680Start,
	Section7690Start,
	Section76a0Start,
	Section76b0Start,
	Section76c0Start,
	Section76d0Start,
	Section76e0Start,
	Section76f0Start,
	Section7700Start,
	Section7710Start,
	Section7720Start,
	Section7730Start,
	Section7740Start,
	Section7750Start,
	Section7760Start,
	Section7770Start,
	Section7780Start,
	Section7790Start,
	Section77a0Start,
	Section77b0Start,
	Section77c0Start,
	Section77d0Start,
	Section77e0Start,
	Section77f0Start,
	Section7800Start,
	Section7810Start,
	Section7820Start,
	Section7830Start,
	Section7840Start,
	Section7850Start,
	Section7860Start,
	Section7870Start,
	Section7880Start,
	Section7890Start,
	Section78a0Start,
	Section78b0Start,
	Section78c0Start,
	Section78d0Start,
	Section78e0Start,
	Section78f0Start,
	Section7900Start,
	Section7910Start,
	Section7920Start,
	Section7930Start,
	Section7940Start,
	Section7950Start,
	Section7960Start,
	Section7970Start,
	Section7980Start,
	Section7990Start,
	Section79a0Start,
	Section79b0Start,
	Section79c0Start,
	Section79d0Start,
	Section79e0Start,
	Section79f0Start,
	Section7a00Start,
	Section7a10Start,
	Section7a20Start,
	Section7a30Start,
	Section7a40Start,
	Section7a50Start,
	Section7a60Start,
	Section7a70Start,
	Section7a80Start,
	Section7a90Start,
	Section7aa0Start,
	Section7ab0Start,
	Section7ac0Start,
	Section7ad0Start,
	Section7ae0Start,
	Section7af0Start,
	Section7b00Start,
	Section7b10Start,
	Section7b20Start,
	Section7b30Start,
	Section7b40Start,
	Section7b50Start,
	Section7b60Start,
	Section7b70Start,
	Section7b80Start,
	Section7b90Start,
	Section7ba0Start,
	Section7bb0Start,
	Section7bc0Start,
	Section7bd0Start,
	Section7be0Start,
	Section7bf0Start,
	Section7c00Start,
	Section7c10Start,
	Section7c20Start,
	Section7c30Start,
	Section7c40Start,
	Section7c50Start,
	Section7c60Start,
	Section7c70Start,
	Section7c80Start,
	Section7c90Start,
	Section7ca0Start,
	Section7cb0Start,
	Section7cc0Start,
	Section7cd0Start,
	Section7ce0Start,
	Section7cf0Start,
	Section7d00Start,
	Section7d10Start,
	Section7d20Start,
	Section7d30Start,
	Section7d40Start,
	Section7d50Start,
	Section7d60Start,
	Section7d70Start,
	Section7d80Start,
	Section7d90Start,
	Section7da0Start,
	Section7db0Start,
	Section7dc0Start,
	Section7dd0Start,
	Section7de0Start,
	Section7df0Start,
	Section7e00Start,
	Section7e10Start,
	Section7e20Start,
	Section7e30Start,
	Section7e40Start,
	Section7e50Start,
	Section7e60Start,
	Section7e70Start,
	Section7e80Start,
	Section7e90Start,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	Section7f30Start,
	Section7f40Start,
	Section7f50Start,
	Section7f60Start,
	Section7f70Start,
	Section7f80Start,
	Section7f90Start,
	Section7fa0Start,
	Section7fb0Start,
	Section7fc0Start,
	Section7fd0Start,
	Section7fe0Start,
	Section7ff0Start,
	Section8000Start,
	Section8010Start,
	Section8020Start,
	Section8030Start,
	Section8040Start,
	Section8050Start,
	Section8060Start,
	Section8070Start,
	Section8080Start,
	Section8090Start,
	Section80a0Start,
	Section80b0Start,
	Section80c0Start,
	Section80d0Start,
	Section80e0Start,
	Section80f0Start,
	Section8100Start,
	Section8110Start,
	Section8120Start,
	Section8130Start,
	Section8140Start,
	Section8150Start,
	Section8160Start,
	Section8170Start,
	Section8180Start,
	Section8190Start,
	Section81a0Start,
	Section81b0Start,
	Section81c0Start,
	Section81d0Start,
	Section81e0Start,
	Section81f0Start,
	Section8200Start,
	Section8210Start,
	Section8220Start,
	Section8230Start,
	Section8240Start,
	Section8250Start,
	Section8260Start,
	Section8270Start,
	Section8280Start,
	Section8290Start,
	Section82a0Start,
	Section82b0Start,
	Section82c0Start,
	Section82d0Start,
	Section82e0Start,
	Section82f0Start,
	Section8300Start,
	Section8310Start,
	Section8320Start,
	Section8330Start,
	Section8340Start,
	Section8350Start,
	0,
	Section8370Start,
	Section8380Start,
	Section8390Start,
	Section83a0Start,
	Section83b0Start,
	Section83c0Start,
	Section83d0Start,
	Section83e0Start,
	Section83f0Start,
	Section8400Start,
	Section8410Start,
	Section8420Start,
	Section8430Start,
	Section8440Start,
	Section8450Start,
	Section8460Start,
	Section8470Start,
	Section8480Start,
	Section8490Start,
	Section84a0Start,
	Section84b0Start,
	Section84c0Start,
	Section84d0Start,
	Section84e0Start,
	Section84f0Start,
	Section8500Start,
	Section8510Start,
	Section8520Start,
	Section8530Start,
	Section8540Start,
	Section8550Start,
	Section8560Start,
	Section8570Start,
	Section8580Start,
	Section8590Start,
	Section85a0Start,
	Section85b0Start,
	Section85c0Start,
	Section85d0Start,
	Section85e0Start,
	Section85f0Start,
	Section8600Start,
	Section8610Start,
	Section8620Start,
	Section8630Start,
	Section8640Start,
	Section8650Start,
	Section8660Start,
	Section8670Start,
	Section8680Start,
	Section8690Start,
	Section86a0Start,
	Section86b0Start,
	Section86c0Start,
	Section86d0Start,
	Section86e0Start,
	Section86f0Start,
	Section8700Start,
	Section8710Start,
	Section8720Start,
	Section8730Start,
	Section8740Start,
	Section8750Start,
	Section8760Start,
	Section8770Start,
	Section8780Start,
	Section8790Start,
	Section87a0Start,
	Section87b0Start,
	Section87c0Start,
	Section87d0Start,
	Section87e0Start,
	Section87f0Start,
	Section8800Start,
	Section8810Start,
	Section8820Start,
	Section8830Start,
	Section8840Start,
	Section8850Start,
	Section8860Start,
	Section8870Start,
	Section8880Start,
	Section8890Start,
	Section88a0Start,
	Section88b0Start,
	Section88c0Start,
	Section88d0Start,
	Section88e0Start,
	Section88f0Start,
	Section8900Start,
	Section8910Start,
	Section8920Start,
	Section8930Start,
	Section8940Start,
	Section8950Start,
	Section8960Start,
	Section8970Start,
	Section8980Start,
	Section8990Start,
	Section89a0Start,
	Section89b0Start,
	Section89c0Start,
	Section89d0Start,
	Section89e0Start,
	Section89f0Start,
	Section8a00Start,
	Section8a10Start,
	Section8a20Start,
	Section8a30Start,
	Section8a40Start,
	Section8a50Start,
	Section8a60Start,
	Section8a70Start,
	Section8a80Start,
	Section8a90Start,
	Section8aa0Start,
	Section8ab0Start,
	Section8ac0Start,
	Section8ad0Start,
	Section8ae0Start,
	Section8af0Start,
	Section8b00Start,
	Section8b10Start,
	Section8b20Start,
	Section8b30Start,
	Section8b40Start,
	Section8b50Start,
	Section8b60Start,
	Section8b70Start,
	Section8b80Start,
	Section8b90Start,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	Section8c30Start,
	Section8c40Start,
	Section8c50Start,
	Section8c60Start,
	Section8c70Start,
	Section8c80Start,
	Section8c90Start,
	Section8ca0Start,
	Section8cb0Start,
	Section8cc0Start,
	Section8cd0Start,
	Section8ce0Start,
	Section8cf0Start,
	Section8d00Start,
	Section8d10Start,
	0,
	0,
	0,
	0,
	Section8d60Start,
	Section8d70Start,
	Section8d80Start,
	Section8d90Start,
	Section8da0Start,
	Section8db0Start,
	Section8dc0Start,
	Section8dd0Start,
	Section8de0Start,
	Section8df0Start,
	Section8e00Start,
	Section8e10Start,
	Section8e20Start,
	Section8e30Start,
	Section8e40Start,
	Section8e50Start,
	Section8e60Start,
	Section8e70Start,
	Section8e80Start,
	Section8e90Start,
	Section8ea0Start,
	Section8eb0Start,
	Section8ec0Start,
	Section8ed0Start,
	Section8ee0Start,
	Section8ef0Start,
	Section8f00Start,
	Section8f10Start,
	Section8f20Start,
	Section8f30Start,
	Section8f40Start,
	Section8f50Start,
	Section8f60Start,
	0,
	0,
	Section8f90Start,
	Section8fa0Start,
	Section8fb0Start,
	Section8fc0Start,
	Section8fd0Start,
	Section8fe0Start,
	Section8ff0Start,
	Section9000Start,
	Section9010Start,
	Section9020Start,
	Section9030Start,
	Section9040Start,
	Section9050Start,
	Section9060Start,
	Section9070Start,
	Section9080Start,
	Section9090Start,
	Section90a0Start,
	Section90b0Start,
	Section90c0Start,
	Section90d0Start,
	Section90e0Start,
	Section90f0Start,
	Section9100Start,
	Section9110Start,
	Section9120Start,
	Section9130Start,
	Section9140Start,
	Section9150Start,
	Section9160Start,
	Section9170Start,
	Section9180Start,
	Section9190Start,
	Section91a0Start,
	Section91b0Start,
	Section91c0Start,
	Section91d0Start,
	Section91e0Start,
	Section91f0Start,
	Section9200Start,
	Section9210Start,
	Section9220Start,
	Section9230Start,
	Section9240Start,
	Section9250Start,
	Section9260Start,
	Section9270Start,
	Section9280Start,
	Section9290Start,
	Section92a0Start,
	Section92b0Start,
	Section92c0Start,
	Section92d0Start,
	Section92e0Start,
	Section92f0Start,
	Section9300Start,
	Section9310Start,
	Section9320Start,
	Section9330Start,
	Section9340Start,
	Section9350Start,
	Section9360Start,
	Section9370Start,
	Section9380Start,
	Section9390Start,
	Section93a0Start,
	Section93b0Start,
	Section93c0Start,
	Section93d0Start,
	Section93e0Start,
	0,
	Section9400Start,
	Section9410Start,
	Section9420Start,
	Section9430Start,
	Section9440Start,
	Section9450Start,
	Section9460Start,
	Section9470Start,
	Section9480Start,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	Section9570Start,
	Section9580Start,
	Section9590Start,
	Section95a0Start,
	Section95b0Start,
	Section95c0Start,
	Section95d0Start,
	Section95e0Start,
	0,
	0,
	Section9610Start,
	Section9620Start,
	Section9630Start,
	Section9640Start,
	Section9650Start,
	Section9660Start,
	Section9670Start,
	Section9680Start,
	Section9690Start,
	Section96a0Start,
	Section96b0Start,
	Section96c0Start,
	Section96d0Start,
	Section96e0Start,
	Section96f0Start,
	Section9700Start,
	Section9710Start,
	Section9720Start,
	Section9730Start,
	Section9740Start,
	Section9750Start,
	Section9760Start,
	Section9770Start,
	Section9780Start,
	Section9790Start,
	Section97a0Start,
	Section97b0Start,
	Section97c0Start,
	Section97d0Start,
	Section97e0Start,
	Section97f0Start,
	Section9800Start,
	Section9810Start,
	Section9820Start,
	Section9830Start,
	Section9840Start,
	Section9850Start,
	Section9860Start,
	Section9870Start,
	0,
	0,
	Section98a0Start,
	Section98b0Start,
	Section98c0Start,
	Section98d0Start,
	Section98e0Start,
	Section98f0Start,
	Section9900Start,
	Section9910Start,
	Section9920Start,
	Section9930Start,
	Section9940Start,
	Section9950Start,
	0,
	0,
	0,
	Section9990Start,
	Section99a0Start,
	Section99b0Start,
	Section99c0Start,
	Section99d0Start,
	Section99e0Start,
	Section99f0Start,
	Section9a00Start,
	Section9a10Start,
	Section9a20Start,
	Section9a30Start,
	Section9a40Start,
	Section9a50Start,
	Section9a60Start,
	0,
	0,
	0,
	Section9aa0Start,
	Section9ab0Start,
	Section9ac0Start,
	Section9ad0Start,
	Section9ae0Start,
	Section9af0Start,
	Section9b00Start,
	Section9b10Start,
	Section9b20Start,
	Section9b30Start,
	Section9b40Start,
	Section9b50Start,
	Section9b60Start,
	Section9b70Start,
	Section9b80Start,
	Section9b90Start,
	Section9ba0Start,
	Section9bb0Start,
	Section9bc0Start,
	Section9bd0Start,
	Section9be0Start,
	Section9bf0Start,
	Section9c00Start,
	Section9c10Start,
	Section9c20Start,
	Section9c30Start,
	Section9c40Start,
	Section9c50Start,
	Section9c60Start,
	Section9c70Start,
	0,
	0,
	0,
	0,
	0,
	0,
	Section9ce0Start,
	Section9cf0Start,
	Section9d00Start,
	Section9d10Start,
	Section9d20Start,
	Section9d30Start,
	Section9d40Start,
	Section9d50Start,
	Section9d60Start,
	Section9d70Start,
	Section9d80Start,
	Section9d90Start,
	Section9da0Start,
	Section9db0Start,
	Section9dc0Start,
	Section9dd0Start,
	Section9de0Start,
	Section9df0Start,
	0,
	Section9e10Start,
	0,
	0,
	0,
	0,
	0,
	Section9e70Start,
	Section9e80Start,
	Section9e90Start,
	Section9ea0Start,
	Section9eb0Start,
	Section9ec0Start,
	Section9ed0Start,
	Section9ee0Start,
	Section9ef0Start,
	Section9f00Start,
	Section9f10Start,
	Section9f20Start,
	Section9f30Start,
	Section9f40Start,
	Section9f50Start,
	Section9f60Start,
	Section9f70Start,
	Section9f80Start,
	Section9f90Start,
	Section9fa0Start

CheckHack <(length UnicodeToSJISTable) eq (UNICODE_KANJI_END-UNICODE_KANJI_START+1)/16>


SJISMiscToUnicodeTable	Chars \
	C_IDEOGRAPHIC_SPACE,				;0x8140
	C_IDEOGRAPHIC_COMMA,
	C_IDEOGRAPHIC_PERIOD,
	C_FULLWIDTH_COMMA,
	C_FULLWIDTH_PERIOD,
	C_KATAKANA_MIDDLE_DOT,
	C_FULLWIDTH_COLON,
	C_FULLWIDTH_SEMICOLON,
	C_FULLWIDTH_QUESTION_MARK,			;0x8148
	C_FULLWIDTH_EXCLAMATION_MARK,
	C_KATAKANA_HIRAGANA_VOICED_SOUND_MARK,
	C_KATAKANA_HIRAGANA_SEMI_VOICED_SOUND_MARK,
	C_SPACING_ACUTE,
	C_FULLWIDTH_SPACING_GRAVE,
	C_SPACING_DIAERESIS,
	C_FULLWIDTH_SPACING_CIRCUMFLEX,
	C_FULLWIDTH_SPACING_MACRON,			;0x8150
	C_FULLWIDTH_SPACING_UNDERSCORE,
	C_KATAKANA_ITERATION_MARK,
	C_KATAKANA_VOICED_ITERATION_MARK,
	C_HIRAGANA_ITERATION_MARK,
	C_HIRAGANA_VOICED_ITERATION_MARK,
	C_DITTO_MARK,
	C_IDEOGRAPHIC_DITTO_MARK,
	C_IDEOGRAPHIC_ITERATION_MARK,			;0x8158
	C_IDEOGRAPHIC_CLOSING_MARK,
	C_IDEOGRAPHIC_NUMBER_ZERO,
	C_KATAKANA_HIRAGANA_PROLONGED_SOUND_MARK,
	C_QUOTATION_DASH,
	C_HYPHEN,
	C_FULLWIDTH_SLASH,
	C_FULLWIDTH_BACKSLASH,
	C_FULLWIDTH_SPACING_TILDE,			;0x8160
	C_DOUBLE_VERTICAL_BAR,
	C_FULLWIDTH_VERTICAL_BAR,
	C_HORIZONTAL_ELLIPSIS,
	C_TWO_DOT_LEADER,
	C_SINGLE_TURNED_COMMA_QUOTATION_MARK,
	C_SINGLE_COMMA_QUOTATION_MARK,
	C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,
	C_DOUBLE_COMMA_QUOTATION_MARK,			;0x8168
	C_FULLWIDTH_OPENING_PARENTHESIS,
	C_FULLWIDTH_CLOSING_PARENTHESIS,
	C_OPENING_TORTOISE_SHELL_BRACKET,
	C_CLOSING_TORTOISE_SHELL_BRACKET,
	C_FULLWIDTH_OPENING_SQUARE_BRACKET,
	C_FULLWIDTH_CLOSING_SQUARE_BRACKET,
	C_FULLWIDTH_OPENING_CURLY_BRACKET,
	C_FULLWIDTH_CLOSING_CURLY_BRACKET,		;0x8170
	C_OPENING_ANGLE_BRACKET,
	C_CLOSING_ANGLE_BRACKET,
	C_OPENING_DOUBLE_ANGLE_BRACKET,
	C_CLOSING_DOUBLE_ANGLE_BRACKET,
	C_OPENING_CORNER_BRACKET,
	C_CLOSING_CORNER_BRACKET,
	C_OPENING_WHITE_CORNER_BRACKET,
	C_CLOSING_WHITE_CORNER_BRACKET,			;0x8178
	C_OPENING_BLACK_LENTICULAR_BRACKET,
	C_CLOSING_BLACK_LENTICULAR_BRACKET,
	C_FULLWIDTH_PLUS_SIGN,
	C_FULLWIDTH_HYPHEN_MINUS,
	C_PLUS_OR_MINUS_SIGN,
	C_MULTIPLICATION_SIGN,
	0,
	C_DIVISION_SIGN,				;0x8180
	C_FULLWIDTH_EQUALS_SIGN,
	C_NOT_EQUAL_TO,
	C_FULLWIDTH_LESS_THAN_SIGN,
	C_FULLWIDTH_GREATER_THAN_SIGN,
	C_LESS_THAN_OVER_EQUAL_TO,
	C_GREATER_THAN_OVER_EQUAL_TO,
	C_INFINITY,
	C_THEREFORE,					;0x8188
	C_MALE_SIGN,
	C_FEMALE_SIGN,
	C_DEGREE_SIGN,
	C_PRIME,
	C_DOUBLE_PRIME,
	C_DEGREES_CENTIGRADE,
	C_FULLWIDTH_YEN_SIGN,
	C_FULLWIDTH_DOLLAR_SIGN,			;0x8190
	C_FULLWIDTH_CENT_SIGN,
	C_FULLWIDTH_POUND_SIGN,
	C_FULLWIDTH_PERCENT_SIGN,
	C_FULLWIDTH_NUMBER_SIGN,
	C_FULLWIDTH_AMPERSAND,
	C_FULLWIDTH_ASTERISK,
	C_FULLWIDTH_COMMERCIAL_AT,
	C_SECTION_SIGN,					;0x8198
	C_WHITE_STAR,
	C_BLACK_STAR,
	C_WHITE_CIRCLE,
	C_BLACK_CIRCLE,
	C_BULLSEYE,
	C_WHITE_DIAMOND,
	C_BLACK_DIAMOND,
	C_WHITE_SQUARE,					;0x81a0
	C_BLACK_SQUARE,
	C_WHITE_UP_POINTING_TRIANGLE,
	C_BLACK_UP_POINTING_TRIANGLE,
	C_WHITE_DOWN_POINTING_TRIANGLE,
	C_BLACK_DOWN_POINTING_TRIANGLE,
	C_REFERENCE_MARK,
	C_POSTAL_MARK,
	C_RIGHT_ARROW,					;0x81a8
	C_LEFT_ARROW,
	C_UP_ARROW,
	C_DOWN_ARROW,
	C_GETA_MARK,
	C_SJISEC_PARENTHESIZED_IDEOGRAPH_STOCK,		;** Toshiba
	C_SJISEC_PARENTHESIZED_IDEOGRAPH_HAVE,		;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_ONE,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_TWO,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_THREE,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_FOUR,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_FIVE,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_SIX,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_SEVEN,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_EIGHT,			;** Toshiba
	C_SJISEC_ROMAN_NUMERAL_NINE,			;** Toshiba
	C_ELEMENT_OF,					;0x81b8
	C_CONTAINS_AS_MEMBER,
	C_SUBSET_OF_OR_EQUAL_TO,
	C_SUPERSET_OF_OR_EQUAL_TO,
	C_SUBSET_OF,
	C_SUPERSET_OF,
	C_UNION,
	C_INTERSECTION,
	C_SQUARED_ML,					;** Toshiba
	C_SJISEC_SQUARED_MG,				;** Toshiba
	C_SJISEC_SQUARED_KG,				;** Toshiba
	C_SQUARED_MS,					;** Toshiba
	C_SJISEC_PARENTHESIZED_IDEOGRAPH_REPRESENT,	;** Toshiba
	C_SJISEC_SQUARED_KK,				;** Toshiba
	C_SJISEC_T_E_L_SYMBOL,				;** Toshiba
	C_SJISEC_NUMERO,				;** Toshiba
	C_LOGICAL_AND,					;0x81c8
	C_LOGICAL_OR,
	C_FULLWIDTH_NOT_SIGN,
	C_RIGHT_DOUBLE_ARROW,
	C_LEFT_RIGHT_DOUBLE_ARROW,
	C_FOR_ALL,
	C_THERE_EXISTS,
	C_SJISEC_SQUARED_AARU,				;** Toshiba
	C_SJISEC_SQUARED_DORU,				;** Toshiba
	C_SJISEC_SQUARED_TON,				;** Toshiba
	C_SJISEC_SQUARED_KIRO,				;** Toshiba
	C_SQUARED_KIROWATTO,				;** Toshiba
	C_SQUARED_KIROGURAMU,				;** Toshiba
	C_SJISEC_SQUARED_WATTO,				;** Toshiba
	C_SJISEC_SQUARED_RITTORU,			;** Toshiba
	C_SJISEC_SQUARED_PASSENTO,			;** Toshiba
	C_SJISEC_SQUARED_PEEZI,				;** Toshiba
	C_SJISEC_YARD,					;** Toshiba
	C_ANGLE,
	C_UP_TACK,
	C_ARC,
	C_PARTIAL_DIFFERENTIAL,
	C_NABLA,
	C_IDENTICAL_TO,
	C_APPROXIMATELY_EQUAL_TO_OR_THE_IMAGE_OF,	;0x81e0
	C_MUCH_LESS_THAN,
	C_MUCH_GREATER_THAN,
	C_SQUARE_ROOT,
	C_REVERSED_TILDE,
	C_PROPORTIONAL_TO,
	C_BECAUSE,
	C_INTEGRAL,
	C_DOUBLE_INTEGRAL,				;0x81e8
	C_SJISEC_PIANO_SHAPED_THINGY,			;** Toshiba
	C_INTEGRAL,					;** Toshiba
	C_SQUARE_ROOT,					;** Toshiba
	C_SJISEC_FORMS_TOP_BAR,				;** Toshiba
	C_SJISEC_FORMS_BOX_TOP,				;** Toshiba
	C_SJISEC_FORMS_BOX_SIDES,			;** Toshiba
	C_SJISEC_FORMS_BOX_BOTTOM,			;** Toshiba
	C_ANGSTROM_UNIT,				;0x81f0
	C_PER_MILLE_SIGN,
	C_SHARP,
	C_FLAT,
	C_EIGHTH_NOTE,
	C_DAGGER,
	C_DOUBLE_DAGGER,
	C_PARAGRAPH_SIGN,
	0,
	0,
	0,
	0,
	C_ENCLOSING_CIRCLE,
	0,
	0,
	0,

	C_SJISEC_LEFT_RESISTOR_WIRE,			;** Toshiba 0x8240
	C_SJISEC_LEFT_RESISTOR_NO_WIRE,			;** Toshiba
	C_FORMS_LIGHT_DOUBLE_DASH_HORIZONTAL,		;** Toshiba
	C_FORMS_HEAVY_DOUBLE_DASH_HORIZONTAL,		;** Toshiba
	C_DOT_OPERATOR,					;** Toshiba
	C_RATIO,					;** Toshiba
	C_WHITE_RIGHT_ARROW,				;** Toshiba
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_FULLWIDTH_DIGIT_ZERO,				;0x8250
	C_FULLWIDTH_DIGIT_ONE,
	C_FULLWIDTH_DIGIT_TWO,
	C_FULLWIDTH_DIGIT_THREE,
	C_FULLWIDTH_DIGIT_FOUR,
	C_FULLWIDTH_DIGIT_FIVE,
	C_FULLWIDTH_DIGIT_SIX,
	C_FULLWIDTH_DIGIT_SEVEN,
	C_FULLWIDTH_DIGIT_EIGHT,
	C_FULLWIDTH_DIGIT_NINE,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_A,		;0x8260
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_B,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_C,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_D,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_E,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_F,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_G,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_H,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_I,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_J,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_K,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_L,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_M,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_N,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_O,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_P,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Q,		;0x8270
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_R,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_S,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_T,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_U,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_V,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_W,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_X,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Y,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Z,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8280
	C_FULLWIDTH_LATIN_SMALL_LETTER_A,
	C_FULLWIDTH_LATIN_SMALL_LETTER_B,
	C_FULLWIDTH_LATIN_SMALL_LETTER_C,
	C_FULLWIDTH_LATIN_SMALL_LETTER_D,
	C_FULLWIDTH_LATIN_SMALL_LETTER_E,
	C_FULLWIDTH_LATIN_SMALL_LETTER_F,
	C_FULLWIDTH_LATIN_SMALL_LETTER_G,
	C_FULLWIDTH_LATIN_SMALL_LETTER_H,
	C_FULLWIDTH_LATIN_SMALL_LETTER_I,
	C_FULLWIDTH_LATIN_SMALL_LETTER_J,
	C_FULLWIDTH_LATIN_SMALL_LETTER_K,
	C_FULLWIDTH_LATIN_SMALL_LETTER_L,
	C_FULLWIDTH_LATIN_SMALL_LETTER_M,
	C_FULLWIDTH_LATIN_SMALL_LETTER_N,
	C_FULLWIDTH_LATIN_SMALL_LETTER_O,
	C_FULLWIDTH_LATIN_SMALL_LETTER_P,		;0x8290
	C_FULLWIDTH_LATIN_SMALL_LETTER_Q,
	C_FULLWIDTH_LATIN_SMALL_LETTER_R,
	C_FULLWIDTH_LATIN_SMALL_LETTER_S,
	C_FULLWIDTH_LATIN_SMALL_LETTER_T,
	C_FULLWIDTH_LATIN_SMALL_LETTER_U,
	C_FULLWIDTH_LATIN_SMALL_LETTER_V,
	C_FULLWIDTH_LATIN_SMALL_LETTER_W,
	C_FULLWIDTH_LATIN_SMALL_LETTER_X,
	C_FULLWIDTH_LATIN_SMALL_LETTER_Y,
	C_FULLWIDTH_LATIN_SMALL_LETTER_Z,
	0,
	0,
	0,
	0,
	C_HIRAGANA_LETTER_SMALL_A,
	C_HIRAGANA_LETTER_A,				;0x82a0
	C_HIRAGANA_LETTER_SMALL_I,
	C_HIRAGANA_LETTER_I,
	C_HIRAGANA_LETTER_SMALL_U,
	C_HIRAGANA_LETTER_U,
	C_HIRAGANA_LETTER_SMALL_E,
	C_HIRAGANA_LETTER_E,
	C_HIRAGANA_LETTER_SMALL_O,
	C_HIRAGANA_LETTER_O,
	C_HIRAGANA_LETTER_KA,
	C_HIRAGANA_LETTER_GA,
	C_HIRAGANA_LETTER_KI,
	C_HIRAGANA_LETTER_GI,
	C_HIRAGANA_LETTER_KU,
	C_HIRAGANA_LETTER_GU,
	C_HIRAGANA_LETTER_KE,
	C_HIRAGANA_LETTER_GE,				;0x82b0
	C_HIRAGANA_LETTER_KO,
	C_HIRAGANA_LETTER_GO,
	C_HIRAGANA_LETTER_SA,
	C_HIRAGANA_LETTER_ZA,
	C_HIRAGANA_LETTER_SI,
	C_HIRAGANA_LETTER_ZI,
	C_HIRAGANA_LETTER_SU,
	C_HIRAGANA_LETTER_ZU,
	C_HIRAGANA_LETTER_SE,
	C_HIRAGANA_LETTER_ZE,
	C_HIRAGANA_LETTER_SO,
	C_HIRAGANA_LETTER_ZO,
	C_HIRAGANA_LETTER_TA,
	C_HIRAGANA_LETTER_DA,
	C_HIRAGANA_LETTER_TI,
	C_HIRAGANA_LETTER_DI,				;0x82c0
	C_HIRAGANA_LETTER_SMALL_TU,
	C_HIRAGANA_LETTER_TU,
	C_HIRAGANA_LETTER_DU,
	C_HIRAGANA_LETTER_TE,
	C_HIRAGANA_LETTER_DE,
	C_HIRAGANA_LETTER_TO,
	C_HIRAGANA_LETTER_DO,
	C_HIRAGANA_LETTER_NA,
	C_HIRAGANA_LETTER_NI,
	C_HIRAGANA_LETTER_NU,
	C_HIRAGANA_LETTER_NE,
	C_HIRAGANA_LETTER_NO,
	C_HIRAGANA_LETTER_HA,
	C_HIRAGANA_LETTER_BA,
	C_HIRAGANA_LETTER_PA,
	C_HIRAGANA_LETTER_HI,				;0x82d0
	C_HIRAGANA_LETTER_BI,
	C_HIRAGANA_LETTER_PI,
	C_HIRAGANA_LETTER_HU,
	C_HIRAGANA_LETTER_BU,
	C_HIRAGANA_LETTER_PU,
	C_HIRAGANA_LETTER_HE,
	C_HIRAGANA_LETTER_BE,
	C_HIRAGANA_LETTER_PE,
	C_HIRAGANA_LETTER_HO,
	C_HIRAGANA_LETTER_BO,
	C_HIRAGANA_LETTER_PO,
	C_HIRAGANA_LETTER_MA,
	C_HIRAGANA_LETTER_MI,
	C_HIRAGANA_LETTER_MU,
	C_HIRAGANA_LETTER_ME,
	C_HIRAGANA_LETTER_MO,				;0x82e0
	C_HIRAGANA_LETTER_SMALL_YA,
	C_HIRAGANA_LETTER_YA,
	C_HIRAGANA_LETTER_SMALL_YU,
	C_HIRAGANA_LETTER_YU,
	C_HIRAGANA_LETTER_SMALL_YO,
	C_HIRAGANA_LETTER_YO,
	C_HIRAGANA_LETTER_RA,
	C_HIRAGANA_LETTER_RI,
	C_HIRAGANA_LETTER_RU,
	C_HIRAGANA_LETTER_RE,
	C_HIRAGANA_LETTER_RO,
	C_HIRAGANA_LETTER_SMALL_WA,
	C_HIRAGANA_LETTER_WA,
	C_HIRAGANA_LETTER_WI,
	C_HIRAGANA_LETTER_WE,
	C_HIRAGANA_LETTER_WO,				;0x82f0
	C_HIRAGANA_LETTER_N,
	C_SJISEC_UPPER_RIGHT_TO_LOWER_LEFT_FILL,	;** Toshiba
	C_SJISEC_UPPER_LEFT_TO_LOWER_RIGHT_FILL,	;** Toshiba
	C_SJISEC_VERTICAL_DASH_FILL,			;** Toshiba
	C_SJISEC_HORIZONTAL_DASH_FILL,			;** Toshiba
	C_LIGHT_SHADE,					;** Toshiba
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_KATAKANA_LETTER_SMALL_A,			;0x8340
	C_KATAKANA_LETTER_A,
	C_KATAKANA_LETTER_SMALL_I,
	C_KATAKANA_LETTER_I,
	C_KATAKANA_LETTER_SMALL_U,
	C_KATAKANA_LETTER_U,
	C_KATAKANA_LETTER_SMALL_E,
	C_KATAKANA_LETTER_E,
	C_KATAKANA_LETTER_SMALL_O,
	C_KATAKANA_LETTER_O,
	C_KATAKANA_LETTER_KA,
	C_KATAKANA_LETTER_GA,
	C_KATAKANA_LETTER_KI,
	C_KATAKANA_LETTER_GI,
	C_KATAKANA_LETTER_KU,
	C_KATAKANA_LETTER_GU,
	C_KATAKANA_LETTER_KE,				;0x8350
	C_KATAKANA_LETTER_GE,
	C_KATAKANA_LETTER_KO,
	C_KATAKANA_LETTER_GO,
	C_KATAKANA_LETTER_SA,
	C_KATAKANA_LETTER_ZA,
	C_KATAKANA_LETTER_SI,
	C_KATAKANA_LETTER_ZI,
	C_KATAKANA_LETTER_SU,				;0x8358
	C_KATAKANA_LETTER_ZU,
	C_KATAKANA_LETTER_SE,
	C_KATAKANA_LETTER_ZE,
	C_KATAKANA_LETTER_SO,
	C_KATAKANA_LETTER_ZO,
	C_KATAKANA_LETTER_TA,
	C_KATAKANA_LETTER_DA,
	C_KATAKANA_LETTER_TI,				;0x8360
	C_KATAKANA_LETTER_DI,
	C_KATAKANA_LETTER_SMALL_TU,
	C_KATAKANA_LETTER_TU,
	C_KATAKANA_LETTER_DU,
	C_KATAKANA_LETTER_TE,
	C_KATAKANA_LETTER_DE,
	C_KATAKANA_LETTER_TO,
	C_KATAKANA_LETTER_DO,				;0x8368
	C_KATAKANA_LETTER_NA,
	C_KATAKANA_LETTER_NI,
	C_KATAKANA_LETTER_NU,
	C_KATAKANA_LETTER_NE,
	C_KATAKANA_LETTER_NO,
	C_KATAKANA_LETTER_HA,
	C_KATAKANA_LETTER_BA,
	C_KATAKANA_LETTER_PA,				;0x8370
	C_KATAKANA_LETTER_HI,
	C_KATAKANA_LETTER_BI,
	C_KATAKANA_LETTER_PI,
	C_KATAKANA_LETTER_HU,
	C_KATAKANA_LETTER_BU,
	C_KATAKANA_LETTER_PU,
	C_KATAKANA_LETTER_HE,
	C_KATAKANA_LETTER_BE,				;0x8378
	C_KATAKANA_LETTER_PE,
	C_KATAKANA_LETTER_HO,
	C_KATAKANA_LETTER_BO,
	C_KATAKANA_LETTER_PO,
	C_KATAKANA_LETTER_MA,
	C_KATAKANA_LETTER_MI,
	0,
	C_KATAKANA_LETTER_MU,				;0x8380
	C_KATAKANA_LETTER_ME,
	C_KATAKANA_LETTER_MO,
	C_KATAKANA_LETTER_SMALL_YA,
	C_KATAKANA_LETTER_YA,
	C_KATAKANA_LETTER_SMALL_YU,
	C_KATAKANA_LETTER_YU,
	C_KATAKANA_LETTER_SMALL_YO,
	C_KATAKANA_LETTER_YO,				;0x8388
	C_KATAKANA_LETTER_RA,
	C_KATAKANA_LETTER_RI,
	C_KATAKANA_LETTER_RU,
	C_KATAKANA_LETTER_RE,
	C_KATAKANA_LETTER_RO,
	C_KATAKANA_LETTER_SMALL_WA,
	C_KATAKANA_LETTER_WA,
	C_KATAKANA_LETTER_WI,				;0x8390
	C_KATAKANA_LETTER_WE,
	C_KATAKANA_LETTER_WO,
	C_KATAKANA_LETTER_N,
	C_KATAKANA_LETTER_VU,
	C_KATAKANA_LETTER_SMALL_KA,
	C_KATAKANA_LETTER_SMALL_KE,
	0,
	0,						;0x8398
	0,
	0,
	0,
	0,
	0,
	0,
	C_GREEK_CAPITAL_LETTER_ALPHA,
	C_GREEK_CAPITAL_LETTER_BETA,			;0x83a0
	C_GREEK_CAPITAL_LETTER_GAMMA,
	C_GREEK_CAPITAL_LETTER_DELTA,
	C_GREEK_CAPITAL_LETTER_EPSILON,
	C_GREEK_CAPITAL_LETTER_ZETA,
	C_GREEK_CAPITAL_LETTER_ETA,
	C_GREEK_CAPITAL_LETTER_THETA,
	C_GREEK_CAPITAL_LETTER_IOTA,
	C_GREEK_CAPITAL_LETTER_KAPPA,			;0x83a8
	C_GREEK_CAPITAL_LETTER_LAMBDA,
	C_GREEK_CAPITAL_LETTER_MU,
	C_GREEK_CAPITAL_LETTER_NU,
	C_GREEK_CAPITAL_LETTER_XI,
	C_GREEK_CAPITAL_LETTER_OMICRON,
	C_GREEK_CAPITAL_LETTER_PI,
	C_GREEK_CAPITAL_LETTER_RHO,
	C_GREEK_CAPITAL_LETTER_SIGMA,			;0x83b0
	C_GREEK_CAPITAL_LETTER_TAU,
	C_GREEK_CAPITAL_LETTER_UPSILON,
	C_GREEK_CAPITAL_LETTER_PHI,
	C_GREEK_CAPITAL_LETTER_CHI,
	C_GREEK_CAPITAL_LETTER_PSI,
	C_GREEK_CAPITAL_LETTER_OMEGA,
	0,
	0,						;0x83b8
	0,
	0,
	0,
	0,
	0,
	C_SJISEC_UNKNOWN_1,				;** Toshiba
	C_GREEK_SMALL_LETTER_ALPHA,
	C_GREEK_SMALL_LETTER_BETA,			;0x83c0
	C_GREEK_SMALL_LETTER_GAMMA,
	C_GREEK_SMALL_LETTER_DELTA,
	C_GREEK_SMALL_LETTER_EPSILON,
	C_GREEK_SMALL_LETTER_ZETA,
	C_GREEK_SMALL_LETTER_ETA,
	C_GREEK_SMALL_LETTER_THETA,
	C_GREEK_SMALL_LETTER_IOTA,
	C_GREEK_SMALL_LETTER_KAPPA,			;0x83c8
	C_GREEK_SMALL_LETTER_LAMBDA,
	C_GREEK_SMALL_LETTER_MU,
	C_GREEK_SMALL_LETTER_NU,
	C_GREEK_SMALL_LETTER_XI,
	C_GREEK_SMALL_LETTER_OMICRON,
	C_GREEK_SMALL_LETTER_PI,
	C_GREEK_SMALL_LETTER_RHO,
	C_GREEK_SMALL_LETTER_SIGMA,			;0x83d0
	C_GREEK_SMALL_LETTER_TAU,
	C_GREEK_SMALL_LETTER_UPSILON,
	C_GREEK_SMALL_LETTER_PHI,
	C_GREEK_SMALL_LETTER_CHI,
	C_GREEK_SMALL_LETTER_PSI,
	C_GREEK_SMALL_LETTER_OMEGA,
	0,
	0,						;0x83d8
	0,
	0,
	0,
	0,
	C_SJISEC_UNKNOWN_2,				;** Toshiba
	0,
	0,
	0,						;0x83e0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x83e8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x83f0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x83f8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_CYRILLIC_CAPITAL_LETTER_A,			;0x8440
	C_CYRILLIC_CAPITAL_LETTER_BE,
	C_CYRILLIC_CAPITAL_LETTER_VE,
	C_CYRILLIC_CAPITAL_LETTER_GE,
	C_CYRILLIC_CAPITAL_LETTER_DE,
	C_CYRILLIC_CAPITAL_LETTER_IE,
	C_CYRILLIC_CAPITAL_LETTER_IO,
	C_CYRILLIC_CAPITAL_LETTER_ZHE,
	C_CYRILLIC_CAPITAL_LETTER_ZE,			;0x8448
	C_CYRILLIC_CAPITAL_LETTER_II,
	C_CYRILLIC_CAPITAL_LETTER_SHORT_II,
	C_CYRILLIC_CAPITAL_LETTER_KA,
	C_CYRILLIC_CAPITAL_LETTER_EL,
	C_CYRILLIC_CAPITAL_LETTER_EM,
	C_CYRILLIC_CAPITAL_LETTER_EN,
	C_CYRILLIC_CAPITAL_LETTER_O,
	C_CYRILLIC_CAPITAL_LETTER_PE,			;0x8450
	C_CYRILLIC_CAPITAL_LETTER_ER,
	C_CYRILLIC_CAPITAL_LETTER_ES,
	C_CYRILLIC_CAPITAL_LETTER_TE,
	C_CYRILLIC_CAPITAL_LETTER_U,
	C_CYRILLIC_CAPITAL_LETTER_EF,
	C_CYRILLIC_CAPITAL_LETTER_KHA,
	C_CYRILLIC_CAPITAL_LETTER_TSE,
	C_CYRILLIC_CAPITAL_LETTER_CHE,			;0x8458
	C_CYRILLIC_CAPITAL_LETTER_SHA,
	C_CYRILLIC_CAPITAL_LETTER_SHCHA,
	C_CYRILLIC_CAPITAL_LETTER_HARD_SIGN,
	C_CYRILLIC_CAPITAL_LETTER_YERI,
	C_CYRILLIC_CAPITAL_LETTER_SOFT_SIGN,
	C_CYRILLIC_CAPITAL_LETTER_REVERSED_E,
	C_CYRILLIC_CAPITAL_LETTER_IU,
	C_CYRILLIC_CAPITAL_LETTER_IA,			;0x8460
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8468
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_CYRILLIC_SMALL_LETTER_A,			;0x8470
	C_CYRILLIC_SMALL_LETTER_BE,
	C_CYRILLIC_SMALL_LETTER_VE,
	C_CYRILLIC_SMALL_LETTER_GE,
	C_CYRILLIC_SMALL_LETTER_DE,
	C_CYRILLIC_SMALL_LETTER_IE,
	C_CYRILLIC_SMALL_LETTER_IO,
	C_CYRILLIC_SMALL_LETTER_ZHE,
	C_CYRILLIC_SMALL_LETTER_ZE,			;0x8478
	C_CYRILLIC_SMALL_LETTER_II,
	C_CYRILLIC_SMALL_LETTER_SHORT_II,
	C_CYRILLIC_SMALL_LETTER_KA,
	C_CYRILLIC_SMALL_LETTER_EL,
	C_CYRILLIC_SMALL_LETTER_EM,
	C_CYRILLIC_SMALL_LETTER_EN,
	0,
	C_CYRILLIC_SMALL_LETTER_O,			;0x8480
	C_CYRILLIC_SMALL_LETTER_PE,
	C_CYRILLIC_SMALL_LETTER_ER,
	C_CYRILLIC_SMALL_LETTER_ES,
	C_CYRILLIC_SMALL_LETTER_TE,
	C_CYRILLIC_SMALL_LETTER_U,
	C_CYRILLIC_SMALL_LETTER_EF,
	C_CYRILLIC_SMALL_LETTER_KHA,
	C_CYRILLIC_SMALL_LETTER_TSE,			;0x8488
	C_CYRILLIC_SMALL_LETTER_CHE,
	C_CYRILLIC_SMALL_LETTER_SHA,
	C_CYRILLIC_SMALL_LETTER_SHCHA,
	C_CYRILLIC_SMALL_LETTER_HARD_SIGN,
	C_CYRILLIC_SMALL_LETTER_YERI,
	C_CYRILLIC_SMALL_LETTER_SOFT_SIGN,
	C_CYRILLIC_SMALL_LETTER_REVERSED_E,
	C_CYRILLIC_SMALL_LETTER_IU,			;0x8490
	C_CYRILLIC_SMALL_LETTER_IA,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8498
	0,
	0,
	0,
	0,
	0,
	0,
	C_FORMS_LIGHT_HORIZONTAL,
	C_FORMS_LIGHT_VERTICAL,				;0x84a0
	C_FORMS_LIGHT_DOWN_AND_RIGHT,
	C_FORMS_LIGHT_DOWN_AND_LEFT,
	C_FORMS_LIGHT_UP_AND_LEFT,
	C_FORMS_LIGHT_UP_AND_RIGHT,
	C_FORMS_LIGHT_VERTICAL_AND_RIGHT,
	C_FORMS_LIGHT_DOWN_AND_HORIZONTAL,
	C_FORMS_LIGHT_VERTICAL_AND_LEFT,
	C_FORMS_LIGHT_UP_AND_HORIZONTAL,		;0x84a8
	C_FORMS_LIGHT_VERTICAL_AND_HORIZONTAL,
	C_FORMS_HEAVY_HORIZONTAL,
	C_FORMS_HEAVY_VERTICAL,
	C_FORMS_HEAVY_DOWN_AND_RIGHT,
	C_FORMS_HEAVY_DOWN_AND_LEFT,
	C_FORMS_HEAVY_UP_AND_LEFT,
	C_FORMS_HEAVY_UP_AND_RIGHT,
	C_FORMS_HEAVY_VERTICAL_AND_RIGHT,		;0x84b0
	C_FORMS_HEAVY_DOWN_AND_HORIZONTAL,
	C_FORMS_HEAVY_VERTICAL_AND_LEFT,
	C_FORMS_HEAVY_UP_AND_HORIZONTAL,
	C_FORMS_HEAVY_VERTICAL_AND_HORIZONTAL,
	C_FORMS_VERTICAL_HEAVY_AND_RIGHT_LIGHT,
	C_FORMS_DOWN_LIGHT_AND_HORIZONTAL_HEAVY,
	C_FORMS_VERTICAL_HEAVY_AND_LEFT_LIGHT,
	C_FORMS_UP_LIGHT_AND_HORIZONTAL_HEAVY,		;0x84b8
	C_FORMS_VERTICAL_LIGHT_AND_HORIZONTAL_HEAVY,
	C_FORMS_VERTICAL_LIGHT_AND_RIGHT_HEAVY,
	C_FORMS_DOWN_HEAVY_AND_HORIZONTAL_LIGHT,
	C_FORMS_VERTICAL_LIGHT_AND_LEFT_HEAVY,
	C_FORMS_UP_HEAVY_AND_HORIZONTAL_LIGHT,
	C_FORMS_VERTICAL_HEAVY_AND_HORIZONTAL_LIGHT,
	C_WREATH_PRODUCT,				;** Toshiba
	0,						;0x84c0
	0,
	C_VERTICAL_ELLIPSIS,				;** Toshiba
	C_GLYPH_FOR_VERTICAL_TWO_DOT_LEADER,		;** Toshiba
	0,
	0,
	C_SJISEC_LOW_DOUBLE_PRIME_QUOTATION_MARK,	;** Toshiba
	C_SJISEC_REVERSED_DOUBLE_PRIME_QUOTATION_MARK,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_PARENTHESIS,	;** Toshiba 0x84c8
	C_GLYPH_FOR_VERTICAL_CLOSING_PARENTHESIS,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_TORTOISE_SHELL_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_CLOSING_TORTOISE_SHELL_BRACKET,	;** Toshiba
	C_SJISEC_GLYPH_FOR_VERTICAL_OPENING_SQUARE_BRACKET,	;** Toshiba
	C_SJISEC_GLYPH_FOR_VERTICAL_CLOSING_SQUARE_BRACKET,	;** Toshiba0
	C_GLYPH_FOR_VERTICAL_OPENING_CURLY_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_CLOSING_CURLY_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_ANGLE_BRACKET,	;** Toshiba 0x84d0
	C_GLYPH_FOR_VERTICAL_CLOSING_ANGLE_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_DOUBLE_ANGLE_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_CLOSING_DOUBLE_ANGLE_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_CORNER_BRACKET,		;** Toshiba
	C_GLYPH_FOR_VERTICAL_CLOSING_CORNER_BRACKET,		;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_WHITE_CORNER_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_CLOSING_WHITE_CORNER_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_OPENING_BLACK_LENTICULAR_BRACKET,	;** Toshiba
	C_GLYPH_FOR_VERTICAL_CLOSING_BLACK_LENTICULAR_BRACKET,	;** Toshiba
	C_SJISEC_CIRCLED_IND,				;** Toshiba
	C_SJISEC_CIRCLED_RIGHT_ARROW,			;** Toshiba
	C_SJISEC_CIRCLED_LEFT_RIGHT_ARROWS_TO_CENTER,	;** Toshiba
	C_SJISEC_CIRCLED_DEC,				;** Toshiba
	0,
	C_SJISEC_FORMS_DOUBLE_VERTICAL_BAR,		;** Toshiba
	C_SJISEC_UPPER_LEFT_TO_LOWER_RIGHT_BLOCKS,	;** Toshiba 0x84e0
	0,
	0,
	C_SJISEC_KATAKANA_LETTER_SMALL_A,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_I,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_U,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_E,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_O,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_YA,		;** Toshiba 0x84e8
	C_SJISEC_KATAKANA_LETTER_SMALL_YU,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_YO,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_TU,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_WA,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_KA,		;** Toshiba
	C_SJISEC_KATAKANA_LETTER_SMALL_KE,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_HORIZONTAL,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_VERTICAL,			;** Toshiba 0x84f0
	C_SJISEC_FORMS_LIGHT_UP_AND_RIGHT,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_DOWN_AND_RIGHT,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_DOWN_AND_LEFT,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_UP_AND_LEFT,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_UP_AND_HORIZONTAL,		;** Toshiba
	C_SJISEC_FORMS_LIGHT_VERTICAL_AND_RIGHT,	;** Toshiba
	C_SJISEC_FORMS_LIGHT_DOWN_AND_HORIZONTAL,	;** Toshiba
	C_SJISEC_FORMS_LIGHT_VERTICAL_AND_LEFT,		;** Toshiba 0x84f8
	C_SJISEC_FORMS_LIGHT_VERTICAL_AND_HORIZONTAL,	;** Toshiba
	C_SJISEC_FORMS_HEAVY_HORIZONTAL_ABOVE,		;** Toshiba
	C_SJISEC_FORMS_HEAVY_HORIZONTAL_BELOW,		;** Toshiba
	C_SJISEC_FORMS_HEAVY_HORIZONTAL_ABOVE_AND_BELOW,	;** Toshiba
	0,
	0,
	0,
	C_SJISEC_DOUBLE_HALFWIDTH_IDEOGRAPHIC_PERIOD,	;** Toshiba 0x8540
	C_SJISEC_DOUBLE_HALFWIDTH_OPENING_CORNER_BRACKET,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_CLOSING_CORNER_BRACKET,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_IDEOGRAPHIC_COMMA,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_MIDDLE_DOT,			;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_WO,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_A,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_I,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_U,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_E,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_O,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_YA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_YU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_YO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SMALL_TU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_PROLONGED_SOUND_MARK, ;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_A,	;** Toshiba 0x8550
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_I,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_U,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_E,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_O,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_KA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_KI,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_KE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_KU,	;** Toshiba 0x8558
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_KO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SI,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_SO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_TA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_TI,	;** Toshiba 0x8560
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_TU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_TE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_TO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_NA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_NI,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_NU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_NE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_NO,	;** Toshiba 0x8568
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_HA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_HI,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_HU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_HE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_HO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_MA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_MI,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_MU,	;** Toshiba 0x8570
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_ME,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_MO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_YA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_YU,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_YO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_RA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_RI,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_RU,	;** Toshiba 0x8578
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_RE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_RO,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_WA,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_LETTER_N,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_HIRAGANA_VOICED_SOUND_MARK, ;**
	C_SJISEC_DOUBLE_HALFWIDTH_KATAKANA_HIRAGANA_VOICED_SEMI_VOICED_SOUND_MARK, ;**
	0,
	C_SJISEC_DOUBLE_HALFWIDTH_THREE_HORIZONTAL_LINES,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_THREE_LINES_UPPER_RIGHT,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLACK_DOWN_POINTING_TRIANGLE,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_LEFT_RIGHT_ARROW,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BACKSLASH,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLACK_DIAMOND,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_WHITE_DIAMOND,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_1,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_2,		;** Toshiba 0x8588
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_3,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_4,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_5,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_6,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_7,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_8,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_BLOCK_9,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_ZERO,		;** Toshiba 0x8590
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_ONE,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_TWO,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_THREE,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_FOUR,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_FIVE,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_SIX,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_SEVEN,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_EIGHT,		;** Toshiba 0x8598
	C_SJISEC_DOUBLE_HALFWIDTH_DIGIT_NINE,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_UNKNOWN_1,		;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_IDEOGRAPH_MOON,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_IDEOGRAPH_SUN,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_DOWN_UP_TRIANGLES,	;** Toshiba
	C_SJISEC_DOUBLE_HALFWIDTH_RIGHT_LEFT_TRIANGLES,	;** Toshiba
	0,
	0,						;0x85a0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85a8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85b0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85b8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85c0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85c8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85d0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85d8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85e0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85e8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85f0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x85f8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8640
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8648
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8650
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8658
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8660
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8668
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8670
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8678
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8680
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8688
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8690
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x8698
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86a0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86a8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86b0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86b8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86c0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86c8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86d0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86d8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86e0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86e8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86f0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x86f8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_CIRCLED_DIGIT_ONE,				; (U+2460) 0x8740
	C_CIRCLED_DIGIT_TWO,				; (U+2461)
	C_CIRCLED_DIGIT_THREE,				; (U+2462)
	C_CIRCLED_DIGIT_FOUR,				; (U+2463)
	C_CIRCLED_DIGIT_FIVE,				; (U+2464)
	C_CIRCLED_DIGIT_SIX,				; (U+2465)
	C_CIRCLED_DIGIT_SEVEN,				; (U+2466)
	C_CIRCLED_DIGIT_EIGHT,				; (U+2467)
	C_CIRCLED_DIGIT_NINE,				; (U+2468) 0x8748
	C_CIRCLED_NUMBER_TEN,				; (U+2469)
	C_CIRCLED_NUMBER_ELEVEN,			; (U+246a)
	C_CIRCLED_NUMBER_TWELVE,			; (U+246b)
	C_CIRCLED_NUMBER_THIRTEEN,			; (U+246c)
	C_CIRCLED_NUMBER_FOURTEEN,			; (U+246d)
	C_CIRCLED_NUMBER_FIFTEEN,			; (U+246e)
	C_CIRCLED_NUMBER_SIXTEEN,			; (U+246f)
	C_CIRCLED_NUMBER_SEVENTEEN,			; (U+2470) 0x8750
	C_CIRCLED_NUMBER_EIGHTEEN,			; (U+2471)
	C_CIRCLED_NUMBER_NINETEEN,			; (U+2472)
	C_CIRCLED_NUMBER_TWENTY,			; (U+2473)
	C_ROMAN_NUMERAL_ONE,				; (U+2160)
	C_ROMAN_NUMERAL_TWO,				; (U+2161)
	C_ROMAN_NUMERAL_THREE,				; (U+2162)
	C_ROMAN_NUMERAL_FOUR,				; (U+2163)
	C_ROMAN_NUMERAL_FIVE,				; (U+2164) 0x8758
	C_ROMAN_NUMERAL_SIX,				; (U+2165)
	C_ROMAN_NUMERAL_SEVEN,				; (U+2166)
	C_ROMAN_NUMERAL_EIGHT,				; (U+2167)
	C_ROMAN_NUMERAL_NINE,				; (U+2168)
	C_ROMAN_NUMERAL_TEN,				; (U+2169)
	0,
	C_SQUARED_MIRI,					; (U+3349)
	C_SQUARED_KIRO,					; (U+3314) 0x8760
	C_SQUARED_SENTI,				; (U+3322)
	C_SQUARED_MEETORU,				; (U+334d)
	C_SQUARED_GURAMU,				; (U+3318)
	C_SQUARED_TON,					; (U+3327)
	C_SQUARED_AARU,					; (U+3303)
	C_SQUARED_HEKUTAARU,				; (U+3336)
	C_SQUARED_RITTORU,				; (U+3351)
	C_SQUARED_WATTO,				; (U+3357) 0x8768
	C_SQUARED_KARORII,				; (U+330d)
	C_SQUARED_DORU,					; (U+3326)
	C_SQUARED_SENTO,				; (U+3323)
	C_SQUARED_PAASENTO,				; (U+332b)
	C_SQUARED_MIRIBAARU,				; (U+334a)
	C_SQUARED_PEEZI,				; (U+333b)
	C_SQUARED_MM,					; (U+339c)
	C_SQUARED_CM,					; (U+339d) 0x8770
	C_SQUARED_KM,					; (U+339e)
	C_SQUARED_MG,					; (U+338e)
	C_SQUARED_KG,					; (U+338f)
	C_SQUARED_CC,					; (U+33c4)
	C_SQUARED_M_SQUARED,				; (U+33a1)
	0,
	0,
	0,						;         0x8778
	0,
	0,
	0,
	0,
	0,
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_HEISEI,	; (U+337b)
	0,
	C_REVERSED_DOUBLE_PRIME_QUOTATION_MARK,		; (U+301d) 0x8780
	C_LOW_DOUBLE_PRIME_QUOTATION_MARK,		; (U+301f)
	C_NUMERO,					; (U+2116)
	C_SQUARED_KK,					; (U+33cd)
	C_T_E_L_SYMBOL,					; (U+2121)
	C_CIRCLED_IDEOGRAPH_HIGH,			; (U+32a4)
	C_CIRCLED_IDEOGRAPH_CENTER,			; (U+32a5)
	C_CIRCLED_IDEOGRAPH_LOW,			; (U+32a6)
	C_CIRCLED_IDEOGRAPH_LEFT,			; (U+32a7) 0x8788
	C_CIRCLED_IDEOGRAPH_RIGHT,			; (U+32a8)
	C_PARENTHESIZED_IDEOGRAPH_STOCK,		; (U+3231)
	C_PARENTHESIZED_IDEOGRAPH_HAVE,			; (U+3232)
	C_PARENTHESIZED_IDEOGRAPH_REPRESENT,		; (U+3239)
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_MEIZI,	; (U+337e)
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_TAISYOU,	; (U+337d)
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_SYOUWA,	; (U+337c)
	C_APPROXIMATELY_EQUAL_TO_OR_THE_IMAGE_OF,	; (U+2252) 0x8790
	C_IDENTICAL_TO,					; (U+2261)
	C_INTEGRAL,					; (U+222b)
	C_CONTOUR_INTEGRAL,				; (U+222e)
	C_N_ARY_SUMMATION,				; (U+2211)
	C_SQUARE_ROOT,					; (U+221a)
	C_UP_TACK,					; (U+22a5)
	C_ANGLE,					; (U+2220)
	C_RIGHT_ANGLE,					; (U+221f) 0x8798
	C_RIGHT_TRIANGLE,				; (U+22bf)
	C_BECAUSE,					; (U+2235)
	C_INTERSECTION,					; (U+2229)
	C_UNION,					; (U+222a)
	0,
	0,
	0,
	0,						;0x87a0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87a8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87b0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87b8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87c0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87c8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87d0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87d8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87e0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87e8
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87f0
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						;0x87f8
	0,
	0,
	0,
	0,
	0,
	0,
	0

SJISKanjiToUnicodeTable	Chars \
	0,					; 0x8840
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					; 0x8850
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					; 0x8860
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					; 0x8870
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					; 0x8880
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					; 0x8890
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0					; 0x889e

Section4e90Start	label	Chars
	Chars C_KANJI_JIS_3021			; 0x889f (U+4e9c)
Section5510Start	label	Chars
	Chars C_KANJI_JIS_3022			; 0x88a0 (U+5516)
Section5a00Start	label	Chars
	Chars C_KANJI_JIS_3023			; 0x88a1 (U+5a03)
Section9630Start	label	Chars
	Chars C_KANJI_JIS_3024			; 0x88a2 (U+963f)
Section54c0Start	label	Chars
	Chars C_KANJI_JIS_3025			; 0x88a3 (U+54c0)
Section6110Start	label	Chars
	Chars C_KANJI_JIS_3026			; 0x88a4 (U+611b)
Section6320Start	label	Chars
	Chars C_KANJI_JIS_3027			; 0x88a5 (U+6328)
Section59f0Start	label	Chars
	Chars C_KANJI_JIS_3028			; 0x88a6 (U+59f6)
Section9020Start	label	Chars
	Chars C_KANJI_JIS_3029			; 0x88a7 (U+9022)
Section8470Start	label	Chars
	Chars C_KANJI_JIS_302A			; 0x88a8 (U+8475)
Section8310Start	label	Chars
	Chars C_KANJI_JIS_302B			; 0x88a9 (U+831c)
Section7a50Start	label	Chars
	Chars C_KANJI_JIS_302C			; 0x88aa (U+7a50)
Section60a0Start	label	Chars
	Chars C_KANJI_JIS_302D			; 0x88ab (U+60aa)
Section63e0Start	label	Chars
	Chars C_KANJI_JIS_302E			; 0x88ac (U+63e1)
Section6e20Start	label	Chars
	Chars C_KANJI_JIS_302F			; 0x88ad (U+6e25)
Section65e0Start	label	Chars
	Chars C_KANJI_JIS_3030			; 0x88ae (U+65ed)
Section8460Start	label	Chars
	Chars C_KANJI_JIS_3031			; 0x88af (U+8466)
Section82a0Start	label	Chars
	Chars C_KANJI_JIS_3032			; 0x88b0 (U+82a6)
Section9bf0Start	label	Chars
	Chars C_KANJI_JIS_3033			; 0x88b1 (U+9bf5)
Section6890Start	label	Chars
	Chars C_KANJI_JIS_3034			; 0x88b2 (U+6893)
Section5720Start	label	Chars
	Chars C_KANJI_JIS_3035			; 0x88b3 (U+5727)
Section65a0Start	label	Chars
	Chars C_KANJI_JIS_3036			; 0x88b4 (U+65a1)
Section6270Start	label	Chars
	Chars C_KANJI_JIS_3037			; 0x88b5 (U+6271)
Section5b90Start	label	Chars
	Chars C_KANJI_JIS_3038			; 0x88b6 (U+5b9b)
Section59d0Start	label	Chars
	Chars C_KANJI_JIS_3039			; 0x88b7 (U+59d0)
Section8670Start	label	Chars
	Chars C_KANJI_JIS_303A			; 0x88b8 (U+867b)
Section98f0Start	label	Chars
	Chars C_KANJI_JIS_303B			; 0x88b9 (U+98f4)
Section7d60Start	label	Chars
	Chars C_KANJI_JIS_303C			; 0x88ba (U+7d62)
Section7db0Start	label	Chars
	Chars C_KANJI_JIS_303D			; 0x88bb (U+7dbe)
Section9b80Start	label	Chars
	Chars C_KANJI_JIS_303E			; 0x88bc (U+9b8e)
Section6210Start	label	Chars
	Chars C_KANJI_JIS_303F			; 0x88bd (U+6216)
Section7c90Start	label	Chars
	Chars C_KANJI_JIS_3040			; 0x88be (U+7c9f)
Section88b0Start	label	Chars
	Chars C_KANJI_JIS_3041			; 0x88bf (U+88b7)
Section5b80Start	label	Chars
	Chars C_KANJI_JIS_3042			; 0x88c0 (U+5b89)
Section5eb0Start	label	Chars
	Chars C_KANJI_JIS_3043			; 0x88c1 (U+5eb5)
Section6300Start	label	Chars
	Chars C_KANJI_JIS_3044			; 0x88c2 (U+6309)
Section6690Start	label	Chars
	Chars C_KANJI_JIS_3045			; 0x88c3 (U+6697)
Section6840Start	label	Chars
	Chars C_KANJI_JIS_3046			; 0x88c4 (U+6848)
Section95c0Start	label	Chars
	Chars C_KANJI_JIS_3047			; 0x88c5 (U+95c7)
Section9780Start	label	Chars
	Chars C_KANJI_JIS_3048			; 0x88c6 (U+978d)
Section6740Start	label	Chars
	Chars C_KANJI_JIS_3049			; 0x88c7 (U+674f)
Section4ee0Start	label	Chars
	Chars C_KANJI_JIS_304A			; 0x88c8 (U+4ee5)
Section4f00Start	label	Chars
	Chars C_KANJI_JIS_304B			; 0x88c9 (U+4f0a)
Section4f40Start	label	Chars
	Chars C_KANJI_JIS_304C			; 0x88ca (U+4f4d)
Section4f90Start	label	Chars
	Chars C_KANJI_JIS_304D			; 0x88cb (U+4f9d)
Section5040Start	label	Chars
	Chars C_KANJI_JIS_304E			; 0x88cc (U+5049)
Section56f0Start	label	Chars
	Chars C_KANJI_JIS_304F			; 0x88cd (U+56f2)
Section5930Start	label	Chars
	Chars C_KANJI_JIS_3050			; 0x88ce (U+5937)
	Chars C_KANJI_JIS_3051			; 0x88cf (U+59d4)
	Chars C_KANJI_JIS_3052			; 0x88d0 (U+5a01)
Section5c00Start	label	Chars
	Chars C_KANJI_JIS_3053			; 0x88d1 (U+5c09)
Section60d0Start	label	Chars
	Chars C_KANJI_JIS_3054			; 0x88d2 (U+60df)
Section6100Start	label	Chars
	Chars C_KANJI_JIS_3055			; 0x88d3 (U+610f)
Section6170Start	label	Chars
	Chars C_KANJI_JIS_3056			; 0x88d4 (U+6170)
Section6610Start	label	Chars
	Chars C_KANJI_JIS_3057			; 0x88d5 (U+6613)
Section6900Start	label	Chars
	Chars C_KANJI_JIS_3058			; 0x88d6 (U+6905)
Section70b0Start	label	Chars
	Chars C_KANJI_JIS_3059			; 0x88d7 (U+70ba)
Section7540Start	label	Chars
	Chars C_KANJI_JIS_305A			; 0x88d8 (U+754f)
Section7570Start	label	Chars
	Chars C_KANJI_JIS_305B			; 0x88d9 (U+7570)
Section79f0Start	label	Chars
	Chars C_KANJI_JIS_305C			; 0x88da (U+79fb)
Section7da0Start	label	Chars
	Chars C_KANJI_JIS_305D			; 0x88db (U+7dad)
Section7de0Start	label	Chars
	Chars C_KANJI_JIS_305E			; 0x88dc (U+7def)
Section80c0Start	label	Chars
	Chars C_KANJI_JIS_305F			; 0x88dd (U+80c3)
Section8400Start	label	Chars
	Chars C_KANJI_JIS_3060			; 0x88de (U+840e)
Section8860Start	label	Chars
	Chars C_KANJI_JIS_3061			; 0x88df (U+8863)
Section8b00Start	label	Chars
	Chars C_KANJI_JIS_3062			; 0x88e0 (U+8b02)
Section9050Start	label	Chars
	Chars C_KANJI_JIS_3063			; 0x88e1 (U+9055)
Section9070Start	label	Chars
	Chars C_KANJI_JIS_3064			; 0x88e2 (U+907a)
Section5330Start	label	Chars
	Chars C_KANJI_JIS_3065			; 0x88e3 (U+533b)
	Chars C_KANJI_JIS_3066			; 0x88e4 (U+4e95)
Section4ea0Start	label	Chars
	Chars C_KANJI_JIS_3067			; 0x88e5 (U+4ea5)
Section57d0Start	label	Chars
	Chars C_KANJI_JIS_3068			; 0x88e6 (U+57df)
Section80b0Start	label	Chars
	Chars C_KANJI_JIS_3069			; 0x88e7 (U+80b2)
Section90c0Start	label	Chars
	Chars C_KANJI_JIS_306A			; 0x88e8 (U+90c1)
Section78e0Start	label	Chars
	Chars C_KANJI_JIS_306B			; 0x88e9 (U+78ef)
Section4e00Start	label	Chars
	Chars C_KANJI_JIS_306C			; 0x88ea (U+4e00)
Section58f0Start	label	Chars
	Chars C_KANJI_JIS_306D			; 0x88eb (U+58f1)
Section6ea0Start	label	Chars
	Chars C_KANJI_JIS_306E			; 0x88ec (U+6ea2)
Section9030Start	label	Chars
	Chars C_KANJI_JIS_306F			; 0x88ed (U+9038)
Section7a30Start	label	Chars
	Chars C_KANJI_JIS_3070			; 0x88ee (U+7a32)
Section8320Start	label	Chars
	Chars C_KANJI_JIS_3071			; 0x88ef (U+8328)
Section8280Start	label	Chars
	Chars C_KANJI_JIS_3072			; 0x88f0 (U+828b)
Section9c20Start	label	Chars
	Chars C_KANJI_JIS_3073			; 0x88f1 (U+9c2f)
Section5140Start	label	Chars
	Chars C_KANJI_JIS_3074			; 0x88f2 (U+5141)
Section5370Start	label	Chars
	Chars C_KANJI_JIS_3075			; 0x88f3 (U+5370)
Section54b0Start	label	Chars
	Chars C_KANJI_JIS_3076			; 0x88f4 (U+54bd)
Section54e0Start	label	Chars
	Chars C_KANJI_JIS_3077			; 0x88f5 (U+54e1)
Section56e0Start	label	Chars
	Chars C_KANJI_JIS_3078			; 0x88f6 (U+56e0)
	Chars C_KANJI_JIS_3079			; 0x88f7 (U+59fb)
Section5f10Start	label	Chars
	Chars C_KANJI_JIS_307A			; 0x88f8 (U+5f15)
	Chars C_KANJI_JIS_307B			; 0x88f9 (U+98f2)
Section6de0Start	label	Chars
	Chars C_KANJI_JIS_307C			; 0x88fa (U+6deb)
Section80e0Start	label	Chars
	Chars C_KANJI_JIS_307D			; 0x88fb (U+80e4)
Section8520Start	label	Chars
	Chars C_KANJI_JIS_307E			; 0x88fc (U+852d)
	Chars 0					; 0x88fd
	Chars 0					; 0x88fe
	Chars 0					; 0x88ff
Section9660Start	label	Chars

	Chars C_KANJI_JIS_3121			; 0x8940 (U+9662)
Section9670Start	label	Chars
	Chars C_KANJI_JIS_3122			; 0x8941 (U+9670)
Section96a0Start	label	Chars
	Chars C_KANJI_JIS_3123			; 0x8942 (U+96a0)
Section97f0Start	label	Chars
	Chars C_KANJI_JIS_3124			; 0x8943 (U+97fb)
Section5400Start	label	Chars
	Chars C_KANJI_JIS_3125			; 0x8944 (U+540b)
Section53f0Start	label	Chars
	Chars C_KANJI_JIS_3126			; 0x8945 (U+53f3)
	Chars C_KANJI_JIS_3127			; 0x8946 (U+5b87)
Section70c0Start	label	Chars
	Chars C_KANJI_JIS_3128			; 0x8947 (U+70cf)
Section7fb0Start	label	Chars
	Chars C_KANJI_JIS_3129			; 0x8948 (U+7fbd)
Section8fc0Start	label	Chars
	Chars C_KANJI_JIS_312A			; 0x8949 (U+8fc2)
Section96e0Start	label	Chars
	Chars C_KANJI_JIS_312B			; 0x894a (U+96e8)
Section5360Start	label	Chars
	Chars C_KANJI_JIS_312C			; 0x894b (U+536f)
Section9d50Start	label	Chars
	Chars C_KANJI_JIS_312D			; 0x894c (U+9d5c)
Section7ab0Start	label	Chars
	Chars C_KANJI_JIS_312E			; 0x894d (U+7aba)
Section4e10Start	label	Chars
	Chars C_KANJI_JIS_312F			; 0x894e (U+4e11)
Section7890Start	label	Chars
	Chars C_KANJI_JIS_3130			; 0x894f (U+7893)
Section81f0Start	label	Chars
	Chars C_KANJI_JIS_3131			; 0x8950 (U+81fc)
	Chars C_KANJI_JIS_3132			; 0x8951 (U+6e26)
Section5610Start	label	Chars
	Chars C_KANJI_JIS_3133			; 0x8952 (U+5618)
Section5500Start	label	Chars
	Chars C_KANJI_JIS_3134			; 0x8953 (U+5504)
Section6b10Start	label	Chars
	Chars C_KANJI_JIS_3135			; 0x8954 (U+6b1d)
Section8510Start	label	Chars
	Chars C_KANJI_JIS_3136			; 0x8955 (U+851a)
Section9c30Start	label	Chars
	Chars C_KANJI_JIS_3137			; 0x8956 (U+9c3b)
Section59e0Start	label	Chars
	Chars C_KANJI_JIS_3138			; 0x8957 (U+59e5)
Section53a0Start	label	Chars
	Chars C_KANJI_JIS_3139			; 0x8958 (U+53a9)
Section6d60Start	label	Chars
	Chars C_KANJI_JIS_313A			; 0x8959 (U+6d66)
Section74d0Start	label	Chars
	Chars C_KANJI_JIS_313B			; 0x895a (U+74dc)
Section9580Start	label	Chars
	Chars C_KANJI_JIS_313C			; 0x895b (U+958f)
Section5640Start	label	Chars
	Chars C_KANJI_JIS_313D			; 0x895c (U+5642)
	Chars C_KANJI_JIS_313E			; 0x895d (U+4e91)
Section9040Start	label	Chars
	Chars C_KANJI_JIS_313F			; 0x895e (U+904b)
Section96f0Start	label	Chars
	Chars C_KANJI_JIS_3140			; 0x895f (U+96f2)
Section8340Start	label	Chars
	Chars C_KANJI_JIS_3141			; 0x8960 (U+834f)
Section9900Start	label	Chars
	Chars C_KANJI_JIS_3142			; 0x8961 (U+990c)
Section53e0Start	label	Chars
	Chars C_KANJI_JIS_3143			; 0x8962 (U+53e1)
Section55b0Start	label	Chars
	Chars C_KANJI_JIS_3144			; 0x8963 (U+55b6)
Section5b30Start	label	Chars
	Chars C_KANJI_JIS_3145			; 0x8964 (U+5b30)
Section5f70Start	label	Chars
	Chars C_KANJI_JIS_3146			; 0x8965 (U+5f71)
Section6620Start	label	Chars
	Chars C_KANJI_JIS_3147			; 0x8966 (U+6620)
Section66f0Start	label	Chars
	Chars C_KANJI_JIS_3148			; 0x8967 (U+66f3)
Section6800Start	label	Chars
	Chars C_KANJI_JIS_3149			; 0x8968 (U+6804)
Section6c30Start	label	Chars
	Chars C_KANJI_JIS_314A			; 0x8969 (U+6c38)
Section6cf0Start	label	Chars
	Chars C_KANJI_JIS_314B			; 0x896a (U+6cf3)
Section6d20Start	label	Chars
	Chars C_KANJI_JIS_314C			; 0x896b (U+6d29)
Section7450Start	label	Chars
	Chars C_KANJI_JIS_314D			; 0x896c (U+745b)
Section76c0Start	label	Chars
	Chars C_KANJI_JIS_314E			; 0x896d (U+76c8)
Section7a40Start	label	Chars
	Chars C_KANJI_JIS_314F			; 0x896e (U+7a4e)
Section9830Start	label	Chars
	Chars C_KANJI_JIS_3150			; 0x896f (U+9834)
Section82f0Start	label	Chars
	Chars C_KANJI_JIS_3151			; 0x8970 (U+82f1)
Section8850Start	label	Chars
	Chars C_KANJI_JIS_3152			; 0x8971 (U+885b)
Section8a60Start	label	Chars
	Chars C_KANJI_JIS_3153			; 0x8972 (U+8a60)
Section92e0Start	label	Chars
	Chars C_KANJI_JIS_3154			; 0x8973 (U+92ed)
Section6db0Start	label	Chars
	Chars C_KANJI_JIS_3155			; 0x8974 (U+6db2)
Section75a0Start	label	Chars
	Chars C_KANJI_JIS_3156			; 0x8975 (U+75ab)
	Chars C_KANJI_JIS_3157			; 0x8976 (U+76ca)
Section99c0Start	label	Chars
	Chars C_KANJI_JIS_3158			; 0x8977 (U+99c5)
	Chars C_KANJI_JIS_3159			; 0x8978 (U+60a6)
	Chars C_KANJI_JIS_315A			; 0x8979 (U+8b01)
Section8d80Start	label	Chars
	Chars C_KANJI_JIS_315B			; 0x897a (U+8d8a)
Section95b0Start	label	Chars
	Chars C_KANJI_JIS_315C			; 0x897b (U+95b2)
Section6980Start	label	Chars
	Chars C_KANJI_JIS_315D			; 0x897c (U+698e)
	Chars C_KANJI_JIS_315E			; 0x897d (U+53ad)
Section5180Start	label	Chars
	Chars C_KANJI_JIS_315F			; 0x897e (U+5186)
	Chars 0					; 0x897f
Section5710Start	label	Chars
	Chars C_KANJI_JIS_3160			; 0x8980 (U+5712)
Section5830Start	label	Chars
	Chars C_KANJI_JIS_3161			; 0x8981 (U+5830)
Section5940Start	label	Chars
	Chars C_KANJI_JIS_3162			; 0x8982 (U+5944)
Section5bb0Start	label	Chars
	Chars C_KANJI_JIS_3163			; 0x8983 (U+5bb4)
Section5ef0Start	label	Chars
	Chars C_KANJI_JIS_3164			; 0x8984 (U+5ef6)
Section6020Start	label	Chars
	Chars C_KANJI_JIS_3165			; 0x8985 (U+6028)
Section63a0Start	label	Chars
	Chars C_KANJI_JIS_3166			; 0x8986 (U+63a9)
Section63f0Start	label	Chars
	Chars C_KANJI_JIS_3167			; 0x8987 (U+63f4)
Section6cb0Start	label	Chars
	Chars C_KANJI_JIS_3168			; 0x8988 (U+6cbf)
Section6f10Start	label	Chars
	Chars C_KANJI_JIS_3169			; 0x8989 (U+6f14)
Section7080Start	label	Chars
	Chars C_KANJI_JIS_316A			; 0x898a (U+708e)
Section7110Start	label	Chars
	Chars C_KANJI_JIS_316B			; 0x898b (U+7114)
Section7150Start	label	Chars
	Chars C_KANJI_JIS_316C			; 0x898c (U+7159)
Section71d0Start	label	Chars
	Chars C_KANJI_JIS_316D			; 0x898d (U+71d5)
Section7330Start	label	Chars
	Chars C_KANJI_JIS_316E			; 0x898e (U+733f)
Section7e00Start	label	Chars
	Chars C_KANJI_JIS_316F			; 0x898f (U+7e01)
Section8270Start	label	Chars
	Chars C_KANJI_JIS_3170			; 0x8990 (U+8276)
Section82d0Start	label	Chars
	Chars C_KANJI_JIS_3171			; 0x8991 (U+82d1)
Section8590Start	label	Chars
	Chars C_KANJI_JIS_3172			; 0x8992 (U+8597)
Section9060Start	label	Chars
	Chars C_KANJI_JIS_3173			; 0x8993 (U+9060)
Section9250Start	label	Chars
	Chars C_KANJI_JIS_3174			; 0x8994 (U+925b)
Section9d10Start	label	Chars
	Chars C_KANJI_JIS_3175			; 0x8995 (U+9d1b)
Section5860Start	label	Chars
	Chars C_KANJI_JIS_3176			; 0x8996 (U+5869)
Section65b0Start	label	Chars
	Chars C_KANJI_JIS_3177			; 0x8997 (U+65bc)
Section6c50Start	label	Chars
	Chars C_KANJI_JIS_3178			; 0x8998 (U+6c5a)
Section7520Start	label	Chars
	Chars C_KANJI_JIS_3179			; 0x8999 (U+7525)
Section51f0Start	label	Chars
	Chars C_KANJI_JIS_317A			; 0x899a (U+51f9)
Section5920Start	label	Chars
	Chars C_KANJI_JIS_317B			; 0x899b (U+592e)
Section5960Start	label	Chars
	Chars C_KANJI_JIS_317C			; 0x899c (U+5965)
Section5f80Start	label	Chars
	Chars C_KANJI_JIS_317D			; 0x899d (U+5f80)
Section5fd0Start	label	Chars
	Chars C_KANJI_JIS_317E			; 0x899e (U+5fdc)
Section62b0Start	label	Chars
	Chars C_KANJI_JIS_3221			; 0x899f (U+62bc)
Section65f0Start	label	Chars
	Chars C_KANJI_JIS_3222			; 0x89a0 (U+65fa)
Section6a20Start	label	Chars
	Chars C_KANJI_JIS_3223			; 0x89a1 (U+6a2a)
Section6b20Start	label	Chars
	Chars C_KANJI_JIS_3224			; 0x89a2 (U+6b27)
Section6bb0Start	label	Chars
	Chars C_KANJI_JIS_3225			; 0x89a3 (U+6bb4)
Section7380Start	label	Chars
	Chars C_KANJI_JIS_3226			; 0x89a4 (U+738b)
Section7fc0Start	label	Chars
	Chars C_KANJI_JIS_3227			; 0x89a5 (U+7fc1)
Section8950Start	label	Chars
	Chars C_KANJI_JIS_3228			; 0x89a6 (U+8956)
Section9d20Start	label	Chars
	Chars C_KANJI_JIS_3229			; 0x89a7 (U+9d2c)
Section9d00Start	label	Chars
	Chars C_KANJI_JIS_322A			; 0x89a8 (U+9d0e)
Section9ec0Start	label	Chars
	Chars C_KANJI_JIS_322B			; 0x89a9 (U+9ec4)
Section5ca0Start	label	Chars
	Chars C_KANJI_JIS_322C			; 0x89aa (U+5ca1)
Section6c90Start	label	Chars
	Chars C_KANJI_JIS_322D			; 0x89ab (U+6c96)
Section8370Start	label	Chars
	Chars C_KANJI_JIS_322E			; 0x89ac (U+837b)
Section5100Start	label	Chars
	Chars C_KANJI_JIS_322F			; 0x89ad (U+5104)
Section5c40Start	label	Chars
	Chars C_KANJI_JIS_3230			; 0x89ae (U+5c4b)
Section61b0Start	label	Chars
	Chars C_KANJI_JIS_3231			; 0x89af (U+61b6)
Section81c0Start	label	Chars
	Chars C_KANJI_JIS_3232			; 0x89b0 (U+81c6)
Section6870Start	label	Chars
	Chars C_KANJI_JIS_3233			; 0x89b1 (U+6876)
Section7260Start	label	Chars
	Chars C_KANJI_JIS_3234			; 0x89b2 (U+7261)
Section4e50Start	label	Chars
	Chars C_KANJI_JIS_3235			; 0x89b3 (U+4e59)
Section4ff0Start	label	Chars
	Chars C_KANJI_JIS_3236			; 0x89b4 (U+4ffa)
	Chars C_KANJI_JIS_3237			; 0x89b5 (U+5378)
Section6060Start	label	Chars
	Chars C_KANJI_JIS_3238			; 0x89b6 (U+6069)
	Chars C_KANJI_JIS_3239			; 0x89b7 (U+6e29)
	Chars C_KANJI_JIS_323A			; 0x89b8 (U+7a4f)
	Chars C_KANJI_JIS_323B			; 0x89b9 (U+97f3)
	Chars C_KANJI_JIS_323C			; 0x89ba (U+4e0b)
Section5310Start	label	Chars
	Chars C_KANJI_JIS_323D			; 0x89bb (U+5316)
	Chars C_KANJI_JIS_323E			; 0x89bc (U+4eee)
Section4f50Start	label	Chars
	Chars C_KANJI_JIS_323F			; 0x89bd (U+4f55)
Section4f30Start	label	Chars
	Chars C_KANJI_JIS_3240			; 0x89be (U+4f3d)
Section4fa0Start	label	Chars
	Chars C_KANJI_JIS_3241			; 0x89bf (U+4fa1)
Section4f70Start	label	Chars
	Chars C_KANJI_JIS_3242			; 0x89c0 (U+4f73)
Section52a0Start	label	Chars
	Chars C_KANJI_JIS_3243			; 0x89c1 (U+52a0)
	Chars C_KANJI_JIS_3244			; 0x89c2 (U+53ef)
Section5600Start	label	Chars
	Chars C_KANJI_JIS_3245			; 0x89c3 (U+5609)
Section5900Start	label	Chars
	Chars C_KANJI_JIS_3246			; 0x89c4 (U+590f)
Section5ac0Start	label	Chars
	Chars C_KANJI_JIS_3247			; 0x89c5 (U+5ac1)
	Chars C_KANJI_JIS_3248			; 0x89c6 (U+5bb6)
Section5be0Start	label	Chars
	Chars C_KANJI_JIS_3249			; 0x89c7 (U+5be1)
Section79d0Start	label	Chars
	Chars C_KANJI_JIS_324A			; 0x89c8 (U+79d1)
Section6680Start	label	Chars
	Chars C_KANJI_JIS_324B			; 0x89c9 (U+6687)
Section6790Start	label	Chars
	Chars C_KANJI_JIS_324C			; 0x89ca (U+679c)
Section67b0Start	label	Chars
	Chars C_KANJI_JIS_324D			; 0x89cb (U+67b6)
Section6b40Start	label	Chars
	Chars C_KANJI_JIS_324E			; 0x89cc (U+6b4c)
	Chars C_KANJI_JIS_324F			; 0x89cd (U+6cb3)
Section7060Start	label	Chars
	Chars C_KANJI_JIS_3250			; 0x89ce (U+706b)
Section73c0Start	label	Chars
	Chars C_KANJI_JIS_3251			; 0x89cf (U+73c2)
Section7980Start	label	Chars
	Chars C_KANJI_JIS_3252			; 0x89d0 (U+798d)
Section79b0Start	label	Chars
	Chars C_KANJI_JIS_3253			; 0x89d1 (U+79be)
	Chars C_KANJI_JIS_3254			; 0x89d2 (U+7a3c)
Section7b80Start	label	Chars
	Chars C_KANJI_JIS_3255			; 0x89d3 (U+7b87)
Section82b0Start	label	Chars
	Chars C_KANJI_JIS_3256			; 0x89d4 (U+82b1)
	Chars C_KANJI_JIS_3257			; 0x89d5 (U+82db)
Section8300Start	label	Chars
	Chars C_KANJI_JIS_3258			; 0x89d6 (U+8304)
	Chars C_KANJI_JIS_3259			; 0x89d7 (U+8377)
Section83e0Start	label	Chars
	Chars C_KANJI_JIS_325A			; 0x89d8 (U+83ef)
Section83d0Start	label	Chars
	Chars C_KANJI_JIS_325B			; 0x89d9 (U+83d3)
Section8760Start	label	Chars
	Chars C_KANJI_JIS_325C			; 0x89da (U+8766)
Section8ab0Start	label	Chars
	Chars C_KANJI_JIS_325D			; 0x89db (U+8ab2)
Section5620Start	label	Chars
	Chars C_KANJI_JIS_325E			; 0x89dc (U+5629)
Section8ca0Start	label	Chars
	Chars C_KANJI_JIS_325F			; 0x89dd (U+8ca8)
Section8fe0Start	label	Chars
	Chars C_KANJI_JIS_3260			; 0x89de (U+8fe6)
	Chars C_KANJI_JIS_3261			; 0x89df (U+904e)
Section9710Start	label	Chars
	Chars C_KANJI_JIS_3262			; 0x89e0 (U+971e)
Section8680Start	label	Chars
	Chars C_KANJI_JIS_3263			; 0x89e1 (U+868a)
Section4fc0Start	label	Chars
	Chars C_KANJI_JIS_3264			; 0x89e2 (U+4fc4)
Section5ce0Start	label	Chars
	Chars C_KANJI_JIS_3265			; 0x89e3 (U+5ce8)
	Chars C_KANJI_JIS_3266			; 0x89e4 (U+6211)
Section7250Start	label	Chars
	Chars C_KANJI_JIS_3267			; 0x89e5 (U+7259)
Section7530Start	label	Chars
	Chars C_KANJI_JIS_3268			; 0x89e6 (U+753b)
Section81e0Start	label	Chars
	Chars C_KANJI_JIS_3269			; 0x89e7 (U+81e5)
	Chars C_KANJI_JIS_326A			; 0x89e8 (U+82bd)
Section86f0Start	label	Chars
	Chars C_KANJI_JIS_326B			; 0x89e9 (U+86fe)
Section8cc0Start	label	Chars
	Chars C_KANJI_JIS_326C			; 0x89ea (U+8cc0)
Section96c0Start	label	Chars
	Chars C_KANJI_JIS_326D			; 0x89eb (U+96c5)
Section9910Start	label	Chars
	Chars C_KANJI_JIS_326E			; 0x89ec (U+9913)
Section99d0Start	label	Chars
	Chars C_KANJI_JIS_326F			; 0x89ed (U+99d5)
Section4ec0Start	label	Chars
	Chars C_KANJI_JIS_3270			; 0x89ee (U+4ecb)
Section4f10Start	label	Chars
	Chars C_KANJI_JIS_3271			; 0x89ef (U+4f1a)
Section89e0Start	label	Chars
	Chars C_KANJI_JIS_3272			; 0x89f0 (U+89e3)
Section56d0Start	label	Chars
	Chars C_KANJI_JIS_3273			; 0x89f1 (U+56de)
Section5840Start	label	Chars
	Chars C_KANJI_JIS_3274			; 0x89f2 (U+584a)
Section58c0Start	label	Chars
	Chars C_KANJI_JIS_3275			; 0x89f3 (U+58ca)
	Chars C_KANJI_JIS_3276			; 0x89f4 (U+5efb)
Section5fe0Start	label	Chars
	Chars C_KANJI_JIS_3277			; 0x89f5 (U+5feb)
	Chars C_KANJI_JIS_3278			; 0x89f6 (U+602a)
Section6090Start	label	Chars
	Chars C_KANJI_JIS_3279			; 0x89f7 (U+6094)
	Chars C_KANJI_JIS_327A			; 0x89f8 (U+6062)
Section61d0Start	label	Chars
	Chars C_KANJI_JIS_327B			; 0x89f9 (U+61d0)
	Chars C_KANJI_JIS_327C			; 0x89fa (U+6212)
Section62d0Start	label	Chars
	Chars C_KANJI_JIS_327D			; 0x89fb (U+62d0)
Section6530Start	label	Chars
	Chars C_KANJI_JIS_327E			; 0x89fc (U+6539)
	Chars 0					; 0x89fd
	Chars 0					; 0x89fe
	Chars 0					; 0x89ff
Section9b40Start	label	Chars

	Chars C_KANJI_JIS_3321			; 0x8a40 (U+9b41)
Section6660Start	label	Chars
	Chars C_KANJI_JIS_3322			; 0x8a41 (U+6666)
Section68b0Start	label	Chars
	Chars C_KANJI_JIS_3323			; 0x8a42 (U+68b0)
Section6d70Start	label	Chars
	Chars C_KANJI_JIS_3324			; 0x8a43 (U+6d77)
Section7070Start	label	Chars
	Chars C_KANJI_JIS_3325			; 0x8a44 (U+7070)
	Chars C_KANJI_JIS_3326			; 0x8a45 (U+754c)
Section7680Start	label	Chars
	Chars C_KANJI_JIS_3327			; 0x8a46 (U+7686)
Section7d70Start	label	Chars
	Chars C_KANJI_JIS_3328			; 0x8a47 (U+7d75)
	Chars C_KANJI_JIS_3329			; 0x8a48 (U+82a5)
Section87f0Start	label	Chars
	Chars C_KANJI_JIS_332A			; 0x8a49 (U+87f9)
	Chars C_KANJI_JIS_332B			; 0x8a4a (U+958b)
Section9680Start	label	Chars
	Chars C_KANJI_JIS_332C			; 0x8a4b (U+968e)
Section8c90Start	label	Chars
	Chars C_KANJI_JIS_332D			; 0x8a4c (U+8c9d)
	Chars C_KANJI_JIS_332E			; 0x8a4d (U+51f1)
Section52b0Start	label	Chars
	Chars C_KANJI_JIS_332F			; 0x8a4e (U+52be)
Section5910Start	label	Chars
	Chars C_KANJI_JIS_3330			; 0x8a4f (U+5916)
	Chars C_KANJI_JIS_3331			; 0x8a50 (U+54b3)
	Chars C_KANJI_JIS_3332			; 0x8a51 (U+5bb3)
Section5d10Start	label	Chars
	Chars C_KANJI_JIS_3333			; 0x8a52 (U+5d16)
Section6160Start	label	Chars
	Chars C_KANJI_JIS_3334			; 0x8a53 (U+6168)
	Chars C_KANJI_JIS_3335			; 0x8a54 (U+6982)
Section6da0Start	label	Chars
	Chars C_KANJI_JIS_3336			; 0x8a55 (U+6daf)
Section7880Start	label	Chars
	Chars C_KANJI_JIS_3337			; 0x8a56 (U+788d)
Section84c0Start	label	Chars
	Chars C_KANJI_JIS_3338			; 0x8a57 (U+84cb)
	Chars C_KANJI_JIS_3339			; 0x8a58 (U+8857)
Section8a70Start	label	Chars
	Chars C_KANJI_JIS_333A			; 0x8a59 (U+8a72)
Section93a0Start	label	Chars
	Chars C_KANJI_JIS_333B			; 0x8a5a (U+93a7)
Section9ab0Start	label	Chars
	Chars C_KANJI_JIS_333C			; 0x8a5b (U+9ab8)
	Chars C_KANJI_JIS_333D			; 0x8a5c (U+6d6c)
Section99a0Start	label	Chars
	Chars C_KANJI_JIS_333E			; 0x8a5d (U+99a8)
Section86d0Start	label	Chars
	Chars C_KANJI_JIS_333F			; 0x8a5e (U+86d9)
Section57a0Start	label	Chars
	Chars C_KANJI_JIS_3340			; 0x8a5f (U+57a3)
Section67f0Start	label	Chars
	Chars C_KANJI_JIS_3341			; 0x8a60 (U+67ff)
Section86c0Start	label	Chars
	Chars C_KANJI_JIS_3342			; 0x8a61 (U+86ce)
Section9200Start	label	Chars
	Chars C_KANJI_JIS_3343			; 0x8a62 (U+920e)
Section5280Start	label	Chars
	Chars C_KANJI_JIS_3344			; 0x8a63 (U+5283)
Section5680Start	label	Chars
	Chars C_KANJI_JIS_3345			; 0x8a64 (U+5687)
	Chars C_KANJI_JIS_3346			; 0x8a65 (U+5404)
Section5ed0Start	label	Chars
	Chars C_KANJI_JIS_3347			; 0x8a66 (U+5ed3)
Section62e0Start	label	Chars
	Chars C_KANJI_JIS_3348			; 0x8a67 (U+62e1)
Section64b0Start	label	Chars
	Chars C_KANJI_JIS_3349			; 0x8a68 (U+64b9)
Section6830Start	label	Chars
	Chars C_KANJI_JIS_334A			; 0x8a69 (U+683c)
	Chars C_KANJI_JIS_334B			; 0x8a6a (U+6838)
	Chars C_KANJI_JIS_334C			; 0x8a6b (U+6bbb)
Section7370Start	label	Chars
	Chars C_KANJI_JIS_334D			; 0x8a6c (U+7372)
Section78b0Start	label	Chars
	Chars C_KANJI_JIS_334E			; 0x8a6d (U+78ba)
Section7a60Start	label	Chars
	Chars C_KANJI_JIS_334F			; 0x8a6e (U+7a6b)
Section8990Start	label	Chars
	Chars C_KANJI_JIS_3350			; 0x8a6f (U+899a)
Section89d0Start	label	Chars
	Chars C_KANJI_JIS_3351			; 0x8a70 (U+89d2)
Section8d60Start	label	Chars
	Chars C_KANJI_JIS_3352			; 0x8a71 (U+8d6b)
Section8f00Start	label	Chars
	Chars C_KANJI_JIS_3353			; 0x8a72 (U+8f03)
Section90e0Start	label	Chars
	Chars C_KANJI_JIS_3354			; 0x8a73 (U+90ed)
Section95a0Start	label	Chars
	Chars C_KANJI_JIS_3355			; 0x8a74 (U+95a3)
Section9690Start	label	Chars
	Chars C_KANJI_JIS_3356			; 0x8a75 (U+9694)
Section9760Start	label	Chars
	Chars C_KANJI_JIS_3357			; 0x8a76 (U+9769)
Section5b60Start	label	Chars
	Chars C_KANJI_JIS_3358			; 0x8a77 (U+5b66)
Section5cb0Start	label	Chars
	Chars C_KANJI_JIS_3359			; 0x8a78 (U+5cb3)
Section6970Start	label	Chars
	Chars C_KANJI_JIS_335A			; 0x8a79 (U+697d)
Section9840Start	label	Chars
	Chars C_KANJI_JIS_335B			; 0x8a7a (U+984d)
	Chars C_KANJI_JIS_335C			; 0x8a7b (U+984e)
Section6390Start	label	Chars
	Chars C_KANJI_JIS_335D			; 0x8a7c (U+639b)
Section7b20Start	label	Chars
	Chars C_KANJI_JIS_335E			; 0x8a7d (U+7b20)
	Chars C_KANJI_JIS_335F			; 0x8a7e (U+6a2b)
	Chars 0					; 0x8a7f
Section6a70Start	label	Chars
	Chars C_KANJI_JIS_3360			; 0x8a80 (U+6a7f)
	Chars C_KANJI_JIS_3361			; 0x8a81 (U+68b6)
Section9c00Start	label	Chars
	Chars C_KANJI_JIS_3362			; 0x8a82 (U+9c0d)
Section6f50Start	label	Chars
	Chars C_KANJI_JIS_3363			; 0x8a83 (U+6f5f)
Section5270Start	label	Chars
	Chars C_KANJI_JIS_3364			; 0x8a84 (U+5272)
Section5590Start	label	Chars
	Chars C_KANJI_JIS_3365			; 0x8a85 (U+559d)
Section6070Start	label	Chars
	Chars C_KANJI_JIS_3366			; 0x8a86 (U+6070)
	Chars C_KANJI_JIS_3367			; 0x8a87 (U+62ec)
Section6d30Start	label	Chars
	Chars C_KANJI_JIS_3368			; 0x8a88 (U+6d3b)
Section6e00Start	label	Chars
	Chars C_KANJI_JIS_3369			; 0x8a89 (U+6e07)
Section6ed0Start	label	Chars
	Chars C_KANJI_JIS_336A			; 0x8a8a (U+6ed1)
Section8450Start	label	Chars
	Chars C_KANJI_JIS_336B			; 0x8a8b (U+845b)
Section8910Start	label	Chars
	Chars C_KANJI_JIS_336C			; 0x8a8c (U+8910)
Section8f40Start	label	Chars
	Chars C_KANJI_JIS_336D			; 0x8a8d (U+8f44)
	Chars C_KANJI_JIS_336E			; 0x8a8e (U+4e14)
	Chars C_KANJI_JIS_336F			; 0x8a8f (U+9c39)
	Chars C_KANJI_JIS_3370			; 0x8a90 (U+53f6)
Section6910Start	label	Chars
	Chars C_KANJI_JIS_3371			; 0x8a91 (U+691b)
Section6a30Start	label	Chars
	Chars C_KANJI_JIS_3372			; 0x8a92 (U+6a3a)
	Chars C_KANJI_JIS_3373			; 0x8a93 (U+9784)
Section6820Start	label	Chars
	Chars C_KANJI_JIS_3374			; 0x8a94 (U+682a)
Section5150Start	label	Chars
	Chars C_KANJI_JIS_3375			; 0x8a95 (U+515c)
Section7ac0Start	label	Chars
	Chars C_KANJI_JIS_3376			; 0x8a96 (U+7ac3)
Section84b0Start	label	Chars
	Chars C_KANJI_JIS_3377			; 0x8a97 (U+84b2)
Section91d0Start	label	Chars
	Chars C_KANJI_JIS_3378			; 0x8a98 (U+91dc)
Section9380Start	label	Chars
	Chars C_KANJI_JIS_3379			; 0x8a99 (U+938c)
Section5650Start	label	Chars
	Chars C_KANJI_JIS_337A			; 0x8a9a (U+565b)
	Chars C_KANJI_JIS_337B			; 0x8a9b (U+9d28)
	Chars C_KANJI_JIS_337C			; 0x8a9c (U+6822)
	Chars C_KANJI_JIS_337D			; 0x8a9d (U+8305)
Section8430Start	label	Chars
	Chars C_KANJI_JIS_337E			; 0x8a9e (U+8431)
Section7ca0Start	label	Chars
	Chars C_KANJI_JIS_3421			; 0x8a9f (U+7ca5)
Section5200Start	label	Chars
	Chars C_KANJI_JIS_3422			; 0x8aa0 (U+5208)
Section82c0Start	label	Chars
	Chars C_KANJI_JIS_3423			; 0x8aa1 (U+82c5)
Section74e0Start	label	Chars
	Chars C_KANJI_JIS_3424			; 0x8aa2 (U+74e6)
Section4e70Start	label	Chars
	Chars C_KANJI_JIS_3425			; 0x8aa3 (U+4e7e)
Section4f80Start	label	Chars
	Chars C_KANJI_JIS_3426			; 0x8aa4 (U+4f83)
Section51a0Start	label	Chars
	Chars C_KANJI_JIS_3427			; 0x8aa5 (U+51a0)
Section5bd0Start	label	Chars
	Chars C_KANJI_JIS_3428			; 0x8aa6 (U+5bd2)
	Chars C_KANJI_JIS_3429			; 0x8aa7 (U+520a)
Section52d0Start	label	Chars
	Chars C_KANJI_JIS_342A			; 0x8aa8 (U+52d8)
Section52e0Start	label	Chars
	Chars C_KANJI_JIS_342B			; 0x8aa9 (U+52e7)
Section5df0Start	label	Chars
	Chars C_KANJI_JIS_342C			; 0x8aaa (U+5dfb)
	Chars C_KANJI_JIS_342D			; 0x8aab (U+559a)
Section5820Start	label	Chars
	Chars C_KANJI_JIS_342E			; 0x8aac (U+582a)
	Chars C_KANJI_JIS_342F			; 0x8aad (U+59e6)
	Chars C_KANJI_JIS_3430			; 0x8aae (U+5b8c)
	Chars C_KANJI_JIS_3431			; 0x8aaf (U+5b98)
	Chars C_KANJI_JIS_3432			; 0x8ab0 (U+5bdb)
Section5e70Start	label	Chars
	Chars C_KANJI_JIS_3433			; 0x8ab1 (U+5e72)
	Chars C_KANJI_JIS_3434			; 0x8ab2 (U+5e79)
	Chars C_KANJI_JIS_3435			; 0x8ab3 (U+60a3)
	Chars C_KANJI_JIS_3436			; 0x8ab4 (U+611f)
	Chars C_KANJI_JIS_3437			; 0x8ab5 (U+6163)
	Chars C_KANJI_JIS_3438			; 0x8ab6 (U+61be)
Section63d0Start	label	Chars
	Chars C_KANJI_JIS_3439			; 0x8ab7 (U+63db)
Section6560Start	label	Chars
	Chars C_KANJI_JIS_343A			; 0x8ab8 (U+6562)
Section67d0Start	label	Chars
	Chars C_KANJI_JIS_343B			; 0x8ab9 (U+67d1)
Section6850Start	label	Chars
	Chars C_KANJI_JIS_343C			; 0x8aba (U+6853)
Section68f0Start	label	Chars
	Chars C_KANJI_JIS_343D			; 0x8abb (U+68fa)
Section6b30Start	label	Chars
	Chars C_KANJI_JIS_343E			; 0x8abc (U+6b3e)
Section6b50Start	label	Chars
	Chars C_KANJI_JIS_343F			; 0x8abd (U+6b53)
	Chars C_KANJI_JIS_3440			; 0x8abe (U+6c57)
Section6f20Start	label	Chars
	Chars C_KANJI_JIS_3441			; 0x8abf (U+6f22)
Section6f90Start	label	Chars
	Chars C_KANJI_JIS_3442			; 0x8ac0 (U+6f97)
Section6f40Start	label	Chars
	Chars C_KANJI_JIS_3443			; 0x8ac1 (U+6f45)
Section74b0Start	label	Chars
	Chars C_KANJI_JIS_3444			; 0x8ac2 (U+74b0)
Section7510Start	label	Chars
	Chars C_KANJI_JIS_3445			; 0x8ac3 (U+7518)
Section76e0Start	label	Chars
	Chars C_KANJI_JIS_3446			; 0x8ac4 (U+76e3)
Section7700Start	label	Chars
	Chars C_KANJI_JIS_3447			; 0x8ac5 (U+770b)
Section7af0Start	label	Chars
	Chars C_KANJI_JIS_3448			; 0x8ac6 (U+7aff)
Section7ba0Start	label	Chars
	Chars C_KANJI_JIS_3449			; 0x8ac7 (U+7ba1)
Section7c20Start	label	Chars
	Chars C_KANJI_JIS_344A			; 0x8ac8 (U+7c21)
	Chars C_KANJI_JIS_344B			; 0x8ac9 (U+7de9)
Section7f30Start	label	Chars
	Chars C_KANJI_JIS_344C			; 0x8aca (U+7f36)
Section7ff0Start	label	Chars
	Chars C_KANJI_JIS_344D			; 0x8acb (U+7ff0)
Section8090Start	label	Chars
	Chars C_KANJI_JIS_344E			; 0x8acc (U+809d)
Section8260Start	label	Chars
	Chars C_KANJI_JIS_344F			; 0x8acd (U+8266)
Section8390Start	label	Chars
	Chars C_KANJI_JIS_3450			; 0x8ace (U+839e)
Section89b0Start	label	Chars
	Chars C_KANJI_JIS_3451			; 0x8acf (U+89b3)
Section8ac0Start	label	Chars
	Chars C_KANJI_JIS_3452			; 0x8ad0 (U+8acc)
	Chars C_KANJI_JIS_3453			; 0x8ad1 (U+8cab)
Section9080Start	label	Chars
	Chars C_KANJI_JIS_3454			; 0x8ad2 (U+9084)
Section9450Start	label	Chars
	Chars C_KANJI_JIS_3455			; 0x8ad3 (U+9451)
Section9590Start	label	Chars
	Chars C_KANJI_JIS_3456			; 0x8ad4 (U+9593)
	Chars C_KANJI_JIS_3457			; 0x8ad5 (U+9591)
	Chars C_KANJI_JIS_3458			; 0x8ad6 (U+95a2)
	Chars C_KANJI_JIS_3459			; 0x8ad7 (U+9665)
Section97d0Start	label	Chars
	Chars C_KANJI_JIS_345A			; 0x8ad8 (U+97d3)
Section9920Start	label	Chars
	Chars C_KANJI_JIS_345B			; 0x8ad9 (U+9928)
Section8210Start	label	Chars
	Chars C_KANJI_JIS_345C			; 0x8ada (U+8218)
Section4e30Start	label	Chars
	Chars C_KANJI_JIS_345D			; 0x8adb (U+4e38)
Section5420Start	label	Chars
	Chars C_KANJI_JIS_345E			; 0x8adc (U+542b)
	Chars C_KANJI_JIS_345F			; 0x8add (U+5cb8)
Section5dc0Start	label	Chars
	Chars C_KANJI_JIS_3460			; 0x8ade (U+5dcc)
Section73a0Start	label	Chars
	Chars C_KANJI_JIS_3461			; 0x8adf (U+73a9)
Section7640Start	label	Chars
	Chars C_KANJI_JIS_3462			; 0x8ae0 (U+764c)
Section7730Start	label	Chars
	Chars C_KANJI_JIS_3463			; 0x8ae1 (U+773c)
	Chars C_KANJI_JIS_3464			; 0x8ae2 (U+5ca9)
Section7fe0Start	label	Chars
	Chars C_KANJI_JIS_3465			; 0x8ae3 (U+7feb)
Section8d00Start	label	Chars
	Chars C_KANJI_JIS_3466			; 0x8ae4 (U+8d0b)
	Chars C_KANJI_JIS_3467			; 0x8ae5 (U+96c1)
Section9810Start	label	Chars
	Chars C_KANJI_JIS_3468			; 0x8ae6 (U+9811)
Section9850Start	label	Chars
	Chars C_KANJI_JIS_3469			; 0x8ae7 (U+9854)
	Chars C_KANJI_JIS_346A			; 0x8ae8 (U+9858)
	Chars C_KANJI_JIS_346B			; 0x8ae9 (U+4f01)
	Chars C_KANJI_JIS_346C			; 0x8aea (U+4f0e)
	Chars C_KANJI_JIS_346D			; 0x8aeb (U+5371)
	Chars C_KANJI_JIS_346E			; 0x8aec (U+559c)
Section5660Start	label	Chars
	Chars C_KANJI_JIS_346F			; 0x8aed (U+5668)
Section57f0Start	label	Chars
	Chars C_KANJI_JIS_3470			; 0x8aee (U+57fa)
	Chars C_KANJI_JIS_3471			; 0x8aef (U+5947)
Section5b00Start	label	Chars
	Chars C_KANJI_JIS_3472			; 0x8af0 (U+5b09)
Section5bc0Start	label	Chars
	Chars C_KANJI_JIS_3473			; 0x8af1 (U+5bc4)
Section5c90Start	label	Chars
	Chars C_KANJI_JIS_3474			; 0x8af2 (U+5c90)
Section5e00Start	label	Chars
	Chars C_KANJI_JIS_3475			; 0x8af3 (U+5e0c)
	Chars C_KANJI_JIS_3476			; 0x8af4 (U+5e7e)
Section5fc0Start	label	Chars
	Chars C_KANJI_JIS_3477			; 0x8af5 (U+5fcc)
	Chars C_KANJI_JIS_3478			; 0x8af6 (U+63ee)
Section6730Start	label	Chars
	Chars C_KANJI_JIS_3479			; 0x8af7 (U+673a)
Section65d0Start	label	Chars
	Chars C_KANJI_JIS_347A			; 0x8af8 (U+65d7)
	Chars C_KANJI_JIS_347B			; 0x8af9 (U+65e2)
Section6710Start	label	Chars
	Chars C_KANJI_JIS_347C			; 0x8afa (U+671f)
Section68c0Start	label	Chars
	Chars C_KANJI_JIS_347D			; 0x8afb (U+68cb)
	Chars C_KANJI_JIS_347E			; 0x8afc (U+68c4)
	Chars 0					; 0x8afd
	Chars 0					; 0x8afe
	Chars 0					; 0x8aff
Section6a50Start	label	Chars

	Chars C_KANJI_JIS_3521			; 0x8b40 (U+6a5f)
Section5e30Start	label	Chars
	Chars C_KANJI_JIS_3522			; 0x8b41 (U+5e30)
Section6bc0Start	label	Chars
	Chars C_KANJI_JIS_3523			; 0x8b42 (U+6bc5)
Section6c10Start	label	Chars
	Chars C_KANJI_JIS_3524			; 0x8b43 (U+6c17)
Section6c70Start	label	Chars
	Chars C_KANJI_JIS_3525			; 0x8b44 (U+6c7d)
	Chars C_KANJI_JIS_3526			; 0x8b45 (U+757f)
Section7940Start	label	Chars
	Chars C_KANJI_JIS_3527			; 0x8b46 (U+7948)
	Chars C_KANJI_JIS_3528			; 0x8b47 (U+5b63)
Section7a00Start	label	Chars
	Chars C_KANJI_JIS_3529			; 0x8b48 (U+7a00)
Section7d00Start	label	Chars
	Chars C_KANJI_JIS_352A			; 0x8b49 (U+7d00)
Section5fb0Start	label	Chars
	Chars C_KANJI_JIS_352B			; 0x8b4a (U+5fbd)
Section8980Start	label	Chars
	Chars C_KANJI_JIS_352C			; 0x8b4b (U+898f)
Section8a10Start	label	Chars
	Chars C_KANJI_JIS_352D			; 0x8b4c (U+8a18)
Section8cb0Start	label	Chars
	Chars C_KANJI_JIS_352E			; 0x8b4d (U+8cb4)
Section8d70Start	label	Chars
	Chars C_KANJI_JIS_352F			; 0x8b4e (U+8d77)
Section8ec0Start	label	Chars
	Chars C_KANJI_JIS_3530			; 0x8b4f (U+8ecc)
Section8f10Start	label	Chars
	Chars C_KANJI_JIS_3531			; 0x8b50 (U+8f1d)
Section98e0Start	label	Chars
	Chars C_KANJI_JIS_3532			; 0x8b51 (U+98e2)
Section9a00Start	label	Chars
	Chars C_KANJI_JIS_3533			; 0x8b52 (U+9a0e)
Section9b30Start	label	Chars
	Chars C_KANJI_JIS_3534			; 0x8b53 (U+9b3c)
Section4e80Start	label	Chars
	Chars C_KANJI_JIS_3535			; 0x8b54 (U+4e80)
Section5070Start	label	Chars
	Chars C_KANJI_JIS_3536			; 0x8b55 (U+507d)
	Chars C_KANJI_JIS_3537			; 0x8b56 (U+5100)
Section5990Start	label	Chars
	Chars C_KANJI_JIS_3538			; 0x8b57 (U+5993)
	Chars C_KANJI_JIS_3539			; 0x8b58 (U+5b9c)
Section6220Start	label	Chars
	Chars C_KANJI_JIS_353A			; 0x8b59 (U+622f)
Section6280Start	label	Chars
	Chars C_KANJI_JIS_353B			; 0x8b5a (U+6280)
Section64e0Start	label	Chars
	Chars C_KANJI_JIS_353C			; 0x8b5b (U+64ec)
	Chars C_KANJI_JIS_353D			; 0x8b5c (U+6b3a)
Section72a0Start	label	Chars
	Chars C_KANJI_JIS_353E			; 0x8b5d (U+72a0)
Section7590Start	label	Chars
	Chars C_KANJI_JIS_353F			; 0x8b5e (U+7591)
	Chars C_KANJI_JIS_3540			; 0x8b5f (U+7947)
Section7fa0Start	label	Chars
	Chars C_KANJI_JIS_3541			; 0x8b60 (U+7fa9)
	Chars C_KANJI_JIS_3542			; 0x8b61 (U+87fb)
	Chars C_KANJI_JIS_3543			; 0x8b62 (U+8abc)
Section8b70Start	label	Chars
	Chars C_KANJI_JIS_3544			; 0x8b63 (U+8b70)
	Chars C_KANJI_JIS_3545			; 0x8b64 (U+63ac)
Section83c0Start	label	Chars
	Chars C_KANJI_JIS_3546			; 0x8b65 (U+83ca)
Section97a0Start	label	Chars
	Chars C_KANJI_JIS_3547			; 0x8b66 (U+97a0)
	Chars C_KANJI_JIS_3548			; 0x8b67 (U+5409)
	Chars C_KANJI_JIS_3549			; 0x8b68 (U+5403)
Section55a0Start	label	Chars
	Chars C_KANJI_JIS_354A			; 0x8b69 (U+55ab)
	Chars C_KANJI_JIS_354B			; 0x8b6a (U+6854)
	Chars C_KANJI_JIS_354C			; 0x8b6b (U+6a58)
	Chars C_KANJI_JIS_354D			; 0x8b6c (U+8a70)
Section7820Start	label	Chars
	Chars C_KANJI_JIS_354E			; 0x8b6d (U+7827)
Section6770Start	label	Chars
	Chars C_KANJI_JIS_354F			; 0x8b6e (U+6775)
	Chars C_KANJI_JIS_3550			; 0x8b6f (U+9ecd)
	Chars C_KANJI_JIS_3551			; 0x8b70 (U+5374)
Section5ba0Start	label	Chars
	Chars C_KANJI_JIS_3552			; 0x8b71 (U+5ba2)
Section8110Start	label	Chars
	Chars C_KANJI_JIS_3553			; 0x8b72 (U+811a)
Section8650Start	label	Chars
	Chars C_KANJI_JIS_3554			; 0x8b73 (U+8650)
Section9000Start	label	Chars
	Chars C_KANJI_JIS_3555			; 0x8b74 (U+9006)
	Chars C_KANJI_JIS_3556			; 0x8b75 (U+4e18)
Section4e40Start	label	Chars
	Chars C_KANJI_JIS_3557			; 0x8b76 (U+4e45)
	Chars C_KANJI_JIS_3558			; 0x8b77 (U+4ec7)
	Chars C_KANJI_JIS_3559			; 0x8b78 (U+4f11)
Section53c0Start	label	Chars
	Chars C_KANJI_JIS_355A			; 0x8b79 (U+53ca)
Section5430Start	label	Chars
	Chars C_KANJI_JIS_355B			; 0x8b7a (U+5438)
	Chars C_KANJI_JIS_355C			; 0x8b7b (U+5bae)
	Chars C_KANJI_JIS_355D			; 0x8b7c (U+5f13)
	Chars C_KANJI_JIS_355E			; 0x8b7d (U+6025)
Section6550Start	label	Chars
	Chars C_KANJI_JIS_355F			; 0x8b7e (U+6551)
	Chars 0					; 0x8b7f
	Chars C_KANJI_JIS_3560			; 0x8b80 (U+673d)
Section6c40Start	label	Chars
	Chars C_KANJI_JIS_3561			; 0x8b81 (U+6c42)
	Chars C_KANJI_JIS_3562			; 0x8b82 (U+6c72)
Section6ce0Start	label	Chars
	Chars C_KANJI_JIS_3563			; 0x8b83 (U+6ce3)
	Chars C_KANJI_JIS_3564			; 0x8b84 (U+7078)
Section7400Start	label	Chars
	Chars C_KANJI_JIS_3565			; 0x8b85 (U+7403)
Section7a70Start	label	Chars
	Chars C_KANJI_JIS_3566			; 0x8b86 (U+7a76)
Section7aa0Start	label	Chars
	Chars C_KANJI_JIS_3567			; 0x8b87 (U+7aae)
Section7b00Start	label	Chars
	Chars C_KANJI_JIS_3568			; 0x8b88 (U+7b08)
Section7d10Start	label	Chars
	Chars C_KANJI_JIS_3569			; 0x8b89 (U+7d1a)
Section7cf0Start	label	Chars
	Chars C_KANJI_JIS_356A			; 0x8b8a (U+7cfe)
	Chars C_KANJI_JIS_356B			; 0x8b8b (U+7d66)
	Chars C_KANJI_JIS_356C			; 0x8b8c (U+65e7)
	Chars C_KANJI_JIS_356D			; 0x8b8d (U+725b)
Section53b0Start	label	Chars
	Chars C_KANJI_JIS_356E			; 0x8b8e (U+53bb)
	Chars C_KANJI_JIS_356F			; 0x8b8f (U+5c45)
Section5de0Start	label	Chars
	Chars C_KANJI_JIS_3570			; 0x8b90 (U+5de8)
	Chars C_KANJI_JIS_3571			; 0x8b91 (U+62d2)
	Chars C_KANJI_JIS_3572			; 0x8b92 (U+62e0)
Section6310Start	label	Chars
	Chars C_KANJI_JIS_3573			; 0x8b93 (U+6319)
	Chars C_KANJI_JIS_3574			; 0x8b94 (U+6e20)
	Chars C_KANJI_JIS_3575			; 0x8b95 (U+865a)
Section8a30Start	label	Chars
	Chars C_KANJI_JIS_3576			; 0x8b96 (U+8a31)
Section8dd0Start	label	Chars
	Chars C_KANJI_JIS_3577			; 0x8b97 (U+8ddd)
Section92f0Start	label	Chars
	Chars C_KANJI_JIS_3578			; 0x8b98 (U+92f8)
Section6f00Start	label	Chars
	Chars C_KANJI_JIS_3579			; 0x8b99 (U+6f01)
Section79a0Start	label	Chars
	Chars C_KANJI_JIS_357A			; 0x8b9a (U+79a6)
Section9b50Start	label	Chars
	Chars C_KANJI_JIS_357B			; 0x8b9b (U+9b5a)
	Chars C_KANJI_JIS_357C			; 0x8b9c (U+4ea8)
	Chars C_KANJI_JIS_357D			; 0x8b9d (U+4eab)
	Chars C_KANJI_JIS_357E			; 0x8b9e (U+4eac)
	Chars C_KANJI_JIS_3621			; 0x8b9f (U+4f9b)
	Chars C_KANJI_JIS_3622			; 0x8ba0 (U+4fa0)
Section50d0Start	label	Chars
	Chars C_KANJI_JIS_3623			; 0x8ba1 (U+50d1)
	Chars C_KANJI_JIS_3624			; 0x8ba2 (U+5147)
	Chars C_KANJI_JIS_3625			; 0x8ba3 (U+7af6)
Section5170Start	label	Chars
	Chars C_KANJI_JIS_3626			; 0x8ba4 (U+5171)
	Chars C_KANJI_JIS_3627			; 0x8ba5 (U+51f6)
Section5350Start	label	Chars
	Chars C_KANJI_JIS_3628			; 0x8ba6 (U+5354)
Section5320Start	label	Chars
	Chars C_KANJI_JIS_3629			; 0x8ba7 (U+5321)
	Chars C_KANJI_JIS_362A			; 0x8ba8 (U+537f)
	Chars C_KANJI_JIS_362B			; 0x8ba9 (U+53eb)
	Chars C_KANJI_JIS_362C			; 0x8baa (U+55ac)
Section5880Start	label	Chars
	Chars C_KANJI_JIS_362D			; 0x8bab (U+5883)
	Chars C_KANJI_JIS_362E			; 0x8bac (U+5ce1)
Section5f30Start	label	Chars
	Chars C_KANJI_JIS_362F			; 0x8bad (U+5f37)
Section5f40Start	label	Chars
	Chars C_KANJI_JIS_3630			; 0x8bae (U+5f4a)
	Chars C_KANJI_JIS_3631			; 0x8baf (U+602f)
Section6050Start	label	Chars
	Chars C_KANJI_JIS_3632			; 0x8bb0 (U+6050)
	Chars C_KANJI_JIS_3633			; 0x8bb1 (U+606d)
	Chars C_KANJI_JIS_3634			; 0x8bb2 (U+631f)
	Chars C_KANJI_JIS_3635			; 0x8bb3 (U+6559)
Section6a40Start	label	Chars
	Chars C_KANJI_JIS_3636			; 0x8bb4 (U+6a4b)
Section6cc0Start	label	Chars
	Chars C_KANJI_JIS_3637			; 0x8bb5 (U+6cc1)
Section72c0Start	label	Chars
	Chars C_KANJI_JIS_3638			; 0x8bb6 (U+72c2)
Section72e0Start	label	Chars
	Chars C_KANJI_JIS_3639			; 0x8bb7 (U+72ed)
Section77e0Start	label	Chars
	Chars C_KANJI_JIS_363A			; 0x8bb8 (U+77ef)
Section80f0Start	label	Chars
	Chars C_KANJI_JIS_363B			; 0x8bb9 (U+80f8)
Section8100Start	label	Chars
	Chars C_KANJI_JIS_363C			; 0x8bba (U+8105)
Section8200Start	label	Chars
	Chars C_KANJI_JIS_363D			; 0x8bbb (U+8208)
Section8540Start	label	Chars
	Chars C_KANJI_JIS_363E			; 0x8bbc (U+854e)
Section90f0Start	label	Chars
	Chars C_KANJI_JIS_363F			; 0x8bbd (U+90f7)
Section93e0Start	label	Chars
	Chars C_KANJI_JIS_3640			; 0x8bbe (U+93e1)
	Chars C_KANJI_JIS_3641			; 0x8bbf (U+97ff)
Section9950Start	label	Chars
	Chars C_KANJI_JIS_3642			; 0x8bc0 (U+9957)
Section9a50Start	label	Chars
	Chars C_KANJI_JIS_3643			; 0x8bc1 (U+9a5a)
Section4ef0Start	label	Chars
	Chars C_KANJI_JIS_3644			; 0x8bc2 (U+4ef0)
Section51d0Start	label	Chars
	Chars C_KANJI_JIS_3645			; 0x8bc3 (U+51dd)
Section5c20Start	label	Chars
	Chars C_KANJI_JIS_3646			; 0x8bc4 (U+5c2d)
	Chars C_KANJI_JIS_3647			; 0x8bc5 (U+6681)
Section6960Start	label	Chars
	Chars C_KANJI_JIS_3648			; 0x8bc6 (U+696d)
	Chars C_KANJI_JIS_3649			; 0x8bc7 (U+5c40)
	Chars C_KANJI_JIS_364A			; 0x8bc8 (U+66f2)
	Chars C_KANJI_JIS_364B			; 0x8bc9 (U+6975)
	Chars C_KANJI_JIS_364C			; 0x8bca (U+7389)
	Chars C_KANJI_JIS_364D			; 0x8bcb (U+6850)
Section7c80Start	label	Chars
	Chars C_KANJI_JIS_364E			; 0x8bcc (U+7c81)
Section50c0Start	label	Chars
	Chars C_KANJI_JIS_364F			; 0x8bcd (U+50c5)
	Chars C_KANJI_JIS_3650			; 0x8bce (U+52e4)
Section5740Start	label	Chars
	Chars C_KANJI_JIS_3651			; 0x8bcf (U+5747)
	Chars C_KANJI_JIS_3652			; 0x8bd0 (U+5dfe)
Section9320Start	label	Chars
	Chars C_KANJI_JIS_3653			; 0x8bd1 (U+9326)
	Chars C_KANJI_JIS_3654			; 0x8bd2 (U+65a4)
	Chars C_KANJI_JIS_3655			; 0x8bd3 (U+6b23)
	Chars C_KANJI_JIS_3656			; 0x8bd4 (U+6b3d)
Section7430Start	label	Chars
	Chars C_KANJI_JIS_3657			; 0x8bd5 (U+7434)
	Chars C_KANJI_JIS_3658			; 0x8bd6 (U+7981)
	Chars C_KANJI_JIS_3659			; 0x8bd7 (U+79bd)
Section7b40Start	label	Chars
	Chars C_KANJI_JIS_365A			; 0x8bd8 (U+7b4b)
Section7dc0Start	label	Chars
	Chars C_KANJI_JIS_365B			; 0x8bd9 (U+7dca)
	Chars C_KANJI_JIS_365C			; 0x8bda (U+82b9)
	Chars C_KANJI_JIS_365D			; 0x8bdb (U+83cc)
Section8870Start	label	Chars
	Chars C_KANJI_JIS_365E			; 0x8bdc (U+887f)
	Chars C_KANJI_JIS_365F			; 0x8bdd (U+895f)
Section8b30Start	label	Chars
	Chars C_KANJI_JIS_3660			; 0x8bde (U+8b39)
Section8fd0Start	label	Chars
	Chars C_KANJI_JIS_3661			; 0x8bdf (U+8fd1)
	Chars C_KANJI_JIS_3662			; 0x8be0 (U+91d1)
Section5410Start	label	Chars
	Chars C_KANJI_JIS_3663			; 0x8be1 (U+541f)
Section9280Start	label	Chars
	Chars C_KANJI_JIS_3664			; 0x8be2 (U+9280)
	Chars C_KANJI_JIS_3665			; 0x8be3 (U+4e5d)
Section5030Start	label	Chars
	Chars C_KANJI_JIS_3666			; 0x8be4 (U+5036)
	Chars C_KANJI_JIS_3667			; 0x8be5 (U+53e5)
	Chars C_KANJI_JIS_3668			; 0x8be6 (U+533a)
Section72d0Start	label	Chars
	Chars C_KANJI_JIS_3669			; 0x8be7 (U+72d7)
Section7390Start	label	Chars
	Chars C_KANJI_JIS_366A			; 0x8be8 (U+7396)
	Chars C_KANJI_JIS_366B			; 0x8be9 (U+77e9)
Section82e0Start	label	Chars
	Chars C_KANJI_JIS_366C			; 0x8bea (U+82e6)
Section8ea0Start	label	Chars
	Chars C_KANJI_JIS_366D			; 0x8beb (U+8eaf)
	Chars C_KANJI_JIS_366E			; 0x8bec (U+99c6)
	Chars C_KANJI_JIS_366F			; 0x8bed (U+99c8)
	Chars C_KANJI_JIS_3670			; 0x8bee (U+99d2)
	Chars C_KANJI_JIS_3671			; 0x8bef (U+5177)
	Chars C_KANJI_JIS_3672			; 0x8bf0 (U+611a)
	Chars C_KANJI_JIS_3673			; 0x8bf1 (U+865e)
	Chars C_KANJI_JIS_3674			; 0x8bf2 (U+55b0)
	Chars C_KANJI_JIS_3675			; 0x8bf3 (U+7a7a)
	Chars C_KANJI_JIS_3676			; 0x8bf4 (U+5076)
	Chars C_KANJI_JIS_3677			; 0x8bf5 (U+5bd3)
	Chars C_KANJI_JIS_3678			; 0x8bf6 (U+9047)
	Chars C_KANJI_JIS_3679			; 0x8bf7 (U+9685)
	Chars C_KANJI_JIS_367A			; 0x8bf8 (U+4e32)
Section6ad0Start	label	Chars
	Chars C_KANJI_JIS_367B			; 0x8bf9 (U+6adb)
Section91e0Start	label	Chars
	Chars C_KANJI_JIS_367C			; 0x8bfa (U+91e7)
Section5c50Start	label	Chars
	Chars C_KANJI_JIS_367D			; 0x8bfb (U+5c51)
	Chars C_KANJI_JIS_367E			; 0x8bfc (U+5c48)
	Chars 0					; 0x8bfd
	Chars 0					; 0x8bfe
	Chars 0					; 0x8bff

	Chars C_KANJI_JIS_3721			; 0x8c40 (U+6398)
Section7a90Start	label	Chars
	Chars C_KANJI_JIS_3722			; 0x8c41 (U+7a9f)
	Chars C_KANJI_JIS_3723			; 0x8c42 (U+6c93)
Section9770Start	label	Chars
	Chars C_KANJI_JIS_3724			; 0x8c43 (U+9774)
Section8f60Start	label	Chars
	Chars C_KANJI_JIS_3725			; 0x8c44 (U+8f61)
	Chars C_KANJI_JIS_3726			; 0x8c45 (U+7aaa)
Section7180Start	label	Chars
	Chars C_KANJI_JIS_3727			; 0x8c46 (U+718a)
	Chars C_KANJI_JIS_3728			; 0x8c47 (U+9688)
	Chars C_KANJI_JIS_3729			; 0x8c48 (U+7c82)
Section6810Start	label	Chars
	Chars C_KANJI_JIS_372A			; 0x8c49 (U+6817)
Section7e70Start	label	Chars
	Chars C_KANJI_JIS_372B			; 0x8c4a (U+7e70)
	Chars C_KANJI_JIS_372C			; 0x8c4b (U+6851)
Section9360Start	label	Chars
	Chars C_KANJI_JIS_372D			; 0x8c4c (U+936c)
Section52f0Start	label	Chars
	Chars C_KANJI_JIS_372E			; 0x8c4d (U+52f2)
	Chars C_KANJI_JIS_372F			; 0x8c4e (U+541b)
Section85a0Start	label	Chars
	Chars C_KANJI_JIS_3730			; 0x8c4f (U+85ab)
	Chars C_KANJI_JIS_3731			; 0x8c50 (U+8a13)
	Chars C_KANJI_JIS_3732			; 0x8c51 (U+7fa4)
	Chars C_KANJI_JIS_3733			; 0x8c52 (U+8ecd)
	Chars C_KANJI_JIS_3734			; 0x8c53 (U+90e1)
	Chars C_KANJI_JIS_3735			; 0x8c54 (U+5366)
Section8880Start	label	Chars
	Chars C_KANJI_JIS_3736			; 0x8c55 (U+8888)
	Chars C_KANJI_JIS_3737			; 0x8c56 (U+7941)
	Chars C_KANJI_JIS_3738			; 0x8c57 (U+4fc2)
Section50b0Start	label	Chars
	Chars C_KANJI_JIS_3739			; 0x8c58 (U+50be)
Section5210Start	label	Chars
	Chars C_KANJI_JIS_373A			; 0x8c59 (U+5211)
	Chars C_KANJI_JIS_373B			; 0x8c5a (U+5144)
Section5550Start	label	Chars
	Chars C_KANJI_JIS_373C			; 0x8c5b (U+5553)
	Chars C_KANJI_JIS_373D			; 0x8c5c (U+572d)
Section73e0Start	label	Chars
	Chars C_KANJI_JIS_373E			; 0x8c5d (U+73ea)
Section5780Start	label	Chars
	Chars C_KANJI_JIS_373F			; 0x8c5e (U+578b)
Section5950Start	label	Chars
	Chars C_KANJI_JIS_3740			; 0x8c5f (U+5951)
Section5f60Start	label	Chars
	Chars C_KANJI_JIS_3741			; 0x8c60 (U+5f62)
	Chars C_KANJI_JIS_3742			; 0x8c61 (U+5f84)
	Chars C_KANJI_JIS_3743			; 0x8c62 (U+6075)
	Chars C_KANJI_JIS_3744			; 0x8c63 (U+6176)
	Chars C_KANJI_JIS_3745			; 0x8c64 (U+6167)
Section61a0Start	label	Chars
	Chars C_KANJI_JIS_3746			; 0x8c65 (U+61a9)
Section63b0Start	label	Chars
	Chars C_KANJI_JIS_3747			; 0x8c66 (U+63b2)
Section6430Start	label	Chars
	Chars C_KANJI_JIS_3748			; 0x8c67 (U+643a)
	Chars C_KANJI_JIS_3749			; 0x8c68 (U+656c)
	Chars C_KANJI_JIS_374A			; 0x8c69 (U+666f)
	Chars C_KANJI_JIS_374B			; 0x8c6a (U+6842)
Section6e10Start	label	Chars
	Chars C_KANJI_JIS_374C			; 0x8c6b (U+6e13)
Section7560Start	label	Chars
	Chars C_KANJI_JIS_374D			; 0x8c6c (U+7566)
	Chars C_KANJI_JIS_374E			; 0x8c6d (U+7a3d)
	Chars C_KANJI_JIS_374F			; 0x8c6e (U+7cfb)
Section7d40Start	label	Chars
	Chars C_KANJI_JIS_3750			; 0x8c6f (U+7d4c)
Section7d90Start	label	Chars
	Chars C_KANJI_JIS_3751			; 0x8c70 (U+7d99)
Section7e40Start	label	Chars
	Chars C_KANJI_JIS_3752			; 0x8c71 (U+7e4b)
Section7f60Start	label	Chars
	Chars C_KANJI_JIS_3753			; 0x8c72 (U+7f6b)
	Chars C_KANJI_JIS_3754			; 0x8c73 (U+830e)
	Chars C_KANJI_JIS_3755			; 0x8c74 (U+834a)
	Chars C_KANJI_JIS_3756			; 0x8c75 (U+86cd)
Section8a00Start	label	Chars
	Chars C_KANJI_JIS_3757			; 0x8c76 (U+8a08)
	Chars C_KANJI_JIS_3758			; 0x8c77 (U+8a63)
Section8b60Start	label	Chars
	Chars C_KANJI_JIS_3759			; 0x8c78 (U+8b66)
Section8ef0Start	label	Chars
	Chars C_KANJI_JIS_375A			; 0x8c79 (U+8efd)
	Chars C_KANJI_JIS_375B			; 0x8c7a (U+981a)
Section9d80Start	label	Chars
	Chars C_KANJI_JIS_375C			; 0x8c7b (U+9d8f)
	Chars C_KANJI_JIS_375D			; 0x8c7c (U+82b8)
	Chars C_KANJI_JIS_375E			; 0x8c7d (U+8fce)
Section9be0Start	label	Chars
	Chars C_KANJI_JIS_375F			; 0x8c7e (U+9be8)
	Chars 0					; 0x8c7f
	Chars C_KANJI_JIS_3760			; 0x8c80 (U+5287)
	Chars C_KANJI_JIS_3761			; 0x8c81 (U+621f)
Section6480Start	label	Chars
	Chars C_KANJI_JIS_3762			; 0x8c82 (U+6483)
Section6fc0Start	label	Chars
	Chars C_KANJI_JIS_3763			; 0x8c83 (U+6fc0)
	Chars C_KANJI_JIS_3764			; 0x8c84 (U+9699)
	Chars C_KANJI_JIS_3765			; 0x8c85 (U+6841)
Section5090Start	label	Chars
	Chars C_KANJI_JIS_3766			; 0x8c86 (U+5091)
	Chars C_KANJI_JIS_3767			; 0x8c87 (U+6b20)
	Chars C_KANJI_JIS_3768			; 0x8c88 (U+6c7a)
	Chars C_KANJI_JIS_3769			; 0x8c89 (U+6f54)
	Chars C_KANJI_JIS_376A			; 0x8c8a (U+7a74)
Section7d50Start	label	Chars
	Chars C_KANJI_JIS_376B			; 0x8c8b (U+7d50)
Section8840Start	label	Chars
	Chars C_KANJI_JIS_376C			; 0x8c8c (U+8840)
Section8a20Start	label	Chars
	Chars C_KANJI_JIS_376D			; 0x8c8d (U+8a23)
Section6700Start	label	Chars
	Chars C_KANJI_JIS_376E			; 0x8c8e (U+6708)
	Chars C_KANJI_JIS_376F			; 0x8c8f (U+4ef6)
	Chars C_KANJI_JIS_3770			; 0x8c90 (U+5039)
Section5020Start	label	Chars
	Chars C_KANJI_JIS_3771			; 0x8c91 (U+5026)
Section5060Start	label	Chars
	Chars C_KANJI_JIS_3772			; 0x8c92 (U+5065)
	Chars C_KANJI_JIS_3773			; 0x8c93 (U+517c)
Section5230Start	label	Chars
	Chars C_KANJI_JIS_3774			; 0x8c94 (U+5238)
Section5260Start	label	Chars
	Chars C_KANJI_JIS_3775			; 0x8c95 (U+5263)
	Chars C_KANJI_JIS_3776			; 0x8c96 (U+55a7)
Section5700Start	label	Chars
	Chars C_KANJI_JIS_3777			; 0x8c97 (U+570f)
Section5800Start	label	Chars
	Chars C_KANJI_JIS_3778			; 0x8c98 (U+5805)
	Chars C_KANJI_JIS_3779			; 0x8c99 (U+5acc)
	Chars C_KANJI_JIS_377A			; 0x8c9a (U+5efa)
	Chars C_KANJI_JIS_377B			; 0x8c9b (U+61b2)
Section61f0Start	label	Chars
	Chars C_KANJI_JIS_377C			; 0x8c9c (U+61f8)
Section62f0Start	label	Chars
	Chars C_KANJI_JIS_377D			; 0x8c9d (U+62f3)
Section6370Start	label	Chars
	Chars C_KANJI_JIS_377E			; 0x8c9e (U+6372)
	Chars C_KANJI_JIS_3821			; 0x8c9f (U+691c)
	Chars C_KANJI_JIS_3822			; 0x8ca0 (U+6a29)
Section7270Start	label	Chars
	Chars C_KANJI_JIS_3823			; 0x8ca1 (U+727d)
	Chars C_KANJI_JIS_3824			; 0x8ca2 (U+72ac)
Section7320Start	label	Chars
	Chars C_KANJI_JIS_3825			; 0x8ca3 (U+732e)
Section7810Start	label	Chars
	Chars C_KANJI_JIS_3826			; 0x8ca4 (U+7814)
Section7860Start	label	Chars
	Chars C_KANJI_JIS_3827			; 0x8ca5 (U+786f)
	Chars C_KANJI_JIS_3828			; 0x8ca6 (U+7d79)
	Chars C_KANJI_JIS_3829			; 0x8ca7 (U+770c)
Section80a0Start	label	Chars
	Chars C_KANJI_JIS_382A			; 0x8ca8 (U+80a9)
	Chars C_KANJI_JIS_382B			; 0x8ca9 (U+898b)
Section8b10Start	label	Chars
	Chars C_KANJI_JIS_382C			; 0x8caa (U+8b19)
Section8ce0Start	label	Chars
	Chars C_KANJI_JIS_382D			; 0x8cab (U+8ce2)
Section8ed0Start	label	Chars
	Chars C_KANJI_JIS_382E			; 0x8cac (U+8ed2)
	Chars C_KANJI_JIS_382F			; 0x8cad (U+9063)
Section9370Start	label	Chars
	Chars C_KANJI_JIS_3830			; 0x8cae (U+9375)
	Chars C_KANJI_JIS_3831			; 0x8caf (U+967a)
	Chars C_KANJI_JIS_3832			; 0x8cb0 (U+9855)
Section9a10Start	label	Chars
	Chars C_KANJI_JIS_3833			; 0x8cb1 (U+9a13)
Section9e70Start	label	Chars
	Chars C_KANJI_JIS_3834			; 0x8cb2 (U+9e78)
	Chars C_KANJI_JIS_3835			; 0x8cb3 (U+5143)
Section5390Start	label	Chars
	Chars C_KANJI_JIS_3836			; 0x8cb4 (U+539f)
	Chars C_KANJI_JIS_3837			; 0x8cb5 (U+53b3)
	Chars C_KANJI_JIS_3838			; 0x8cb6 (U+5e7b)
Section5f20Start	label	Chars
	Chars C_KANJI_JIS_3839			; 0x8cb7 (U+5f26)
	Chars C_KANJI_JIS_383A			; 0x8cb8 (U+6e1b)
Section6e90Start	label	Chars
	Chars C_KANJI_JIS_383B			; 0x8cb9 (U+6e90)
	Chars C_KANJI_JIS_383C			; 0x8cba (U+7384)
Section73f0Start	label	Chars
	Chars C_KANJI_JIS_383D			; 0x8cbb (U+73fe)
	Chars C_KANJI_JIS_383E			; 0x8cbc (U+7d43)
Section8230Start	label	Chars
	Chars C_KANJI_JIS_383F			; 0x8cbd (U+8237)
	Chars C_KANJI_JIS_3840			; 0x8cbe (U+8a00)
Section8af0Start	label	Chars
	Chars C_KANJI_JIS_3841			; 0x8cbf (U+8afa)
Section9650Start	label	Chars
	Chars C_KANJI_JIS_3842			; 0x8cc0 (U+9650)
	Chars C_KANJI_JIS_3843			; 0x8cc1 (U+4e4e)
Section5000Start	label	Chars
	Chars C_KANJI_JIS_3844			; 0x8cc2 (U+500b)
	Chars C_KANJI_JIS_3845			; 0x8cc3 (U+53e4)
Section5470Start	label	Chars
	Chars C_KANJI_JIS_3846			; 0x8cc4 (U+547c)
	Chars C_KANJI_JIS_3847			; 0x8cc5 (U+56fa)
	Chars C_KANJI_JIS_3848			; 0x8cc6 (U+59d1)
	Chars C_KANJI_JIS_3849			; 0x8cc7 (U+5b64)
	Chars C_KANJI_JIS_384A			; 0x8cc8 (U+5df1)
Section5ea0Start	label	Chars
	Chars C_KANJI_JIS_384B			; 0x8cc9 (U+5eab)
	Chars C_KANJI_JIS_384C			; 0x8cca (U+5f27)
Section6230Start	label	Chars
	Chars C_KANJI_JIS_384D			; 0x8ccb (U+6238)
Section6540Start	label	Chars
	Chars C_KANJI_JIS_384E			; 0x8ccc (U+6545)
Section67a0Start	label	Chars
	Chars C_KANJI_JIS_384F			; 0x8ccd (U+67af)
Section6e50Start	label	Chars
	Chars C_KANJI_JIS_3850			; 0x8cce (U+6e56)
	Chars C_KANJI_JIS_3851			; 0x8ccf (U+72d0)
Section7cc0Start	label	Chars
	Chars C_KANJI_JIS_3852			; 0x8cd0 (U+7cca)
	Chars C_KANJI_JIS_3853			; 0x8cd1 (U+88b4)
	Chars C_KANJI_JIS_3854			; 0x8cd2 (U+80a1)
	Chars C_KANJI_JIS_3855			; 0x8cd3 (U+80e1)
Section83f0Start	label	Chars
	Chars C_KANJI_JIS_3856			; 0x8cd4 (U+83f0)
Section8640Start	label	Chars
	Chars C_KANJI_JIS_3857			; 0x8cd5 (U+864e)
Section8a80Start	label	Chars
	Chars C_KANJI_JIS_3858			; 0x8cd6 (U+8a87)
Section8de0Start	label	Chars
	Chars C_KANJI_JIS_3859			; 0x8cd7 (U+8de8)
Section9230Start	label	Chars
	Chars C_KANJI_JIS_385A			; 0x8cd8 (U+9237)
	Chars C_KANJI_JIS_385B			; 0x8cd9 (U+96c7)
Section9860Start	label	Chars
	Chars C_KANJI_JIS_385C			; 0x8cda (U+9867)
Section9f10Start	label	Chars
	Chars C_KANJI_JIS_385D			; 0x8cdb (U+9f13)
	Chars C_KANJI_JIS_385E			; 0x8cdc (U+4e94)
	Chars C_KANJI_JIS_385F			; 0x8cdd (U+4e92)
	Chars C_KANJI_JIS_3860			; 0x8cde (U+4f0d)
Section5340Start	label	Chars
	Chars C_KANJI_JIS_3861			; 0x8cdf (U+5348)
Section5440Start	label	Chars
	Chars C_KANJI_JIS_3862			; 0x8ce0 (U+5449)
	Chars C_KANJI_JIS_3863			; 0x8ce1 (U+543e)
Section5a20Start	label	Chars
	Chars C_KANJI_JIS_3864			; 0x8ce2 (U+5a2f)
	Chars C_KANJI_JIS_3865			; 0x8ce3 (U+5f8c)
Section5fa0Start	label	Chars
	Chars C_KANJI_JIS_3866			; 0x8ce4 (U+5fa1)
	Chars C_KANJI_JIS_3867			; 0x8ce5 (U+609f)
Section68a0Start	label	Chars
	Chars C_KANJI_JIS_3868			; 0x8ce6 (U+68a7)
Section6a80Start	label	Chars
	Chars C_KANJI_JIS_3869			; 0x8ce7 (U+6a8e)
	Chars C_KANJI_JIS_386A			; 0x8ce8 (U+745a)
	Chars C_KANJI_JIS_386B			; 0x8ce9 (U+7881)
Section8a90Start	label	Chars
	Chars C_KANJI_JIS_386C			; 0x8cea (U+8a9e)
Section8aa0Start	label	Chars
	Chars C_KANJI_JIS_386D			; 0x8ceb (U+8aa4)
	Chars C_KANJI_JIS_386E			; 0x8cec (U+8b77)
Section9190Start	label	Chars
	Chars C_KANJI_JIS_386F			; 0x8ced (U+9190)
	Chars C_KANJI_JIS_3870			; 0x8cee (U+4e5e)
Section9bc0Start	label	Chars
	Chars C_KANJI_JIS_3871			; 0x8cef (U+9bc9)
	Chars C_KANJI_JIS_3872			; 0x8cf0 (U+4ea4)
	Chars C_KANJI_JIS_3873			; 0x8cf1 (U+4f7c)
	Chars C_KANJI_JIS_3874			; 0x8cf2 (U+4faf)
Section5010Start	label	Chars
	Chars C_KANJI_JIS_3875			; 0x8cf3 (U+5019)
	Chars C_KANJI_JIS_3876			; 0x8cf4 (U+5016)
	Chars C_KANJI_JIS_3877			; 0x8cf5 (U+5149)
Section5160Start	label	Chars
	Chars C_KANJI_JIS_3878			; 0x8cf6 (U+516c)
Section5290Start	label	Chars
	Chars C_KANJI_JIS_3879			; 0x8cf7 (U+529f)
	Chars C_KANJI_JIS_387A			; 0x8cf8 (U+52b9)
	Chars C_KANJI_JIS_387B			; 0x8cf9 (U+52fe)
	Chars C_KANJI_JIS_387C			; 0x8cfa (U+539a)
	Chars C_KANJI_JIS_387D			; 0x8cfb (U+53e3)
	Chars C_KANJI_JIS_387E			; 0x8cfc (U+5411)
	Chars 0					; 0x8cfd
	Chars 0					; 0x8cfe
	Chars 0					; 0x8cff

	Chars C_KANJI_JIS_3921			; 0x8d40 (U+540e)
Section5580Start	label	Chars
	Chars C_KANJI_JIS_3922			; 0x8d41 (U+5589)
Section5750Start	label	Chars
	Chars C_KANJI_JIS_3923			; 0x8d42 (U+5751)
	Chars C_KANJI_JIS_3924			; 0x8d43 (U+57a2)
Section5970Start	label	Chars
	Chars C_KANJI_JIS_3925			; 0x8d44 (U+597d)
Section5b50Start	label	Chars
	Chars C_KANJI_JIS_3926			; 0x8d45 (U+5b54)
	Chars C_KANJI_JIS_3927			; 0x8d46 (U+5b5d)
	Chars C_KANJI_JIS_3928			; 0x8d47 (U+5b8f)
	Chars C_KANJI_JIS_3929			; 0x8d48 (U+5de5)
	Chars C_KANJI_JIS_392A			; 0x8d49 (U+5de7)
	Chars C_KANJI_JIS_392B			; 0x8d4a (U+5df7)
	Chars C_KANJI_JIS_392C			; 0x8d4b (U+5e78)
Section5e80Start	label	Chars
	Chars C_KANJI_JIS_392D			; 0x8d4c (U+5e83)
Section5e90Start	label	Chars
	Chars C_KANJI_JIS_392E			; 0x8d4d (U+5e9a)
	Chars C_KANJI_JIS_392F			; 0x8d4e (U+5eb7)
	Chars C_KANJI_JIS_3930			; 0x8d4f (U+5f18)
	Chars C_KANJI_JIS_3931			; 0x8d50 (U+6052)
Section6140Start	label	Chars
	Chars C_KANJI_JIS_3932			; 0x8d51 (U+614c)
Section6290Start	label	Chars
	Chars C_KANJI_JIS_3933			; 0x8d52 (U+6297)
	Chars C_KANJI_JIS_3934			; 0x8d53 (U+62d8)
	Chars C_KANJI_JIS_3935			; 0x8d54 (U+63a7)
	Chars C_KANJI_JIS_3936			; 0x8d55 (U+653b)
Section6600Start	label	Chars
	Chars C_KANJI_JIS_3937			; 0x8d56 (U+6602)
Section6640Start	label	Chars
	Chars C_KANJI_JIS_3938			; 0x8d57 (U+6643)
	Chars C_KANJI_JIS_3939			; 0x8d58 (U+66f4)
Section6760Start	label	Chars
	Chars C_KANJI_JIS_393A			; 0x8d59 (U+676d)
	Chars C_KANJI_JIS_393B			; 0x8d5a (U+6821)
	Chars C_KANJI_JIS_393C			; 0x8d5b (U+6897)
Section69c0Start	label	Chars
	Chars C_KANJI_JIS_393D			; 0x8d5c (U+69cb)
	Chars C_KANJI_JIS_393E			; 0x8d5d (U+6c5f)
	Chars C_KANJI_JIS_393F			; 0x8d5e (U+6d2a)
	Chars C_KANJI_JIS_3940			; 0x8d5f (U+6d69)
	Chars C_KANJI_JIS_3941			; 0x8d60 (U+6e2f)
	Chars C_KANJI_JIS_3942			; 0x8d61 (U+6e9d)
	Chars C_KANJI_JIS_3943			; 0x8d62 (U+7532)
	Chars C_KANJI_JIS_3944			; 0x8d63 (U+7687)
	Chars C_KANJI_JIS_3945			; 0x8d64 (U+786c)
	Chars C_KANJI_JIS_3946			; 0x8d65 (U+7a3f)
Section7ce0Start	label	Chars
	Chars C_KANJI_JIS_3947			; 0x8d66 (U+7ce0)
	Chars C_KANJI_JIS_3948			; 0x8d67 (U+7d05)
	Chars C_KANJI_JIS_3949			; 0x8d68 (U+7d18)
	Chars C_KANJI_JIS_394A			; 0x8d69 (U+7d5e)
	Chars C_KANJI_JIS_394B			; 0x8d6a (U+7db1)
Section8010Start	label	Chars
	Chars C_KANJI_JIS_394C			; 0x8d6b (U+8015)
Section8000Start	label	Chars
	Chars C_KANJI_JIS_394D			; 0x8d6c (U+8003)
	Chars C_KANJI_JIS_394E			; 0x8d6d (U+80af)
	Chars C_KANJI_JIS_394F			; 0x8d6e (U+80b1)
Section8150Start	label	Chars
	Chars C_KANJI_JIS_3950			; 0x8d6f (U+8154)
Section8180Start	label	Chars
	Chars C_KANJI_JIS_3951			; 0x8d70 (U+818f)
Section8220Start	label	Chars
	Chars C_KANJI_JIS_3952			; 0x8d71 (U+822a)
Section8350Start	label	Chars
	Chars C_KANJI_JIS_3953			; 0x8d72 (U+8352)
	Chars C_KANJI_JIS_3954			; 0x8d73 (U+884c)
	Chars C_KANJI_JIS_3955			; 0x8d74 (U+8861)
	Chars C_KANJI_JIS_3956			; 0x8d75 (U+8b1b)
	Chars C_KANJI_JIS_3957			; 0x8d76 (U+8ca2)
Section8cf0Start	label	Chars
	Chars C_KANJI_JIS_3958			; 0x8d77 (U+8cfc)
	Chars C_KANJI_JIS_3959			; 0x8d78 (U+90ca)
Section9170Start	label	Chars
	Chars C_KANJI_JIS_395A			; 0x8d79 (U+9175)
Section9270Start	label	Chars
	Chars C_KANJI_JIS_395B			; 0x8d7a (U+9271)
Section7830Start	label	Chars
	Chars C_KANJI_JIS_395C			; 0x8d7b (U+783f)
	Chars C_KANJI_JIS_395D			; 0x8d7c (U+92fc)
	Chars C_KANJI_JIS_395E			; 0x8d7d (U+95a4)
Section9640Start	label	Chars
	Chars C_KANJI_JIS_395F			; 0x8d7e (U+964d)
	Chars 0					; 0x8d7f
Section9800Start	label	Chars
	Chars C_KANJI_JIS_3960			; 0x8d80 (U+9805)
Section9990Start	label	Chars
	Chars C_KANJI_JIS_3961			; 0x8d81 (U+9999)
Section9ad0Start	label	Chars
	Chars C_KANJI_JIS_3962			; 0x8d82 (U+9ad8)
Section9d30Start	label	Chars
	Chars C_KANJI_JIS_3963			; 0x8d83 (U+9d3b)
Section5250Start	label	Chars
	Chars C_KANJI_JIS_3964			; 0x8d84 (U+525b)
	Chars C_KANJI_JIS_3965			; 0x8d85 (U+52ab)
	Chars C_KANJI_JIS_3966			; 0x8d86 (U+53f7)
	Chars C_KANJI_JIS_3967			; 0x8d87 (U+5408)
Section58d0Start	label	Chars
	Chars C_KANJI_JIS_3968			; 0x8d88 (U+58d5)
	Chars C_KANJI_JIS_3969			; 0x8d89 (U+62f7)
Section6fe0Start	label	Chars
	Chars C_KANJI_JIS_396A			; 0x8d8a (U+6fe0)
Section8c60Start	label	Chars
	Chars C_KANJI_JIS_396B			; 0x8d8b (U+8c6a)
Section8f50Start	label	Chars
	Chars C_KANJI_JIS_396C			; 0x8d8c (U+8f5f)
Section9eb0Start	label	Chars
	Chars C_KANJI_JIS_396D			; 0x8d8d (U+9eb9)
	Chars C_KANJI_JIS_396E			; 0x8d8e (U+514b)
	Chars C_KANJI_JIS_396F			; 0x8d8f (U+523b)
	Chars C_KANJI_JIS_3970			; 0x8d90 (U+544a)
	Chars C_KANJI_JIS_3971			; 0x8d91 (U+56fd)
	Chars C_KANJI_JIS_3972			; 0x8d92 (U+7a40)
	Chars C_KANJI_JIS_3973			; 0x8d93 (U+9177)
Section9d60Start	label	Chars
	Chars C_KANJI_JIS_3974			; 0x8d94 (U+9d60)
Section9ed0Start	label	Chars
	Chars C_KANJI_JIS_3975			; 0x8d95 (U+9ed2)
Section7340Start	label	Chars
	Chars C_KANJI_JIS_3976			; 0x8d96 (U+7344)
	Chars C_KANJI_JIS_3977			; 0x8d97 (U+6f09)
Section8170Start	label	Chars
	Chars C_KANJI_JIS_3978			; 0x8d98 (U+8170)
	Chars C_KANJI_JIS_3979			; 0x8d99 (U+7511)
Section5ff0Start	label	Chars
	Chars C_KANJI_JIS_397A			; 0x8d9a (U+5ffd)
	Chars C_KANJI_JIS_397B			; 0x8d9b (U+60da)
Section9aa0Start	label	Chars
	Chars C_KANJI_JIS_397C			; 0x8d9c (U+9aa8)
	Chars C_KANJI_JIS_397D			; 0x8d9d (U+72db)
Section8fb0Start	label	Chars
	Chars C_KANJI_JIS_397E			; 0x8d9e (U+8fbc)
Section6b60Start	label	Chars
	Chars C_KANJI_JIS_3A21			; 0x8d9f (U+6b64)
	Chars C_KANJI_JIS_3A22			; 0x8da0 (U+9803)
	Chars C_KANJI_JIS_3A23			; 0x8da1 (U+4eca)
	Chars C_KANJI_JIS_3A24			; 0x8da2 (U+56f0)
Section5760Start	label	Chars
	Chars C_KANJI_JIS_3A25			; 0x8da3 (U+5764)
Section58b0Start	label	Chars
	Chars C_KANJI_JIS_3A26			; 0x8da4 (U+58be)
Section5a50Start	label	Chars
	Chars C_KANJI_JIS_3A27			; 0x8da5 (U+5a5a)
	Chars C_KANJI_JIS_3A28			; 0x8da6 (U+6068)
Section61c0Start	label	Chars
	Chars C_KANJI_JIS_3A29			; 0x8da7 (U+61c7)
	Chars C_KANJI_JIS_3A2A			; 0x8da8 (U+660f)
	Chars C_KANJI_JIS_3A2B			; 0x8da9 (U+6606)
	Chars C_KANJI_JIS_3A2C			; 0x8daa (U+6839)
	Chars C_KANJI_JIS_3A2D			; 0x8dab (U+68b1)
Section6df0Start	label	Chars
	Chars C_KANJI_JIS_3A2E			; 0x8dac (U+6df7)
Section75d0Start	label	Chars
	Chars C_KANJI_JIS_3A2F			; 0x8dad (U+75d5)
Section7d30Start	label	Chars
	Chars C_KANJI_JIS_3A30			; 0x8dae (U+7d3a)
	Chars C_KANJI_JIS_3A31			; 0x8daf (U+826e)
	Chars C_KANJI_JIS_3A32			; 0x8db0 (U+9b42)
	Chars C_KANJI_JIS_3A33			; 0x8db1 (U+4e9b)
	Chars C_KANJI_JIS_3A34			; 0x8db2 (U+4f50)
	Chars C_KANJI_JIS_3A35			; 0x8db3 (U+53c9)
	Chars C_KANJI_JIS_3A36			; 0x8db4 (U+5506)
Section5d60Start	label	Chars
	Chars C_KANJI_JIS_3A37			; 0x8db5 (U+5d6f)
	Chars C_KANJI_JIS_3A38			; 0x8db6 (U+5de6)
	Chars C_KANJI_JIS_3A39			; 0x8db7 (U+5dee)
	Chars C_KANJI_JIS_3A3A			; 0x8db8 (U+67fb)
	Chars C_KANJI_JIS_3A3B			; 0x8db9 (U+6c99)
Section7470Start	label	Chars
	Chars C_KANJI_JIS_3A3C			; 0x8dba (U+7473)
Section7800Start	label	Chars
	Chars C_KANJI_JIS_3A3D			; 0x8dbb (U+7802)
Section8a50Start	label	Chars
	Chars C_KANJI_JIS_3A3E			; 0x8dbc (U+8a50)
Section9390Start	label	Chars
	Chars C_KANJI_JIS_3A3F			; 0x8dbd (U+9396)
Section88d0Start	label	Chars
	Chars C_KANJI_JIS_3A40			; 0x8dbe (U+88df)
	Chars C_KANJI_JIS_3A41			; 0x8dbf (U+5750)
	Chars C_KANJI_JIS_3A42			; 0x8dc0 (U+5ea7)
	Chars C_KANJI_JIS_3A43			; 0x8dc1 (U+632b)
	Chars C_KANJI_JIS_3A44			; 0x8dc2 (U+50b5)
Section50a0Start	label	Chars
	Chars C_KANJI_JIS_3A45			; 0x8dc3 (U+50ac)
	Chars C_KANJI_JIS_3A46			; 0x8dc4 (U+518d)
	Chars C_KANJI_JIS_3A47			; 0x8dc5 (U+6700)
	Chars C_KANJI_JIS_3A48			; 0x8dc6 (U+54c9)
Section5850Start	label	Chars
	Chars C_KANJI_JIS_3A49			; 0x8dc7 (U+585e)
Section59b0Start	label	Chars
	Chars C_KANJI_JIS_3A4A			; 0x8dc8 (U+59bb)
	Chars C_KANJI_JIS_3A4B			; 0x8dc9 (U+5bb0)
	Chars C_KANJI_JIS_3A4C			; 0x8dca (U+5f69)
Section6240Start	label	Chars
	Chars C_KANJI_JIS_3A4D			; 0x8dcb (U+624d)
	Chars C_KANJI_JIS_3A4E			; 0x8dcc (U+63a1)
	Chars C_KANJI_JIS_3A4F			; 0x8dcd (U+683d)
Section6b70Start	label	Chars
	Chars C_KANJI_JIS_3A50			; 0x8dce (U+6b73)
	Chars C_KANJI_JIS_3A51			; 0x8dcf (U+6e08)
	Chars C_KANJI_JIS_3A52			; 0x8dd0 (U+707d)
Section91c0Start	label	Chars
	Chars C_KANJI_JIS_3A53			; 0x8dd1 (U+91c7)
Section7280Start	label	Chars
	Chars C_KANJI_JIS_3A54			; 0x8dd2 (U+7280)
	Chars C_KANJI_JIS_3A55			; 0x8dd3 (U+7815)
	Chars C_KANJI_JIS_3A56			; 0x8dd4 (U+7826)
Section7960Start	label	Chars
	Chars C_KANJI_JIS_3A57			; 0x8dd5 (U+796d)
Section6580Start	label	Chars
	Chars C_KANJI_JIS_3A58			; 0x8dd6 (U+658e)
	Chars C_KANJI_JIS_3A59			; 0x8dd7 (U+7d30)
	Chars C_KANJI_JIS_3A5A			; 0x8dd8 (U+83dc)
Section88c0Start	label	Chars
	Chars C_KANJI_JIS_3A5B			; 0x8dd9 (U+88c1)
	Chars C_KANJI_JIS_3A5C			; 0x8dda (U+8f09)
	Chars C_KANJI_JIS_3A5D			; 0x8ddb (U+969b)
	Chars C_KANJI_JIS_3A5E			; 0x8ddc (U+5264)
	Chars C_KANJI_JIS_3A5F			; 0x8ddd (U+5728)
Section6750Start	label	Chars
	Chars C_KANJI_JIS_3A60			; 0x8dde (U+6750)
	Chars C_KANJI_JIS_3A61			; 0x8ddf (U+7f6a)
	Chars C_KANJI_JIS_3A62			; 0x8de0 (U+8ca1)
Section51b0Start	label	Chars
	Chars C_KANJI_JIS_3A63			; 0x8de1 (U+51b4)
	Chars C_KANJI_JIS_3A64			; 0x8de2 (U+5742)
Section9620Start	label	Chars
	Chars C_KANJI_JIS_3A65			; 0x8de3 (U+962a)
	Chars C_KANJI_JIS_3A66			; 0x8de4 (U+583a)
	Chars C_KANJI_JIS_3A67			; 0x8de5 (U+698a)
	Chars C_KANJI_JIS_3A68			; 0x8de6 (U+80b4)
	Chars C_KANJI_JIS_3A69			; 0x8de7 (U+54b2)
Section5d00Start	label	Chars
	Chars C_KANJI_JIS_3A6A			; 0x8de8 (U+5d0e)
	Chars C_KANJI_JIS_3A6B			; 0x8de9 (U+57fc)
	Chars C_KANJI_JIS_3A6C			; 0x8dea (U+7895)
Section9df0Start	label	Chars
	Chars C_KANJI_JIS_3A6D			; 0x8deb (U+9dfa)
	Chars C_KANJI_JIS_3A6E			; 0x8dec (U+4f5c)
Section5240Start	label	Chars
	Chars C_KANJI_JIS_3A6F			; 0x8ded (U+524a)
Section5480Start	label	Chars
	Chars C_KANJI_JIS_3A70			; 0x8dee (U+548b)
	Chars C_KANJI_JIS_3A71			; 0x8def (U+643e)
	Chars C_KANJI_JIS_3A72			; 0x8df0 (U+6628)
	Chars C_KANJI_JIS_3A73			; 0x8df1 (U+6714)
	Chars C_KANJI_JIS_3A74			; 0x8df2 (U+67f5)
Section7a80Start	label	Chars
	Chars C_KANJI_JIS_3A75			; 0x8df3 (U+7a84)
Section7b50Start	label	Chars
	Chars C_KANJI_JIS_3A76			; 0x8df4 (U+7b56)
Section7d20Start	label	Chars
	Chars C_KANJI_JIS_3A77			; 0x8df5 (U+7d22)
	Chars C_KANJI_JIS_3A78			; 0x8df6 (U+932f)
	Chars C_KANJI_JIS_3A79			; 0x8df7 (U+685c)
Section9ba0Start	label	Chars
	Chars C_KANJI_JIS_3A7A			; 0x8df8 (U+9bad)
Section7b30Start	label	Chars
	Chars C_KANJI_JIS_3A7B			; 0x8df9 (U+7b39)
	Chars C_KANJI_JIS_3A7C			; 0x8dfa (U+5319)
	Chars C_KANJI_JIS_3A7D			; 0x8dfb (U+518a)
	Chars C_KANJI_JIS_3A7E			; 0x8dfc (U+5237)
	Chars 0					; 0x8dfd
	Chars 0					; 0x8dfe
	Chars 0					; 0x8dff

	Chars C_KANJI_JIS_3B21			; 0x8e40 (U+5bdf)
	Chars C_KANJI_JIS_3B22			; 0x8e41 (U+62f6)
Section64a0Start	label	Chars
	Chars C_KANJI_JIS_3B23			; 0x8e42 (U+64ae)
	Chars C_KANJI_JIS_3B24			; 0x8e43 (U+64e6)
Section6720Start	label	Chars
	Chars C_KANJI_JIS_3B25			; 0x8e44 (U+672d)
	Chars C_KANJI_JIS_3B26			; 0x8e45 (U+6bba)
	Chars C_KANJI_JIS_3B27			; 0x8e46 (U+85a9)
Section96d0Start	label	Chars
	Chars C_KANJI_JIS_3B28			; 0x8e47 (U+96d1)
Section7690Start	label	Chars
	Chars C_KANJI_JIS_3B29			; 0x8e48 (U+7690)
Section9bd0Start	label	Chars
	Chars C_KANJI_JIS_3B2A			; 0x8e49 (U+9bd6)
Section6340Start	label	Chars
	Chars C_KANJI_JIS_3B2B			; 0x8e4a (U+634c)
Section9300Start	label	Chars
	Chars C_KANJI_JIS_3B2C			; 0x8e4b (U+9306)
	Chars C_KANJI_JIS_3B2D			; 0x8e4c (U+9bab)
Section76b0Start	label	Chars
	Chars C_KANJI_JIS_3B2E			; 0x8e4d (U+76bf)
Section6650Start	label	Chars
	Chars C_KANJI_JIS_3B2F			; 0x8e4e (U+6652)
	Chars C_KANJI_JIS_3B30			; 0x8e4f (U+4e09)
	Chars C_KANJI_JIS_3B31			; 0x8e50 (U+5098)
	Chars C_KANJI_JIS_3B32			; 0x8e51 (U+53c2)
Section5c70Start	label	Chars
	Chars C_KANJI_JIS_3B33			; 0x8e52 (U+5c71)
Section60e0Start	label	Chars
	Chars C_KANJI_JIS_3B34			; 0x8e53 (U+60e8)
Section6490Start	label	Chars
	Chars C_KANJI_JIS_3B35			; 0x8e54 (U+6492)
	Chars C_KANJI_JIS_3B36			; 0x8e55 (U+6563)
	Chars C_KANJI_JIS_3B37			; 0x8e56 (U+685f)
Section71e0Start	label	Chars
	Chars C_KANJI_JIS_3B38			; 0x8e57 (U+71e6)
	Chars C_KANJI_JIS_3B39			; 0x8e58 (U+73ca)
	Chars C_KANJI_JIS_3B3A			; 0x8e59 (U+7523)
Section7b90Start	label	Chars
	Chars C_KANJI_JIS_3B3B			; 0x8e5a (U+7b97)
Section7e80Start	label	Chars
	Chars C_KANJI_JIS_3B3C			; 0x8e5b (U+7e82)
Section8690Start	label	Chars
	Chars C_KANJI_JIS_3B3D			; 0x8e5c (U+8695)
Section8b80Start	label	Chars
	Chars C_KANJI_JIS_3B3E			; 0x8e5d (U+8b83)
Section8cd0Start	label	Chars
	Chars C_KANJI_JIS_3B3F			; 0x8e5e (U+8cdb)
	Chars C_KANJI_JIS_3B40			; 0x8e5f (U+9178)
	Chars C_KANJI_JIS_3B41			; 0x8e60 (U+9910)
	Chars C_KANJI_JIS_3B42			; 0x8e61 (U+65ac)
Section66a0Start	label	Chars
	Chars C_KANJI_JIS_3B43			; 0x8e62 (U+66ab)
Section6b80Start	label	Chars
	Chars C_KANJI_JIS_3B44			; 0x8e63 (U+6b8b)
Section4ed0Start	label	Chars
	Chars C_KANJI_JIS_3B45			; 0x8e64 (U+4ed5)
	Chars C_KANJI_JIS_3B46			; 0x8e65 (U+4ed4)
	Chars C_KANJI_JIS_3B47			; 0x8e66 (U+4f3a)
	Chars C_KANJI_JIS_3B48			; 0x8e67 (U+4f7f)
	Chars C_KANJI_JIS_3B49			; 0x8e68 (U+523a)
	Chars C_KANJI_JIS_3B4A			; 0x8e69 (U+53f8)
	Chars C_KANJI_JIS_3B4B			; 0x8e6a (U+53f2)
Section55e0Start	label	Chars
	Chars C_KANJI_JIS_3B4C			; 0x8e6b (U+55e3)
	Chars C_KANJI_JIS_3B4D			; 0x8e6c (U+56db)
Section58e0Start	label	Chars
	Chars C_KANJI_JIS_3B4E			; 0x8e6d (U+58eb)
Section59c0Start	label	Chars
	Chars C_KANJI_JIS_3B4F			; 0x8e6e (U+59cb)
	Chars C_KANJI_JIS_3B50			; 0x8e6f (U+59c9)
	Chars C_KANJI_JIS_3B51			; 0x8e70 (U+59ff)
	Chars C_KANJI_JIS_3B52			; 0x8e71 (U+5b50)
	Chars C_KANJI_JIS_3B53			; 0x8e72 (U+5c4d)
	Chars C_KANJI_JIS_3B54			; 0x8e73 (U+5e02)
Section5e20Start	label	Chars
	Chars C_KANJI_JIS_3B55			; 0x8e74 (U+5e2b)
	Chars C_KANJI_JIS_3B56			; 0x8e75 (U+5fd7)
Section6010Start	label	Chars
	Chars C_KANJI_JIS_3B57			; 0x8e76 (U+601d)
	Chars C_KANJI_JIS_3B58			; 0x8e77 (U+6307)
Section6520Start	label	Chars
	Chars C_KANJI_JIS_3B59			; 0x8e78 (U+652f)
	Chars C_KANJI_JIS_3B5A			; 0x8e79 (U+5b5c)
	Chars C_KANJI_JIS_3B5B			; 0x8e7a (U+65af)
	Chars C_KANJI_JIS_3B5C			; 0x8e7b (U+65bd)
	Chars C_KANJI_JIS_3B5D			; 0x8e7c (U+65e8)
	Chars C_KANJI_JIS_3B5E			; 0x8e7d (U+679d)
	Chars C_KANJI_JIS_3B5F			; 0x8e7e (U+6b62)
	Chars 0					; 0x8e7f
	Chars C_KANJI_JIS_3B60			; 0x8e80 (U+6b7b)
Section6c00Start	label	Chars
	Chars C_KANJI_JIS_3B61			; 0x8e81 (U+6c0f)
	Chars C_KANJI_JIS_3B62			; 0x8e82 (U+7345)
	Chars C_KANJI_JIS_3B63			; 0x8e83 (U+7949)
Section79c0Start	label	Chars
	Chars C_KANJI_JIS_3B64			; 0x8e84 (U+79c1)
	Chars C_KANJI_JIS_3B65			; 0x8e85 (U+7cf8)
	Chars C_KANJI_JIS_3B66			; 0x8e86 (U+7d19)
	Chars C_KANJI_JIS_3B67			; 0x8e87 (U+7d2b)
	Chars C_KANJI_JIS_3B68			; 0x8e88 (U+80a2)
	Chars C_KANJI_JIS_3B69			; 0x8e89 (U+8102)
	Chars C_KANJI_JIS_3B6A			; 0x8e8a (U+81f3)
	Chars C_KANJI_JIS_3B6B			; 0x8e8b (U+8996)
	Chars C_KANJI_JIS_3B6C			; 0x8e8c (U+8a5e)
	Chars C_KANJI_JIS_3B6D			; 0x8e8d (U+8a69)
	Chars C_KANJI_JIS_3B6E			; 0x8e8e (U+8a66)
	Chars C_KANJI_JIS_3B6F			; 0x8e8f (U+8a8c)
Section8ae0Start	label	Chars
	Chars C_KANJI_JIS_3B70			; 0x8e90 (U+8aee)
	Chars C_KANJI_JIS_3B71			; 0x8e91 (U+8cc7)
	Chars C_KANJI_JIS_3B72			; 0x8e92 (U+8cdc)
	Chars C_KANJI_JIS_3B73			; 0x8e93 (U+96cc)
	Chars C_KANJI_JIS_3B74			; 0x8e94 (U+98fc)
	Chars C_KANJI_JIS_3B75			; 0x8e95 (U+6b6f)
	Chars C_KANJI_JIS_3B76			; 0x8e96 (U+4e8b)
	Chars C_KANJI_JIS_3B77			; 0x8e97 (U+4f3c)
	Chars C_KANJI_JIS_3B78			; 0x8e98 (U+4f8d)
	Chars C_KANJI_JIS_3B79			; 0x8e99 (U+5150)
	Chars C_KANJI_JIS_3B7A			; 0x8e9a (U+5b57)
Section5bf0Start	label	Chars
	Chars C_KANJI_JIS_3B7B			; 0x8e9b (U+5bfa)
	Chars C_KANJI_JIS_3B7C			; 0x8e9c (U+6148)
	Chars C_KANJI_JIS_3B7D			; 0x8e9d (U+6301)
	Chars C_KANJI_JIS_3B7E			; 0x8e9e (U+6642)
	Chars C_KANJI_JIS_3C21			; 0x8e9f (U+6b21)
Section6ec0Start	label	Chars
	Chars C_KANJI_JIS_3C22			; 0x8ea0 (U+6ecb)
	Chars C_KANJI_JIS_3C23			; 0x8ea1 (U+6cbb)
Section7230Start	label	Chars
	Chars C_KANJI_JIS_3C24			; 0x8ea2 (U+723e)
	Chars C_KANJI_JIS_3C25			; 0x8ea3 (U+74bd)
	Chars C_KANJI_JIS_3C26			; 0x8ea4 (U+75d4)
Section78c0Start	label	Chars
	Chars C_KANJI_JIS_3C27			; 0x8ea5 (U+78c1)
Section7930Start	label	Chars
	Chars C_KANJI_JIS_3C28			; 0x8ea6 (U+793a)
	Chars C_KANJI_JIS_3C29			; 0x8ea7 (U+800c)
Section8030Start	label	Chars
	Chars C_KANJI_JIS_3C2A			; 0x8ea8 (U+8033)
	Chars C_KANJI_JIS_3C2B			; 0x8ea9 (U+81ea)
Section8490Start	label	Chars
	Chars C_KANJI_JIS_3C2C			; 0x8eaa (U+8494)
Section8f90Start	label	Chars
	Chars C_KANJI_JIS_3C2D			; 0x8eab (U+8f9e)
	Chars C_KANJI_JIS_3C2E			; 0x8eac (U+6c50)
	Chars C_KANJI_JIS_3C2F			; 0x8ead (U+9e7f)
Section5f00Start	label	Chars
	Chars C_KANJI_JIS_3C30			; 0x8eae (U+5f0f)
Section8b50Start	label	Chars
	Chars C_KANJI_JIS_3C31			; 0x8eaf (U+8b58)
	Chars C_KANJI_JIS_3C32			; 0x8eb0 (U+9d2b)
	Chars C_KANJI_JIS_3C33			; 0x8eb1 (U+7afa)
	Chars C_KANJI_JIS_3C34			; 0x8eb2 (U+8ef8)
	Chars C_KANJI_JIS_3C35			; 0x8eb3 (U+5b8d)
	Chars C_KANJI_JIS_3C36			; 0x8eb4 (U+96eb)
	Chars C_KANJI_JIS_3C37			; 0x8eb5 (U+4e03)
	Chars C_KANJI_JIS_3C38			; 0x8eb6 (U+53f1)
	Chars C_KANJI_JIS_3C39			; 0x8eb7 (U+57f7)
	Chars C_KANJI_JIS_3C3A			; 0x8eb8 (U+5931)
	Chars C_KANJI_JIS_3C3B			; 0x8eb9 (U+5ac9)
	Chars C_KANJI_JIS_3C3C			; 0x8eba (U+5ba4)
Section6080Start	label	Chars
	Chars C_KANJI_JIS_3C3D			; 0x8ebb (U+6089)
Section6e70Start	label	Chars
	Chars C_KANJI_JIS_3C3E			; 0x8ebc (U+6e7f)
	Chars C_KANJI_JIS_3C3F			; 0x8ebd (U+6f06)
Section75b0Start	label	Chars
	Chars C_KANJI_JIS_3C40			; 0x8ebe (U+75be)
	Chars C_KANJI_JIS_3C41			; 0x8ebf (U+8cea)
	Chars C_KANJI_JIS_3C42			; 0x8ec0 (U+5b9f)
Section8500Start	label	Chars
	Chars C_KANJI_JIS_3C43			; 0x8ec1 (U+8500)
Section7be0Start	label	Chars
	Chars C_KANJI_JIS_3C44			; 0x8ec2 (U+7be0)
	Chars C_KANJI_JIS_3C45			; 0x8ec3 (U+5072)
	Chars C_KANJI_JIS_3C46			; 0x8ec4 (U+67f4)
Section8290Start	label	Chars
	Chars C_KANJI_JIS_3C47			; 0x8ec5 (U+829d)
Section5c60Start	label	Chars
	Chars C_KANJI_JIS_3C48			; 0x8ec6 (U+5c61)
	Chars C_KANJI_JIS_3C49			; 0x8ec7 (U+854a)
Section7e10Start	label	Chars
	Chars C_KANJI_JIS_3C4A			; 0x8ec8 (U+7e1e)
	Chars C_KANJI_JIS_3C4B			; 0x8ec9 (U+820e)
Section5190Start	label	Chars
	Chars C_KANJI_JIS_3C4C			; 0x8eca (U+5199)
	Chars C_KANJI_JIS_3C4D			; 0x8ecb (U+5c04)
Section6360Start	label	Chars
	Chars C_KANJI_JIS_3C4E			; 0x8ecc (U+6368)
	Chars C_KANJI_JIS_3C4F			; 0x8ecd (U+8d66)
Section6590Start	label	Chars
	Chars C_KANJI_JIS_3C50			; 0x8ece (U+659c)
Section7160Start	label	Chars
	Chars C_KANJI_JIS_3C51			; 0x8ecf (U+716e)
	Chars C_KANJI_JIS_3C52			; 0x8ed0 (U+793e)
	Chars C_KANJI_JIS_3C53			; 0x8ed1 (U+7d17)
	Chars C_KANJI_JIS_3C54			; 0x8ed2 (U+8005)
	Chars C_KANJI_JIS_3C55			; 0x8ed3 (U+8b1d)
	Chars C_KANJI_JIS_3C56			; 0x8ed4 (U+8eca)
	Chars C_KANJI_JIS_3C57			; 0x8ed5 (U+906e)
	Chars C_KANJI_JIS_3C58			; 0x8ed6 (U+86c7)
Section90a0Start	label	Chars
	Chars C_KANJI_JIS_3C59			; 0x8ed7 (U+90aa)
	Chars C_KANJI_JIS_3C5A			; 0x8ed8 (U+501f)
	Chars C_KANJI_JIS_3C5B			; 0x8ed9 (U+52fa)
Section5c30Start	label	Chars
	Chars C_KANJI_JIS_3C5C			; 0x8eda (U+5c3a)
	Chars C_KANJI_JIS_3C5D			; 0x8edb (U+6753)
	Chars C_KANJI_JIS_3C5E			; 0x8edc (U+707c)
	Chars C_KANJI_JIS_3C5F			; 0x8edd (U+7235)
Section9140Start	label	Chars
	Chars C_KANJI_JIS_3C60			; 0x8ede (U+914c)
	Chars C_KANJI_JIS_3C61			; 0x8edf (U+91c8)
	Chars C_KANJI_JIS_3C62			; 0x8ee0 (U+932b)
	Chars C_KANJI_JIS_3C63			; 0x8ee1 (U+82e5)
	Chars C_KANJI_JIS_3C64			; 0x8ee2 (U+5bc2)
	Chars C_KANJI_JIS_3C65			; 0x8ee3 (U+5f31)
Section60f0Start	label	Chars
	Chars C_KANJI_JIS_3C66			; 0x8ee4 (U+60f9)
	Chars C_KANJI_JIS_3C67			; 0x8ee5 (U+4e3b)
Section53d0Start	label	Chars
	Chars C_KANJI_JIS_3C68			; 0x8ee6 (U+53d6)
	Chars C_KANJI_JIS_3C69			; 0x8ee7 (U+5b88)
	Chars C_KANJI_JIS_3C6A			; 0x8ee8 (U+624b)
	Chars C_KANJI_JIS_3C6B			; 0x8ee9 (U+6731)
	Chars C_KANJI_JIS_3C6C			; 0x8eea (U+6b8a)
	Chars C_KANJI_JIS_3C6D			; 0x8eeb (U+72e9)
	Chars C_KANJI_JIS_3C6E			; 0x8eec (U+73e0)
Section7a20Start	label	Chars
	Chars C_KANJI_JIS_3C6F			; 0x8eed (U+7a2e)
Section8160Start	label	Chars
	Chars C_KANJI_JIS_3C70			; 0x8eee (U+816b)
Section8da0Start	label	Chars
	Chars C_KANJI_JIS_3C71			; 0x8eef (U+8da3)
Section9150Start	label	Chars
	Chars C_KANJI_JIS_3C72			; 0x8ef0 (U+9152)
	Chars C_KANJI_JIS_3C73			; 0x8ef1 (U+9996)
Section5110Start	label	Chars
	Chars C_KANJI_JIS_3C74			; 0x8ef2 (U+5112)
	Chars C_KANJI_JIS_3C75			; 0x8ef3 (U+53d7)
Section5460Start	label	Chars
	Chars C_KANJI_JIS_3C76			; 0x8ef4 (U+546a)
	Chars C_KANJI_JIS_3C77			; 0x8ef5 (U+5bff)
Section6380Start	label	Chars
	Chars C_KANJI_JIS_3C78			; 0x8ef6 (U+6388)
	Chars C_KANJI_JIS_3C79			; 0x8ef7 (U+6a39)
	Chars C_KANJI_JIS_3C7A			; 0x8ef8 (U+7dac)
Section9700Start	label	Chars
	Chars C_KANJI_JIS_3C7B			; 0x8ef9 (U+9700)
	Chars C_KANJI_JIS_3C7C			; 0x8efa (U+56da)
	Chars C_KANJI_JIS_3C7D			; 0x8efb (U+53ce)
	Chars C_KANJI_JIS_3C7E			; 0x8efc (U+5468)
	Chars 0					; 0x8efd
	Chars 0					; 0x8efe
	Chars 0					; 0x8eff

	Chars C_KANJI_JIS_3D21			; 0x8f40 (U+5b97)
	Chars C_KANJI_JIS_3D22			; 0x8f41 (U+5c31)
Section5dd0Start	label	Chars
	Chars C_KANJI_JIS_3D23			; 0x8f42 (U+5dde)
Section4fe0Start	label	Chars
	Chars C_KANJI_JIS_3D24			; 0x8f43 (U+4fee)
	Chars C_KANJI_JIS_3D25			; 0x8f44 (U+6101)
	Chars C_KANJI_JIS_3D26			; 0x8f45 (U+62fe)
	Chars C_KANJI_JIS_3D27			; 0x8f46 (U+6d32)
	Chars C_KANJI_JIS_3D28			; 0x8f47 (U+79c0)
	Chars C_KANJI_JIS_3D29			; 0x8f48 (U+79cb)
	Chars C_KANJI_JIS_3D2A			; 0x8f49 (U+7d42)
	Chars C_KANJI_JIS_3D2B			; 0x8f4a (U+7e4d)
Section7fd0Start	label	Chars
	Chars C_KANJI_JIS_3D2C			; 0x8f4b (U+7fd2)
	Chars C_KANJI_JIS_3D2D			; 0x8f4c (U+81ed)
	Chars C_KANJI_JIS_3D2E			; 0x8f4d (U+821f)
	Chars C_KANJI_JIS_3D2F			; 0x8f4e (U+8490)
	Chars C_KANJI_JIS_3D30			; 0x8f4f (U+8846)
Section8970Start	label	Chars
	Chars C_KANJI_JIS_3D31			; 0x8f50 (U+8972)
Section8b90Start	label	Chars
	Chars C_KANJI_JIS_3D32			; 0x8f51 (U+8b90)
Section8e70Start	label	Chars
	Chars C_KANJI_JIS_3D33			; 0x8f52 (U+8e74)
Section8f20Start	label	Chars
	Chars C_KANJI_JIS_3D34			; 0x8f53 (U+8f2f)
	Chars C_KANJI_JIS_3D35			; 0x8f54 (U+9031)
	Chars C_KANJI_JIS_3D36			; 0x8f55 (U+914b)
Section9160Start	label	Chars
	Chars C_KANJI_JIS_3D37			; 0x8f56 (U+916c)
	Chars C_KANJI_JIS_3D38			; 0x8f57 (U+96c6)
	Chars C_KANJI_JIS_3D39			; 0x8f58 (U+919c)
	Chars C_KANJI_JIS_3D3A			; 0x8f59 (U+4ec0)
	Chars C_KANJI_JIS_3D3B			; 0x8f5a (U+4f4f)
	Chars C_KANJI_JIS_3D3C			; 0x8f5b (U+5145)
	Chars C_KANJI_JIS_3D3D			; 0x8f5c (U+5341)
Section5f90Start	label	Chars
	Chars C_KANJI_JIS_3D3E			; 0x8f5d (U+5f93)
Section6200Start	label	Chars
	Chars C_KANJI_JIS_3D3F			; 0x8f5e (U+620e)
	Chars C_KANJI_JIS_3D40			; 0x8f5f (U+67d4)
	Chars C_KANJI_JIS_3D41			; 0x8f60 (U+6c41)
	Chars C_KANJI_JIS_3D42			; 0x8f61 (U+6e0b)
Section7360Start	label	Chars
	Chars C_KANJI_JIS_3D43			; 0x8f62 (U+7363)
Section7e20Start	label	Chars
	Chars C_KANJI_JIS_3D44			; 0x8f63 (U+7e26)
	Chars C_KANJI_JIS_3D45			; 0x8f64 (U+91cd)
	Chars C_KANJI_JIS_3D46			; 0x8f65 (U+9283)
	Chars C_KANJI_JIS_3D47			; 0x8f66 (U+53d4)
	Chars C_KANJI_JIS_3D48			; 0x8f67 (U+5919)
	Chars C_KANJI_JIS_3D49			; 0x8f68 (U+5bbf)
Section6dd0Start	label	Chars
	Chars C_KANJI_JIS_3D4A			; 0x8f69 (U+6dd1)
Section7950Start	label	Chars
	Chars C_KANJI_JIS_3D4B			; 0x8f6a (U+795d)
	Chars C_KANJI_JIS_3D4C			; 0x8f6b (U+7e2e)
	Chars C_KANJI_JIS_3D4D			; 0x8f6c (U+7c9b)
Section5870Start	label	Chars
	Chars C_KANJI_JIS_3D4E			; 0x8f6d (U+587e)
Section7190Start	label	Chars
	Chars C_KANJI_JIS_3D4F			; 0x8f6e (U+719f)
	Chars C_KANJI_JIS_3D50			; 0x8f6f (U+51fa)
	Chars C_KANJI_JIS_3D51			; 0x8f70 (U+8853)
Section8ff0Start	label	Chars
	Chars C_KANJI_JIS_3D52			; 0x8f71 (U+8ff0)
	Chars C_KANJI_JIS_3D53			; 0x8f72 (U+4fca)
Section5cf0Start	label	Chars
	Chars C_KANJI_JIS_3D54			; 0x8f73 (U+5cfb)
	Chars C_KANJI_JIS_3D55			; 0x8f74 (U+6625)
Section77a0Start	label	Chars
	Chars C_KANJI_JIS_3D56			; 0x8f75 (U+77ac)
Section7ae0Start	label	Chars
	Chars C_KANJI_JIS_3D57			; 0x8f76 (U+7ae3)
	Chars C_KANJI_JIS_3D58			; 0x8f77 (U+821c)
Section99f0Start	label	Chars
	Chars C_KANJI_JIS_3D59			; 0x8f78 (U+99ff)
Section51c0Start	label	Chars
	Chars C_KANJI_JIS_3D5A			; 0x8f79 (U+51c6)
	Chars C_KANJI_JIS_3D5B			; 0x8f7a (U+5faa)
	Chars C_KANJI_JIS_3D5C			; 0x8f7b (U+65ec)
	Chars C_KANJI_JIS_3D5D			; 0x8f7c (U+696f)
	Chars C_KANJI_JIS_3D5E			; 0x8f7d (U+6b89)
	Chars C_KANJI_JIS_3D5F			; 0x8f7e (U+6df3)
	Chars 0					; 0x8f7f
	Chars C_KANJI_JIS_3D60			; 0x8f80 (U+6e96)
Section6f60Start	label	Chars
	Chars C_KANJI_JIS_3D61			; 0x8f81 (U+6f64)
Section76f0Start	label	Chars
	Chars C_KANJI_JIS_3D62			; 0x8f82 (U+76fe)
	Chars C_KANJI_JIS_3D63			; 0x8f83 (U+7d14)
	Chars C_KANJI_JIS_3D64			; 0x8f84 (U+5de1)
	Chars C_KANJI_JIS_3D65			; 0x8f85 (U+9075)
Section9180Start	label	Chars
	Chars C_KANJI_JIS_3D66			; 0x8f86 (U+9187)
	Chars C_KANJI_JIS_3D67			; 0x8f87 (U+9806)
Section51e0Start	label	Chars
	Chars C_KANJI_JIS_3D68			; 0x8f88 (U+51e6)
	Chars C_KANJI_JIS_3D69			; 0x8f89 (U+521d)
	Chars C_KANJI_JIS_3D6A			; 0x8f8a (U+6240)
	Chars C_KANJI_JIS_3D6B			; 0x8f8b (U+6691)
Section66d0Start	label	Chars
	Chars C_KANJI_JIS_3D6C			; 0x8f8c (U+66d9)
	Chars C_KANJI_JIS_3D6D			; 0x8f8d (U+6e1a)
	Chars C_KANJI_JIS_3D6E			; 0x8f8e (U+5eb6)
Section7dd0Start	label	Chars
	Chars C_KANJI_JIS_3D6F			; 0x8f8f (U+7dd2)
Section7f70Start	label	Chars
	Chars C_KANJI_JIS_3D70			; 0x8f90 (U+7f72)
	Chars C_KANJI_JIS_3D71			; 0x8f91 (U+66f8)
	Chars C_KANJI_JIS_3D72			; 0x8f92 (U+85af)
Section85f0Start	label	Chars
	Chars C_KANJI_JIS_3D73			; 0x8f93 (U+85f7)
	Chars C_KANJI_JIS_3D74			; 0x8f94 (U+8af8)
	Chars C_KANJI_JIS_3D75			; 0x8f95 (U+52a9)
	Chars C_KANJI_JIS_3D76			; 0x8f96 (U+53d9)
	Chars C_KANJI_JIS_3D77			; 0x8f97 (U+5973)
	Chars C_KANJI_JIS_3D78			; 0x8f98 (U+5e8f)
	Chars C_KANJI_JIS_3D79			; 0x8f99 (U+5f90)
	Chars C_KANJI_JIS_3D7A			; 0x8f9a (U+6055)
	Chars C_KANJI_JIS_3D7B			; 0x8f9b (U+92e4)
	Chars C_KANJI_JIS_3D7C			; 0x8f9c (U+9664)
	Chars C_KANJI_JIS_3D7D			; 0x8f9d (U+50b7)
	Chars C_KANJI_JIS_3D7E			; 0x8f9e (U+511f)
	Chars C_KANJI_JIS_3E21			; 0x8f9f (U+52dd)
	Chars C_KANJI_JIS_3E22			; 0x8fa0 (U+5320)
	Chars C_KANJI_JIS_3E23			; 0x8fa1 (U+5347)
	Chars C_KANJI_JIS_3E24			; 0x8fa2 (U+53ec)
	Chars C_KANJI_JIS_3E25			; 0x8fa3 (U+54e8)
Section5540Start	label	Chars
	Chars C_KANJI_JIS_3E26			; 0x8fa4 (U+5546)
Section5530Start	label	Chars
	Chars C_KANJI_JIS_3E27			; 0x8fa5 (U+5531)
	Chars C_KANJI_JIS_3E28			; 0x8fa6 (U+5617)
	Chars C_KANJI_JIS_3E29			; 0x8fa7 (U+5968)
	Chars C_KANJI_JIS_3E2A			; 0x8fa8 (U+59be)
Section5a30Start	label	Chars
	Chars C_KANJI_JIS_3E2B			; 0x8fa9 (U+5a3c)
	Chars C_KANJI_JIS_3E2C			; 0x8faa (U+5bb5)
	Chars C_KANJI_JIS_3E2D			; 0x8fab (U+5c06)
	Chars C_KANJI_JIS_3E2E			; 0x8fac (U+5c0f)
Section5c10Start	label	Chars
	Chars C_KANJI_JIS_3E2F			; 0x8fad (U+5c11)
	Chars C_KANJI_JIS_3E30			; 0x8fae (U+5c1a)
	Chars C_KANJI_JIS_3E31			; 0x8faf (U+5e84)
	Chars C_KANJI_JIS_3E32			; 0x8fb0 (U+5e8a)
Section5ee0Start	label	Chars
	Chars C_KANJI_JIS_3E33			; 0x8fb1 (U+5ee0)
	Chars C_KANJI_JIS_3E34			; 0x8fb2 (U+5f70)
	Chars C_KANJI_JIS_3E35			; 0x8fb3 (U+627f)
	Chars C_KANJI_JIS_3E36			; 0x8fb4 (U+6284)
	Chars C_KANJI_JIS_3E37			; 0x8fb5 (U+62db)
	Chars C_KANJI_JIS_3E38			; 0x8fb6 (U+638c)
	Chars C_KANJI_JIS_3E39			; 0x8fb7 (U+6377)
	Chars C_KANJI_JIS_3E3A			; 0x8fb8 (U+6607)
	Chars C_KANJI_JIS_3E3B			; 0x8fb9 (U+660c)
	Chars C_KANJI_JIS_3E3C			; 0x8fba (U+662d)
Section6670Start	label	Chars
	Chars C_KANJI_JIS_3E3D			; 0x8fbb (U+6676)
	Chars C_KANJI_JIS_3E3E			; 0x8fbc (U+677e)
	Chars C_KANJI_JIS_3E3F			; 0x8fbd (U+68a2)
Section6a10Start	label	Chars
	Chars C_KANJI_JIS_3E40			; 0x8fbe (U+6a1f)
	Chars C_KANJI_JIS_3E41			; 0x8fbf (U+6a35)
	Chars C_KANJI_JIS_3E42			; 0x8fc0 (U+6cbc)
Section6d80Start	label	Chars
	Chars C_KANJI_JIS_3E43			; 0x8fc1 (U+6d88)
	Chars C_KANJI_JIS_3E44			; 0x8fc2 (U+6e09)
	Chars C_KANJI_JIS_3E45			; 0x8fc3 (U+6e58)
Section7130Start	label	Chars
	Chars C_KANJI_JIS_3E46			; 0x8fc4 (U+713c)
Section7120Start	label	Chars
	Chars C_KANJI_JIS_3E47			; 0x8fc5 (U+7126)
	Chars C_KANJI_JIS_3E48			; 0x8fc6 (U+7167)
Section75c0Start	label	Chars
	Chars C_KANJI_JIS_3E49			; 0x8fc7 (U+75c7)
	Chars C_KANJI_JIS_3E4A			; 0x8fc8 (U+7701)
Section7850Start	label	Chars
	Chars C_KANJI_JIS_3E4B			; 0x8fc9 (U+785d)
Section7900Start	label	Chars
	Chars C_KANJI_JIS_3E4C			; 0x8fca (U+7901)
	Chars C_KANJI_JIS_3E4D			; 0x8fcb (U+7965)
	Chars C_KANJI_JIS_3E4E			; 0x8fcc (U+79f0)
	Chars C_KANJI_JIS_3E4F			; 0x8fcd (U+7ae0)
Section7b10Start	label	Chars
	Chars C_KANJI_JIS_3E50			; 0x8fce (U+7b11)
	Chars C_KANJI_JIS_3E51			; 0x8fcf (U+7ca7)
	Chars C_KANJI_JIS_3E52			; 0x8fd0 (U+7d39)
	Chars C_KANJI_JIS_3E53			; 0x8fd1 (U+8096)
	Chars C_KANJI_JIS_3E54			; 0x8fd2 (U+83d6)
Section8480Start	label	Chars
	Chars C_KANJI_JIS_3E55			; 0x8fd3 (U+848b)
	Chars C_KANJI_JIS_3E56			; 0x8fd4 (U+8549)
	Chars C_KANJI_JIS_3E57			; 0x8fd5 (U+885d)
Section88f0Start	label	Chars
	Chars C_KANJI_JIS_3E58			; 0x8fd6 (U+88f3)
	Chars C_KANJI_JIS_3E59			; 0x8fd7 (U+8a1f)
	Chars C_KANJI_JIS_3E5A			; 0x8fd8 (U+8a3c)
	Chars C_KANJI_JIS_3E5B			; 0x8fd9 (U+8a54)
	Chars C_KANJI_JIS_3E5C			; 0x8fda (U+8a73)
	Chars C_KANJI_JIS_3E5D			; 0x8fdb (U+8c61)
	Chars C_KANJI_JIS_3E5E			; 0x8fdc (U+8cde)
Section91a0Start	label	Chars
	Chars C_KANJI_JIS_3E5F			; 0x8fdd (U+91a4)
Section9260Start	label	Chars
	Chars C_KANJI_JIS_3E60			; 0x8fde (U+9266)
	Chars C_KANJI_JIS_3E61			; 0x8fdf (U+937e)
Section9410Start	label	Chars
	Chars C_KANJI_JIS_3E62			; 0x8fe0 (U+9418)
	Chars C_KANJI_JIS_3E63			; 0x8fe1 (U+969c)
Section9790Start	label	Chars
	Chars C_KANJI_JIS_3E64			; 0x8fe2 (U+9798)
	Chars C_KANJI_JIS_3E65			; 0x8fe3 (U+4e0a)
	Chars C_KANJI_JIS_3E66			; 0x8fe4 (U+4e08)
	Chars C_KANJI_JIS_3E67			; 0x8fe5 (U+4e1e)
	Chars C_KANJI_JIS_3E68			; 0x8fe6 (U+4e57)
	Chars C_KANJI_JIS_3E69			; 0x8fe7 (U+5197)
	Chars C_KANJI_JIS_3E6A			; 0x8fe8 (U+5270)
Section57c0Start	label	Chars
	Chars C_KANJI_JIS_3E6B			; 0x8fe9 (U+57ce)
	Chars C_KANJI_JIS_3E6C			; 0x8fea (U+5834)
	Chars C_KANJI_JIS_3E6D			; 0x8feb (U+58cc)
Section5b20Start	label	Chars
	Chars C_KANJI_JIS_3E6E			; 0x8fec (U+5b22)
	Chars C_KANJI_JIS_3E6F			; 0x8fed (U+5e38)
Section60c0Start	label	Chars
	Chars C_KANJI_JIS_3E70			; 0x8fee (U+60c5)
Section64f0Start	label	Chars
	Chars C_KANJI_JIS_3E71			; 0x8fef (U+64fe)
	Chars C_KANJI_JIS_3E72			; 0x8ff0 (U+6761)
	Chars C_KANJI_JIS_3E73			; 0x8ff1 (U+6756)
Section6d40Start	label	Chars
	Chars C_KANJI_JIS_3E74			; 0x8ff2 (U+6d44)
Section72b0Start	label	Chars
	Chars C_KANJI_JIS_3E75			; 0x8ff3 (U+72b6)
	Chars C_KANJI_JIS_3E76			; 0x8ff4 (U+7573)
	Chars C_KANJI_JIS_3E77			; 0x8ff5 (U+7a63)
	Chars C_KANJI_JIS_3E78			; 0x8ff6 (U+84b8)
	Chars C_KANJI_JIS_3E79			; 0x8ff7 (U+8b72)
Section91b0Start	label	Chars
	Chars C_KANJI_JIS_3E7A			; 0x8ff8 (U+91b8)
	Chars C_KANJI_JIS_3E7B			; 0x8ff9 (U+9320)
Section5630Start	label	Chars
	Chars C_KANJI_JIS_3E7C			; 0x8ffa (U+5631)
	Chars C_KANJI_JIS_3E7D			; 0x8ffb (U+57f4)
	Chars C_KANJI_JIS_3E7E			; 0x8ffc (U+98fe)
	Chars 0					; 0x8ffd
	Chars 0					; 0x8ffe
	Chars 0					; 0x8fff

	Chars C_KANJI_JIS_3F21			; 0x9040 (U+62ed)
	Chars C_KANJI_JIS_3F22			; 0x9041 (U+690d)
Section6b90Start	label	Chars
	Chars C_KANJI_JIS_3F23			; 0x9042 (U+6b96)
	Chars C_KANJI_JIS_3F24			; 0x9043 (U+71ed)
Section7e50Start	label	Chars
	Chars C_KANJI_JIS_3F25			; 0x9044 (U+7e54)
Section8070Start	label	Chars
	Chars C_KANJI_JIS_3F26			; 0x9045 (U+8077)
	Chars C_KANJI_JIS_3F27			; 0x9046 (U+8272)
	Chars C_KANJI_JIS_3F28			; 0x9047 (U+89e6)
Section98d0Start	label	Chars
	Chars C_KANJI_JIS_3F29			; 0x9048 (U+98df)
Section8750Start	label	Chars
	Chars C_KANJI_JIS_3F2A			; 0x9049 (U+8755)
	Chars C_KANJI_JIS_3F2B			; 0x904a (U+8fb1)
	Chars C_KANJI_JIS_3F2C			; 0x904b (U+5c3b)
	Chars C_KANJI_JIS_3F2D			; 0x904c (U+4f38)
	Chars C_KANJI_JIS_3F2E			; 0x904d (U+4fe1)
Section4fb0Start	label	Chars
	Chars C_KANJI_JIS_3F2F			; 0x904e (U+4fb5)
	Chars C_KANJI_JIS_3F30			; 0x904f (U+5507)
	Chars C_KANJI_JIS_3F31			; 0x9050 (U+5a20)
	Chars C_KANJI_JIS_3F32			; 0x9051 (U+5bdd)
	Chars C_KANJI_JIS_3F33			; 0x9052 (U+5be9)
	Chars C_KANJI_JIS_3F34			; 0x9053 (U+5fc3)
	Chars C_KANJI_JIS_3F35			; 0x9054 (U+614e)
	Chars C_KANJI_JIS_3F36			; 0x9055 (U+632f)
	Chars C_KANJI_JIS_3F37			; 0x9056 (U+65b0)
	Chars C_KANJI_JIS_3F38			; 0x9057 (U+664b)
Section68e0Start	label	Chars
	Chars C_KANJI_JIS_3F39			; 0x9058 (U+68ee)
Section6990Start	label	Chars
	Chars C_KANJI_JIS_3F3A			; 0x9059 (U+699b)
	Chars C_KANJI_JIS_3F3B			; 0x905a (U+6d78)
	Chars C_KANJI_JIS_3F3C			; 0x905b (U+6df1)
	Chars C_KANJI_JIS_3F3D			; 0x905c (U+7533)
	Chars C_KANJI_JIS_3F3E			; 0x905d (U+75b9)
Section7710Start	label	Chars
	Chars C_KANJI_JIS_3F3F			; 0x905e (U+771f)
	Chars C_KANJI_JIS_3F40			; 0x905f (U+795e)
Section79e0Start	label	Chars
	Chars C_KANJI_JIS_3F41			; 0x9060 (U+79e6)
	Chars C_KANJI_JIS_3F42			; 0x9061 (U+7d33)
	Chars C_KANJI_JIS_3F43			; 0x9062 (U+81e3)
	Chars C_KANJI_JIS_3F44			; 0x9063 (U+82af)
	Chars C_KANJI_JIS_3F45			; 0x9064 (U+85aa)
Section89a0Start	label	Chars
	Chars C_KANJI_JIS_3F46			; 0x9065 (U+89aa)
	Chars C_KANJI_JIS_3F47			; 0x9066 (U+8a3a)
	Chars C_KANJI_JIS_3F48			; 0x9067 (U+8eab)
	Chars C_KANJI_JIS_3F49			; 0x9068 (U+8f9b)
	Chars C_KANJI_JIS_3F4A			; 0x9069 (U+9032)
	Chars C_KANJI_JIS_3F4B			; 0x906a (U+91dd)
	Chars C_KANJI_JIS_3F4C			; 0x906b (U+9707)
Section4eb0Start	label	Chars
	Chars C_KANJI_JIS_3F4D			; 0x906c (U+4eba)
	Chars C_KANJI_JIS_3F4E			; 0x906d (U+4ec1)
	Chars C_KANJI_JIS_3F4F			; 0x906e (U+5203)
	Chars C_KANJI_JIS_3F50			; 0x906f (U+5875)
	Chars C_KANJI_JIS_3F51			; 0x9070 (U+58ec)
	Chars C_KANJI_JIS_3F52			; 0x9071 (U+5c0b)
	Chars C_KANJI_JIS_3F53			; 0x9072 (U+751a)
	Chars C_KANJI_JIS_3F54			; 0x9073 (U+5c3d)
Section8140Start	label	Chars
	Chars C_KANJI_JIS_3F55			; 0x9074 (U+814e)
	Chars C_KANJI_JIS_3F56			; 0x9075 (U+8a0a)
	Chars C_KANJI_JIS_3F57			; 0x9076 (U+8fc5)
	Chars C_KANJI_JIS_3F58			; 0x9077 (U+9663)
	Chars C_KANJI_JIS_3F59			; 0x9078 (U+976d)
	Chars C_KANJI_JIS_3F5A			; 0x9079 (U+7b25)
	Chars C_KANJI_JIS_3F5B			; 0x907a (U+8acf)
	Chars C_KANJI_JIS_3F5C			; 0x907b (U+9808)
	Chars C_KANJI_JIS_3F5D			; 0x907c (U+9162)
	Chars C_KANJI_JIS_3F5E			; 0x907d (U+56f3)
	Chars C_KANJI_JIS_3F5F			; 0x907e (U+53a8)
	Chars 0					; 0x907f
Section9010Start	label	Chars
	Chars C_KANJI_JIS_3F60			; 0x9080 (U+9017)
	Chars C_KANJI_JIS_3F61			; 0x9081 (U+5439)
	Chars C_KANJI_JIS_3F62			; 0x9082 (U+5782)
	Chars C_KANJI_JIS_3F63			; 0x9083 (U+5e25)
	Chars C_KANJI_JIS_3F64			; 0x9084 (U+63a8)
	Chars C_KANJI_JIS_3F65			; 0x9085 (U+6c34)
	Chars C_KANJI_JIS_3F66			; 0x9086 (U+708a)
Section7760Start	label	Chars
	Chars C_KANJI_JIS_3F67			; 0x9087 (U+7761)
	Chars C_KANJI_JIS_3F68			; 0x9088 (U+7c8b)
	Chars C_KANJI_JIS_3F69			; 0x9089 (U+7fe0)
	Chars C_KANJI_JIS_3F6A			; 0x908a (U+8870)
	Chars C_KANJI_JIS_3F6B			; 0x908b (U+9042)
	Chars C_KANJI_JIS_3F6C			; 0x908c (U+9154)
Section9310Start	label	Chars
	Chars C_KANJI_JIS_3F6D			; 0x908d (U+9310)
	Chars C_KANJI_JIS_3F6E			; 0x908e (U+9318)
	Chars C_KANJI_JIS_3F6F			; 0x908f (U+968f)
	Chars C_KANJI_JIS_3F70			; 0x9090 (U+745e)
Section9ac0Start	label	Chars
	Chars C_KANJI_JIS_3F71			; 0x9091 (U+9ac4)
	Chars C_KANJI_JIS_3F72			; 0x9092 (U+5d07)
	Chars C_KANJI_JIS_3F73			; 0x9093 (U+5d69)
Section6570Start	label	Chars
	Chars C_KANJI_JIS_3F74			; 0x9094 (U+6570)
	Chars C_KANJI_JIS_3F75			; 0x9095 (U+67a2)
	Chars C_KANJI_JIS_3F76			; 0x9096 (U+8da8)
	Chars C_KANJI_JIS_3F77			; 0x9097 (U+96db)
	Chars C_KANJI_JIS_3F78			; 0x9098 (U+636e)
	Chars C_KANJI_JIS_3F79			; 0x9099 (U+6749)
	Chars C_KANJI_JIS_3F7A			; 0x909a (U+6919)
	Chars C_KANJI_JIS_3F7B			; 0x909b (U+83c5)
	Chars C_KANJI_JIS_3F7C			; 0x909c (U+9817)
	Chars C_KANJI_JIS_3F7D			; 0x909d (U+96c0)
	Chars C_KANJI_JIS_3F7E			; 0x909e (U+88fe)
Section6f80Start	label	Chars
	Chars C_KANJI_JIS_4021			; 0x909f (U+6f84)
Section6470Start	label	Chars
	Chars C_KANJI_JIS_4022			; 0x90a0 (U+647a)
	Chars C_KANJI_JIS_4023			; 0x90a1 (U+5bf8)
	Chars C_KANJI_JIS_4024			; 0x90a2 (U+4e16)
Section7020Start	label	Chars
	Chars C_KANJI_JIS_4025			; 0x90a3 (U+702c)
Section7550Start	label	Chars
	Chars C_KANJI_JIS_4026			; 0x90a4 (U+755d)
	Chars C_KANJI_JIS_4027			; 0x90a5 (U+662f)
	Chars C_KANJI_JIS_4028			; 0x90a6 (U+51c4)
	Chars C_KANJI_JIS_4029			; 0x90a7 (U+5236)
	Chars C_KANJI_JIS_402A			; 0x90a8 (U+52e2)
	Chars C_KANJI_JIS_402B			; 0x90a9 (U+59d3)
	Chars C_KANJI_JIS_402C			; 0x90aa (U+5f81)
	Chars C_KANJI_JIS_402D			; 0x90ab (U+6027)
	Chars C_KANJI_JIS_402E			; 0x90ac (U+6210)
	Chars C_KANJI_JIS_402F			; 0x90ad (U+653f)
	Chars C_KANJI_JIS_4030			; 0x90ae (U+6574)
	Chars C_KANJI_JIS_4031			; 0x90af (U+661f)
	Chars C_KANJI_JIS_4032			; 0x90b0 (U+6674)
	Chars C_KANJI_JIS_4033			; 0x90b1 (U+68f2)
	Chars C_KANJI_JIS_4034			; 0x90b2 (U+6816)
	Chars C_KANJI_JIS_4035			; 0x90b3 (U+6b63)
	Chars C_KANJI_JIS_4036			; 0x90b4 (U+6e05)
	Chars C_KANJI_JIS_4037			; 0x90b5 (U+7272)
	Chars C_KANJI_JIS_4038			; 0x90b6 (U+751f)
Section76d0Start	label	Chars
	Chars C_KANJI_JIS_4039			; 0x90b7 (U+76db)
Section7cb0Start	label	Chars
	Chars C_KANJI_JIS_403A			; 0x90b8 (U+7cbe)
Section8050Start	label	Chars
	Chars C_KANJI_JIS_403B			; 0x90b9 (U+8056)
	Chars C_KANJI_JIS_403C			; 0x90ba (U+58f0)
	Chars C_KANJI_JIS_403D			; 0x90bb (U+88fd)
	Chars C_KANJI_JIS_403E			; 0x90bc (U+897f)
	Chars C_KANJI_JIS_403F			; 0x90bd (U+8aa0)
	Chars C_KANJI_JIS_4040			; 0x90be (U+8a93)
	Chars C_KANJI_JIS_4041			; 0x90bf (U+8acb)
	Chars C_KANJI_JIS_4042			; 0x90c0 (U+901d)
	Chars C_KANJI_JIS_4043			; 0x90c1 (U+9192)
Section9750Start	label	Chars
	Chars C_KANJI_JIS_4044			; 0x90c2 (U+9752)
	Chars C_KANJI_JIS_4045			; 0x90c3 (U+9759)
	Chars C_KANJI_JIS_4046			; 0x90c4 (U+6589)
	Chars C_KANJI_JIS_4047			; 0x90c5 (U+7a0e)
	Chars C_KANJI_JIS_4048			; 0x90c6 (U+8106)
Section96b0Start	label	Chars
	Chars C_KANJI_JIS_4049			; 0x90c7 (U+96bb)
	Chars C_KANJI_JIS_404A			; 0x90c8 (U+5e2d)
	Chars C_KANJI_JIS_404B			; 0x90c9 (U+60dc)
	Chars C_KANJI_JIS_404C			; 0x90ca (U+621a)
	Chars C_KANJI_JIS_404D			; 0x90cb (U+65a5)
	Chars C_KANJI_JIS_404E			; 0x90cc (U+6614)
	Chars C_KANJI_JIS_404F			; 0x90cd (U+6790)
Section77f0Start	label	Chars
	Chars C_KANJI_JIS_4050			; 0x90ce (U+77f3)
	Chars C_KANJI_JIS_4051			; 0x90cf (U+7a4d)
Section7c40Start	label	Chars
	Chars C_KANJI_JIS_4052			; 0x90d0 (U+7c4d)
Section7e30Start	label	Chars
	Chars C_KANJI_JIS_4053			; 0x90d1 (U+7e3e)
	Chars C_KANJI_JIS_4054			; 0x90d2 (U+810a)
	Chars C_KANJI_JIS_4055			; 0x90d3 (U+8cac)
	Chars C_KANJI_JIS_4056			; 0x90d4 (U+8d64)
	Chars C_KANJI_JIS_4057			; 0x90d5 (U+8de1)
Section8e50Start	label	Chars
	Chars C_KANJI_JIS_4058			; 0x90d6 (U+8e5f)
Section78a0Start	label	Chars
	Chars C_KANJI_JIS_4059			; 0x90d7 (U+78a9)
	Chars C_KANJI_JIS_405A			; 0x90d8 (U+5207)
	Chars C_KANJI_JIS_405B			; 0x90d9 (U+62d9)
	Chars C_KANJI_JIS_405C			; 0x90da (U+63a5)
Section6440Start	label	Chars
	Chars C_KANJI_JIS_405D			; 0x90db (U+6442)
	Chars C_KANJI_JIS_405E			; 0x90dc (U+6298)
	Chars C_KANJI_JIS_405F			; 0x90dd (U+8a2d)
	Chars C_KANJI_JIS_4060			; 0x90de (U+7a83)
Section7bc0Start	label	Chars
	Chars C_KANJI_JIS_4061			; 0x90df (U+7bc0)
	Chars C_KANJI_JIS_4062			; 0x90e0 (U+8aac)
	Chars C_KANJI_JIS_4063			; 0x90e1 (U+96ea)
	Chars C_KANJI_JIS_4064			; 0x90e2 (U+7d76)
	Chars C_KANJI_JIS_4065			; 0x90e3 (U+820c)
Section8740Start	label	Chars
	Chars C_KANJI_JIS_4066			; 0x90e4 (U+8749)
	Chars C_KANJI_JIS_4067			; 0x90e5 (U+4ed9)
	Chars C_KANJI_JIS_4068			; 0x90e6 (U+5148)
	Chars C_KANJI_JIS_4069			; 0x90e7 (U+5343)
	Chars C_KANJI_JIS_406A			; 0x90e8 (U+5360)
	Chars C_KANJI_JIS_406B			; 0x90e9 (U+5ba3)
	Chars C_KANJI_JIS_406C			; 0x90ea (U+5c02)
	Chars C_KANJI_JIS_406D			; 0x90eb (U+5c16)
	Chars C_KANJI_JIS_406E			; 0x90ec (U+5ddd)
	Chars C_KANJI_JIS_406F			; 0x90ed (U+6226)
	Chars C_KANJI_JIS_4070			; 0x90ee (U+6247)
	Chars C_KANJI_JIS_4071			; 0x90ef (U+64b0)
	Chars C_KANJI_JIS_4072			; 0x90f0 (U+6813)
	Chars C_KANJI_JIS_4073			; 0x90f1 (U+6834)
	Chars C_KANJI_JIS_4074			; 0x90f2 (U+6cc9)
	Chars C_KANJI_JIS_4075			; 0x90f3 (U+6d45)
Section6d10Start	label	Chars
	Chars C_KANJI_JIS_4076			; 0x90f4 (U+6d17)
	Chars C_KANJI_JIS_4077			; 0x90f5 (U+67d3)
	Chars C_KANJI_JIS_4078			; 0x90f6 (U+6f5c)
Section7140Start	label	Chars
	Chars C_KANJI_JIS_4079			; 0x90f7 (U+714e)
Section7170Start	label	Chars
	Chars C_KANJI_JIS_407A			; 0x90f8 (U+717d)
Section65c0Start	label	Chars
	Chars C_KANJI_JIS_407B			; 0x90f9 (U+65cb)
	Chars C_KANJI_JIS_407C			; 0x90fa (U+7a7f)
	Chars C_KANJI_JIS_407D			; 0x90fb (U+7bad)
	Chars C_KANJI_JIS_407E			; 0x90fc (U+7dda)
	Chars 0					; 0x90fd
	Chars 0					; 0x90fe
	Chars 0					; 0x90ff

	Chars C_KANJI_JIS_4121			; 0x9140 (U+7e4a)
	Chars C_KANJI_JIS_4122			; 0x9141 (U+7fa8)
	Chars C_KANJI_JIS_4123			; 0x9142 (U+817a)
	Chars C_KANJI_JIS_4124			; 0x9143 (U+821b)
	Chars C_KANJI_JIS_4125			; 0x9144 (U+8239)
	Chars C_KANJI_JIS_4126			; 0x9145 (U+85a6)
	Chars C_KANJI_JIS_4127			; 0x9146 (U+8a6e)
	Chars C_KANJI_JIS_4128			; 0x9147 (U+8cce)
Section8df0Start	label	Chars
	Chars C_KANJI_JIS_4129			; 0x9148 (U+8df5)
	Chars C_KANJI_JIS_412A			; 0x9149 (U+9078)
	Chars C_KANJI_JIS_412B			; 0x914a (U+9077)
Section92a0Start	label	Chars
	Chars C_KANJI_JIS_412C			; 0x914b (U+92ad)
Section9290Start	label	Chars
	Chars C_KANJI_JIS_412D			; 0x914c (U+9291)
	Chars C_KANJI_JIS_412E			; 0x914d (U+9583)
	Chars C_KANJI_JIS_412F			; 0x914e (U+9bae)
	Chars C_KANJI_JIS_4130			; 0x914f (U+524d)
	Chars C_KANJI_JIS_4131			; 0x9150 (U+5584)
Section6f30Start	label	Chars
	Chars C_KANJI_JIS_4132			; 0x9151 (U+6f38)
	Chars C_KANJI_JIS_4133			; 0x9152 (U+7136)
	Chars C_KANJI_JIS_4134			; 0x9153 (U+5168)
	Chars C_KANJI_JIS_4135			; 0x9154 (U+7985)
	Chars C_KANJI_JIS_4136			; 0x9155 (U+7e55)
Section81b0Start	label	Chars
	Chars C_KANJI_JIS_4137			; 0x9156 (U+81b3)
	Chars C_KANJI_JIS_4138			; 0x9157 (U+7cce)
	Chars C_KANJI_JIS_4139			; 0x9158 (U+564c)
	Chars C_KANJI_JIS_413A			; 0x9159 (U+5851)
	Chars C_KANJI_JIS_413B			; 0x915a (U+5ca8)
	Chars C_KANJI_JIS_413C			; 0x915b (U+63aa)
	Chars C_KANJI_JIS_413D			; 0x915c (U+66fe)
	Chars C_KANJI_JIS_413E			; 0x915d (U+66fd)
Section6950Start	label	Chars
	Chars C_KANJI_JIS_413F			; 0x915e (U+695a)
	Chars C_KANJI_JIS_4140			; 0x915f (U+72d9)
Section7580Start	label	Chars
	Chars C_KANJI_JIS_4141			; 0x9160 (U+758f)
	Chars C_KANJI_JIS_4142			; 0x9161 (U+758e)
	Chars C_KANJI_JIS_4143			; 0x9162 (U+790e)
	Chars C_KANJI_JIS_4144			; 0x9163 (U+7956)
	Chars C_KANJI_JIS_4145			; 0x9164 (U+79df)
	Chars C_KANJI_JIS_4146			; 0x9165 (U+7c97)
	Chars C_KANJI_JIS_4147			; 0x9166 (U+7d20)
	Chars C_KANJI_JIS_4148			; 0x9167 (U+7d44)
Section8600Start	label	Chars
	Chars C_KANJI_JIS_4149			; 0x9168 (U+8607)
	Chars C_KANJI_JIS_414A			; 0x9169 (U+8a34)
	Chars C_KANJI_JIS_414B			; 0x916a (U+963b)
	Chars C_KANJI_JIS_414C			; 0x916b (U+9061)
Section9f20Start	label	Chars
	Chars C_KANJI_JIS_414D			; 0x916c (U+9f20)
Section50e0Start	label	Chars
	Chars C_KANJI_JIS_414E			; 0x916d (U+50e7)
	Chars C_KANJI_JIS_414F			; 0x916e (U+5275)
	Chars C_KANJI_JIS_4150			; 0x916f (U+53cc)
	Chars C_KANJI_JIS_4151			; 0x9170 (U+53e2)
	Chars C_KANJI_JIS_4152			; 0x9171 (U+5009)
	Chars C_KANJI_JIS_4153			; 0x9172 (U+55aa)
	Chars C_KANJI_JIS_4154			; 0x9173 (U+58ee)
	Chars C_KANJI_JIS_4155			; 0x9174 (U+594f)
	Chars C_KANJI_JIS_4156			; 0x9175 (U+723d)
	Chars C_KANJI_JIS_4157			; 0x9176 (U+5b8b)
	Chars C_KANJI_JIS_4158			; 0x9177 (U+5c64)
	Chars C_KANJI_JIS_4159			; 0x9178 (U+531d)
	Chars C_KANJI_JIS_415A			; 0x9179 (U+60e3)
	Chars C_KANJI_JIS_415B			; 0x917a (U+60f3)
Section6350Start	label	Chars
	Chars C_KANJI_JIS_415C			; 0x917b (U+635c)
	Chars C_KANJI_JIS_415D			; 0x917c (U+6383)
Section6330Start	label	Chars
	Chars C_KANJI_JIS_415E			; 0x917d (U+633f)
	Chars C_KANJI_JIS_415F			; 0x917e (U+63bb)
	Chars 0					; 0x917f
Section64c0Start	label	Chars
	Chars C_KANJI_JIS_4160			; 0x9180 (U+64cd)
	Chars C_KANJI_JIS_4161			; 0x9181 (U+65e9)
	Chars C_KANJI_JIS_4162			; 0x9182 (U+66f9)
	Chars C_KANJI_JIS_4163			; 0x9183 (U+5de3)
	Chars C_KANJI_JIS_4164			; 0x9184 (U+69cd)
Section69f0Start	label	Chars
	Chars C_KANJI_JIS_4165			; 0x9185 (U+69fd)
	Chars C_KANJI_JIS_4166			; 0x9186 (U+6f15)
	Chars C_KANJI_JIS_4167			; 0x9187 (U+71e5)
	Chars C_KANJI_JIS_4168			; 0x9188 (U+4e89)
Section75e0Start	label	Chars
	Chars C_KANJI_JIS_4169			; 0x9189 (U+75e9)
	Chars C_KANJI_JIS_416A			; 0x918a (U+76f8)
	Chars C_KANJI_JIS_416B			; 0x918b (U+7a93)
Section7cd0Start	label	Chars
	Chars C_KANJI_JIS_416C			; 0x918c (U+7cdf)
	Chars C_KANJI_JIS_416D			; 0x918d (U+7dcf)
	Chars C_KANJI_JIS_416E			; 0x918e (U+7d9c)
Section8060Start	label	Chars
	Chars C_KANJI_JIS_416F			; 0x918f (U+8061)
	Chars C_KANJI_JIS_4170			; 0x9190 (U+8349)
	Chars C_KANJI_JIS_4171			; 0x9191 (U+8358)
	Chars C_KANJI_JIS_4172			; 0x9192 (U+846c)
	Chars C_KANJI_JIS_4173			; 0x9193 (U+84bc)
	Chars C_KANJI_JIS_4174			; 0x9194 (U+85fb)
	Chars C_KANJI_JIS_4175			; 0x9195 (U+88c5)
	Chars C_KANJI_JIS_4176			; 0x9196 (U+8d70)
	Chars C_KANJI_JIS_4177			; 0x9197 (U+9001)
	Chars C_KANJI_JIS_4178			; 0x9198 (U+906d)
	Chars C_KANJI_JIS_4179			; 0x9199 (U+9397)
	Chars C_KANJI_JIS_417A			; 0x919a (U+971c)
	Chars C_KANJI_JIS_417B			; 0x919b (U+9a12)
	Chars C_KANJI_JIS_417C			; 0x919c (U+50cf)
Section5890Start	label	Chars
	Chars C_KANJI_JIS_417D			; 0x919d (U+5897)
Section6180Start	label	Chars
	Chars C_KANJI_JIS_417E			; 0x919e (U+618e)
Section81d0Start	label	Chars
	Chars C_KANJI_JIS_4221			; 0x919f (U+81d3)
Section8530Start	label	Chars
	Chars C_KANJI_JIS_4222			; 0x91a0 (U+8535)
	Chars C_KANJI_JIS_4223			; 0x91a1 (U+8d08)
	Chars C_KANJI_JIS_4224			; 0x91a2 (U+9020)
	Chars C_KANJI_JIS_4225			; 0x91a3 (U+4fc3)
	Chars C_KANJI_JIS_4226			; 0x91a4 (U+5074)
	Chars C_KANJI_JIS_4227			; 0x91a5 (U+5247)
	Chars C_KANJI_JIS_4228			; 0x91a6 (U+5373)
	Chars C_KANJI_JIS_4229			; 0x91a7 (U+606f)
	Chars C_KANJI_JIS_422A			; 0x91a8 (U+6349)
	Chars C_KANJI_JIS_422B			; 0x91a9 (U+675f)
	Chars C_KANJI_JIS_422C			; 0x91aa (U+6e2c)
Section8db0Start	label	Chars
	Chars C_KANJI_JIS_422D			; 0x91ab (U+8db3)
	Chars C_KANJI_JIS_422E			; 0x91ac (U+901f)
Section4fd0Start	label	Chars
	Chars C_KANJI_JIS_422F			; 0x91ad (U+4fd7)
	Chars C_KANJI_JIS_4230			; 0x91ae (U+5c5e)
	Chars C_KANJI_JIS_4231			; 0x91af (U+8cca)
	Chars C_KANJI_JIS_4232			; 0x91b0 (U+65cf)
	Chars C_KANJI_JIS_4233			; 0x91b1 (U+7d9a)
	Chars C_KANJI_JIS_4234			; 0x91b2 (U+5352)
Section8890Start	label	Chars
	Chars C_KANJI_JIS_4235			; 0x91b3 (U+8896)
	Chars C_KANJI_JIS_4236			; 0x91b4 (U+5176)
Section63c0Start	label	Chars
	Chars C_KANJI_JIS_4237			; 0x91b5 (U+63c3)
	Chars C_KANJI_JIS_4238			; 0x91b6 (U+5b58)
	Chars C_KANJI_JIS_4239			; 0x91b7 (U+5b6b)
	Chars C_KANJI_JIS_423A			; 0x91b8 (U+5c0a)
Section6400Start	label	Chars
	Chars C_KANJI_JIS_423B			; 0x91b9 (U+640d)
	Chars C_KANJI_JIS_423C			; 0x91ba (U+6751)
	Chars C_KANJI_JIS_423D			; 0x91bb (U+905c)
	Chars C_KANJI_JIS_423E			; 0x91bc (U+4ed6)
	Chars C_KANJI_JIS_423F			; 0x91bd (U+591a)
	Chars C_KANJI_JIS_4240			; 0x91be (U+592a)
	Chars C_KANJI_JIS_4241			; 0x91bf (U+6c70)
	Chars C_KANJI_JIS_4242			; 0x91c0 (U+8a51)
	Chars C_KANJI_JIS_4243			; 0x91c1 (U+553e)
Section5810Start	label	Chars
	Chars C_KANJI_JIS_4244			; 0x91c2 (U+5815)
Section59a0Start	label	Chars
	Chars C_KANJI_JIS_4245			; 0x91c3 (U+59a5)
	Chars C_KANJI_JIS_4246			; 0x91c4 (U+60f0)
Section6250Start	label	Chars
	Chars C_KANJI_JIS_4247			; 0x91c5 (U+6253)
Section67c0Start	label	Chars
	Chars C_KANJI_JIS_4248			; 0x91c6 (U+67c1)
	Chars C_KANJI_JIS_4249			; 0x91c7 (U+8235)
	Chars C_KANJI_JIS_424A			; 0x91c8 (U+6955)
	Chars C_KANJI_JIS_424B			; 0x91c9 (U+9640)
	Chars C_KANJI_JIS_424C			; 0x91ca (U+99c4)
Section9a20Start	label	Chars
	Chars C_KANJI_JIS_424D			; 0x91cb (U+9a28)
	Chars C_KANJI_JIS_424E			; 0x91cc (U+4f53)
	Chars C_KANJI_JIS_424F			; 0x91cd (U+5806)
	Chars C_KANJI_JIS_4250			; 0x91ce (U+5bfe)
	Chars C_KANJI_JIS_4251			; 0x91cf (U+8010)
	Chars C_KANJI_JIS_4252			; 0x91d0 (U+5cb1)
	Chars C_KANJI_JIS_4253			; 0x91d1 (U+5e2f)
	Chars C_KANJI_JIS_4254			; 0x91d2 (U+5f85)
	Chars C_KANJI_JIS_4255			; 0x91d3 (U+6020)
	Chars C_KANJI_JIS_4256			; 0x91d4 (U+614b)
	Chars C_KANJI_JIS_4257			; 0x91d5 (U+6234)
	Chars C_KANJI_JIS_4258			; 0x91d6 (U+66ff)
	Chars C_KANJI_JIS_4259			; 0x91d7 (U+6cf0)
	Chars C_KANJI_JIS_425A			; 0x91d8 (U+6ede)
	Chars C_KANJI_JIS_425B			; 0x91d9 (U+80ce)
	Chars C_KANJI_JIS_425C			; 0x91da (U+817f)
	Chars C_KANJI_JIS_425D			; 0x91db (U+82d4)
	Chars C_KANJI_JIS_425E			; 0x91dc (U+888b)
	Chars C_KANJI_JIS_425F			; 0x91dd (U+8cb8)
	Chars C_KANJI_JIS_4260			; 0x91de (U+9000)
	Chars C_KANJI_JIS_4261			; 0x91df (U+902e)
	Chars C_KANJI_JIS_4262			; 0x91e0 (U+968a)
	Chars C_KANJI_JIS_4263			; 0x91e1 (U+9edb)
	Chars C_KANJI_JIS_4264			; 0x91e2 (U+9bdb)
	Chars C_KANJI_JIS_4265			; 0x91e3 (U+4ee3)
	Chars C_KANJI_JIS_4266			; 0x91e4 (U+53f0)
	Chars C_KANJI_JIS_4267			; 0x91e5 (U+5927)
	Chars C_KANJI_JIS_4268			; 0x91e6 (U+7b2c)
	Chars C_KANJI_JIS_4269			; 0x91e7 (U+918d)
	Chars C_KANJI_JIS_426A			; 0x91e8 (U+984c)
	Chars C_KANJI_JIS_426B			; 0x91e9 (U+9df9)
	Chars C_KANJI_JIS_426C			; 0x91ea (U+6edd)
	Chars C_KANJI_JIS_426D			; 0x91eb (U+7027)
	Chars C_KANJI_JIS_426E			; 0x91ec (U+5353)
	Chars C_KANJI_JIS_426F			; 0x91ed (U+5544)
	Chars C_KANJI_JIS_4270			; 0x91ee (U+5b85)
	Chars C_KANJI_JIS_4271			; 0x91ef (U+6258)
	Chars C_KANJI_JIS_4272			; 0x91f0 (U+629e)
	Chars C_KANJI_JIS_4273			; 0x91f1 (U+62d3)
Section6ca0Start	label	Chars
	Chars C_KANJI_JIS_4274			; 0x91f2 (U+6ca2)
	Chars C_KANJI_JIS_4275			; 0x91f3 (U+6fef)
Section7420Start	label	Chars
	Chars C_KANJI_JIS_4276			; 0x91f4 (U+7422)
	Chars C_KANJI_JIS_4277			; 0x91f5 (U+8a17)
Section9430Start	label	Chars
	Chars C_KANJI_JIS_4278			; 0x91f6 (U+9438)
	Chars C_KANJI_JIS_4279			; 0x91f7 (U+6fc1)
	Chars C_KANJI_JIS_427A			; 0x91f8 (U+8afe)
Section8330Start	label	Chars
	Chars C_KANJI_JIS_427B			; 0x91f9 (U+8338)
	Chars C_KANJI_JIS_427C			; 0x91fa (U+51e7)
	Chars C_KANJI_JIS_427D			; 0x91fb (U+86f8)
	Chars C_KANJI_JIS_427E			; 0x91fc (U+53ea)
	Chars 0					; 0x91fd
	Chars 0					; 0x91fe
	Chars 0					; 0x91ff

	Chars C_KANJI_JIS_4321			; 0x9240 (U+53e9)
	Chars C_KANJI_JIS_4322			; 0x9241 (U+4f46)
	Chars C_KANJI_JIS_4323			; 0x9242 (U+9054)
	Chars C_KANJI_JIS_4324			; 0x9243 (U+8fb0)
	Chars C_KANJI_JIS_4325			; 0x9244 (U+596a)
Section8130Start	label	Chars
	Chars C_KANJI_JIS_4326			; 0x9245 (U+8131)
	Chars C_KANJI_JIS_4327			; 0x9246 (U+5dfd)
	Chars C_KANJI_JIS_4328			; 0x9247 (U+7aea)
	Chars C_KANJI_JIS_4329			; 0x9248 (U+8fbf)
Section68d0Start	label	Chars
	Chars C_KANJI_JIS_432A			; 0x9249 (U+68da)
Section8c30Start	label	Chars
	Chars C_KANJI_JIS_432B			; 0x924a (U+8c37)
Section72f0Start	label	Chars
	Chars C_KANJI_JIS_432C			; 0x924b (U+72f8)
Section9c40Start	label	Chars
	Chars C_KANJI_JIS_432D			; 0x924c (U+9c48)
	Chars C_KANJI_JIS_432E			; 0x924d (U+6a3d)
	Chars C_KANJI_JIS_432F			; 0x924e (U+8ab0)
	Chars C_KANJI_JIS_4330			; 0x924f (U+4e39)
	Chars C_KANJI_JIS_4331			; 0x9250 (U+5358)
	Chars C_KANJI_JIS_4332			; 0x9251 (U+5606)
	Chars C_KANJI_JIS_4333			; 0x9252 (U+5766)
Section62c0Start	label	Chars
	Chars C_KANJI_JIS_4334			; 0x9253 (U+62c5)
	Chars C_KANJI_JIS_4335			; 0x9254 (U+63a2)
	Chars C_KANJI_JIS_4336			; 0x9255 (U+65e6)
	Chars C_KANJI_JIS_4337			; 0x9256 (U+6b4e)
	Chars C_KANJI_JIS_4338			; 0x9257 (U+6de1)
	Chars C_KANJI_JIS_4339			; 0x9258 (U+6e5b)
Section70a0Start	label	Chars
	Chars C_KANJI_JIS_433A			; 0x9259 (U+70ad)
	Chars C_KANJI_JIS_433B			; 0x925a (U+77ed)
	Chars C_KANJI_JIS_433C			; 0x925b (U+7aef)
	Chars C_KANJI_JIS_433D			; 0x925c (U+7baa)
	Chars C_KANJI_JIS_433E			; 0x925d (U+7dbb)
	Chars C_KANJI_JIS_433F			; 0x925e (U+803d)
	Chars C_KANJI_JIS_4340			; 0x925f (U+80c6)
	Chars C_KANJI_JIS_4341			; 0x9260 (U+86cb)
	Chars C_KANJI_JIS_4342			; 0x9261 (U+8a95)
Section9350Start	label	Chars
	Chars C_KANJI_JIS_4343			; 0x9262 (U+935b)
	Chars C_KANJI_JIS_4344			; 0x9263 (U+56e3)
	Chars C_KANJI_JIS_4345			; 0x9264 (U+58c7)
	Chars C_KANJI_JIS_4346			; 0x9265 (U+5f3e)
	Chars C_KANJI_JIS_4347			; 0x9266 (U+65ad)
	Chars C_KANJI_JIS_4348			; 0x9267 (U+6696)
	Chars C_KANJI_JIS_4349			; 0x9268 (U+6a80)
	Chars C_KANJI_JIS_434A			; 0x9269 (U+6bb5)
	Chars C_KANJI_JIS_434B			; 0x926a (U+7537)
	Chars C_KANJI_JIS_434C			; 0x926b (U+8ac7)
	Chars C_KANJI_JIS_434D			; 0x926c (U+5024)
	Chars C_KANJI_JIS_434E			; 0x926d (U+77e5)
Section5730Start	label	Chars
	Chars C_KANJI_JIS_434F			; 0x926e (U+5730)
	Chars C_KANJI_JIS_4350			; 0x926f (U+5f1b)
	Chars C_KANJI_JIS_4351			; 0x9270 (U+6065)
	Chars C_KANJI_JIS_4352			; 0x9271 (U+667a)
Section6c60Start	label	Chars
	Chars C_KANJI_JIS_4353			; 0x9272 (U+6c60)
Section75f0Start	label	Chars
	Chars C_KANJI_JIS_4354			; 0x9273 (U+75f4)
Section7a10Start	label	Chars
	Chars C_KANJI_JIS_4355			; 0x9274 (U+7a1a)
	Chars C_KANJI_JIS_4356			; 0x9275 (U+7f6e)
	Chars C_KANJI_JIS_4357			; 0x9276 (U+81f4)
Section8710Start	label	Chars
	Chars C_KANJI_JIS_4358			; 0x9277 (U+8718)
	Chars C_KANJI_JIS_4359			; 0x9278 (U+9045)
Section99b0Start	label	Chars
	Chars C_KANJI_JIS_435A			; 0x9279 (U+99b3)
	Chars C_KANJI_JIS_435B			; 0x927a (U+7bc9)
	Chars C_KANJI_JIS_435C			; 0x927b (U+755c)
	Chars C_KANJI_JIS_435D			; 0x927c (U+7af9)
	Chars C_KANJI_JIS_435E			; 0x927d (U+7b51)
	Chars C_KANJI_JIS_435F			; 0x927e (U+84c4)
	Chars 0					; 0x927f
	Chars C_KANJI_JIS_4360			; 0x9280 (U+9010)
	Chars C_KANJI_JIS_4361			; 0x9281 (U+79e9)
	Chars C_KANJI_JIS_4362			; 0x9282 (U+7a92)
	Chars C_KANJI_JIS_4363			; 0x9283 (U+8336)
Section5ae0Start	label	Chars
	Chars C_KANJI_JIS_4364			; 0x9284 (U+5ae1)
Section7740Start	label	Chars
	Chars C_KANJI_JIS_4365			; 0x9285 (U+7740)
Section4e20Start	label	Chars
	Chars C_KANJI_JIS_4366			; 0x9286 (U+4e2d)
	Chars C_KANJI_JIS_4367			; 0x9287 (U+4ef2)
	Chars C_KANJI_JIS_4368			; 0x9288 (U+5b99)
	Chars C_KANJI_JIS_4369			; 0x9289 (U+5fe0)
	Chars C_KANJI_JIS_436A			; 0x928a (U+62bd)
Section6630Start	label	Chars
	Chars C_KANJI_JIS_436B			; 0x928b (U+663c)
	Chars C_KANJI_JIS_436C			; 0x928c (U+67f1)
	Chars C_KANJI_JIS_436D			; 0x928d (U+6ce8)
Section8660Start	label	Chars
	Chars C_KANJI_JIS_436E			; 0x928e (U+866b)
	Chars C_KANJI_JIS_436F			; 0x928f (U+8877)
	Chars C_KANJI_JIS_4370			; 0x9290 (U+8a3b)
	Chars C_KANJI_JIS_4371			; 0x9291 (U+914e)
	Chars C_KANJI_JIS_4372			; 0x9292 (U+92f3)
	Chars C_KANJI_JIS_4373			; 0x9293 (U+99d0)
	Chars C_KANJI_JIS_4374			; 0x9294 (U+6a17)
	Chars C_KANJI_JIS_4375			; 0x9295 (U+7026)
	Chars C_KANJI_JIS_4376			; 0x9296 (U+732a)
	Chars C_KANJI_JIS_4377			; 0x9297 (U+82e7)
	Chars C_KANJI_JIS_4378			; 0x9298 (U+8457)
	Chars C_KANJI_JIS_4379			; 0x9299 (U+8caf)
	Chars C_KANJI_JIS_437A			; 0x929a (U+4e01)
	Chars C_KANJI_JIS_437B			; 0x929b (U+5146)
	Chars C_KANJI_JIS_437C			; 0x929c (U+51cb)
	Chars C_KANJI_JIS_437D			; 0x929d (U+558b)
	Chars C_KANJI_JIS_437E			; 0x929e (U+5bf5)
Section5e10Start	label	Chars
	Chars C_KANJI_JIS_4421			; 0x929f (U+5e16)
	Chars C_KANJI_JIS_4422			; 0x92a0 (U+5e33)
	Chars C_KANJI_JIS_4423			; 0x92a1 (U+5e81)
	Chars C_KANJI_JIS_4424			; 0x92a2 (U+5f14)
	Chars C_KANJI_JIS_4425			; 0x92a3 (U+5f35)
	Chars C_KANJI_JIS_4426			; 0x92a4 (U+5f6b)
	Chars C_KANJI_JIS_4427			; 0x92a5 (U+5fb4)
	Chars C_KANJI_JIS_4428			; 0x92a6 (U+61f2)
	Chars C_KANJI_JIS_4429			; 0x92a7 (U+6311)
	Chars C_KANJI_JIS_442A			; 0x92a8 (U+66a2)
	Chars C_KANJI_JIS_442B			; 0x92a9 (U+671d)
	Chars C_KANJI_JIS_442C			; 0x92aa (U+6f6e)
	Chars C_KANJI_JIS_442D			; 0x92ab (U+7252)
	Chars C_KANJI_JIS_442E			; 0x92ac (U+753a)
	Chars C_KANJI_JIS_442F			; 0x92ad (U+773a)
	Chars C_KANJI_JIS_4430			; 0x92ae (U+8074)
	Chars C_KANJI_JIS_4431			; 0x92af (U+8139)
	Chars C_KANJI_JIS_4432			; 0x92b0 (U+8178)
Section8770Start	label	Chars
	Chars C_KANJI_JIS_4433			; 0x92b1 (U+8776)
	Chars C_KANJI_JIS_4434			; 0x92b2 (U+8abf)
Section8ad0Start	label	Chars
	Chars C_KANJI_JIS_4435			; 0x92b3 (U+8adc)
	Chars C_KANJI_JIS_4436			; 0x92b4 (U+8d85)
	Chars C_KANJI_JIS_4437			; 0x92b5 (U+8df3)
	Chars C_KANJI_JIS_4438			; 0x92b6 (U+929a)
Section9570Start	label	Chars
	Chars C_KANJI_JIS_4439			; 0x92b7 (U+9577)
	Chars C_KANJI_JIS_443A			; 0x92b8 (U+9802)
Section9ce0Start	label	Chars
	Chars C_KANJI_JIS_443B			; 0x92b9 (U+9ce5)
Section52c0Start	label	Chars
	Chars C_KANJI_JIS_443C			; 0x92ba (U+52c5)
	Chars C_KANJI_JIS_443D			; 0x92bb (U+6357)
	Chars C_KANJI_JIS_443E			; 0x92bc (U+76f4)
	Chars C_KANJI_JIS_443F			; 0x92bd (U+6715)
Section6c80Start	label	Chars
	Chars C_KANJI_JIS_4440			; 0x92be (U+6c88)
	Chars C_KANJI_JIS_4441			; 0x92bf (U+73cd)
	Chars C_KANJI_JIS_4442			; 0x92c0 (U+8cc3)
	Chars C_KANJI_JIS_4443			; 0x92c1 (U+93ae)
	Chars C_KANJI_JIS_4444			; 0x92c2 (U+9673)
	Chars C_KANJI_JIS_4445			; 0x92c3 (U+6d25)
	Chars C_KANJI_JIS_4446			; 0x92c4 (U+589c)
	Chars C_KANJI_JIS_4447			; 0x92c5 (U+690e)
	Chars C_KANJI_JIS_4448			; 0x92c6 (U+69cc)
	Chars C_KANJI_JIS_4449			; 0x92c7 (U+8ffd)
	Chars C_KANJI_JIS_444A			; 0x92c8 (U+939a)
	Chars C_KANJI_JIS_444B			; 0x92c9 (U+75db)
	Chars C_KANJI_JIS_444C			; 0x92ca (U+901a)
	Chars C_KANJI_JIS_444D			; 0x92cb (U+585a)
	Chars C_KANJI_JIS_444E			; 0x92cc (U+6802)
	Chars C_KANJI_JIS_444F			; 0x92cd (U+63b4)
	Chars C_KANJI_JIS_4450			; 0x92ce (U+69fb)
	Chars C_KANJI_JIS_4451			; 0x92cf (U+4f43)
	Chars C_KANJI_JIS_4452			; 0x92d0 (U+6f2c)
	Chars C_KANJI_JIS_4453			; 0x92d1 (U+67d8)
	Chars C_KANJI_JIS_4454			; 0x92d2 (U+8fbb)
	Chars C_KANJI_JIS_4455			; 0x92d3 (U+8526)
	Chars C_KANJI_JIS_4456			; 0x92d4 (U+7db4)
	Chars C_KANJI_JIS_4457			; 0x92d5 (U+9354)
Section6930Start	label	Chars
	Chars C_KANJI_JIS_4458			; 0x92d6 (U+693f)
Section6f70Start	label	Chars
	Chars C_KANJI_JIS_4459			; 0x92d7 (U+6f70)
	Chars C_KANJI_JIS_445A			; 0x92d8 (U+576a)
	Chars C_KANJI_JIS_445B			; 0x92d9 (U+58f7)
	Chars C_KANJI_JIS_445C			; 0x92da (U+5b2c)
	Chars C_KANJI_JIS_445D			; 0x92db (U+7d2c)
Section7220Start	label	Chars
	Chars C_KANJI_JIS_445E			; 0x92dc (U+722a)
	Chars C_KANJI_JIS_445F			; 0x92dd (U+540a)
	Chars C_KANJI_JIS_4460			; 0x92de (U+91e3)
Section9db0Start	label	Chars
	Chars C_KANJI_JIS_4461			; 0x92df (U+9db4)
	Chars C_KANJI_JIS_4462			; 0x92e0 (U+4ead)
	Chars C_KANJI_JIS_4463			; 0x92e1 (U+4f4e)
Section5050Start	label	Chars
	Chars C_KANJI_JIS_4464			; 0x92e2 (U+505c)
	Chars C_KANJI_JIS_4465			; 0x92e3 (U+5075)
	Chars C_KANJI_JIS_4466			; 0x92e4 (U+5243)
	Chars C_KANJI_JIS_4467			; 0x92e5 (U+8c9e)
	Chars C_KANJI_JIS_4468			; 0x92e6 (U+5448)
	Chars C_KANJI_JIS_4469			; 0x92e7 (U+5824)
	Chars C_KANJI_JIS_446A			; 0x92e8 (U+5b9a)
	Chars C_KANJI_JIS_446B			; 0x92e9 (U+5e1d)
	Chars C_KANJI_JIS_446C			; 0x92ea (U+5e95)
	Chars C_KANJI_JIS_446D			; 0x92eb (U+5ead)
	Chars C_KANJI_JIS_446E			; 0x92ec (U+5ef7)
	Chars C_KANJI_JIS_446F			; 0x92ed (U+5f1f)
	Chars C_KANJI_JIS_4470			; 0x92ee (U+608c)
	Chars C_KANJI_JIS_4471			; 0x92ef (U+62b5)
	Chars C_KANJI_JIS_4472			; 0x92f0 (U+633a)
	Chars C_KANJI_JIS_4473			; 0x92f1 (U+63d0)
	Chars C_KANJI_JIS_4474			; 0x92f2 (U+68af)
	Chars C_KANJI_JIS_4475			; 0x92f3 (U+6c40)
	Chars C_KANJI_JIS_4476			; 0x92f4 (U+7887)
	Chars C_KANJI_JIS_4477			; 0x92f5 (U+798e)
	Chars C_KANJI_JIS_4478			; 0x92f6 (U+7a0b)
	Chars C_KANJI_JIS_4479			; 0x92f7 (U+7de0)
Section8240Start	label	Chars
	Chars C_KANJI_JIS_447A			; 0x92f8 (U+8247)
	Chars C_KANJI_JIS_447B			; 0x92f9 (U+8a02)
	Chars C_KANJI_JIS_447C			; 0x92fa (U+8ae6)
Section8e40Start	label	Chars
	Chars C_KANJI_JIS_447D			; 0x92fb (U+8e44)
	Chars C_KANJI_JIS_447E			; 0x92fc (U+9013)
	Chars 0					; 0x92fd
	Chars 0					; 0x92fe
	Chars 0					; 0x92ff
Section90b0Start	label	Chars

	Chars C_KANJI_JIS_4521			; 0x9340 (U+90b8)
Section9120Start	label	Chars
	Chars C_KANJI_JIS_4522			; 0x9341 (U+912d)
	Chars C_KANJI_JIS_4523			; 0x9342 (U+91d8)
Section9f00Start	label	Chars
	Chars C_KANJI_JIS_4524			; 0x9343 (U+9f0e)
	Chars C_KANJI_JIS_4525			; 0x9344 (U+6ce5)
Section6450Start	label	Chars
	Chars C_KANJI_JIS_4526			; 0x9345 (U+6458)
	Chars C_KANJI_JIS_4527			; 0x9346 (U+64e2)
	Chars C_KANJI_JIS_4528			; 0x9347 (U+6575)
Section6ef0Start	label	Chars
	Chars C_KANJI_JIS_4529			; 0x9348 (U+6ef4)
	Chars C_KANJI_JIS_452A			; 0x9349 (U+7684)
	Chars C_KANJI_JIS_452B			; 0x934a (U+7b1b)
	Chars C_KANJI_JIS_452C			; 0x934b (U+9069)
Section93d0Start	label	Chars
	Chars C_KANJI_JIS_452D			; 0x934c (U+93d1)
Section6eb0Start	label	Chars
	Chars C_KANJI_JIS_452E			; 0x934d (U+6eba)
Section54f0Start	label	Chars
	Chars C_KANJI_JIS_452F			; 0x934e (U+54f2)
	Chars C_KANJI_JIS_4530			; 0x934f (U+5fb9)
	Chars C_KANJI_JIS_4531			; 0x9350 (U+64a4)
	Chars C_KANJI_JIS_4532			; 0x9351 (U+8f4d)
	Chars C_KANJI_JIS_4533			; 0x9352 (U+8fed)
Section9240Start	label	Chars
	Chars C_KANJI_JIS_4534			; 0x9353 (U+9244)
	Chars C_KANJI_JIS_4535			; 0x9354 (U+5178)
	Chars C_KANJI_JIS_4536			; 0x9355 (U+586b)
	Chars C_KANJI_JIS_4537			; 0x9356 (U+5929)
	Chars C_KANJI_JIS_4538			; 0x9357 (U+5c55)
	Chars C_KANJI_JIS_4539			; 0x9358 (U+5e97)
	Chars C_KANJI_JIS_453A			; 0x9359 (U+6dfb)
	Chars C_KANJI_JIS_453B			; 0x935a (U+7e8f)
	Chars C_KANJI_JIS_453C			; 0x935b (U+751c)
	Chars C_KANJI_JIS_453D			; 0x935c (U+8cbc)
Section8ee0Start	label	Chars
	Chars C_KANJI_JIS_453E			; 0x935d (U+8ee2)
	Chars C_KANJI_JIS_453F			; 0x935e (U+985b)
	Chars C_KANJI_JIS_4540			; 0x935f (U+70b9)
	Chars C_KANJI_JIS_4541			; 0x9360 (U+4f1d)
	Chars C_KANJI_JIS_4542			; 0x9361 (U+6bbf)
Section6fb0Start	label	Chars
	Chars C_KANJI_JIS_4543			; 0x9362 (U+6fb1)
	Chars C_KANJI_JIS_4544			; 0x9363 (U+7530)
	Chars C_KANJI_JIS_4545			; 0x9364 (U+96fb)
	Chars C_KANJI_JIS_4546			; 0x9365 (U+514e)
	Chars C_KANJI_JIS_4547			; 0x9366 (U+5410)
	Chars C_KANJI_JIS_4548			; 0x9367 (U+5835)
	Chars C_KANJI_JIS_4549			; 0x9368 (U+5857)
	Chars C_KANJI_JIS_454A			; 0x9369 (U+59ac)
	Chars C_KANJI_JIS_454B			; 0x936a (U+5c60)
	Chars C_KANJI_JIS_454C			; 0x936b (U+5f92)
	Chars C_KANJI_JIS_454D			; 0x936c (U+6597)
	Chars C_KANJI_JIS_454E			; 0x936d (U+675c)
	Chars C_KANJI_JIS_454F			; 0x936e (U+6e21)
Section7670Start	label	Chars
	Chars C_KANJI_JIS_4550			; 0x936f (U+767b)
	Chars C_KANJI_JIS_4551			; 0x9370 (U+83df)
	Chars C_KANJI_JIS_4552			; 0x9371 (U+8ced)
	Chars C_KANJI_JIS_4553			; 0x9372 (U+9014)
	Chars C_KANJI_JIS_4554			; 0x9373 (U+90fd)
Section9340Start	label	Chars
	Chars C_KANJI_JIS_4555			; 0x9374 (U+934d)
	Chars C_KANJI_JIS_4556			; 0x9375 (U+7825)
	Chars C_KANJI_JIS_4557			; 0x9376 (U+783a)
	Chars C_KANJI_JIS_4558			; 0x9377 (U+52aa)
	Chars C_KANJI_JIS_4559			; 0x9378 (U+5ea6)
	Chars C_KANJI_JIS_455A			; 0x9379 (U+571f)
	Chars C_KANJI_JIS_455B			; 0x937a (U+5974)
	Chars C_KANJI_JIS_455C			; 0x937b (U+6012)
	Chars C_KANJI_JIS_455D			; 0x937c (U+5012)
	Chars C_KANJI_JIS_455E			; 0x937d (U+515a)
	Chars C_KANJI_JIS_455F			; 0x937e (U+51ac)
	Chars 0					; 0x937f
	Chars C_KANJI_JIS_4560			; 0x9380 (U+51cd)
	Chars C_KANJI_JIS_4561			; 0x9381 (U+5200)
	Chars C_KANJI_JIS_4562			; 0x9382 (U+5510)
	Chars C_KANJI_JIS_4563			; 0x9383 (U+5854)
	Chars C_KANJI_JIS_4564			; 0x9384 (U+5858)
	Chars C_KANJI_JIS_4565			; 0x9385 (U+5957)
	Chars C_KANJI_JIS_4566			; 0x9386 (U+5b95)
	Chars C_KANJI_JIS_4567			; 0x9387 (U+5cf6)
Section5d80Start	label	Chars
	Chars C_KANJI_JIS_4568			; 0x9388 (U+5d8b)
Section60b0Start	label	Chars
	Chars C_KANJI_JIS_4569			; 0x9389 (U+60bc)
	Chars C_KANJI_JIS_456A			; 0x938a (U+6295)
Section6420Start	label	Chars
	Chars C_KANJI_JIS_456B			; 0x938b (U+642d)
	Chars C_KANJI_JIS_456C			; 0x938c (U+6771)
	Chars C_KANJI_JIS_456D			; 0x938d (U+6843)
	Chars C_KANJI_JIS_456E			; 0x938e (U+68bc)
	Chars C_KANJI_JIS_456F			; 0x938f (U+68df)
	Chars C_KANJI_JIS_4570			; 0x9390 (U+76d7)
	Chars C_KANJI_JIS_4571			; 0x9391 (U+6dd8)
Section6e60Start	label	Chars
	Chars C_KANJI_JIS_4572			; 0x9392 (U+6e6f)
Section6d90Start	label	Chars
	Chars C_KANJI_JIS_4573			; 0x9393 (U+6d9b)
	Chars C_KANJI_JIS_4574			; 0x9394 (U+706f)
Section71c0Start	label	Chars
	Chars C_KANJI_JIS_4575			; 0x9395 (U+71c8)
Section5f50Start	label	Chars
	Chars C_KANJI_JIS_4576			; 0x9396 (U+5f53)
	Chars C_KANJI_JIS_4577			; 0x9397 (U+75d8)
Section7970Start	label	Chars
	Chars C_KANJI_JIS_4578			; 0x9398 (U+7977)
	Chars C_KANJI_JIS_4579			; 0x9399 (U+7b49)
	Chars C_KANJI_JIS_457A			; 0x939a (U+7b54)
	Chars C_KANJI_JIS_457B			; 0x939b (U+7b52)
	Chars C_KANJI_JIS_457C			; 0x939c (U+7cd6)
	Chars C_KANJI_JIS_457D			; 0x939d (U+7d71)
	Chars C_KANJI_JIS_457E			; 0x939e (U+5230)
	Chars C_KANJI_JIS_4621			; 0x939f (U+8463)
Section8560Start	label	Chars
	Chars C_KANJI_JIS_4622			; 0x93a0 (U+8569)
Section85e0Start	label	Chars
	Chars C_KANJI_JIS_4623			; 0x93a1 (U+85e4)
	Chars C_KANJI_JIS_4624			; 0x93a2 (U+8a0e)
	Chars C_KANJI_JIS_4625			; 0x93a3 (U+8b04)
Section8c40Start	label	Chars
	Chars C_KANJI_JIS_4626			; 0x93a4 (U+8c46)
Section8e00Start	label	Chars
	Chars C_KANJI_JIS_4627			; 0x93a5 (U+8e0f)
	Chars C_KANJI_JIS_4628			; 0x93a6 (U+9003)
	Chars C_KANJI_JIS_4629			; 0x93a7 (U+900f)
	Chars C_KANJI_JIS_462A			; 0x93a8 (U+9419)
	Chars C_KANJI_JIS_462B			; 0x93a9 (U+9676)
Section9820Start	label	Chars
	Chars C_KANJI_JIS_462C			; 0x93aa (U+982d)
Section9a30Start	label	Chars
	Chars C_KANJI_JIS_462D			; 0x93ab (U+9a30)
Section95d0Start	label	Chars
	Chars C_KANJI_JIS_462E			; 0x93ac (U+95d8)
	Chars C_KANJI_JIS_462F			; 0x93ad (U+50cd)
	Chars C_KANJI_JIS_4630			; 0x93ae (U+52d5)
	Chars C_KANJI_JIS_4631			; 0x93af (U+540c)
	Chars C_KANJI_JIS_4632			; 0x93b0 (U+5802)
	Chars C_KANJI_JIS_4633			; 0x93b1 (U+5c0e)
	Chars C_KANJI_JIS_4634			; 0x93b2 (U+61a7)
	Chars C_KANJI_JIS_4635			; 0x93b3 (U+649e)
	Chars C_KANJI_JIS_4636			; 0x93b4 (U+6d1e)
Section77b0Start	label	Chars
	Chars C_KANJI_JIS_4637			; 0x93b5 (U+77b3)
	Chars C_KANJI_JIS_4638			; 0x93b6 (U+7ae5)
	Chars C_KANJI_JIS_4639			; 0x93b7 (U+80f4)
	Chars C_KANJI_JIS_463A			; 0x93b8 (U+8404)
	Chars C_KANJI_JIS_463B			; 0x93b9 (U+9053)
	Chars C_KANJI_JIS_463C			; 0x93ba (U+9285)
	Chars C_KANJI_JIS_463D			; 0x93bb (U+5ce0)
	Chars C_KANJI_JIS_463E			; 0x93bc (U+9d07)
	Chars C_KANJI_JIS_463F			; 0x93bd (U+533f)
	Chars C_KANJI_JIS_4640			; 0x93be (U+5f97)
	Chars C_KANJI_JIS_4641			; 0x93bf (U+5fb3)
	Chars C_KANJI_JIS_4642			; 0x93c0 (U+6d9c)
	Chars C_KANJI_JIS_4643			; 0x93c1 (U+7279)
	Chars C_KANJI_JIS_4644			; 0x93c2 (U+7763)
	Chars C_KANJI_JIS_4645			; 0x93c3 (U+79bf)
	Chars C_KANJI_JIS_4646			; 0x93c4 (U+7be4)
Section6bd0Start	label	Chars
	Chars C_KANJI_JIS_4647			; 0x93c5 (U+6bd2)
	Chars C_KANJI_JIS_4648			; 0x93c6 (U+72ec)
	Chars C_KANJI_JIS_4649			; 0x93c7 (U+8aad)
	Chars C_KANJI_JIS_464A			; 0x93c8 (U+6803)
Section6a60Start	label	Chars
	Chars C_KANJI_JIS_464B			; 0x93c9 (U+6a61)
	Chars C_KANJI_JIS_464C			; 0x93ca (U+51f8)
	Chars C_KANJI_JIS_464D			; 0x93cb (U+7a81)
	Chars C_KANJI_JIS_464E			; 0x93cc (U+6934)
	Chars C_KANJI_JIS_464F			; 0x93cd (U+5c4a)
Section9cf0Start	label	Chars
	Chars C_KANJI_JIS_4650			; 0x93ce (U+9cf6)
	Chars C_KANJI_JIS_4651			; 0x93cf (U+82eb)
	Chars C_KANJI_JIS_4652			; 0x93d0 (U+5bc5)
	Chars C_KANJI_JIS_4653			; 0x93d1 (U+9149)
Section7010Start	label	Chars
	Chars C_KANJI_JIS_4654			; 0x93d2 (U+701e)
Section5670Start	label	Chars
	Chars C_KANJI_JIS_4655			; 0x93d3 (U+5678)
	Chars C_KANJI_JIS_4656			; 0x93d4 (U+5c6f)
	Chars C_KANJI_JIS_4657			; 0x93d5 (U+60c7)
	Chars C_KANJI_JIS_4658			; 0x93d6 (U+6566)
	Chars C_KANJI_JIS_4659			; 0x93d7 (U+6c8c)
Section8c50Start	label	Chars
	Chars C_KANJI_JIS_465A			; 0x93d8 (U+8c5a)
	Chars C_KANJI_JIS_465B			; 0x93d9 (U+9041)
	Chars C_KANJI_JIS_465C			; 0x93da (U+9813)
Section5450Start	label	Chars
	Chars C_KANJI_JIS_465D			; 0x93db (U+5451)
Section66c0Start	label	Chars
	Chars C_KANJI_JIS_465E			; 0x93dc (U+66c7)
	Chars C_KANJI_JIS_465F			; 0x93dd (U+920d)
	Chars C_KANJI_JIS_4660			; 0x93de (U+5948)
	Chars C_KANJI_JIS_4661			; 0x93df (U+90a3)
	Chars C_KANJI_JIS_4662			; 0x93e0 (U+5185)
	Chars C_KANJI_JIS_4663			; 0x93e1 (U+4e4d)
	Chars C_KANJI_JIS_4664			; 0x93e2 (U+51ea)
	Chars C_KANJI_JIS_4665			; 0x93e3 (U+8599)
	Chars C_KANJI_JIS_4666			; 0x93e4 (U+8b0e)
Section7050Start	label	Chars
	Chars C_KANJI_JIS_4667			; 0x93e5 (U+7058)
	Chars C_KANJI_JIS_4668			; 0x93e6 (U+637a)
	Chars C_KANJI_JIS_4669			; 0x93e7 (U+934b)
	Chars C_KANJI_JIS_466A			; 0x93e8 (U+6962)
	Chars C_KANJI_JIS_466B			; 0x93e9 (U+99b4)
	Chars C_KANJI_JIS_466C			; 0x93ea (U+7e04)
	Chars C_KANJI_JIS_466D			; 0x93eb (U+7577)
	Chars C_KANJI_JIS_466E			; 0x93ec (U+5357)
	Chars C_KANJI_JIS_466F			; 0x93ed (U+6960)
	Chars C_KANJI_JIS_4670			; 0x93ee (U+8edf)
	Chars C_KANJI_JIS_4671			; 0x93ef (U+96e3)
	Chars C_KANJI_JIS_4672			; 0x93f0 (U+6c5d)
	Chars C_KANJI_JIS_4673			; 0x93f1 (U+4e8c)
	Chars C_KANJI_JIS_4674			; 0x93f2 (U+5c3c)
	Chars C_KANJI_JIS_4675			; 0x93f3 (U+5f10)
	Chars C_KANJI_JIS_4676			; 0x93f4 (U+8fe9)
Section5300Start	label	Chars
	Chars C_KANJI_JIS_4677			; 0x93f5 (U+5302)
	Chars C_KANJI_JIS_4678			; 0x93f6 (U+8cd1)
Section8080Start	label	Chars
	Chars C_KANJI_JIS_4679			; 0x93f7 (U+8089)
	Chars C_KANJI_JIS_467A			; 0x93f8 (U+8679)
	Chars C_KANJI_JIS_467B			; 0x93f9 (U+5eff)
	Chars C_KANJI_JIS_467C			; 0x93fa (U+65e5)
	Chars C_KANJI_JIS_467D			; 0x93fb (U+4e73)
	Chars C_KANJI_JIS_467E			; 0x93fc (U+5165)
	Chars 0					; 0x93fd
	Chars 0					; 0x93fe
	Chars 0					; 0x93ff
Section5980Start	label	Chars

	Chars C_KANJI_JIS_4721			; 0x9440 (U+5982)
	Chars C_KANJI_JIS_4722			; 0x9441 (U+5c3f)
Section97e0Start	label	Chars
	Chars C_KANJI_JIS_4723			; 0x9442 (U+97ee)
	Chars C_KANJI_JIS_4724			; 0x9443 (U+4efb)
	Chars C_KANJI_JIS_4725			; 0x9444 (U+598a)
	Chars C_KANJI_JIS_4726			; 0x9445 (U+5fcd)
	Chars C_KANJI_JIS_4727			; 0x9446 (U+8a8d)
	Chars C_KANJI_JIS_4728			; 0x9447 (U+6fe1)
	Chars C_KANJI_JIS_4729			; 0x9448 (U+79b0)
	Chars C_KANJI_JIS_472A			; 0x9449 (U+7962)
	Chars C_KANJI_JIS_472B			; 0x944a (U+5be7)
	Chars C_KANJI_JIS_472C			; 0x944b (U+8471)
	Chars C_KANJI_JIS_472D			; 0x944c (U+732b)
Section71b0Start	label	Chars
	Chars C_KANJI_JIS_472E			; 0x944d (U+71b1)
	Chars C_KANJI_JIS_472F			; 0x944e (U+5e74)
	Chars C_KANJI_JIS_4730			; 0x944f (U+5ff5)
	Chars C_KANJI_JIS_4731			; 0x9450 (U+637b)
	Chars C_KANJI_JIS_4732			; 0x9451 (U+649a)
	Chars C_KANJI_JIS_4733			; 0x9452 (U+71c3)
	Chars C_KANJI_JIS_4734			; 0x9453 (U+7c98)
	Chars C_KANJI_JIS_4735			; 0x9454 (U+4e43)
	Chars C_KANJI_JIS_4736			; 0x9455 (U+5efc)
	Chars C_KANJI_JIS_4737			; 0x9456 (U+4e4b)
	Chars C_KANJI_JIS_4738			; 0x9457 (U+57dc)
Section56a0Start	label	Chars
	Chars C_KANJI_JIS_4739			; 0x9458 (U+56a2)
	Chars C_KANJI_JIS_473A			; 0x9459 (U+60a9)
	Chars C_KANJI_JIS_473B			; 0x945a (U+6fc3)
	Chars C_KANJI_JIS_473C			; 0x945b (U+7d0d)
	Chars C_KANJI_JIS_473D			; 0x945c (U+80fd)
	Chars C_KANJI_JIS_473E			; 0x945d (U+8133)
	Chars C_KANJI_JIS_473F			; 0x945e (U+81bf)
	Chars C_KANJI_JIS_4740			; 0x945f (U+8fb2)
	Chars C_KANJI_JIS_4741			; 0x9460 (U+8997)
Section86a0Start	label	Chars
	Chars C_KANJI_JIS_4742			; 0x9461 (U+86a4)
	Chars C_KANJI_JIS_4743			; 0x9462 (U+5df4)
	Chars C_KANJI_JIS_4744			; 0x9463 (U+628a)
	Chars C_KANJI_JIS_4745			; 0x9464 (U+64ad)
	Chars C_KANJI_JIS_4746			; 0x9465 (U+8987)
	Chars C_KANJI_JIS_4747			; 0x9466 (U+6777)
	Chars C_KANJI_JIS_4748			; 0x9467 (U+6ce2)
	Chars C_KANJI_JIS_4749			; 0x9468 (U+6d3e)
	Chars C_KANJI_JIS_474A			; 0x9469 (U+7436)
	Chars C_KANJI_JIS_474B			; 0x946a (U+7834)
Section5a40Start	label	Chars
	Chars C_KANJI_JIS_474C			; 0x946b (U+5a46)
	Chars C_KANJI_JIS_474D			; 0x946c (U+7f75)
	Chars C_KANJI_JIS_474E			; 0x946d (U+82ad)
	Chars C_KANJI_JIS_474F			; 0x946e (U+99ac)
	Chars C_KANJI_JIS_4750			; 0x946f (U+4ff3)
Section5ec0Start	label	Chars
	Chars C_KANJI_JIS_4751			; 0x9470 (U+5ec3)
	Chars C_KANJI_JIS_4752			; 0x9471 (U+62dd)
	Chars C_KANJI_JIS_4753			; 0x9472 (U+6392)
	Chars C_KANJI_JIS_4754			; 0x9473 (U+6557)
	Chars C_KANJI_JIS_4755			; 0x9474 (U+676f)
	Chars C_KANJI_JIS_4756			; 0x9475 (U+76c3)
Section7240Start	label	Chars
	Chars C_KANJI_JIS_4757			; 0x9476 (U+724c)
	Chars C_KANJI_JIS_4758			; 0x9477 (U+80cc)
	Chars C_KANJI_JIS_4759			; 0x9478 (U+80ba)
	Chars C_KANJI_JIS_475A			; 0x9479 (U+8f29)
	Chars C_KANJI_JIS_475B			; 0x947a (U+914d)
	Chars C_KANJI_JIS_475C			; 0x947b (U+500d)
	Chars C_KANJI_JIS_475D			; 0x947c (U+57f9)
Section5a90Start	label	Chars
	Chars C_KANJI_JIS_475E			; 0x947d (U+5a92)
Section6880Start	label	Chars
	Chars C_KANJI_JIS_475F			; 0x947e (U+6885)
	Chars 0					; 0x947f
	Chars C_KANJI_JIS_4760			; 0x9480 (U+6973)
	Chars C_KANJI_JIS_4761			; 0x9481 (U+7164)
	Chars C_KANJI_JIS_4762			; 0x9482 (U+72fd)
	Chars C_KANJI_JIS_4763			; 0x9483 (U+8cb7)
	Chars C_KANJI_JIS_4764			; 0x9484 (U+58f2)
	Chars C_KANJI_JIS_4765			; 0x9485 (U+8ce0)
	Chars C_KANJI_JIS_4766			; 0x9486 (U+966a)
	Chars C_KANJI_JIS_4767			; 0x9487 (U+9019)
	Chars C_KANJI_JIS_4768			; 0x9488 (U+877f)
	Chars C_KANJI_JIS_4769			; 0x9489 (U+79e4)
	Chars C_KANJI_JIS_476A			; 0x948a (U+77e7)
Section8420Start	label	Chars
	Chars C_KANJI_JIS_476B			; 0x948b (U+8429)
Section4f20Start	label	Chars
	Chars C_KANJI_JIS_476C			; 0x948c (U+4f2f)
	Chars C_KANJI_JIS_476D			; 0x948d (U+5265)
	Chars C_KANJI_JIS_476E			; 0x948e (U+535a)
	Chars C_KANJI_JIS_476F			; 0x948f (U+62cd)
	Chars C_KANJI_JIS_4770			; 0x9490 (U+67cf)
	Chars C_KANJI_JIS_4771			; 0x9491 (U+6cca)
	Chars C_KANJI_JIS_4772			; 0x9492 (U+767d)
	Chars C_KANJI_JIS_4773			; 0x9493 (U+7b94)
	Chars C_KANJI_JIS_4774			; 0x9494 (U+7c95)
	Chars C_KANJI_JIS_4775			; 0x9495 (U+8236)
Section8580Start	label	Chars
	Chars C_KANJI_JIS_4776			; 0x9496 (U+8584)
	Chars C_KANJI_JIS_4777			; 0x9497 (U+8feb)
	Chars C_KANJI_JIS_4778			; 0x9498 (U+66dd)
	Chars C_KANJI_JIS_4779			; 0x9499 (U+6f20)
Section7200Start	label	Chars
	Chars C_KANJI_JIS_477A			; 0x949a (U+7206)
	Chars C_KANJI_JIS_477B			; 0x949b (U+7e1b)
Section83a0Start	label	Chars
	Chars C_KANJI_JIS_477C			; 0x949c (U+83ab)
	Chars C_KANJI_JIS_477D			; 0x949d (U+99c1)
Section9ea0Start	label	Chars
	Chars C_KANJI_JIS_477E			; 0x949e (U+9ea6)
	Chars C_KANJI_JIS_4821			; 0x949f (U+51fd)
Section7bb0Start	label	Chars
	Chars C_KANJI_JIS_4822			; 0x94a0 (U+7bb1)
Section7870Start	label	Chars
	Chars C_KANJI_JIS_4823			; 0x94a1 (U+7872)
	Chars C_KANJI_JIS_4824			; 0x94a2 (U+7bb8)
	Chars C_KANJI_JIS_4825			; 0x94a3 (U+8087)
	Chars C_KANJI_JIS_4826			; 0x94a4 (U+7b48)
Section6ae0Start	label	Chars
	Chars C_KANJI_JIS_4827			; 0x94a5 (U+6ae8)
Section5e60Start	label	Chars
	Chars C_KANJI_JIS_4828			; 0x94a6 (U+5e61)
	Chars C_KANJI_JIS_4829			; 0x94a7 (U+808c)
	Chars C_KANJI_JIS_482A			; 0x94a8 (U+7551)
	Chars C_KANJI_JIS_482B			; 0x94a9 (U+7560)
	Chars C_KANJI_JIS_482C			; 0x94aa (U+516b)
	Chars C_KANJI_JIS_482D			; 0x94ab (U+9262)
Section6e80Start	label	Chars
	Chars C_KANJI_JIS_482E			; 0x94ac (U+6e8c)
	Chars C_KANJI_JIS_482F			; 0x94ad (U+767a)
	Chars C_KANJI_JIS_4830			; 0x94ae (U+9197)
Section9ae0Start	label	Chars
	Chars C_KANJI_JIS_4831			; 0x94af (U+9aea)
	Chars C_KANJI_JIS_4832			; 0x94b0 (U+4f10)
	Chars C_KANJI_JIS_4833			; 0x94b1 (U+7f70)
	Chars C_KANJI_JIS_4834			; 0x94b2 (U+629c)
	Chars C_KANJI_JIS_4835			; 0x94b3 (U+7b4f)
	Chars C_KANJI_JIS_4836			; 0x94b4 (U+95a5)
	Chars C_KANJI_JIS_4837			; 0x94b5 (U+9ce9)
	Chars C_KANJI_JIS_4838			; 0x94b6 (U+567a)
	Chars C_KANJI_JIS_4839			; 0x94b7 (U+5859)
Section86e0Start	label	Chars
	Chars C_KANJI_JIS_483A			; 0x94b8 (U+86e4)
	Chars C_KANJI_JIS_483B			; 0x94b9 (U+96bc)
	Chars C_KANJI_JIS_483C			; 0x94ba (U+4f34)
Section5220Start	label	Chars
	Chars C_KANJI_JIS_483D			; 0x94bb (U+5224)
	Chars C_KANJI_JIS_483E			; 0x94bc (U+534a)
	Chars C_KANJI_JIS_483F			; 0x94bd (U+53cd)
	Chars C_KANJI_JIS_4840			; 0x94be (U+53db)
	Chars C_KANJI_JIS_4841			; 0x94bf (U+5e06)
	Chars C_KANJI_JIS_4842			; 0x94c0 (U+642c)
	Chars C_KANJI_JIS_4843			; 0x94c1 (U+6591)
	Chars C_KANJI_JIS_4844			; 0x94c2 (U+677f)
	Chars C_KANJI_JIS_4845			; 0x94c3 (U+6c3e)
	Chars C_KANJI_JIS_4846			; 0x94c4 (U+6c4e)
	Chars C_KANJI_JIS_4847			; 0x94c5 (U+7248)
	Chars C_KANJI_JIS_4848			; 0x94c6 (U+72af)
	Chars C_KANJI_JIS_4849			; 0x94c7 (U+73ed)
	Chars C_KANJI_JIS_484A			; 0x94c8 (U+7554)
	Chars C_KANJI_JIS_484B			; 0x94c9 (U+7e41)
	Chars C_KANJI_JIS_484C			; 0x94ca (U+822c)
	Chars C_KANJI_JIS_484D			; 0x94cb (U+85e9)
	Chars C_KANJI_JIS_484E			; 0x94cc (U+8ca9)
	Chars C_KANJI_JIS_484F			; 0x94cd (U+7bc4)
	Chars C_KANJI_JIS_4850			; 0x94ce (U+91c6)
	Chars C_KANJI_JIS_4851			; 0x94cf (U+7169)
	Chars C_KANJI_JIS_4852			; 0x94d0 (U+9812)
	Chars C_KANJI_JIS_4853			; 0x94d1 (U+98ef)
	Chars C_KANJI_JIS_4854			; 0x94d2 (U+633d)
	Chars C_KANJI_JIS_4855			; 0x94d3 (U+6669)
	Chars C_KANJI_JIS_4856			; 0x94d4 (U+756a)
	Chars C_KANJI_JIS_4857			; 0x94d5 (U+76e4)
Section78d0Start	label	Chars
	Chars C_KANJI_JIS_4858			; 0x94d6 (U+78d0)
	Chars C_KANJI_JIS_4859			; 0x94d7 (U+8543)
	Chars C_KANJI_JIS_485A			; 0x94d8 (U+86ee)
	Chars C_KANJI_JIS_485B			; 0x94d9 (U+532a)
	Chars C_KANJI_JIS_485C			; 0x94da (U+5351)
	Chars C_KANJI_JIS_485D			; 0x94db (U+5426)
	Chars C_KANJI_JIS_485E			; 0x94dc (U+5983)
	Chars C_KANJI_JIS_485F			; 0x94dd (U+5e87)
	Chars C_KANJI_JIS_4860			; 0x94de (U+5f7c)
	Chars C_KANJI_JIS_4861			; 0x94df (U+60b2)
	Chars C_KANJI_JIS_4862			; 0x94e0 (U+6249)
	Chars C_KANJI_JIS_4863			; 0x94e1 (U+6279)
Section62a0Start	label	Chars
	Chars C_KANJI_JIS_4864			; 0x94e2 (U+62ab)
	Chars C_KANJI_JIS_4865			; 0x94e3 (U+6590)
	Chars C_KANJI_JIS_4866			; 0x94e4 (U+6bd4)
	Chars C_KANJI_JIS_4867			; 0x94e5 (U+6ccc)
	Chars C_KANJI_JIS_4868			; 0x94e6 (U+75b2)
Section76a0Start	label	Chars
	Chars C_KANJI_JIS_4869			; 0x94e7 (U+76ae)
	Chars C_KANJI_JIS_486A			; 0x94e8 (U+7891)
	Chars C_KANJI_JIS_486B			; 0x94e9 (U+79d8)
	Chars C_KANJI_JIS_486C			; 0x94ea (U+7dcb)
	Chars C_KANJI_JIS_486D			; 0x94eb (U+7f77)
	Chars C_KANJI_JIS_486E			; 0x94ec (U+80a5)
Section88a0Start	label	Chars
	Chars C_KANJI_JIS_486F			; 0x94ed (U+88ab)
	Chars C_KANJI_JIS_4870			; 0x94ee (U+8ab9)
	Chars C_KANJI_JIS_4871			; 0x94ef (U+8cbb)
	Chars C_KANJI_JIS_4872			; 0x94f0 (U+907f)
	Chars C_KANJI_JIS_4873			; 0x94f1 (U+975e)
	Chars C_KANJI_JIS_4874			; 0x94f2 (U+98db)
Section6a00Start	label	Chars
	Chars C_KANJI_JIS_4875			; 0x94f3 (U+6a0b)
Section7c30Start	label	Chars
	Chars C_KANJI_JIS_4876			; 0x94f4 (U+7c38)
	Chars C_KANJI_JIS_4877			; 0x94f5 (U+5099)
	Chars C_KANJI_JIS_4878			; 0x94f6 (U+5c3e)
	Chars C_KANJI_JIS_4879			; 0x94f7 (U+5fae)
Section6780Start	label	Chars
	Chars C_KANJI_JIS_487A			; 0x94f8 (U+6787)
	Chars C_KANJI_JIS_487B			; 0x94f9 (U+6bd8)
	Chars C_KANJI_JIS_487C			; 0x94fa (U+7435)
	Chars C_KANJI_JIS_487D			; 0x94fb (U+7709)
Section7f80Start	label	Chars
	Chars C_KANJI_JIS_487E			; 0x94fc (U+7f8e)
	Chars 0					; 0x94fd
	Chars 0					; 0x94fe
	Chars 0					; 0x94ff
Section9f30Start	label	Chars

	Chars C_KANJI_JIS_4921			; 0x9540 (U+9f3b)
	Chars C_KANJI_JIS_4922			; 0x9541 (U+67ca)
	Chars C_KANJI_JIS_4923			; 0x9542 (U+7a17)
	Chars C_KANJI_JIS_4924			; 0x9543 (U+5339)
	Chars C_KANJI_JIS_4925			; 0x9544 (U+758b)
	Chars C_KANJI_JIS_4926			; 0x9545 (U+9aed)
	Chars C_KANJI_JIS_4927			; 0x9546 (U+5f66)
Section8190Start	label	Chars
	Chars C_KANJI_JIS_4928			; 0x9547 (U+819d)
	Chars C_KANJI_JIS_4929			; 0x9548 (U+83f1)
	Chars C_KANJI_JIS_492A			; 0x9549 (U+8098)
	Chars C_KANJI_JIS_492B			; 0x954a (U+5f3c)
	Chars C_KANJI_JIS_492C			; 0x954b (U+5fc5)
	Chars C_KANJI_JIS_492D			; 0x954c (U+7562)
	Chars C_KANJI_JIS_492E			; 0x954d (U+7b46)
	Chars C_KANJI_JIS_492F			; 0x954e (U+903c)
Section6860Start	label	Chars
	Chars C_KANJI_JIS_4930			; 0x954f (U+6867)
	Chars C_KANJI_JIS_4931			; 0x9550 (U+59eb)
	Chars C_KANJI_JIS_4932			; 0x9551 (U+5a9b)
	Chars C_KANJI_JIS_4933			; 0x9552 (U+7d10)
	Chars C_KANJI_JIS_4934			; 0x9553 (U+767e)
Section8b20Start	label	Chars
	Chars C_KANJI_JIS_4935			; 0x9554 (U+8b2c)
	Chars C_KANJI_JIS_4936			; 0x9555 (U+4ff5)
	Chars C_KANJI_JIS_4937			; 0x9556 (U+5f6a)
	Chars C_KANJI_JIS_4938			; 0x9557 (U+6a19)
	Chars C_KANJI_JIS_4939			; 0x9558 (U+6c37)
	Chars C_KANJI_JIS_493A			; 0x9559 (U+6f02)
	Chars C_KANJI_JIS_493B			; 0x955a (U+74e2)
	Chars C_KANJI_JIS_493C			; 0x955b (U+7968)
	Chars C_KANJI_JIS_493D			; 0x955c (U+8868)
	Chars C_KANJI_JIS_493E			; 0x955d (U+8a55)
Section8c70Start	label	Chars
	Chars C_KANJI_JIS_493F			; 0x955e (U+8c79)
	Chars C_KANJI_JIS_4940			; 0x955f (U+5edf)
	Chars C_KANJI_JIS_4941			; 0x9560 (U+63cf)
	Chars C_KANJI_JIS_4942			; 0x9561 (U+75c5)
	Chars C_KANJI_JIS_4943			; 0x9562 (U+79d2)
	Chars C_KANJI_JIS_4944			; 0x9563 (U+82d7)
	Chars C_KANJI_JIS_4945			; 0x9564 (U+9328)
	Chars C_KANJI_JIS_4946			; 0x9565 (U+92f2)
	Chars C_KANJI_JIS_4947			; 0x9566 (U+849c)
	Chars C_KANJI_JIS_4948			; 0x9567 (U+86ed)
	Chars C_KANJI_JIS_4949			; 0x9568 (U+9c2d)
	Chars C_KANJI_JIS_494A			; 0x9569 (U+54c1)
	Chars C_KANJI_JIS_494B			; 0x956a (U+5f6c)
	Chars C_KANJI_JIS_494C			; 0x956b (U+658c)
Section6d50Start	label	Chars
	Chars C_KANJI_JIS_494D			; 0x956c (U+6d5c)
	Chars C_KANJI_JIS_494E			; 0x956d (U+7015)
	Chars C_KANJI_JIS_494F			; 0x956e (U+8ca7)
	Chars C_KANJI_JIS_4950			; 0x956f (U+8cd3)
	Chars C_KANJI_JIS_4951			; 0x9570 (U+983b)
	Chars C_KANJI_JIS_4952			; 0x9571 (U+654f)
Section74f0Start	label	Chars
	Chars C_KANJI_JIS_4953			; 0x9572 (U+74f6)
	Chars C_KANJI_JIS_4954			; 0x9573 (U+4e0d)
	Chars C_KANJI_JIS_4955			; 0x9574 (U+4ed8)
Section57e0Start	label	Chars
	Chars C_KANJI_JIS_4956			; 0x9575 (U+57e0)
	Chars C_KANJI_JIS_4957			; 0x9576 (U+592b)
Section5a60Start	label	Chars
	Chars C_KANJI_JIS_4958			; 0x9577 (U+5a66)
	Chars C_KANJI_JIS_4959			; 0x9578 (U+5bcc)
	Chars C_KANJI_JIS_495A			; 0x9579 (U+51a8)
	Chars C_KANJI_JIS_495B			; 0x957a (U+5e03)
	Chars C_KANJI_JIS_495C			; 0x957b (U+5e9c)
	Chars C_KANJI_JIS_495D			; 0x957c (U+6016)
	Chars C_KANJI_JIS_495E			; 0x957d (U+6276)
	Chars C_KANJI_JIS_495F			; 0x957e (U+6577)
	Chars 0					; 0x957f
	Chars C_KANJI_JIS_4960			; 0x9580 (U+65a7)
	Chars C_KANJI_JIS_4961			; 0x9581 (U+666e)
	Chars C_KANJI_JIS_4962			; 0x9582 (U+6d6e)
	Chars C_KANJI_JIS_4963			; 0x9583 (U+7236)
	Chars C_KANJI_JIS_4964			; 0x9584 (U+7b26)
	Chars C_KANJI_JIS_4965			; 0x9585 (U+8150)
	Chars C_KANJI_JIS_4966			; 0x9586 (U+819a)
	Chars C_KANJI_JIS_4967			; 0x9587 (U+8299)
	Chars C_KANJI_JIS_4968			; 0x9588 (U+8b5c)
	Chars C_KANJI_JIS_4969			; 0x9589 (U+8ca0)
	Chars C_KANJI_JIS_496A			; 0x958a (U+8ce6)
	Chars C_KANJI_JIS_496B			; 0x958b (U+8d74)
Section9610Start	label	Chars
	Chars C_KANJI_JIS_496C			; 0x958c (U+961c)
	Chars C_KANJI_JIS_496D			; 0x958d (U+9644)
	Chars C_KANJI_JIS_496E			; 0x958e (U+4fae)
	Chars C_KANJI_JIS_496F			; 0x958f (U+64ab)
	Chars C_KANJI_JIS_4970			; 0x9590 (U+6b66)
	Chars C_KANJI_JIS_4971			; 0x9591 (U+821e)
	Chars C_KANJI_JIS_4972			; 0x9592 (U+8461)
	Chars C_KANJI_JIS_4973			; 0x9593 (U+856a)
	Chars C_KANJI_JIS_4974			; 0x9594 (U+90e8)
	Chars C_KANJI_JIS_4975			; 0x9595 (U+5c01)
	Chars C_KANJI_JIS_4976			; 0x9596 (U+6953)
Section98a0Start	label	Chars
	Chars C_KANJI_JIS_4977			; 0x9597 (U+98a8)
	Chars C_KANJI_JIS_4978			; 0x9598 (U+847a)
Section8550Start	label	Chars
	Chars C_KANJI_JIS_4979			; 0x9599 (U+8557)
	Chars C_KANJI_JIS_497A			; 0x959a (U+4f0f)
	Chars C_KANJI_JIS_497B			; 0x959b (U+526f)
	Chars C_KANJI_JIS_497C			; 0x959c (U+5fa9)
Section5e40Start	label	Chars
	Chars C_KANJI_JIS_497D			; 0x959d (U+5e45)
	Chars C_KANJI_JIS_497E			; 0x959e (U+670d)
	Chars C_KANJI_JIS_4A21			; 0x959f (U+798f)
	Chars C_KANJI_JIS_4A22			; 0x95a0 (U+8179)
Section8900Start	label	Chars
	Chars C_KANJI_JIS_4A23			; 0x95a1 (U+8907)
	Chars C_KANJI_JIS_4A24			; 0x95a2 (U+8986)
	Chars C_KANJI_JIS_4A25			; 0x95a3 (U+6df5)
	Chars C_KANJI_JIS_4A26			; 0x95a4 (U+5f17)
	Chars C_KANJI_JIS_4A27			; 0x95a5 (U+6255)
	Chars C_KANJI_JIS_4A28			; 0x95a6 (U+6cb8)
	Chars C_KANJI_JIS_4A29			; 0x95a7 (U+4ecf)
	Chars C_KANJI_JIS_4A2A			; 0x95a8 (U+7269)
Section9b90Start	label	Chars
	Chars C_KANJI_JIS_4A2B			; 0x95a9 (U+9b92)
	Chars C_KANJI_JIS_4A2C			; 0x95aa (U+5206)
	Chars C_KANJI_JIS_4A2D			; 0x95ab (U+543b)
	Chars C_KANJI_JIS_4A2E			; 0x95ac (U+5674)
	Chars C_KANJI_JIS_4A2F			; 0x95ad (U+58b3)
	Chars C_KANJI_JIS_4A30			; 0x95ae (U+61a4)
Section6260Start	label	Chars
	Chars C_KANJI_JIS_4A31			; 0x95af (U+626e)
	Chars C_KANJI_JIS_4A32			; 0x95b0 (U+711a)
	Chars C_KANJI_JIS_4A33			; 0x95b1 (U+596e)
	Chars C_KANJI_JIS_4A34			; 0x95b2 (U+7c89)
	Chars C_KANJI_JIS_4A35			; 0x95b3 (U+7cde)
	Chars C_KANJI_JIS_4A36			; 0x95b4 (U+7d1b)
	Chars C_KANJI_JIS_4A37			; 0x95b5 (U+96f0)
	Chars C_KANJI_JIS_4A38			; 0x95b6 (U+6587)
	Chars C_KANJI_JIS_4A39			; 0x95b7 (U+805e)
	Chars C_KANJI_JIS_4A3A			; 0x95b8 (U+4e19)
	Chars C_KANJI_JIS_4A3B			; 0x95b9 (U+4f75)
	Chars C_KANJI_JIS_4A3C			; 0x95ba (U+5175)
	Chars C_KANJI_JIS_4A3D			; 0x95bb (U+5840)
	Chars C_KANJI_JIS_4A3E			; 0x95bc (U+5e63)
	Chars C_KANJI_JIS_4A3F			; 0x95bd (U+5e73)
	Chars C_KANJI_JIS_4A40			; 0x95be (U+5f0a)
	Chars C_KANJI_JIS_4A41			; 0x95bf (U+67c4)
	Chars C_KANJI_JIS_4A42			; 0x95c0 (U+4e26)
	Chars C_KANJI_JIS_4A43			; 0x95c1 (U+853d)
	Chars C_KANJI_JIS_4A44			; 0x95c2 (U+9589)
	Chars C_KANJI_JIS_4A45			; 0x95c3 (U+965b)
Section7c70Start	label	Chars
	Chars C_KANJI_JIS_4A46			; 0x95c4 (U+7c73)
	Chars C_KANJI_JIS_4A47			; 0x95c5 (U+9801)
Section50f0Start	label	Chars
	Chars C_KANJI_JIS_4A48			; 0x95c6 (U+50fb)
	Chars C_KANJI_JIS_4A49			; 0x95c7 (U+58c1)
Section7650Start	label	Chars
	Chars C_KANJI_JIS_4A4A			; 0x95c8 (U+7656)
	Chars C_KANJI_JIS_4A4B			; 0x95c9 (U+78a7)
	Chars C_KANJI_JIS_4A4C			; 0x95ca (U+5225)
	Chars C_KANJI_JIS_4A4D			; 0x95cb (U+77a5)
	Chars C_KANJI_JIS_4A4E			; 0x95cc (U+8511)
	Chars C_KANJI_JIS_4A4F			; 0x95cd (U+7b86)
	Chars C_KANJI_JIS_4A50			; 0x95ce (U+504f)
	Chars C_KANJI_JIS_4A51			; 0x95cf (U+5909)
	Chars C_KANJI_JIS_4A52			; 0x95d0 (U+7247)
	Chars C_KANJI_JIS_4A53			; 0x95d1 (U+7bc7)
	Chars C_KANJI_JIS_4A54			; 0x95d2 (U+7de8)
	Chars C_KANJI_JIS_4A55			; 0x95d3 (U+8fba)
	Chars C_KANJI_JIS_4A56			; 0x95d4 (U+8fd4)
	Chars C_KANJI_JIS_4A57			; 0x95d5 (U+904d)
	Chars C_KANJI_JIS_4A58			; 0x95d6 (U+4fbf)
	Chars C_KANJI_JIS_4A59			; 0x95d7 (U+52c9)
	Chars C_KANJI_JIS_4A5A			; 0x95d8 (U+5a29)
	Chars C_KANJI_JIS_4A5B			; 0x95d9 (U+5f01)
	Chars C_KANJI_JIS_4A5C			; 0x95da (U+97ad)
	Chars C_KANJI_JIS_4A5D			; 0x95db (U+4fdd)
	Chars C_KANJI_JIS_4A5E			; 0x95dc (U+8217)
	Chars C_KANJI_JIS_4A5F			; 0x95dd (U+92ea)
	Chars C_KANJI_JIS_4A60			; 0x95de (U+5703)
	Chars C_KANJI_JIS_4A61			; 0x95df (U+6355)
	Chars C_KANJI_JIS_4A62			; 0x95e0 (U+6b69)
	Chars C_KANJI_JIS_4A63			; 0x95e1 (U+752b)
	Chars C_KANJI_JIS_4A64			; 0x95e2 (U+88dc)
	Chars C_KANJI_JIS_4A65			; 0x95e3 (U+8f14)
	Chars C_KANJI_JIS_4A66			; 0x95e4 (U+7a42)
	Chars C_KANJI_JIS_4A67			; 0x95e5 (U+52df)
	Chars C_KANJI_JIS_4A68			; 0x95e6 (U+5893)
Section6150Start	label	Chars
	Chars C_KANJI_JIS_4A69			; 0x95e7 (U+6155)
	Chars C_KANJI_JIS_4A6A			; 0x95e8 (U+620a)
	Chars C_KANJI_JIS_4A6B			; 0x95e9 (U+66ae)
	Chars C_KANJI_JIS_4A6C			; 0x95ea (U+6bcd)
	Chars C_KANJI_JIS_4A6D			; 0x95eb (U+7c3f)
	Chars C_KANJI_JIS_4A6E			; 0x95ec (U+83e9)
	Chars C_KANJI_JIS_4A6F			; 0x95ed (U+5023)
	Chars C_KANJI_JIS_4A70			; 0x95ee (U+4ff8)
	Chars C_KANJI_JIS_4A71			; 0x95ef (U+5305)
	Chars C_KANJI_JIS_4A72			; 0x95f0 (U+5446)
	Chars C_KANJI_JIS_4A73			; 0x95f1 (U+5831)
	Chars C_KANJI_JIS_4A74			; 0x95f2 (U+5949)
	Chars C_KANJI_JIS_4A75			; 0x95f3 (U+5b9d)
	Chars C_KANJI_JIS_4A76			; 0x95f4 (U+5cf0)
	Chars C_KANJI_JIS_4A77			; 0x95f5 (U+5cef)
Section5d20Start	label	Chars
	Chars C_KANJI_JIS_4A78			; 0x95f6 (U+5d29)
	Chars C_KANJI_JIS_4A79			; 0x95f7 (U+5e96)
	Chars C_KANJI_JIS_4A7A			; 0x95f8 (U+62b1)
	Chars C_KANJI_JIS_4A7B			; 0x95f9 (U+6367)
	Chars C_KANJI_JIS_4A7C			; 0x95fa (U+653e)
	Chars C_KANJI_JIS_4A7D			; 0x95fb (U+65b9)
	Chars C_KANJI_JIS_4A7E			; 0x95fc (U+670b)
	Chars 0					; 0x95fd
	Chars 0					; 0x95fe
	Chars 0					; 0x95ff
Section6cd0Start	label	Chars

	Chars C_KANJI_JIS_4B21			; 0x9640 (U+6cd5)
	Chars C_KANJI_JIS_4B22			; 0x9641 (U+6ce1)
Section70f0Start	label	Chars
	Chars C_KANJI_JIS_4B23			; 0x9642 (U+70f9)
	Chars C_KANJI_JIS_4B24			; 0x9643 (U+7832)
	Chars C_KANJI_JIS_4B25			; 0x9644 (U+7e2b)
Section80d0Start	label	Chars
	Chars C_KANJI_JIS_4B26			; 0x9645 (U+80de)
	Chars C_KANJI_JIS_4B27			; 0x9646 (U+82b3)
	Chars C_KANJI_JIS_4B28			; 0x9647 (U+840c)
Section84e0Start	label	Chars
	Chars C_KANJI_JIS_4B29			; 0x9648 (U+84ec)
Section8700Start	label	Chars
	Chars C_KANJI_JIS_4B2A			; 0x9649 (U+8702)
	Chars C_KANJI_JIS_4B2B			; 0x964a (U+8912)
	Chars C_KANJI_JIS_4B2C			; 0x964b (U+8a2a)
	Chars C_KANJI_JIS_4B2D			; 0x964c (U+8c4a)
	Chars C_KANJI_JIS_4B2E			; 0x964d (U+90a6)
Section92d0Start	label	Chars
	Chars C_KANJI_JIS_4B2F			; 0x964e (U+92d2)
	Chars C_KANJI_JIS_4B30			; 0x964f (U+98fd)
	Chars C_KANJI_JIS_4B31			; 0x9650 (U+9cf3)
	Chars C_KANJI_JIS_4B32			; 0x9651 (U+9d6c)
	Chars C_KANJI_JIS_4B33			; 0x9652 (U+4e4f)
	Chars C_KANJI_JIS_4B34			; 0x9653 (U+4ea1)
Section5080Start	label	Chars
	Chars C_KANJI_JIS_4B35			; 0x9654 (U+508d)
	Chars C_KANJI_JIS_4B36			; 0x9655 (U+5256)
	Chars C_KANJI_JIS_4B37			; 0x9656 (U+574a)
	Chars C_KANJI_JIS_4B38			; 0x9657 (U+59a8)
	Chars C_KANJI_JIS_4B39			; 0x9658 (U+5e3d)
	Chars C_KANJI_JIS_4B3A			; 0x9659 (U+5fd8)
	Chars C_KANJI_JIS_4B3B			; 0x965a (U+5fd9)
	Chars C_KANJI_JIS_4B3C			; 0x965b (U+623f)
Section66b0Start	label	Chars
	Chars C_KANJI_JIS_4B3D			; 0x965c (U+66b4)
	Chars C_KANJI_JIS_4B3E			; 0x965d (U+671b)
	Chars C_KANJI_JIS_4B3F			; 0x965e (U+67d0)
	Chars C_KANJI_JIS_4B40			; 0x965f (U+68d2)
	Chars C_KANJI_JIS_4B41			; 0x9660 (U+5192)
	Chars C_KANJI_JIS_4B42			; 0x9661 (U+7d21)
	Chars C_KANJI_JIS_4B43			; 0x9662 (U+80aa)
Section81a0Start	label	Chars
	Chars C_KANJI_JIS_4B44			; 0x9663 (U+81a8)
	Chars C_KANJI_JIS_4B45			; 0x9664 (U+8b00)
Section8c80Start	label	Chars
	Chars C_KANJI_JIS_4B46			; 0x9665 (U+8c8c)
	Chars C_KANJI_JIS_4B47			; 0x9666 (U+8cbf)
	Chars C_KANJI_JIS_4B48			; 0x9667 (U+927e)
	Chars C_KANJI_JIS_4B49			; 0x9668 (U+9632)
	Chars C_KANJI_JIS_4B4A			; 0x9669 (U+5420)
	Chars C_KANJI_JIS_4B4B			; 0x966a (U+982c)
	Chars C_KANJI_JIS_4B4C			; 0x966b (U+5317)
	Chars C_KANJI_JIS_4B4D			; 0x966c (U+50d5)
	Chars C_KANJI_JIS_4B4E			; 0x966d (U+535c)
Section58a0Start	label	Chars
	Chars C_KANJI_JIS_4B4F			; 0x966e (U+58a8)
	Chars C_KANJI_JIS_4B50			; 0x966f (U+64b2)
	Chars C_KANJI_JIS_4B51			; 0x9670 (U+6734)
	Chars C_KANJI_JIS_4B52			; 0x9671 (U+7267)
	Chars C_KANJI_JIS_4B53			; 0x9672 (U+7766)
	Chars C_KANJI_JIS_4B54			; 0x9673 (U+7a46)
	Chars C_KANJI_JIS_4B55			; 0x9674 (U+91e6)
	Chars C_KANJI_JIS_4B56			; 0x9675 (U+52c3)
	Chars C_KANJI_JIS_4B57			; 0x9676 (U+6ca1)
	Chars C_KANJI_JIS_4B58			; 0x9677 (U+6b86)
	Chars C_KANJI_JIS_4B59			; 0x9678 (U+5800)
	Chars C_KANJI_JIS_4B5A			; 0x9679 (U+5e4c)
	Chars C_KANJI_JIS_4B5B			; 0x967a (U+5954)
	Chars C_KANJI_JIS_4B5C			; 0x967b (U+672c)
	Chars C_KANJI_JIS_4B5D			; 0x967c (U+7ffb)
	Chars C_KANJI_JIS_4B5E			; 0x967d (U+51e1)
	Chars C_KANJI_JIS_4B5F			; 0x967e (U+76c6)
	Chars 0					; 0x967f
Section6460Start	label	Chars
	Chars C_KANJI_JIS_4B60			; 0x9680 (U+6469)
	Chars C_KANJI_JIS_4B61			; 0x9681 (U+78e8)
	Chars C_KANJI_JIS_4B62			; 0x9682 (U+9b54)
	Chars C_KANJI_JIS_4B63			; 0x9683 (U+9ebb)
	Chars C_KANJI_JIS_4B64			; 0x9684 (U+57cb)
	Chars C_KANJI_JIS_4B65			; 0x9685 (U+59b9)
	Chars C_KANJI_JIS_4B66			; 0x9686 (U+6627)
	Chars C_KANJI_JIS_4B67			; 0x9687 (U+679a)
	Chars C_KANJI_JIS_4B68			; 0x9688 (U+6bce)
	Chars C_KANJI_JIS_4B69			; 0x9689 (U+54e9)
Section69d0Start	label	Chars
	Chars C_KANJI_JIS_4B6A			; 0x968a (U+69d9)
Section5e50Start	label	Chars
	Chars C_KANJI_JIS_4B6B			; 0x968b (U+5e55)
	Chars C_KANJI_JIS_4B6C			; 0x968c (U+819c)
	Chars C_KANJI_JIS_4B6D			; 0x968d (U+6795)
	Chars C_KANJI_JIS_4B6E			; 0x968e (U+9baa)
	Chars C_KANJI_JIS_4B6F			; 0x968f (U+67fe)
Section9c50Start	label	Chars
	Chars C_KANJI_JIS_4B70			; 0x9690 (U+9c52)
	Chars C_KANJI_JIS_4B71			; 0x9691 (U+685d)
	Chars C_KANJI_JIS_4B72			; 0x9692 (U+4ea6)
	Chars C_KANJI_JIS_4B73			; 0x9693 (U+4fe3)
	Chars C_KANJI_JIS_4B74			; 0x9694 (U+53c8)
	Chars C_KANJI_JIS_4B75			; 0x9695 (U+62b9)
	Chars C_KANJI_JIS_4B76			; 0x9696 (U+672b)
	Chars C_KANJI_JIS_4B77			; 0x9697 (U+6cab)
	Chars C_KANJI_JIS_4B78			; 0x9698 (U+8fc4)
	Chars C_KANJI_JIS_4B79			; 0x9699 (U+4fad)
Section7e60Start	label	Chars
	Chars C_KANJI_JIS_4B7A			; 0x969a (U+7e6d)
	Chars C_KANJI_JIS_4B7B			; 0x969b (U+9ebf)
	Chars C_KANJI_JIS_4B7C			; 0x969c (U+4e07)
	Chars C_KANJI_JIS_4B7D			; 0x969d (U+6162)
	Chars C_KANJI_JIS_4B7E			; 0x969e (U+6e80)
	Chars C_KANJI_JIS_4C21			; 0x969f (U+6f2b)
	Chars C_KANJI_JIS_4C22			; 0x96a0 (U+8513)
	Chars C_KANJI_JIS_4C23			; 0x96a1 (U+5473)
	Chars C_KANJI_JIS_4C24			; 0x96a2 (U+672a)
	Chars C_KANJI_JIS_4C25			; 0x96a3 (U+9b45)
	Chars C_KANJI_JIS_4C26			; 0x96a4 (U+5df3)
	Chars C_KANJI_JIS_4C27			; 0x96a5 (U+7b95)
	Chars C_KANJI_JIS_4C28			; 0x96a6 (U+5cac)
	Chars C_KANJI_JIS_4C29			; 0x96a7 (U+5bc6)
	Chars C_KANJI_JIS_4C2A			; 0x96a8 (U+871c)
Section6e40Start	label	Chars
	Chars C_KANJI_JIS_4C2B			; 0x96a9 (U+6e4a)
Section84d0Start	label	Chars
	Chars C_KANJI_JIS_4C2C			; 0x96aa (U+84d1)
	Chars C_KANJI_JIS_4C2D			; 0x96ab (U+7a14)
	Chars C_KANJI_JIS_4C2E			; 0x96ac (U+8108)
	Chars C_KANJI_JIS_4C2F			; 0x96ad (U+5999)
	Chars C_KANJI_JIS_4C30			; 0x96ae (U+7c8d)
	Chars C_KANJI_JIS_4C31			; 0x96af (U+6c11)
Section7720Start	label	Chars
	Chars C_KANJI_JIS_4C32			; 0x96b0 (U+7720)
	Chars C_KANJI_JIS_4C33			; 0x96b1 (U+52d9)
	Chars C_KANJI_JIS_4C34			; 0x96b2 (U+5922)
	Chars C_KANJI_JIS_4C35			; 0x96b3 (U+7121)
	Chars C_KANJI_JIS_4C36			; 0x96b4 (U+725f)
Section77d0Start	label	Chars
	Chars C_KANJI_JIS_4C37			; 0x96b5 (U+77db)
Section9720Start	label	Chars
	Chars C_KANJI_JIS_4C38			; 0x96b6 (U+9727)
	Chars C_KANJI_JIS_4C39			; 0x96b7 (U+9d61)
	Chars C_KANJI_JIS_4C3A			; 0x96b8 (U+690b)
Section5a70Start	label	Chars
	Chars C_KANJI_JIS_4C3B			; 0x96b9 (U+5a7f)
Section5a10Start	label	Chars
	Chars C_KANJI_JIS_4C3C			; 0x96ba (U+5a18)
	Chars C_KANJI_JIS_4C3D			; 0x96bb (U+51a5)
	Chars C_KANJI_JIS_4C3E			; 0x96bc (U+540d)
	Chars C_KANJI_JIS_4C3F			; 0x96bd (U+547d)
	Chars C_KANJI_JIS_4C40			; 0x96be (U+660e)
	Chars C_KANJI_JIS_4C41			; 0x96bf (U+76df)
	Chars C_KANJI_JIS_4C42			; 0x96c0 (U+8ff7)
	Chars C_KANJI_JIS_4C43			; 0x96c1 (U+9298)
	Chars C_KANJI_JIS_4C44			; 0x96c2 (U+9cf4)
	Chars C_KANJI_JIS_4C45			; 0x96c3 (U+59ea)
	Chars C_KANJI_JIS_4C46			; 0x96c4 (U+725d)
	Chars C_KANJI_JIS_4C47			; 0x96c5 (U+6ec5)
	Chars C_KANJI_JIS_4C48			; 0x96c6 (U+514d)
	Chars C_KANJI_JIS_4C49			; 0x96c7 (U+68c9)
	Chars C_KANJI_JIS_4C4A			; 0x96c8 (U+7dbf)
	Chars C_KANJI_JIS_4C4B			; 0x96c9 (U+7dec)
	Chars C_KANJI_JIS_4C4C			; 0x96ca (U+9762)
	Chars C_KANJI_JIS_4C4D			; 0x96cb (U+9eba)
	Chars C_KANJI_JIS_4C4E			; 0x96cc (U+6478)
	Chars C_KANJI_JIS_4C4F			; 0x96cd (U+6a21)
	Chars C_KANJI_JIS_4C50			; 0x96ce (U+8302)
	Chars C_KANJI_JIS_4C51			; 0x96cf (U+5984)
	Chars C_KANJI_JIS_4C52			; 0x96d0 (U+5b5f)
	Chars C_KANJI_JIS_4C53			; 0x96d1 (U+6bdb)
Section7310Start	label	Chars
	Chars C_KANJI_JIS_4C54			; 0x96d2 (U+731b)
	Chars C_KANJI_JIS_4C55			; 0x96d3 (U+76f2)
	Chars C_KANJI_JIS_4C56			; 0x96d4 (U+7db2)
	Chars C_KANJI_JIS_4C57			; 0x96d5 (U+8017)
	Chars C_KANJI_JIS_4C58			; 0x96d6 (U+8499)
Section5130Start	label	Chars
	Chars C_KANJI_JIS_4C59			; 0x96d7 (U+5132)
	Chars C_KANJI_JIS_4C5A			; 0x96d8 (U+6728)
	Chars C_KANJI_JIS_4C5B			; 0x96d9 (U+9ed9)
	Chars C_KANJI_JIS_4C5C			; 0x96da (U+76ee)
	Chars C_KANJI_JIS_4C5D			; 0x96db (U+6762)
	Chars C_KANJI_JIS_4C5E			; 0x96dc (U+52ff)
	Chars C_KANJI_JIS_4C5F			; 0x96dd (U+9905)
	Chars C_KANJI_JIS_4C60			; 0x96de (U+5c24)
	Chars C_KANJI_JIS_4C61			; 0x96df (U+623b)
	Chars C_KANJI_JIS_4C62			; 0x96e0 (U+7c7e)
	Chars C_KANJI_JIS_4C63			; 0x96e1 (U+8cb0)
	Chars C_KANJI_JIS_4C64			; 0x96e2 (U+554f)
	Chars C_KANJI_JIS_4C65			; 0x96e3 (U+60b6)
	Chars C_KANJI_JIS_4C66			; 0x96e4 (U+7d0b)
	Chars C_KANJI_JIS_4C67			; 0x96e5 (U+9580)
	Chars C_KANJI_JIS_4C68			; 0x96e6 (U+5301)
	Chars C_KANJI_JIS_4C69			; 0x96e7 (U+4e5f)
	Chars C_KANJI_JIS_4C6A			; 0x96e8 (U+51b6)
	Chars C_KANJI_JIS_4C6B			; 0x96e9 (U+591c)
	Chars C_KANJI_JIS_4C6C			; 0x96ea (U+723a)
	Chars C_KANJI_JIS_4C6D			; 0x96eb (U+8036)
	Chars C_KANJI_JIS_4C6E			; 0x96ec (U+91ce)
	Chars C_KANJI_JIS_4C6F			; 0x96ed (U+5f25)
	Chars C_KANJI_JIS_4C70			; 0x96ee (U+77e2)
Section5380Start	label	Chars
	Chars C_KANJI_JIS_4C71			; 0x96ef (U+5384)
	Chars C_KANJI_JIS_4C72			; 0x96f0 (U+5f79)
	Chars C_KANJI_JIS_4C73			; 0x96f1 (U+7d04)
	Chars C_KANJI_JIS_4C74			; 0x96f2 (U+85ac)
	Chars C_KANJI_JIS_4C75			; 0x96f3 (U+8a33)
Section8e80Start	label	Chars
	Chars C_KANJI_JIS_4C76			; 0x96f4 (U+8e8d)
	Chars C_KANJI_JIS_4C77			; 0x96f5 (U+9756)
	Chars C_KANJI_JIS_4C78			; 0x96f6 (U+67f3)
	Chars C_KANJI_JIS_4C79			; 0x96f7 (U+85ae)
	Chars C_KANJI_JIS_4C7A			; 0x96f8 (U+9453)
	Chars C_KANJI_JIS_4C7B			; 0x96f9 (U+6109)
	Chars C_KANJI_JIS_4C7C			; 0x96fa (U+6108)
	Chars C_KANJI_JIS_4C7D			; 0x96fb (U+6cb9)
	Chars C_KANJI_JIS_4C7E			; 0x96fc (U+7652)
	Chars 0					; 0x96fd
	Chars 0					; 0x96fe
	Chars 0					; 0x96ff

	Chars C_KANJI_JIS_4D21			; 0x9740 (U+8aed)
Section8f30Start	label	Chars
	Chars C_KANJI_JIS_4D22			; 0x9741 (U+8f38)
Section5520Start	label	Chars
	Chars C_KANJI_JIS_4D23			; 0x9742 (U+552f)
	Chars C_KANJI_JIS_4D24			; 0x9743 (U+4f51)
Section5120Start	label	Chars
	Chars C_KANJI_JIS_4D25			; 0x9744 (U+512a)
	Chars C_KANJI_JIS_4D26			; 0x9745 (U+52c7)
	Chars C_KANJI_JIS_4D27			; 0x9746 (U+53cb)
	Chars C_KANJI_JIS_4D28			; 0x9747 (U+5ba5)
	Chars C_KANJI_JIS_4D29			; 0x9748 (U+5e7d)
	Chars C_KANJI_JIS_4D2A			; 0x9749 (U+60a0)
	Chars C_KANJI_JIS_4D2B			; 0x974a (U+6182)
	Chars C_KANJI_JIS_4D2C			; 0x974b (U+63d6)
	Chars C_KANJI_JIS_4D2D			; 0x974c (U+6709)
	Chars C_KANJI_JIS_4D2E			; 0x974d (U+67da)
	Chars C_KANJI_JIS_4D2F			; 0x974e (U+6e67)
	Chars C_KANJI_JIS_4D30			; 0x974f (U+6d8c)
	Chars C_KANJI_JIS_4D31			; 0x9750 (U+7336)
	Chars C_KANJI_JIS_4D32			; 0x9751 (U+7337)
	Chars C_KANJI_JIS_4D33			; 0x9752 (U+7531)
	Chars C_KANJI_JIS_4D34			; 0x9753 (U+7950)
	Chars C_KANJI_JIS_4D35			; 0x9754 (U+88d5)
	Chars C_KANJI_JIS_4D36			; 0x9755 (U+8a98)
	Chars C_KANJI_JIS_4D37			; 0x9756 (U+904a)
Section9090Start	label	Chars
	Chars C_KANJI_JIS_4D38			; 0x9757 (U+9091)
	Chars C_KANJI_JIS_4D39			; 0x9758 (U+90f5)
	Chars C_KANJI_JIS_4D3A			; 0x9759 (U+96c4)
Section8780Start	label	Chars
	Chars C_KANJI_JIS_4D3B			; 0x975a (U+878d)
	Chars C_KANJI_JIS_4D3C			; 0x975b (U+5915)
	Chars C_KANJI_JIS_4D3D			; 0x975c (U+4e88)
	Chars C_KANJI_JIS_4D3E			; 0x975d (U+4f59)
	Chars C_KANJI_JIS_4D3F			; 0x975e (U+4e0e)
	Chars C_KANJI_JIS_4D40			; 0x975f (U+8a89)
	Chars C_KANJI_JIS_4D41			; 0x9760 (U+8f3f)
	Chars C_KANJI_JIS_4D42			; 0x9761 (U+9810)
	Chars C_KANJI_JIS_4D43			; 0x9762 (U+50ad)
	Chars C_KANJI_JIS_4D44			; 0x9763 (U+5e7c)
	Chars C_KANJI_JIS_4D45			; 0x9764 (U+5996)
	Chars C_KANJI_JIS_4D46			; 0x9765 (U+5bb9)
	Chars C_KANJI_JIS_4D47			; 0x9766 (U+5eb8)
	Chars C_KANJI_JIS_4D48			; 0x9767 (U+63da)
	Chars C_KANJI_JIS_4D49			; 0x9768 (U+63fa)
	Chars C_KANJI_JIS_4D4A			; 0x9769 (U+64c1)
	Chars C_KANJI_JIS_4D4B			; 0x976a (U+66dc)
Section6940Start	label	Chars
	Chars C_KANJI_JIS_4D4C			; 0x976b (U+694a)
	Chars C_KANJI_JIS_4D4D			; 0x976c (U+69d8)
Section6d00Start	label	Chars
	Chars C_KANJI_JIS_4D4E			; 0x976d (U+6d0b)
	Chars C_KANJI_JIS_4D4F			; 0x976e (U+6eb6)
	Chars C_KANJI_JIS_4D50			; 0x976f (U+7194)
	Chars C_KANJI_JIS_4D51			; 0x9770 (U+7528)
	Chars C_KANJI_JIS_4D52			; 0x9771 (U+7aaf)
	Chars C_KANJI_JIS_4D53			; 0x9772 (U+7f8a)
	Chars C_KANJI_JIS_4D54			; 0x9773 (U+8000)
Section8440Start	label	Chars
	Chars C_KANJI_JIS_4D55			; 0x9774 (U+8449)
	Chars C_KANJI_JIS_4D56			; 0x9775 (U+84c9)
	Chars C_KANJI_JIS_4D57			; 0x9776 (U+8981)
	Chars C_KANJI_JIS_4D58			; 0x9777 (U+8b21)
	Chars C_KANJI_JIS_4D59			; 0x9778 (U+8e0a)
	Chars C_KANJI_JIS_4D5A			; 0x9779 (U+9065)
	Chars C_KANJI_JIS_4D5B			; 0x977a (U+967d)
	Chars C_KANJI_JIS_4D5C			; 0x977b (U+990a)
	Chars C_KANJI_JIS_4D5D			; 0x977c (U+617e)
	Chars C_KANJI_JIS_4D5E			; 0x977d (U+6291)
	Chars C_KANJI_JIS_4D5F			; 0x977e (U+6b32)
	Chars 0					; 0x977f
	Chars C_KANJI_JIS_4D60			; 0x9780 (U+6c83)
	Chars C_KANJI_JIS_4D61			; 0x9781 (U+6d74)
	Chars C_KANJI_JIS_4D62			; 0x9782 (U+7fcc)
	Chars C_KANJI_JIS_4D63			; 0x9783 (U+7ffc)
Section6dc0Start	label	Chars
	Chars C_KANJI_JIS_4D64			; 0x9784 (U+6dc0)
	Chars C_KANJI_JIS_4D65			; 0x9785 (U+7f85)
Section87b0Start	label	Chars
	Chars C_KANJI_JIS_4D66			; 0x9786 (U+87ba)
	Chars C_KANJI_JIS_4D67			; 0x9787 (U+88f8)
	Chars C_KANJI_JIS_4D68			; 0x9788 (U+6765)
Section83b0Start	label	Chars
	Chars C_KANJI_JIS_4D69			; 0x9789 (U+83b1)
	Chars C_KANJI_JIS_4D6A			; 0x978a (U+983c)
	Chars C_KANJI_JIS_4D6B			; 0x978b (U+96f7)
	Chars C_KANJI_JIS_4D6C			; 0x978c (U+6d1b)
	Chars C_KANJI_JIS_4D6D			; 0x978d (U+7d61)
	Chars C_KANJI_JIS_4D6E			; 0x978e (U+843d)
	Chars C_KANJI_JIS_4D6F			; 0x978f (U+916a)
	Chars C_KANJI_JIS_4D70			; 0x9790 (U+4e71)
	Chars C_KANJI_JIS_4D71			; 0x9791 (U+5375)
Section5d50Start	label	Chars
	Chars C_KANJI_JIS_4D72			; 0x9792 (U+5d50)
Section6b00Start	label	Chars
	Chars C_KANJI_JIS_4D73			; 0x9793 (U+6b04)
	Chars C_KANJI_JIS_4D74			; 0x9794 (U+6feb)
Section85c0Start	label	Chars
	Chars C_KANJI_JIS_4D75			; 0x9795 (U+85cd)
Section8620Start	label	Chars
	Chars C_KANJI_JIS_4D76			; 0x9796 (U+862d)
	Chars C_KANJI_JIS_4D77			; 0x9797 (U+89a7)
	Chars C_KANJI_JIS_4D78			; 0x9798 (U+5229)
	Chars C_KANJI_JIS_4D79			; 0x9799 (U+540f)
	Chars C_KANJI_JIS_4D7A			; 0x979a (U+5c65)
	Chars C_KANJI_JIS_4D7B			; 0x979b (U+674e)
	Chars C_KANJI_JIS_4D7C			; 0x979c (U+68a8)
	Chars C_KANJI_JIS_4D7D			; 0x979d (U+7406)
Section7480Start	label	Chars
	Chars C_KANJI_JIS_4D7E			; 0x979e (U+7483)
	Chars C_KANJI_JIS_4E21			; 0x979f (U+75e2)
	Chars C_KANJI_JIS_4E22			; 0x97a0 (U+88cf)
Section88e0Start	label	Chars
	Chars C_KANJI_JIS_4E23			; 0x97a1 (U+88e1)
	Chars C_KANJI_JIS_4E24			; 0x97a2 (U+91cc)
	Chars C_KANJI_JIS_4E25			; 0x97a3 (U+96e2)
	Chars C_KANJI_JIS_4E26			; 0x97a4 (U+9678)
	Chars C_KANJI_JIS_4E27			; 0x97a5 (U+5f8b)
	Chars C_KANJI_JIS_4E28			; 0x97a6 (U+7387)
	Chars C_KANJI_JIS_4E29			; 0x97a7 (U+7acb)
	Chars C_KANJI_JIS_4E2A			; 0x97a8 (U+844e)
	Chars C_KANJI_JIS_4E2B			; 0x97a9 (U+63a0)
	Chars C_KANJI_JIS_4E2C			; 0x97aa (U+7565)
	Chars C_KANJI_JIS_4E2D			; 0x97ab (U+5289)
	Chars C_KANJI_JIS_4E2E			; 0x97ac (U+6d41)
	Chars C_KANJI_JIS_4E2F			; 0x97ad (U+6e9c)
	Chars C_KANJI_JIS_4E30			; 0x97ae (U+7409)
	Chars C_KANJI_JIS_4E31			; 0x97af (U+7559)
	Chars C_KANJI_JIS_4E32			; 0x97b0 (U+786b)
	Chars C_KANJI_JIS_4E33			; 0x97b1 (U+7c92)
	Chars C_KANJI_JIS_4E34			; 0x97b2 (U+9686)
Section7ad0Start	label	Chars
	Chars C_KANJI_JIS_4E35			; 0x97b3 (U+7adc)
Section9f80Start	label	Chars
	Chars C_KANJI_JIS_4E36			; 0x97b4 (U+9f8d)
	Chars C_KANJI_JIS_4E37			; 0x97b5 (U+4fb6)
	Chars C_KANJI_JIS_4E38			; 0x97b6 (U+616e)
	Chars C_KANJI_JIS_4E39			; 0x97b7 (U+65c5)
	Chars C_KANJI_JIS_4E3A			; 0x97b8 (U+865c)
	Chars C_KANJI_JIS_4E3B			; 0x97b9 (U+4e86)
	Chars C_KANJI_JIS_4E3C			; 0x97ba (U+4eae)
	Chars C_KANJI_JIS_4E3D			; 0x97bb (U+50da)
	Chars C_KANJI_JIS_4E3E			; 0x97bc (U+4e21)
	Chars C_KANJI_JIS_4E3F			; 0x97bd (U+51cc)
	Chars C_KANJI_JIS_4E40			; 0x97be (U+5bee)
	Chars C_KANJI_JIS_4E41			; 0x97bf (U+6599)
	Chars C_KANJI_JIS_4E42			; 0x97c0 (U+6881)
	Chars C_KANJI_JIS_4E43			; 0x97c1 (U+6dbc)
	Chars C_KANJI_JIS_4E44			; 0x97c2 (U+731f)
	Chars C_KANJI_JIS_4E45			; 0x97c3 (U+7642)
	Chars C_KANJI_JIS_4E46			; 0x97c4 (U+77ad)
	Chars C_KANJI_JIS_4E47			; 0x97c5 (U+7a1c)
	Chars C_KANJI_JIS_4E48			; 0x97c6 (U+7ce7)
	Chars C_KANJI_JIS_4E49			; 0x97c7 (U+826f)
	Chars C_KANJI_JIS_4E4A			; 0x97c8 (U+8ad2)
	Chars C_KANJI_JIS_4E4B			; 0x97c9 (U+907c)
	Chars C_KANJI_JIS_4E4C			; 0x97ca (U+91cf)
	Chars C_KANJI_JIS_4E4D			; 0x97cb (U+9675)
	Chars C_KANJI_JIS_4E4E			; 0x97cc (U+9818)
	Chars C_KANJI_JIS_4E4F			; 0x97cd (U+529b)
	Chars C_KANJI_JIS_4E50			; 0x97ce (U+7dd1)
	Chars C_KANJI_JIS_4E51			; 0x97cf (U+502b)
	Chars C_KANJI_JIS_4E52			; 0x97d0 (U+5398)
	Chars C_KANJI_JIS_4E53			; 0x97d1 (U+6797)
	Chars C_KANJI_JIS_4E54			; 0x97d2 (U+6dcb)
	Chars C_KANJI_JIS_4E55			; 0x97d3 (U+71d0)
	Chars C_KANJI_JIS_4E56			; 0x97d4 (U+7433)
	Chars C_KANJI_JIS_4E57			; 0x97d5 (U+81e8)
	Chars C_KANJI_JIS_4E58			; 0x97d6 (U+8f2a)
	Chars C_KANJI_JIS_4E59			; 0x97d7 (U+96a3)
	Chars C_KANJI_JIS_4E5A			; 0x97d8 (U+9c57)
Section9e90Start	label	Chars
	Chars C_KANJI_JIS_4E5B			; 0x97d9 (U+9e9f)
Section7460Start	label	Chars
	Chars C_KANJI_JIS_4E5C			; 0x97da (U+7460)
	Chars C_KANJI_JIS_4E5D			; 0x97db (U+5841)
	Chars C_KANJI_JIS_4E5E			; 0x97dc (U+6d99)
	Chars C_KANJI_JIS_4E5F			; 0x97dd (U+7d2f)
	Chars C_KANJI_JIS_4E60			; 0x97de (U+985e)
	Chars C_KANJI_JIS_4E61			; 0x97df (U+4ee4)
	Chars C_KANJI_JIS_4E62			; 0x97e0 (U+4f36)
	Chars C_KANJI_JIS_4E63			; 0x97e1 (U+4f8b)
	Chars C_KANJI_JIS_4E64			; 0x97e2 (U+51b7)
	Chars C_KANJI_JIS_4E65			; 0x97e3 (U+52b1)
Section5db0Start	label	Chars
	Chars C_KANJI_JIS_4E66			; 0x97e4 (U+5dba)
	Chars C_KANJI_JIS_4E67			; 0x97e5 (U+601c)
Section73b0Start	label	Chars
	Chars C_KANJI_JIS_4E68			; 0x97e6 (U+73b2)
	Chars C_KANJI_JIS_4E69			; 0x97e7 (U+793c)
	Chars C_KANJI_JIS_4E6A			; 0x97e8 (U+82d3)
	Chars C_KANJI_JIS_4E6B			; 0x97e9 (U+9234)
	Chars C_KANJI_JIS_4E6C			; 0x97ea (U+96b7)
	Chars C_KANJI_JIS_4E6D			; 0x97eb (U+96f6)
	Chars C_KANJI_JIS_4E6E			; 0x97ec (U+970a)
	Chars C_KANJI_JIS_4E6F			; 0x97ed (U+9e97)
Section9f60Start	label	Chars
	Chars C_KANJI_JIS_4E70			; 0x97ee (U+9f62)
	Chars C_KANJI_JIS_4E71			; 0x97ef (U+66a6)
	Chars C_KANJI_JIS_4E72			; 0x97f0 (U+6b74)
	Chars C_KANJI_JIS_4E73			; 0x97f1 (U+5217)
	Chars C_KANJI_JIS_4E74			; 0x97f2 (U+52a3)
	Chars C_KANJI_JIS_4E75			; 0x97f3 (U+70c8)
	Chars C_KANJI_JIS_4E76			; 0x97f4 (U+88c2)
	Chars C_KANJI_JIS_4E77			; 0x97f5 (U+5ec9)
Section6040Start	label	Chars
	Chars C_KANJI_JIS_4E78			; 0x97f6 (U+604b)
Section6190Start	label	Chars
	Chars C_KANJI_JIS_4E79			; 0x97f7 (U+6190)
	Chars C_KANJI_JIS_4E7A			; 0x97f8 (U+6f23)
	Chars C_KANJI_JIS_4E7B			; 0x97f9 (U+7149)
	Chars C_KANJI_JIS_4E7C			; 0x97fa (U+7c3e)
Section7df0Start	label	Chars
	Chars C_KANJI_JIS_4E7D			; 0x97fb (U+7df4)
	Chars C_KANJI_JIS_4E7E			; 0x97fc (U+806f)
	Chars 0					; 0x97fd
	Chars 0					; 0x97fe
	Chars 0					; 0x97ff

	Chars C_KANJI_JIS_4F21			; 0x9840 (U+84ee)
	Chars C_KANJI_JIS_4F22			; 0x9841 (U+9023)
	Chars C_KANJI_JIS_4F23			; 0x9842 (U+932c)
	Chars C_KANJI_JIS_4F24			; 0x9843 (U+5442)
Section9b60Start	label	Chars
	Chars C_KANJI_JIS_4F25			; 0x9844 (U+9b6f)
	Chars C_KANJI_JIS_4F26			; 0x9845 (U+6ad3)
	Chars C_KANJI_JIS_4F27			; 0x9846 (U+7089)
	Chars C_KANJI_JIS_4F28			; 0x9847 (U+8cc2)
	Chars C_KANJI_JIS_4F29			; 0x9848 (U+8def)
Section9730Start	label	Chars
	Chars C_KANJI_JIS_4F2A			; 0x9849 (U+9732)
	Chars C_KANJI_JIS_4F2B			; 0x984a (U+52b4)
	Chars C_KANJI_JIS_4F2C			; 0x984b (U+5a41)
	Chars C_KANJI_JIS_4F2D			; 0x984c (U+5eca)
	Chars C_KANJI_JIS_4F2E			; 0x984d (U+5f04)
	Chars C_KANJI_JIS_4F2F			; 0x984e (U+6717)
	Chars C_KANJI_JIS_4F30			; 0x984f (U+697c)
	Chars C_KANJI_JIS_4F31			; 0x9850 (U+6994)
	Chars C_KANJI_JIS_4F32			; 0x9851 (U+6d6a)
	Chars C_KANJI_JIS_4F33			; 0x9852 (U+6f0f)
	Chars C_KANJI_JIS_4F34			; 0x9853 (U+7262)
	Chars C_KANJI_JIS_4F35			; 0x9854 (U+72fc)
	Chars C_KANJI_JIS_4F36			; 0x9855 (U+7bed)
	Chars C_KANJI_JIS_4F37			; 0x9856 (U+8001)
	Chars C_KANJI_JIS_4F38			; 0x9857 (U+807e)
	Chars C_KANJI_JIS_4F39			; 0x9858 (U+874b)
	Chars C_KANJI_JIS_4F3A			; 0x9859 (U+90ce)
	Chars C_KANJI_JIS_4F3B			; 0x985a (U+516d)
	Chars C_KANJI_JIS_4F3C			; 0x985b (U+9e93)
	Chars C_KANJI_JIS_4F3D			; 0x985c (U+7984)
	Chars C_KANJI_JIS_4F3E			; 0x985d (U+808b)
Section9330Start	label	Chars
	Chars C_KANJI_JIS_4F3F			; 0x985e (U+9332)
	Chars C_KANJI_JIS_4F40			; 0x985f (U+8ad6)
	Chars C_KANJI_JIS_4F41			; 0x9860 (U+502d)
	Chars C_KANJI_JIS_4F42			; 0x9861 (U+548c)
	Chars C_KANJI_JIS_4F43			; 0x9862 (U+8a71)
	Chars C_KANJI_JIS_4F44			; 0x9863 (U+6b6a)
	Chars C_KANJI_JIS_4F45			; 0x9864 (U+8cc4)
	Chars C_KANJI_JIS_4F46			; 0x9865 (U+8107)
	Chars C_KANJI_JIS_4F47			; 0x9866 (U+60d1)
	Chars C_KANJI_JIS_4F48			; 0x9867 (U+67a0)
	Chars C_KANJI_JIS_4F49			; 0x9868 (U+9df2)
	Chars C_KANJI_JIS_4F4A			; 0x9869 (U+4e99)
	Chars C_KANJI_JIS_4F4B			; 0x986a (U+4e98)
Section9c10Start	label	Chars
	Chars C_KANJI_JIS_4F4C			; 0x986b (U+9c10)
	Chars C_KANJI_JIS_4F4D			; 0x986c (U+8a6b)
	Chars C_KANJI_JIS_4F4E			; 0x986d (U+85c1)
	Chars C_KANJI_JIS_4F4F			; 0x986e (U+8568)
	Chars C_KANJI_JIS_4F50			; 0x986f (U+6900)
	Chars C_KANJI_JIS_4F51			; 0x9870 (U+6e7e)
	Chars C_KANJI_JIS_4F52			; 0x9871 (U+7897)
	Chars C_KANJI_JIS_4F53			; 0x9872 (U+8155)
	Chars 0					; 0x9873
	Chars 0					; 0x9874
	Chars 0					; 0x9875
	Chars 0					; 0x9876
	Chars 0					; 0x9877
	Chars 0					; 0x9878
	Chars 0					; 0x9879
	Chars 0					; 0x987a
	Chars 0					; 0x987b
	Chars 0					; 0x987c
	Chars 0					; 0x987d
	Chars 0					; 0x987e
	Chars 0					; 0x987f
	Chars 0					; 0x9880
	Chars 0					; 0x9881
	Chars 0					; 0x9882
	Chars 0					; 0x9883
	Chars 0					; 0x9884
	Chars 0					; 0x9885
	Chars 0					; 0x9886
	Chars 0					; 0x9887
	Chars 0					; 0x9888
	Chars 0					; 0x9889
	Chars 0					; 0x988a
	Chars 0					; 0x988b
	Chars 0					; 0x988c
	Chars 0					; 0x988d
	Chars 0					; 0x988e
	Chars 0					; 0x988f
	Chars 0					; 0x9890
	Chars 0					; 0x9891
	Chars 0					; 0x9892
	Chars 0					; 0x9893
	Chars 0					; 0x9894
	Chars 0					; 0x9895
	Chars 0					; 0x9896
	Chars 0					; 0x9897
	Chars 0					; 0x9898
	Chars 0					; 0x9899
	Chars 0					; 0x989a
	Chars 0					; 0x989b
	Chars 0					; 0x989c
	Chars 0					; 0x989d
	Chars 0					; 0x989e
	Chars C_KANJI_JIS_5021			; 0x989f (U+5f0c)
	Chars C_KANJI_JIS_5022			; 0x98a0 (U+4e10)
	Chars C_KANJI_JIS_5023			; 0x98a1 (U+4e15)
	Chars C_KANJI_JIS_5024			; 0x98a2 (U+4e2a)
	Chars C_KANJI_JIS_5025			; 0x98a3 (U+4e31)
	Chars C_KANJI_JIS_5026			; 0x98a4 (U+4e36)
	Chars C_KANJI_JIS_5027			; 0x98a5 (U+4e3c)
	Chars C_KANJI_JIS_5028			; 0x98a6 (U+4e3f)
	Chars C_KANJI_JIS_5029			; 0x98a7 (U+4e42)
	Chars C_KANJI_JIS_502A			; 0x98a8 (U+4e56)
	Chars C_KANJI_JIS_502B			; 0x98a9 (U+4e58)
	Chars C_KANJI_JIS_502C			; 0x98aa (U+4e82)
	Chars C_KANJI_JIS_502D			; 0x98ab (U+4e85)
	Chars C_KANJI_JIS_502E			; 0x98ac (U+8c6b)
	Chars C_KANJI_JIS_502F			; 0x98ad (U+4e8a)
	Chars C_KANJI_JIS_5030			; 0x98ae (U+8212)
	Chars C_KANJI_JIS_5031			; 0x98af (U+5f0d)
	Chars C_KANJI_JIS_5032			; 0x98b0 (U+4e8e)
	Chars C_KANJI_JIS_5033			; 0x98b1 (U+4e9e)
	Chars C_KANJI_JIS_5034			; 0x98b2 (U+4e9f)
	Chars C_KANJI_JIS_5035			; 0x98b3 (U+4ea0)
	Chars C_KANJI_JIS_5036			; 0x98b4 (U+4ea2)
	Chars C_KANJI_JIS_5037			; 0x98b5 (U+4eb0)
	Chars C_KANJI_JIS_5038			; 0x98b6 (U+4eb3)
	Chars C_KANJI_JIS_5039			; 0x98b7 (U+4eb6)
	Chars C_KANJI_JIS_503A			; 0x98b8 (U+4ece)
	Chars C_KANJI_JIS_503B			; 0x98b9 (U+4ecd)
	Chars C_KANJI_JIS_503C			; 0x98ba (U+4ec4)
	Chars C_KANJI_JIS_503D			; 0x98bb (U+4ec6)
	Chars C_KANJI_JIS_503E			; 0x98bc (U+4ec2)
	Chars C_KANJI_JIS_503F			; 0x98bd (U+4ed7)
	Chars C_KANJI_JIS_5040			; 0x98be (U+4ede)
	Chars C_KANJI_JIS_5041			; 0x98bf (U+4eed)
	Chars C_KANJI_JIS_5042			; 0x98c0 (U+4edf)
	Chars C_KANJI_JIS_5043			; 0x98c1 (U+4ef7)
	Chars C_KANJI_JIS_5044			; 0x98c2 (U+4f09)
	Chars C_KANJI_JIS_5045			; 0x98c3 (U+4f5a)
	Chars C_KANJI_JIS_5046			; 0x98c4 (U+4f30)
	Chars C_KANJI_JIS_5047			; 0x98c5 (U+4f5b)
	Chars C_KANJI_JIS_5048			; 0x98c6 (U+4f5d)
	Chars C_KANJI_JIS_5049			; 0x98c7 (U+4f57)
	Chars C_KANJI_JIS_504A			; 0x98c8 (U+4f47)
	Chars C_KANJI_JIS_504B			; 0x98c9 (U+4f76)
	Chars C_KANJI_JIS_504C			; 0x98ca (U+4f88)
	Chars C_KANJI_JIS_504D			; 0x98cb (U+4f8f)
	Chars C_KANJI_JIS_504E			; 0x98cc (U+4f98)
	Chars C_KANJI_JIS_504F			; 0x98cd (U+4f7b)
Section4f60Start	label	Chars
	Chars C_KANJI_JIS_5050			; 0x98ce (U+4f69)
	Chars C_KANJI_JIS_5051			; 0x98cf (U+4f70)
	Chars C_KANJI_JIS_5052			; 0x98d0 (U+4f91)
	Chars C_KANJI_JIS_5053			; 0x98d1 (U+4f6f)
	Chars C_KANJI_JIS_5054			; 0x98d2 (U+4f86)
	Chars C_KANJI_JIS_5055			; 0x98d3 (U+4f96)
	Chars C_KANJI_JIS_5056			; 0x98d4 (U+5118)
	Chars C_KANJI_JIS_5057			; 0x98d5 (U+4fd4)
	Chars C_KANJI_JIS_5058			; 0x98d6 (U+4fdf)
	Chars C_KANJI_JIS_5059			; 0x98d7 (U+4fce)
	Chars C_KANJI_JIS_505A			; 0x98d8 (U+4fd8)
	Chars C_KANJI_JIS_505B			; 0x98d9 (U+4fdb)
	Chars C_KANJI_JIS_505C			; 0x98da (U+4fd1)
	Chars C_KANJI_JIS_505D			; 0x98db (U+4fda)
	Chars C_KANJI_JIS_505E			; 0x98dc (U+4fd0)
	Chars C_KANJI_JIS_505F			; 0x98dd (U+4fe4)
	Chars C_KANJI_JIS_5060			; 0x98de (U+4fe5)
	Chars C_KANJI_JIS_5061			; 0x98df (U+501a)
	Chars C_KANJI_JIS_5062			; 0x98e0 (U+5028)
	Chars C_KANJI_JIS_5063			; 0x98e1 (U+5014)
	Chars C_KANJI_JIS_5064			; 0x98e2 (U+502a)
	Chars C_KANJI_JIS_5065			; 0x98e3 (U+5025)
	Chars C_KANJI_JIS_5066			; 0x98e4 (U+5005)
	Chars C_KANJI_JIS_5067			; 0x98e5 (U+4f1c)
	Chars C_KANJI_JIS_5068			; 0x98e6 (U+4ff6)
	Chars C_KANJI_JIS_5069			; 0x98e7 (U+5021)
	Chars C_KANJI_JIS_506A			; 0x98e8 (U+5029)
	Chars C_KANJI_JIS_506B			; 0x98e9 (U+502c)
	Chars C_KANJI_JIS_506C			; 0x98ea (U+4ffe)
	Chars C_KANJI_JIS_506D			; 0x98eb (U+4fef)
	Chars C_KANJI_JIS_506E			; 0x98ec (U+5011)
	Chars C_KANJI_JIS_506F			; 0x98ed (U+5006)
	Chars C_KANJI_JIS_5070			; 0x98ee (U+5043)
	Chars C_KANJI_JIS_5071			; 0x98ef (U+5047)
	Chars C_KANJI_JIS_5072			; 0x98f0 (U+6703)
	Chars C_KANJI_JIS_5073			; 0x98f1 (U+5055)
	Chars C_KANJI_JIS_5074			; 0x98f2 (U+5050)
	Chars C_KANJI_JIS_5075			; 0x98f3 (U+5048)
	Chars C_KANJI_JIS_5076			; 0x98f4 (U+505a)
	Chars C_KANJI_JIS_5077			; 0x98f5 (U+5056)
	Chars C_KANJI_JIS_5078			; 0x98f6 (U+506c)
	Chars C_KANJI_JIS_5079			; 0x98f7 (U+5078)
	Chars C_KANJI_JIS_507A			; 0x98f8 (U+5080)
	Chars C_KANJI_JIS_507B			; 0x98f9 (U+509a)
	Chars C_KANJI_JIS_507C			; 0x98fa (U+5085)
	Chars C_KANJI_JIS_507D			; 0x98fb (U+50b4)
	Chars C_KANJI_JIS_507E			; 0x98fc (U+50b2)
	Chars 0					; 0x98fd
	Chars 0					; 0x98fe
	Chars 0					; 0x98ff

	Chars C_KANJI_JIS_5121			; 0x9940 (U+50c9)
	Chars C_KANJI_JIS_5122			; 0x9941 (U+50ca)
	Chars C_KANJI_JIS_5123			; 0x9942 (U+50b3)
	Chars C_KANJI_JIS_5124			; 0x9943 (U+50c2)
	Chars C_KANJI_JIS_5125			; 0x9944 (U+50d6)
	Chars C_KANJI_JIS_5126			; 0x9945 (U+50de)
	Chars C_KANJI_JIS_5127			; 0x9946 (U+50e5)
	Chars C_KANJI_JIS_5128			; 0x9947 (U+50ed)
	Chars C_KANJI_JIS_5129			; 0x9948 (U+50e3)
	Chars C_KANJI_JIS_512A			; 0x9949 (U+50ee)
	Chars C_KANJI_JIS_512B			; 0x994a (U+50f9)
	Chars C_KANJI_JIS_512C			; 0x994b (U+50f5)
	Chars C_KANJI_JIS_512D			; 0x994c (U+5109)
	Chars C_KANJI_JIS_512E			; 0x994d (U+5101)
	Chars C_KANJI_JIS_512F			; 0x994e (U+5102)
	Chars C_KANJI_JIS_5130			; 0x994f (U+5116)
	Chars C_KANJI_JIS_5131			; 0x9950 (U+5115)
	Chars C_KANJI_JIS_5132			; 0x9951 (U+5114)
	Chars C_KANJI_JIS_5133			; 0x9952 (U+511a)
	Chars C_KANJI_JIS_5134			; 0x9953 (U+5121)
	Chars C_KANJI_JIS_5135			; 0x9954 (U+513a)
	Chars C_KANJI_JIS_5136			; 0x9955 (U+5137)
	Chars C_KANJI_JIS_5137			; 0x9956 (U+513c)
	Chars C_KANJI_JIS_5138			; 0x9957 (U+513b)
	Chars C_KANJI_JIS_5139			; 0x9958 (U+513f)
	Chars C_KANJI_JIS_513A			; 0x9959 (U+5140)
	Chars C_KANJI_JIS_513B			; 0x995a (U+5152)
	Chars C_KANJI_JIS_513C			; 0x995b (U+514c)
	Chars C_KANJI_JIS_513D			; 0x995c (U+5154)
	Chars C_KANJI_JIS_513E			; 0x995d (U+5162)
	Chars C_KANJI_JIS_513F			; 0x995e (U+7af8)
	Chars C_KANJI_JIS_5140			; 0x995f (U+5169)
	Chars C_KANJI_JIS_5141			; 0x9960 (U+516a)
	Chars C_KANJI_JIS_5142			; 0x9961 (U+516e)
	Chars C_KANJI_JIS_5143			; 0x9962 (U+5180)
	Chars C_KANJI_JIS_5144			; 0x9963 (U+5182)
	Chars C_KANJI_JIS_5145			; 0x9964 (U+56d8)
	Chars C_KANJI_JIS_5146			; 0x9965 (U+518c)
	Chars C_KANJI_JIS_5147			; 0x9966 (U+5189)
	Chars C_KANJI_JIS_5148			; 0x9967 (U+518f)
	Chars C_KANJI_JIS_5149			; 0x9968 (U+5191)
	Chars C_KANJI_JIS_514A			; 0x9969 (U+5193)
	Chars C_KANJI_JIS_514B			; 0x996a (U+5195)
	Chars C_KANJI_JIS_514C			; 0x996b (U+5196)
	Chars C_KANJI_JIS_514D			; 0x996c (U+51a4)
	Chars C_KANJI_JIS_514E			; 0x996d (U+51a6)
	Chars C_KANJI_JIS_514F			; 0x996e (U+51a2)
	Chars C_KANJI_JIS_5150			; 0x996f (U+51a9)
	Chars C_KANJI_JIS_5151			; 0x9970 (U+51aa)
	Chars C_KANJI_JIS_5152			; 0x9971 (U+51ab)
	Chars C_KANJI_JIS_5153			; 0x9972 (U+51b3)
	Chars C_KANJI_JIS_5154			; 0x9973 (U+51b1)
	Chars C_KANJI_JIS_5155			; 0x9974 (U+51b2)
	Chars C_KANJI_JIS_5156			; 0x9975 (U+51b0)
	Chars C_KANJI_JIS_5157			; 0x9976 (U+51b5)
	Chars C_KANJI_JIS_5158			; 0x9977 (U+51bd)
	Chars C_KANJI_JIS_5159			; 0x9978 (U+51c5)
	Chars C_KANJI_JIS_515A			; 0x9979 (U+51c9)
	Chars C_KANJI_JIS_515B			; 0x997a (U+51db)
	Chars C_KANJI_JIS_515C			; 0x997b (U+51e0)
	Chars C_KANJI_JIS_515D			; 0x997c (U+8655)
	Chars C_KANJI_JIS_515E			; 0x997d (U+51e9)
	Chars C_KANJI_JIS_515F			; 0x997e (U+51ed)
	Chars 0					; 0x997f
	Chars C_KANJI_JIS_5160			; 0x9980 (U+51f0)
	Chars C_KANJI_JIS_5161			; 0x9981 (U+51f5)
	Chars C_KANJI_JIS_5162			; 0x9982 (U+51fe)
	Chars C_KANJI_JIS_5163			; 0x9983 (U+5204)
	Chars C_KANJI_JIS_5164			; 0x9984 (U+520b)
	Chars C_KANJI_JIS_5165			; 0x9985 (U+5214)
	Chars C_KANJI_JIS_5166			; 0x9986 (U+520e)
	Chars C_KANJI_JIS_5167			; 0x9987 (U+5227)
	Chars C_KANJI_JIS_5168			; 0x9988 (U+522a)
	Chars C_KANJI_JIS_5169			; 0x9989 (U+522e)
	Chars C_KANJI_JIS_516A			; 0x998a (U+5233)
	Chars C_KANJI_JIS_516B			; 0x998b (U+5239)
	Chars C_KANJI_JIS_516C			; 0x998c (U+524f)
	Chars C_KANJI_JIS_516D			; 0x998d (U+5244)
	Chars C_KANJI_JIS_516E			; 0x998e (U+524b)
	Chars C_KANJI_JIS_516F			; 0x998f (U+524c)
	Chars C_KANJI_JIS_5170			; 0x9990 (U+525e)
	Chars C_KANJI_JIS_5171			; 0x9991 (U+5254)
	Chars C_KANJI_JIS_5172			; 0x9992 (U+526a)
	Chars C_KANJI_JIS_5173			; 0x9993 (U+5274)
	Chars C_KANJI_JIS_5174			; 0x9994 (U+5269)
	Chars C_KANJI_JIS_5175			; 0x9995 (U+5273)
	Chars C_KANJI_JIS_5176			; 0x9996 (U+527f)
	Chars C_KANJI_JIS_5177			; 0x9997 (U+527d)
	Chars C_KANJI_JIS_5178			; 0x9998 (U+528d)
	Chars C_KANJI_JIS_5179			; 0x9999 (U+5294)
	Chars C_KANJI_JIS_517A			; 0x999a (U+5292)
	Chars C_KANJI_JIS_517B			; 0x999b (U+5271)
	Chars C_KANJI_JIS_517C			; 0x999c (U+5288)
	Chars C_KANJI_JIS_517D			; 0x999d (U+5291)
Section8fa0Start	label	Chars
	Chars C_KANJI_JIS_517E			; 0x999e (U+8fa8)
	Chars C_KANJI_JIS_5221			; 0x999f (U+8fa7)
	Chars C_KANJI_JIS_5222			; 0x99a0 (U+52ac)
	Chars C_KANJI_JIS_5223			; 0x99a1 (U+52ad)
	Chars C_KANJI_JIS_5224			; 0x99a2 (U+52bc)
	Chars C_KANJI_JIS_5225			; 0x99a3 (U+52b5)
	Chars C_KANJI_JIS_5226			; 0x99a4 (U+52c1)
	Chars C_KANJI_JIS_5227			; 0x99a5 (U+52cd)
	Chars C_KANJI_JIS_5228			; 0x99a6 (U+52d7)
	Chars C_KANJI_JIS_5229			; 0x99a7 (U+52de)
	Chars C_KANJI_JIS_522A			; 0x99a8 (U+52e3)
	Chars C_KANJI_JIS_522B			; 0x99a9 (U+52e6)
	Chars C_KANJI_JIS_522C			; 0x99aa (U+98ed)
	Chars C_KANJI_JIS_522D			; 0x99ab (U+52e0)
	Chars C_KANJI_JIS_522E			; 0x99ac (U+52f3)
	Chars C_KANJI_JIS_522F			; 0x99ad (U+52f5)
	Chars C_KANJI_JIS_5230			; 0x99ae (U+52f8)
	Chars C_KANJI_JIS_5231			; 0x99af (U+52f9)
	Chars C_KANJI_JIS_5232			; 0x99b0 (U+5306)
	Chars C_KANJI_JIS_5233			; 0x99b1 (U+5308)
	Chars C_KANJI_JIS_5234			; 0x99b2 (U+7538)
	Chars C_KANJI_JIS_5235			; 0x99b3 (U+530d)
	Chars C_KANJI_JIS_5236			; 0x99b4 (U+5310)
	Chars C_KANJI_JIS_5237			; 0x99b5 (U+530f)
	Chars C_KANJI_JIS_5238			; 0x99b6 (U+5315)
	Chars C_KANJI_JIS_5239			; 0x99b7 (U+531a)
	Chars C_KANJI_JIS_523A			; 0x99b8 (U+5323)
	Chars C_KANJI_JIS_523B			; 0x99b9 (U+532f)
	Chars C_KANJI_JIS_523C			; 0x99ba (U+5331)
	Chars C_KANJI_JIS_523D			; 0x99bb (U+5333)
	Chars C_KANJI_JIS_523E			; 0x99bc (U+5338)
	Chars C_KANJI_JIS_523F			; 0x99bd (U+5340)
	Chars C_KANJI_JIS_5240			; 0x99be (U+5346)
	Chars C_KANJI_JIS_5241			; 0x99bf (U+5345)
	Chars C_KANJI_JIS_5242			; 0x99c0 (U+4e17)
	Chars C_KANJI_JIS_5243			; 0x99c1 (U+5349)
	Chars C_KANJI_JIS_5244			; 0x99c2 (U+534d)
	Chars C_KANJI_JIS_5245			; 0x99c3 (U+51d6)
	Chars C_KANJI_JIS_5246			; 0x99c4 (U+535e)
	Chars C_KANJI_JIS_5247			; 0x99c5 (U+5369)
	Chars C_KANJI_JIS_5248			; 0x99c6 (U+536e)
	Chars C_KANJI_JIS_5249			; 0x99c7 (U+5918)
	Chars C_KANJI_JIS_524A			; 0x99c8 (U+537b)
	Chars C_KANJI_JIS_524B			; 0x99c9 (U+5377)
	Chars C_KANJI_JIS_524C			; 0x99ca (U+5382)
	Chars C_KANJI_JIS_524D			; 0x99cb (U+5396)
	Chars C_KANJI_JIS_524E			; 0x99cc (U+53a0)
	Chars C_KANJI_JIS_524F			; 0x99cd (U+53a6)
	Chars C_KANJI_JIS_5250			; 0x99ce (U+53a5)
	Chars C_KANJI_JIS_5251			; 0x99cf (U+53ae)
	Chars C_KANJI_JIS_5252			; 0x99d0 (U+53b0)
	Chars C_KANJI_JIS_5253			; 0x99d1 (U+53b6)
	Chars C_KANJI_JIS_5254			; 0x99d2 (U+53c3)
Section7c10Start	label	Chars
	Chars C_KANJI_JIS_5255			; 0x99d3 (U+7c12)
	Chars C_KANJI_JIS_5256			; 0x99d4 (U+96d9)
	Chars C_KANJI_JIS_5257			; 0x99d5 (U+53df)
	Chars C_KANJI_JIS_5258			; 0x99d6 (U+66fc)
	Chars C_KANJI_JIS_5259			; 0x99d7 (U+71ee)
	Chars C_KANJI_JIS_525A			; 0x99d8 (U+53ee)
	Chars C_KANJI_JIS_525B			; 0x99d9 (U+53e8)
	Chars C_KANJI_JIS_525C			; 0x99da (U+53ed)
	Chars C_KANJI_JIS_525D			; 0x99db (U+53fa)
	Chars C_KANJI_JIS_525E			; 0x99dc (U+5401)
	Chars C_KANJI_JIS_525F			; 0x99dd (U+543d)
	Chars C_KANJI_JIS_5260			; 0x99de (U+5440)
	Chars C_KANJI_JIS_5261			; 0x99df (U+542c)
	Chars C_KANJI_JIS_5262			; 0x99e0 (U+542d)
	Chars C_KANJI_JIS_5263			; 0x99e1 (U+543c)
	Chars C_KANJI_JIS_5264			; 0x99e2 (U+542e)
	Chars C_KANJI_JIS_5265			; 0x99e3 (U+5436)
	Chars C_KANJI_JIS_5266			; 0x99e4 (U+5429)
	Chars C_KANJI_JIS_5267			; 0x99e5 (U+541d)
	Chars C_KANJI_JIS_5268			; 0x99e6 (U+544e)
	Chars C_KANJI_JIS_5269			; 0x99e7 (U+548f)
	Chars C_KANJI_JIS_526A			; 0x99e8 (U+5475)
	Chars C_KANJI_JIS_526B			; 0x99e9 (U+548e)
	Chars C_KANJI_JIS_526C			; 0x99ea (U+545f)
	Chars C_KANJI_JIS_526D			; 0x99eb (U+5471)
	Chars C_KANJI_JIS_526E			; 0x99ec (U+5477)
	Chars C_KANJI_JIS_526F			; 0x99ed (U+5470)
Section5490Start	label	Chars
	Chars C_KANJI_JIS_5270			; 0x99ee (U+5492)
	Chars C_KANJI_JIS_5271			; 0x99ef (U+547b)
	Chars C_KANJI_JIS_5272			; 0x99f0 (U+5480)
	Chars C_KANJI_JIS_5273			; 0x99f1 (U+5476)
	Chars C_KANJI_JIS_5274			; 0x99f2 (U+5484)
	Chars C_KANJI_JIS_5275			; 0x99f3 (U+5490)
	Chars C_KANJI_JIS_5276			; 0x99f4 (U+5486)
	Chars C_KANJI_JIS_5277			; 0x99f5 (U+54c7)
Section54a0Start	label	Chars
	Chars C_KANJI_JIS_5278			; 0x99f6 (U+54a2)
	Chars C_KANJI_JIS_5279			; 0x99f7 (U+54b8)
	Chars C_KANJI_JIS_527A			; 0x99f8 (U+54a5)
	Chars C_KANJI_JIS_527B			; 0x99f9 (U+54ac)
	Chars C_KANJI_JIS_527C			; 0x99fa (U+54c4)
	Chars C_KANJI_JIS_527D			; 0x99fb (U+54c8)
	Chars C_KANJI_JIS_527E			; 0x99fc (U+54a8)
	Chars 0					; 0x99fd
	Chars 0					; 0x99fe
	Chars 0					; 0x99ff

	Chars C_KANJI_JIS_5321			; 0x9a40 (U+54ab)
	Chars C_KANJI_JIS_5322			; 0x9a41 (U+54c2)
	Chars C_KANJI_JIS_5323			; 0x9a42 (U+54a4)
	Chars C_KANJI_JIS_5324			; 0x9a43 (U+54be)
	Chars C_KANJI_JIS_5325			; 0x9a44 (U+54bc)
Section54d0Start	label	Chars
	Chars C_KANJI_JIS_5326			; 0x9a45 (U+54d8)
	Chars C_KANJI_JIS_5327			; 0x9a46 (U+54e5)
	Chars C_KANJI_JIS_5328			; 0x9a47 (U+54e6)
	Chars C_KANJI_JIS_5329			; 0x9a48 (U+550f)
	Chars C_KANJI_JIS_532A			; 0x9a49 (U+5514)
	Chars C_KANJI_JIS_532B			; 0x9a4a (U+54fd)
	Chars C_KANJI_JIS_532C			; 0x9a4b (U+54ee)
	Chars C_KANJI_JIS_532D			; 0x9a4c (U+54ed)
	Chars C_KANJI_JIS_532E			; 0x9a4d (U+54fa)
	Chars C_KANJI_JIS_532F			; 0x9a4e (U+54e2)
	Chars C_KANJI_JIS_5330			; 0x9a4f (U+5539)
	Chars C_KANJI_JIS_5331			; 0x9a50 (U+5540)
Section5560Start	label	Chars
	Chars C_KANJI_JIS_5332			; 0x9a51 (U+5563)
	Chars C_KANJI_JIS_5333			; 0x9a52 (U+554c)
	Chars C_KANJI_JIS_5334			; 0x9a53 (U+552e)
	Chars C_KANJI_JIS_5335			; 0x9a54 (U+555c)
	Chars C_KANJI_JIS_5336			; 0x9a55 (U+5545)
	Chars C_KANJI_JIS_5337			; 0x9a56 (U+5556)
	Chars C_KANJI_JIS_5338			; 0x9a57 (U+5557)
	Chars C_KANJI_JIS_5339			; 0x9a58 (U+5538)
	Chars C_KANJI_JIS_533A			; 0x9a59 (U+5533)
	Chars C_KANJI_JIS_533B			; 0x9a5a (U+555d)
	Chars C_KANJI_JIS_533C			; 0x9a5b (U+5599)
	Chars C_KANJI_JIS_533D			; 0x9a5c (U+5580)
	Chars C_KANJI_JIS_533E			; 0x9a5d (U+54af)
	Chars C_KANJI_JIS_533F			; 0x9a5e (U+558a)
	Chars C_KANJI_JIS_5340			; 0x9a5f (U+559f)
Section5570Start	label	Chars
	Chars C_KANJI_JIS_5341			; 0x9a60 (U+557b)
	Chars C_KANJI_JIS_5342			; 0x9a61 (U+557e)
	Chars C_KANJI_JIS_5343			; 0x9a62 (U+5598)
	Chars C_KANJI_JIS_5344			; 0x9a63 (U+559e)
	Chars C_KANJI_JIS_5345			; 0x9a64 (U+55ae)
	Chars C_KANJI_JIS_5346			; 0x9a65 (U+557c)
	Chars C_KANJI_JIS_5347			; 0x9a66 (U+5583)
	Chars C_KANJI_JIS_5348			; 0x9a67 (U+55a9)
	Chars C_KANJI_JIS_5349			; 0x9a68 (U+5587)
	Chars C_KANJI_JIS_534A			; 0x9a69 (U+55a8)
Section55d0Start	label	Chars
	Chars C_KANJI_JIS_534B			; 0x9a6a (U+55da)
Section55c0Start	label	Chars
	Chars C_KANJI_JIS_534C			; 0x9a6b (U+55c5)
	Chars C_KANJI_JIS_534D			; 0x9a6c (U+55df)
	Chars C_KANJI_JIS_534E			; 0x9a6d (U+55c4)
	Chars C_KANJI_JIS_534F			; 0x9a6e (U+55dc)
	Chars C_KANJI_JIS_5350			; 0x9a6f (U+55e4)
	Chars C_KANJI_JIS_5351			; 0x9a70 (U+55d4)
	Chars C_KANJI_JIS_5352			; 0x9a71 (U+5614)
Section55f0Start	label	Chars
	Chars C_KANJI_JIS_5353			; 0x9a72 (U+55f7)
	Chars C_KANJI_JIS_5354			; 0x9a73 (U+5616)
	Chars C_KANJI_JIS_5355			; 0x9a74 (U+55fe)
	Chars C_KANJI_JIS_5356			; 0x9a75 (U+55fd)
	Chars C_KANJI_JIS_5357			; 0x9a76 (U+561b)
	Chars C_KANJI_JIS_5358			; 0x9a77 (U+55f9)
	Chars C_KANJI_JIS_5359			; 0x9a78 (U+564e)
	Chars C_KANJI_JIS_535A			; 0x9a79 (U+5650)
	Chars C_KANJI_JIS_535B			; 0x9a7a (U+71df)
	Chars C_KANJI_JIS_535C			; 0x9a7b (U+5634)
	Chars C_KANJI_JIS_535D			; 0x9a7c (U+5636)
	Chars C_KANJI_JIS_535E			; 0x9a7d (U+5632)
	Chars C_KANJI_JIS_535F			; 0x9a7e (U+5638)
	Chars 0					; 0x9a7f
	Chars C_KANJI_JIS_5360			; 0x9a80 (U+566b)
	Chars C_KANJI_JIS_5361			; 0x9a81 (U+5664)
	Chars C_KANJI_JIS_5362			; 0x9a82 (U+562f)
	Chars C_KANJI_JIS_5363			; 0x9a83 (U+566c)
	Chars C_KANJI_JIS_5364			; 0x9a84 (U+566a)
	Chars C_KANJI_JIS_5365			; 0x9a85 (U+5686)
	Chars C_KANJI_JIS_5366			; 0x9a86 (U+5680)
	Chars C_KANJI_JIS_5367			; 0x9a87 (U+568a)
	Chars C_KANJI_JIS_5368			; 0x9a88 (U+56a0)
Section5690Start	label	Chars
	Chars C_KANJI_JIS_5369			; 0x9a89 (U+5694)
	Chars C_KANJI_JIS_536A			; 0x9a8a (U+568f)
	Chars C_KANJI_JIS_536B			; 0x9a8b (U+56a5)
	Chars C_KANJI_JIS_536C			; 0x9a8c (U+56ae)
Section56b0Start	label	Chars
	Chars C_KANJI_JIS_536D			; 0x9a8d (U+56b6)
	Chars C_KANJI_JIS_536E			; 0x9a8e (U+56b4)
Section56c0Start	label	Chars
	Chars C_KANJI_JIS_536F			; 0x9a8f (U+56c2)
	Chars C_KANJI_JIS_5370			; 0x9a90 (U+56bc)
	Chars C_KANJI_JIS_5371			; 0x9a91 (U+56c1)
	Chars C_KANJI_JIS_5372			; 0x9a92 (U+56c3)
	Chars C_KANJI_JIS_5373			; 0x9a93 (U+56c0)
	Chars C_KANJI_JIS_5374			; 0x9a94 (U+56c8)
	Chars C_KANJI_JIS_5375			; 0x9a95 (U+56ce)
	Chars C_KANJI_JIS_5376			; 0x9a96 (U+56d1)
	Chars C_KANJI_JIS_5377			; 0x9a97 (U+56d3)
	Chars C_KANJI_JIS_5378			; 0x9a98 (U+56d7)
	Chars C_KANJI_JIS_5379			; 0x9a99 (U+56ee)
	Chars C_KANJI_JIS_537A			; 0x9a9a (U+56f9)
	Chars C_KANJI_JIS_537B			; 0x9a9b (U+5700)
	Chars C_KANJI_JIS_537C			; 0x9a9c (U+56ff)
	Chars C_KANJI_JIS_537D			; 0x9a9d (U+5704)
	Chars C_KANJI_JIS_537E			; 0x9a9e (U+5709)
	Chars C_KANJI_JIS_5421			; 0x9a9f (U+5708)
	Chars C_KANJI_JIS_5422			; 0x9aa0 (U+570b)
	Chars C_KANJI_JIS_5423			; 0x9aa1 (U+570d)
	Chars C_KANJI_JIS_5424			; 0x9aa2 (U+5713)
	Chars C_KANJI_JIS_5425			; 0x9aa3 (U+5718)
	Chars C_KANJI_JIS_5426			; 0x9aa4 (U+5716)
	Chars C_KANJI_JIS_5427			; 0x9aa5 (U+55c7)
	Chars C_KANJI_JIS_5428			; 0x9aa6 (U+571c)
	Chars C_KANJI_JIS_5429			; 0x9aa7 (U+5726)
	Chars C_KANJI_JIS_542A			; 0x9aa8 (U+5737)
	Chars C_KANJI_JIS_542B			; 0x9aa9 (U+5738)
	Chars C_KANJI_JIS_542C			; 0x9aaa (U+574e)
	Chars C_KANJI_JIS_542D			; 0x9aab (U+573b)
	Chars C_KANJI_JIS_542E			; 0x9aac (U+5740)
	Chars C_KANJI_JIS_542F			; 0x9aad (U+574f)
	Chars C_KANJI_JIS_5430			; 0x9aae (U+5769)
	Chars C_KANJI_JIS_5431			; 0x9aaf (U+57c0)
	Chars C_KANJI_JIS_5432			; 0x9ab0 (U+5788)
	Chars C_KANJI_JIS_5433			; 0x9ab1 (U+5761)
Section5770Start	label	Chars
	Chars C_KANJI_JIS_5434			; 0x9ab2 (U+577f)
	Chars C_KANJI_JIS_5435			; 0x9ab3 (U+5789)
Section5790Start	label	Chars
	Chars C_KANJI_JIS_5436			; 0x9ab4 (U+5793)
	Chars C_KANJI_JIS_5437			; 0x9ab5 (U+57a0)
Section57b0Start	label	Chars
	Chars C_KANJI_JIS_5438			; 0x9ab6 (U+57b3)
	Chars C_KANJI_JIS_5439			; 0x9ab7 (U+57a4)
	Chars C_KANJI_JIS_543A			; 0x9ab8 (U+57aa)
	Chars C_KANJI_JIS_543B			; 0x9ab9 (U+57b0)
	Chars C_KANJI_JIS_543C			; 0x9aba (U+57c3)
	Chars C_KANJI_JIS_543D			; 0x9abb (U+57c6)
	Chars C_KANJI_JIS_543E			; 0x9abc (U+57d4)
	Chars C_KANJI_JIS_543F			; 0x9abd (U+57d2)
	Chars C_KANJI_JIS_5440			; 0x9abe (U+57d3)
	Chars C_KANJI_JIS_5441			; 0x9abf (U+580a)
	Chars C_KANJI_JIS_5442			; 0x9ac0 (U+57d6)
	Chars C_KANJI_JIS_5443			; 0x9ac1 (U+57e3)
	Chars C_KANJI_JIS_5444			; 0x9ac2 (U+580b)
	Chars C_KANJI_JIS_5445			; 0x9ac3 (U+5819)
	Chars C_KANJI_JIS_5446			; 0x9ac4 (U+581d)
	Chars C_KANJI_JIS_5447			; 0x9ac5 (U+5872)
	Chars C_KANJI_JIS_5448			; 0x9ac6 (U+5821)
	Chars C_KANJI_JIS_5449			; 0x9ac7 (U+5862)
	Chars C_KANJI_JIS_544A			; 0x9ac8 (U+584b)
	Chars C_KANJI_JIS_544B			; 0x9ac9 (U+5870)
	Chars C_KANJI_JIS_544C			; 0x9aca (U+6bc0)
	Chars C_KANJI_JIS_544D			; 0x9acb (U+5852)
	Chars C_KANJI_JIS_544E			; 0x9acc (U+583d)
	Chars C_KANJI_JIS_544F			; 0x9acd (U+5879)
	Chars C_KANJI_JIS_5450			; 0x9ace (U+5885)
	Chars C_KANJI_JIS_5451			; 0x9acf (U+58b9)
	Chars C_KANJI_JIS_5452			; 0x9ad0 (U+589f)
	Chars C_KANJI_JIS_5453			; 0x9ad1 (U+58ab)
	Chars C_KANJI_JIS_5454			; 0x9ad2 (U+58ba)
	Chars C_KANJI_JIS_5455			; 0x9ad3 (U+58de)
	Chars C_KANJI_JIS_5456			; 0x9ad4 (U+58bb)
	Chars C_KANJI_JIS_5457			; 0x9ad5 (U+58b8)
	Chars C_KANJI_JIS_5458			; 0x9ad6 (U+58ae)
	Chars C_KANJI_JIS_5459			; 0x9ad7 (U+58c5)
	Chars C_KANJI_JIS_545A			; 0x9ad8 (U+58d3)
	Chars C_KANJI_JIS_545B			; 0x9ad9 (U+58d1)
	Chars C_KANJI_JIS_545C			; 0x9ada (U+58d7)
	Chars C_KANJI_JIS_545D			; 0x9adb (U+58d9)
	Chars C_KANJI_JIS_545E			; 0x9adc (U+58d8)
	Chars C_KANJI_JIS_545F			; 0x9add (U+58e5)
	Chars C_KANJI_JIS_5460			; 0x9ade (U+58dc)
	Chars C_KANJI_JIS_5461			; 0x9adf (U+58e4)
	Chars C_KANJI_JIS_5462			; 0x9ae0 (U+58df)
	Chars C_KANJI_JIS_5463			; 0x9ae1 (U+58ef)
	Chars C_KANJI_JIS_5464			; 0x9ae2 (U+58fa)
	Chars C_KANJI_JIS_5465			; 0x9ae3 (U+58f9)
	Chars C_KANJI_JIS_5466			; 0x9ae4 (U+58fb)
	Chars C_KANJI_JIS_5467			; 0x9ae5 (U+58fc)
	Chars C_KANJI_JIS_5468			; 0x9ae6 (U+58fd)
	Chars C_KANJI_JIS_5469			; 0x9ae7 (U+5902)
	Chars C_KANJI_JIS_546A			; 0x9ae8 (U+590a)
	Chars C_KANJI_JIS_546B			; 0x9ae9 (U+5910)
	Chars C_KANJI_JIS_546C			; 0x9aea (U+591b)
	Chars C_KANJI_JIS_546D			; 0x9aeb (U+68a6)
	Chars C_KANJI_JIS_546E			; 0x9aec (U+5925)
	Chars C_KANJI_JIS_546F			; 0x9aed (U+592c)
	Chars C_KANJI_JIS_5470			; 0x9aee (U+592d)
	Chars C_KANJI_JIS_5471			; 0x9aef (U+5932)
	Chars C_KANJI_JIS_5472			; 0x9af0 (U+5938)
	Chars C_KANJI_JIS_5473			; 0x9af1 (U+593e)
	Chars C_KANJI_JIS_5474			; 0x9af2 (U+7ad2)
	Chars C_KANJI_JIS_5475			; 0x9af3 (U+5955)
	Chars C_KANJI_JIS_5476			; 0x9af4 (U+5950)
	Chars C_KANJI_JIS_5477			; 0x9af5 (U+594e)
	Chars C_KANJI_JIS_5478			; 0x9af6 (U+595a)
	Chars C_KANJI_JIS_5479			; 0x9af7 (U+5958)
	Chars C_KANJI_JIS_547A			; 0x9af8 (U+5962)
	Chars C_KANJI_JIS_547B			; 0x9af9 (U+5960)
	Chars C_KANJI_JIS_547C			; 0x9afa (U+5967)
	Chars C_KANJI_JIS_547D			; 0x9afb (U+596c)
	Chars C_KANJI_JIS_547E			; 0x9afc (U+5969)
	Chars 0					; 0x9afd
	Chars 0					; 0x9afe
	Chars 0					; 0x9aff

	Chars C_KANJI_JIS_5521			; 0x9b40 (U+5978)
	Chars C_KANJI_JIS_5522			; 0x9b41 (U+5981)
	Chars C_KANJI_JIS_5523			; 0x9b42 (U+599d)
	Chars C_KANJI_JIS_5524			; 0x9b43 (U+4f5e)
	Chars C_KANJI_JIS_5525			; 0x9b44 (U+4fab)
	Chars C_KANJI_JIS_5526			; 0x9b45 (U+59a3)
	Chars C_KANJI_JIS_5527			; 0x9b46 (U+59b2)
	Chars C_KANJI_JIS_5528			; 0x9b47 (U+59c6)
	Chars C_KANJI_JIS_5529			; 0x9b48 (U+59e8)
	Chars C_KANJI_JIS_552A			; 0x9b49 (U+59dc)
	Chars C_KANJI_JIS_552B			; 0x9b4a (U+598d)
	Chars C_KANJI_JIS_552C			; 0x9b4b (U+59d9)
	Chars C_KANJI_JIS_552D			; 0x9b4c (U+59da)
	Chars C_KANJI_JIS_552E			; 0x9b4d (U+5a25)
	Chars C_KANJI_JIS_552F			; 0x9b4e (U+5a1f)
	Chars C_KANJI_JIS_5530			; 0x9b4f (U+5a11)
	Chars C_KANJI_JIS_5531			; 0x9b50 (U+5a1c)
	Chars C_KANJI_JIS_5532			; 0x9b51 (U+5a09)
	Chars C_KANJI_JIS_5533			; 0x9b52 (U+5a1a)
	Chars C_KANJI_JIS_5534			; 0x9b53 (U+5a40)
	Chars C_KANJI_JIS_5535			; 0x9b54 (U+5a6c)
	Chars C_KANJI_JIS_5536			; 0x9b55 (U+5a49)
	Chars C_KANJI_JIS_5537			; 0x9b56 (U+5a35)
	Chars C_KANJI_JIS_5538			; 0x9b57 (U+5a36)
	Chars C_KANJI_JIS_5539			; 0x9b58 (U+5a62)
	Chars C_KANJI_JIS_553A			; 0x9b59 (U+5a6a)
	Chars C_KANJI_JIS_553B			; 0x9b5a (U+5a9a)
Section5ab0Start	label	Chars
	Chars C_KANJI_JIS_553C			; 0x9b5b (U+5abc)
	Chars C_KANJI_JIS_553D			; 0x9b5c (U+5abe)
	Chars C_KANJI_JIS_553E			; 0x9b5d (U+5acb)
	Chars C_KANJI_JIS_553F			; 0x9b5e (U+5ac2)
	Chars C_KANJI_JIS_5540			; 0x9b5f (U+5abd)
	Chars C_KANJI_JIS_5541			; 0x9b60 (U+5ae3)
Section5ad0Start	label	Chars
	Chars C_KANJI_JIS_5542			; 0x9b61 (U+5ad7)
	Chars C_KANJI_JIS_5543			; 0x9b62 (U+5ae6)
	Chars C_KANJI_JIS_5544			; 0x9b63 (U+5ae9)
	Chars C_KANJI_JIS_5545			; 0x9b64 (U+5ad6)
Section5af0Start	label	Chars
	Chars C_KANJI_JIS_5546			; 0x9b65 (U+5afa)
	Chars C_KANJI_JIS_5547			; 0x9b66 (U+5afb)
	Chars C_KANJI_JIS_5548			; 0x9b67 (U+5b0c)
	Chars C_KANJI_JIS_5549			; 0x9b68 (U+5b0b)
Section5b10Start	label	Chars
	Chars C_KANJI_JIS_554A			; 0x9b69 (U+5b16)
	Chars C_KANJI_JIS_554B			; 0x9b6a (U+5b32)
	Chars C_KANJI_JIS_554C			; 0x9b6b (U+5ad0)
	Chars C_KANJI_JIS_554D			; 0x9b6c (U+5b2a)
	Chars C_KANJI_JIS_554E			; 0x9b6d (U+5b36)
	Chars C_KANJI_JIS_554F			; 0x9b6e (U+5b3e)
Section5b40Start	label	Chars
	Chars C_KANJI_JIS_5550			; 0x9b6f (U+5b43)
	Chars C_KANJI_JIS_5551			; 0x9b70 (U+5b45)
	Chars C_KANJI_JIS_5552			; 0x9b71 (U+5b40)
	Chars C_KANJI_JIS_5553			; 0x9b72 (U+5b51)
	Chars C_KANJI_JIS_5554			; 0x9b73 (U+5b55)
	Chars C_KANJI_JIS_5555			; 0x9b74 (U+5b5a)
	Chars C_KANJI_JIS_5556			; 0x9b75 (U+5b5b)
	Chars C_KANJI_JIS_5557			; 0x9b76 (U+5b65)
	Chars C_KANJI_JIS_5558			; 0x9b77 (U+5b69)
Section5b70Start	label	Chars
	Chars C_KANJI_JIS_5559			; 0x9b78 (U+5b70)
	Chars C_KANJI_JIS_555A			; 0x9b79 (U+5b73)
	Chars C_KANJI_JIS_555B			; 0x9b7a (U+5b75)
	Chars C_KANJI_JIS_555C			; 0x9b7b (U+5b78)
	Chars C_KANJI_JIS_555D			; 0x9b7c (U+6588)
	Chars C_KANJI_JIS_555E			; 0x9b7d (U+5b7a)
	Chars C_KANJI_JIS_555F			; 0x9b7e (U+5b80)
	Chars 0					; 0x9b7f
	Chars C_KANJI_JIS_5560			; 0x9b80 (U+5b83)
	Chars C_KANJI_JIS_5561			; 0x9b81 (U+5ba6)
	Chars C_KANJI_JIS_5562			; 0x9b82 (U+5bb8)
	Chars C_KANJI_JIS_5563			; 0x9b83 (U+5bc3)
	Chars C_KANJI_JIS_5564			; 0x9b84 (U+5bc7)
	Chars C_KANJI_JIS_5565			; 0x9b85 (U+5bc9)
	Chars C_KANJI_JIS_5566			; 0x9b86 (U+5bd4)
	Chars C_KANJI_JIS_5567			; 0x9b87 (U+5bd0)
	Chars C_KANJI_JIS_5568			; 0x9b88 (U+5be4)
	Chars C_KANJI_JIS_5569			; 0x9b89 (U+5be6)
	Chars C_KANJI_JIS_556A			; 0x9b8a (U+5be2)
	Chars C_KANJI_JIS_556B			; 0x9b8b (U+5bde)
	Chars C_KANJI_JIS_556C			; 0x9b8c (U+5be5)
	Chars C_KANJI_JIS_556D			; 0x9b8d (U+5beb)
	Chars C_KANJI_JIS_556E			; 0x9b8e (U+5bf0)
	Chars C_KANJI_JIS_556F			; 0x9b8f (U+5bf6)
	Chars C_KANJI_JIS_5570			; 0x9b90 (U+5bf3)
	Chars C_KANJI_JIS_5571			; 0x9b91 (U+5c05)
	Chars C_KANJI_JIS_5572			; 0x9b92 (U+5c07)
	Chars C_KANJI_JIS_5573			; 0x9b93 (U+5c08)
	Chars C_KANJI_JIS_5574			; 0x9b94 (U+5c0d)
	Chars C_KANJI_JIS_5575			; 0x9b95 (U+5c13)
	Chars C_KANJI_JIS_5576			; 0x9b96 (U+5c20)
	Chars C_KANJI_JIS_5577			; 0x9b97 (U+5c22)
	Chars C_KANJI_JIS_5578			; 0x9b98 (U+5c28)
	Chars C_KANJI_JIS_5579			; 0x9b99 (U+5c38)
	Chars C_KANJI_JIS_557A			; 0x9b9a (U+5c39)
	Chars C_KANJI_JIS_557B			; 0x9b9b (U+5c41)
	Chars C_KANJI_JIS_557C			; 0x9b9c (U+5c46)
	Chars C_KANJI_JIS_557D			; 0x9b9d (U+5c4e)
	Chars C_KANJI_JIS_557E			; 0x9b9e (U+5c53)
	Chars C_KANJI_JIS_5621			; 0x9b9f (U+5c50)
	Chars C_KANJI_JIS_5622			; 0x9ba0 (U+5c4f)
	Chars C_KANJI_JIS_5623			; 0x9ba1 (U+5b71)
	Chars C_KANJI_JIS_5624			; 0x9ba2 (U+5c6c)
	Chars C_KANJI_JIS_5625			; 0x9ba3 (U+5c6e)
Section4e60Start	label	Chars
	Chars C_KANJI_JIS_5626			; 0x9ba4 (U+4e62)
	Chars C_KANJI_JIS_5627			; 0x9ba5 (U+5c76)
	Chars C_KANJI_JIS_5628			; 0x9ba6 (U+5c79)
Section5c80Start	label	Chars
	Chars C_KANJI_JIS_5629			; 0x9ba7 (U+5c8c)
	Chars C_KANJI_JIS_562A			; 0x9ba8 (U+5c91)
	Chars C_KANJI_JIS_562B			; 0x9ba9 (U+5c94)
	Chars C_KANJI_JIS_562C			; 0x9baa (U+599b)
	Chars C_KANJI_JIS_562D			; 0x9bab (U+5cab)
	Chars C_KANJI_JIS_562E			; 0x9bac (U+5cbb)
	Chars C_KANJI_JIS_562F			; 0x9bad (U+5cb6)
	Chars C_KANJI_JIS_5630			; 0x9bae (U+5cbc)
	Chars C_KANJI_JIS_5631			; 0x9baf (U+5cb7)
Section5cc0Start	label	Chars
	Chars C_KANJI_JIS_5632			; 0x9bb0 (U+5cc5)
	Chars C_KANJI_JIS_5633			; 0x9bb1 (U+5cbe)
	Chars C_KANJI_JIS_5634			; 0x9bb2 (U+5cc7)
Section5cd0Start	label	Chars
	Chars C_KANJI_JIS_5635			; 0x9bb3 (U+5cd9)
	Chars C_KANJI_JIS_5636			; 0x9bb4 (U+5ce9)
	Chars C_KANJI_JIS_5637			; 0x9bb5 (U+5cfd)
	Chars C_KANJI_JIS_5638			; 0x9bb6 (U+5cfa)
	Chars C_KANJI_JIS_5639			; 0x9bb7 (U+5ced)
	Chars C_KANJI_JIS_563A			; 0x9bb8 (U+5d8c)
	Chars C_KANJI_JIS_563B			; 0x9bb9 (U+5cea)
	Chars C_KANJI_JIS_563C			; 0x9bba (U+5d0b)
	Chars C_KANJI_JIS_563D			; 0x9bbb (U+5d15)
	Chars C_KANJI_JIS_563E			; 0x9bbc (U+5d17)
	Chars C_KANJI_JIS_563F			; 0x9bbd (U+5d5c)
	Chars C_KANJI_JIS_5640			; 0x9bbe (U+5d1f)
	Chars C_KANJI_JIS_5641			; 0x9bbf (U+5d1b)
	Chars C_KANJI_JIS_5642			; 0x9bc0 (U+5d11)
	Chars C_KANJI_JIS_5643			; 0x9bc1 (U+5d14)
	Chars C_KANJI_JIS_5644			; 0x9bc2 (U+5d22)
	Chars C_KANJI_JIS_5645			; 0x9bc3 (U+5d1a)
	Chars C_KANJI_JIS_5646			; 0x9bc4 (U+5d19)
	Chars C_KANJI_JIS_5647			; 0x9bc5 (U+5d18)
Section5d40Start	label	Chars
	Chars C_KANJI_JIS_5648			; 0x9bc6 (U+5d4c)
	Chars C_KANJI_JIS_5649			; 0x9bc7 (U+5d52)
	Chars C_KANJI_JIS_564A			; 0x9bc8 (U+5d4e)
	Chars C_KANJI_JIS_564B			; 0x9bc9 (U+5d4b)
	Chars C_KANJI_JIS_564C			; 0x9bca (U+5d6c)
Section5d70Start	label	Chars
	Chars C_KANJI_JIS_564D			; 0x9bcb (U+5d73)
	Chars C_KANJI_JIS_564E			; 0x9bcc (U+5d76)
	Chars C_KANJI_JIS_564F			; 0x9bcd (U+5d87)
	Chars C_KANJI_JIS_5650			; 0x9bce (U+5d84)
	Chars C_KANJI_JIS_5651			; 0x9bcf (U+5d82)
Section5da0Start	label	Chars
	Chars C_KANJI_JIS_5652			; 0x9bd0 (U+5da2)
Section5d90Start	label	Chars
	Chars C_KANJI_JIS_5653			; 0x9bd1 (U+5d9d)
	Chars C_KANJI_JIS_5654			; 0x9bd2 (U+5dac)
	Chars C_KANJI_JIS_5655			; 0x9bd3 (U+5dae)
	Chars C_KANJI_JIS_5656			; 0x9bd4 (U+5dbd)
	Chars C_KANJI_JIS_5657			; 0x9bd5 (U+5d90)
	Chars C_KANJI_JIS_5658			; 0x9bd6 (U+5db7)
	Chars C_KANJI_JIS_5659			; 0x9bd7 (U+5dbc)
	Chars C_KANJI_JIS_565A			; 0x9bd8 (U+5dc9)
	Chars C_KANJI_JIS_565B			; 0x9bd9 (U+5dcd)
	Chars C_KANJI_JIS_565C			; 0x9bda (U+5dd3)
	Chars C_KANJI_JIS_565D			; 0x9bdb (U+5dd2)
	Chars C_KANJI_JIS_565E			; 0x9bdc (U+5dd6)
	Chars C_KANJI_JIS_565F			; 0x9bdd (U+5ddb)
	Chars C_KANJI_JIS_5660			; 0x9bde (U+5deb)
	Chars C_KANJI_JIS_5661			; 0x9bdf (U+5df2)
	Chars C_KANJI_JIS_5662			; 0x9be0 (U+5df5)
	Chars C_KANJI_JIS_5663			; 0x9be1 (U+5e0b)
	Chars C_KANJI_JIS_5664			; 0x9be2 (U+5e1a)
	Chars C_KANJI_JIS_5665			; 0x9be3 (U+5e19)
	Chars C_KANJI_JIS_5666			; 0x9be4 (U+5e11)
	Chars C_KANJI_JIS_5667			; 0x9be5 (U+5e1b)
	Chars C_KANJI_JIS_5668			; 0x9be6 (U+5e36)
	Chars C_KANJI_JIS_5669			; 0x9be7 (U+5e37)
	Chars C_KANJI_JIS_566A			; 0x9be8 (U+5e44)
	Chars C_KANJI_JIS_566B			; 0x9be9 (U+5e43)
	Chars C_KANJI_JIS_566C			; 0x9bea (U+5e40)
	Chars C_KANJI_JIS_566D			; 0x9beb (U+5e4e)
	Chars C_KANJI_JIS_566E			; 0x9bec (U+5e57)
	Chars C_KANJI_JIS_566F			; 0x9bed (U+5e54)
	Chars C_KANJI_JIS_5670			; 0x9bee (U+5e5f)
	Chars C_KANJI_JIS_5671			; 0x9bef (U+5e62)
	Chars C_KANJI_JIS_5672			; 0x9bf0 (U+5e64)
	Chars C_KANJI_JIS_5673			; 0x9bf1 (U+5e47)
	Chars C_KANJI_JIS_5674			; 0x9bf2 (U+5e75)
	Chars C_KANJI_JIS_5675			; 0x9bf3 (U+5e76)
	Chars C_KANJI_JIS_5676			; 0x9bf4 (U+5e7a)
	Chars C_KANJI_JIS_5677			; 0x9bf5 (U+9ebc)
	Chars C_KANJI_JIS_5678			; 0x9bf6 (U+5e7f)
	Chars C_KANJI_JIS_5679			; 0x9bf7 (U+5ea0)
	Chars C_KANJI_JIS_567A			; 0x9bf8 (U+5ec1)
	Chars C_KANJI_JIS_567B			; 0x9bf9 (U+5ec2)
	Chars C_KANJI_JIS_567C			; 0x9bfa (U+5ec8)
	Chars C_KANJI_JIS_567D			; 0x9bfb (U+5ed0)
	Chars C_KANJI_JIS_567E			; 0x9bfc (U+5ecf)
	Chars 0					; 0x9bfd
	Chars 0					; 0x9bfe
	Chars 0					; 0x9bff

	Chars C_KANJI_JIS_5721			; 0x9c40 (U+5ed6)
	Chars C_KANJI_JIS_5722			; 0x9c41 (U+5ee3)
	Chars C_KANJI_JIS_5723			; 0x9c42 (U+5edd)
	Chars C_KANJI_JIS_5724			; 0x9c43 (U+5eda)
	Chars C_KANJI_JIS_5725			; 0x9c44 (U+5edb)
	Chars C_KANJI_JIS_5726			; 0x9c45 (U+5ee2)
	Chars C_KANJI_JIS_5727			; 0x9c46 (U+5ee1)
	Chars C_KANJI_JIS_5728			; 0x9c47 (U+5ee8)
	Chars C_KANJI_JIS_5729			; 0x9c48 (U+5ee9)
	Chars C_KANJI_JIS_572A			; 0x9c49 (U+5eec)
	Chars C_KANJI_JIS_572B			; 0x9c4a (U+5ef1)
	Chars C_KANJI_JIS_572C			; 0x9c4b (U+5ef3)
	Chars C_KANJI_JIS_572D			; 0x9c4c (U+5ef0)
	Chars C_KANJI_JIS_572E			; 0x9c4d (U+5ef4)
	Chars C_KANJI_JIS_572F			; 0x9c4e (U+5ef8)
	Chars C_KANJI_JIS_5730			; 0x9c4f (U+5efe)
	Chars C_KANJI_JIS_5731			; 0x9c50 (U+5f03)
	Chars C_KANJI_JIS_5732			; 0x9c51 (U+5f09)
	Chars C_KANJI_JIS_5733			; 0x9c52 (U+5f5d)
	Chars C_KANJI_JIS_5734			; 0x9c53 (U+5f5c)
	Chars C_KANJI_JIS_5735			; 0x9c54 (U+5f0b)
	Chars C_KANJI_JIS_5736			; 0x9c55 (U+5f11)
	Chars C_KANJI_JIS_5737			; 0x9c56 (U+5f16)
	Chars C_KANJI_JIS_5738			; 0x9c57 (U+5f29)
	Chars C_KANJI_JIS_5739			; 0x9c58 (U+5f2d)
	Chars C_KANJI_JIS_573A			; 0x9c59 (U+5f38)
	Chars C_KANJI_JIS_573B			; 0x9c5a (U+5f41)
	Chars C_KANJI_JIS_573C			; 0x9c5b (U+5f48)
	Chars C_KANJI_JIS_573D			; 0x9c5c (U+5f4c)
	Chars C_KANJI_JIS_573E			; 0x9c5d (U+5f4e)
	Chars C_KANJI_JIS_573F			; 0x9c5e (U+5f2f)
	Chars C_KANJI_JIS_5740			; 0x9c5f (U+5f51)
	Chars C_KANJI_JIS_5741			; 0x9c60 (U+5f56)
	Chars C_KANJI_JIS_5742			; 0x9c61 (U+5f57)
	Chars C_KANJI_JIS_5743			; 0x9c62 (U+5f59)
	Chars C_KANJI_JIS_5744			; 0x9c63 (U+5f61)
	Chars C_KANJI_JIS_5745			; 0x9c64 (U+5f6d)
	Chars C_KANJI_JIS_5746			; 0x9c65 (U+5f73)
	Chars C_KANJI_JIS_5747			; 0x9c66 (U+5f77)
	Chars C_KANJI_JIS_5748			; 0x9c67 (U+5f83)
	Chars C_KANJI_JIS_5749			; 0x9c68 (U+5f82)
	Chars C_KANJI_JIS_574A			; 0x9c69 (U+5f7f)
	Chars C_KANJI_JIS_574B			; 0x9c6a (U+5f8a)
	Chars C_KANJI_JIS_574C			; 0x9c6b (U+5f88)
	Chars C_KANJI_JIS_574D			; 0x9c6c (U+5f91)
	Chars C_KANJI_JIS_574E			; 0x9c6d (U+5f87)
	Chars C_KANJI_JIS_574F			; 0x9c6e (U+5f9e)
	Chars C_KANJI_JIS_5750			; 0x9c6f (U+5f99)
	Chars C_KANJI_JIS_5751			; 0x9c70 (U+5f98)
	Chars C_KANJI_JIS_5752			; 0x9c71 (U+5fa0)
	Chars C_KANJI_JIS_5753			; 0x9c72 (U+5fa8)
	Chars C_KANJI_JIS_5754			; 0x9c73 (U+5fad)
	Chars C_KANJI_JIS_5755			; 0x9c74 (U+5fbc)
	Chars C_KANJI_JIS_5756			; 0x9c75 (U+5fd6)
	Chars C_KANJI_JIS_5757			; 0x9c76 (U+5ffb)
	Chars C_KANJI_JIS_5758			; 0x9c77 (U+5fe4)
	Chars C_KANJI_JIS_5759			; 0x9c78 (U+5ff8)
	Chars C_KANJI_JIS_575A			; 0x9c79 (U+5ff1)
	Chars C_KANJI_JIS_575B			; 0x9c7a (U+5fdd)
	Chars C_KANJI_JIS_575C			; 0x9c7b (U+60b3)
	Chars C_KANJI_JIS_575D			; 0x9c7c (U+5fff)
	Chars C_KANJI_JIS_575E			; 0x9c7d (U+6021)
	Chars C_KANJI_JIS_575F			; 0x9c7e (U+6060)
	Chars 0					; 0x9c7f
	Chars C_KANJI_JIS_5760			; 0x9c80 (U+6019)
	Chars C_KANJI_JIS_5761			; 0x9c81 (U+6010)
	Chars C_KANJI_JIS_5762			; 0x9c82 (U+6029)
Section6000Start	label	Chars
	Chars C_KANJI_JIS_5763			; 0x9c83 (U+600e)
Section6030Start	label	Chars
	Chars C_KANJI_JIS_5764			; 0x9c84 (U+6031)
	Chars C_KANJI_JIS_5765			; 0x9c85 (U+601b)
	Chars C_KANJI_JIS_5766			; 0x9c86 (U+6015)
	Chars C_KANJI_JIS_5767			; 0x9c87 (U+602b)
	Chars C_KANJI_JIS_5768			; 0x9c88 (U+6026)
	Chars C_KANJI_JIS_5769			; 0x9c89 (U+600f)
	Chars C_KANJI_JIS_576A			; 0x9c8a (U+603a)
	Chars C_KANJI_JIS_576B			; 0x9c8b (U+605a)
	Chars C_KANJI_JIS_576C			; 0x9c8c (U+6041)
	Chars C_KANJI_JIS_576D			; 0x9c8d (U+606a)
	Chars C_KANJI_JIS_576E			; 0x9c8e (U+6077)
	Chars C_KANJI_JIS_576F			; 0x9c8f (U+605f)
	Chars C_KANJI_JIS_5770			; 0x9c90 (U+604a)
	Chars C_KANJI_JIS_5771			; 0x9c91 (U+6046)
	Chars C_KANJI_JIS_5772			; 0x9c92 (U+604d)
	Chars C_KANJI_JIS_5773			; 0x9c93 (U+6063)
	Chars C_KANJI_JIS_5774			; 0x9c94 (U+6043)
	Chars C_KANJI_JIS_5775			; 0x9c95 (U+6064)
	Chars C_KANJI_JIS_5776			; 0x9c96 (U+6042)
	Chars C_KANJI_JIS_5777			; 0x9c97 (U+606c)
	Chars C_KANJI_JIS_5778			; 0x9c98 (U+606b)
	Chars C_KANJI_JIS_5779			; 0x9c99 (U+6059)
	Chars C_KANJI_JIS_577A			; 0x9c9a (U+6081)
	Chars C_KANJI_JIS_577B			; 0x9c9b (U+608d)
	Chars C_KANJI_JIS_577C			; 0x9c9c (U+60e7)
	Chars C_KANJI_JIS_577D			; 0x9c9d (U+6083)
	Chars C_KANJI_JIS_577E			; 0x9c9e (U+609a)
	Chars C_KANJI_JIS_5821			; 0x9c9f (U+6084)
	Chars C_KANJI_JIS_5822			; 0x9ca0 (U+609b)
	Chars C_KANJI_JIS_5823			; 0x9ca1 (U+6096)
	Chars C_KANJI_JIS_5824			; 0x9ca2 (U+6097)
	Chars C_KANJI_JIS_5825			; 0x9ca3 (U+6092)
	Chars C_KANJI_JIS_5826			; 0x9ca4 (U+60a7)
	Chars C_KANJI_JIS_5827			; 0x9ca5 (U+608b)
	Chars C_KANJI_JIS_5828			; 0x9ca6 (U+60e1)
	Chars C_KANJI_JIS_5829			; 0x9ca7 (U+60b8)
	Chars C_KANJI_JIS_582A			; 0x9ca8 (U+60e0)
	Chars C_KANJI_JIS_582B			; 0x9ca9 (U+60d3)
	Chars C_KANJI_JIS_582C			; 0x9caa (U+60b4)
	Chars C_KANJI_JIS_582D			; 0x9cab (U+5ff0)
	Chars C_KANJI_JIS_582E			; 0x9cac (U+60bd)
	Chars C_KANJI_JIS_582F			; 0x9cad (U+60c6)
	Chars C_KANJI_JIS_5830			; 0x9cae (U+60b5)
	Chars C_KANJI_JIS_5831			; 0x9caf (U+60d8)
	Chars C_KANJI_JIS_5832			; 0x9cb0 (U+614d)
	Chars C_KANJI_JIS_5833			; 0x9cb1 (U+6115)
	Chars C_KANJI_JIS_5834			; 0x9cb2 (U+6106)
	Chars C_KANJI_JIS_5835			; 0x9cb3 (U+60f6)
	Chars C_KANJI_JIS_5836			; 0x9cb4 (U+60f7)
	Chars C_KANJI_JIS_5837			; 0x9cb5 (U+6100)
	Chars C_KANJI_JIS_5838			; 0x9cb6 (U+60f4)
	Chars C_KANJI_JIS_5839			; 0x9cb7 (U+60fa)
	Chars C_KANJI_JIS_583A			; 0x9cb8 (U+6103)
Section6120Start	label	Chars
	Chars C_KANJI_JIS_583B			; 0x9cb9 (U+6121)
	Chars C_KANJI_JIS_583C			; 0x9cba (U+60fb)
	Chars C_KANJI_JIS_583D			; 0x9cbb (U+60f1)
	Chars C_KANJI_JIS_583E			; 0x9cbc (U+610d)
	Chars C_KANJI_JIS_583F			; 0x9cbd (U+610e)
	Chars C_KANJI_JIS_5840			; 0x9cbe (U+6147)
Section6130Start	label	Chars
	Chars C_KANJI_JIS_5841			; 0x9cbf (U+613e)
	Chars C_KANJI_JIS_5842			; 0x9cc0 (U+6128)
	Chars C_KANJI_JIS_5843			; 0x9cc1 (U+6127)
	Chars C_KANJI_JIS_5844			; 0x9cc2 (U+614a)
	Chars C_KANJI_JIS_5845			; 0x9cc3 (U+613f)
	Chars C_KANJI_JIS_5846			; 0x9cc4 (U+613c)
	Chars C_KANJI_JIS_5847			; 0x9cc5 (U+612c)
	Chars C_KANJI_JIS_5848			; 0x9cc6 (U+6134)
	Chars C_KANJI_JIS_5849			; 0x9cc7 (U+613d)
	Chars C_KANJI_JIS_584A			; 0x9cc8 (U+6142)
	Chars C_KANJI_JIS_584B			; 0x9cc9 (U+6144)
	Chars C_KANJI_JIS_584C			; 0x9cca (U+6173)
	Chars C_KANJI_JIS_584D			; 0x9ccb (U+6177)
	Chars C_KANJI_JIS_584E			; 0x9ccc (U+6158)
	Chars C_KANJI_JIS_584F			; 0x9ccd (U+6159)
	Chars C_KANJI_JIS_5850			; 0x9cce (U+615a)
	Chars C_KANJI_JIS_5851			; 0x9ccf (U+616b)
	Chars C_KANJI_JIS_5852			; 0x9cd0 (U+6174)
	Chars C_KANJI_JIS_5853			; 0x9cd1 (U+616f)
	Chars C_KANJI_JIS_5854			; 0x9cd2 (U+6165)
	Chars C_KANJI_JIS_5855			; 0x9cd3 (U+6171)
	Chars C_KANJI_JIS_5856			; 0x9cd4 (U+615f)
	Chars C_KANJI_JIS_5857			; 0x9cd5 (U+615d)
	Chars C_KANJI_JIS_5858			; 0x9cd6 (U+6153)
	Chars C_KANJI_JIS_5859			; 0x9cd7 (U+6175)
	Chars C_KANJI_JIS_585A			; 0x9cd8 (U+6199)
	Chars C_KANJI_JIS_585B			; 0x9cd9 (U+6196)
	Chars C_KANJI_JIS_585C			; 0x9cda (U+6187)
	Chars C_KANJI_JIS_585D			; 0x9cdb (U+61ac)
	Chars C_KANJI_JIS_585E			; 0x9cdc (U+6194)
	Chars C_KANJI_JIS_585F			; 0x9cdd (U+619a)
	Chars C_KANJI_JIS_5860			; 0x9cde (U+618a)
	Chars C_KANJI_JIS_5861			; 0x9cdf (U+6191)
	Chars C_KANJI_JIS_5862			; 0x9ce0 (U+61ab)
	Chars C_KANJI_JIS_5863			; 0x9ce1 (U+61ae)
	Chars C_KANJI_JIS_5864			; 0x9ce2 (U+61cc)
	Chars C_KANJI_JIS_5865			; 0x9ce3 (U+61ca)
	Chars C_KANJI_JIS_5866			; 0x9ce4 (U+61c9)
	Chars C_KANJI_JIS_5867			; 0x9ce5 (U+61f7)
	Chars C_KANJI_JIS_5868			; 0x9ce6 (U+61c8)
	Chars C_KANJI_JIS_5869			; 0x9ce7 (U+61c3)
	Chars C_KANJI_JIS_586A			; 0x9ce8 (U+61c6)
	Chars C_KANJI_JIS_586B			; 0x9ce9 (U+61ba)
	Chars C_KANJI_JIS_586C			; 0x9cea (U+61cb)
	Chars C_KANJI_JIS_586D			; 0x9ceb (U+7f79)
	Chars C_KANJI_JIS_586E			; 0x9cec (U+61cd)
Section61e0Start	label	Chars
	Chars C_KANJI_JIS_586F			; 0x9ced (U+61e6)
	Chars C_KANJI_JIS_5870			; 0x9cee (U+61e3)
	Chars C_KANJI_JIS_5871			; 0x9cef (U+61f6)
	Chars C_KANJI_JIS_5872			; 0x9cf0 (U+61fa)
	Chars C_KANJI_JIS_5873			; 0x9cf1 (U+61f4)
	Chars C_KANJI_JIS_5874			; 0x9cf2 (U+61ff)
	Chars C_KANJI_JIS_5875			; 0x9cf3 (U+61fd)
	Chars C_KANJI_JIS_5876			; 0x9cf4 (U+61fc)
	Chars C_KANJI_JIS_5877			; 0x9cf5 (U+61fe)
	Chars C_KANJI_JIS_5878			; 0x9cf6 (U+6200)
	Chars C_KANJI_JIS_5879			; 0x9cf7 (U+6208)
	Chars C_KANJI_JIS_587A			; 0x9cf8 (U+6209)
	Chars C_KANJI_JIS_587B			; 0x9cf9 (U+620d)
	Chars C_KANJI_JIS_587C			; 0x9cfa (U+620c)
	Chars C_KANJI_JIS_587D			; 0x9cfb (U+6214)
	Chars C_KANJI_JIS_587E			; 0x9cfc (U+621b)
	Chars 0					; 0x9cfd
	Chars 0					; 0x9cfe
	Chars 0					; 0x9cff

	Chars C_KANJI_JIS_5921			; 0x9d40 (U+621e)
	Chars C_KANJI_JIS_5922			; 0x9d41 (U+6221)
	Chars C_KANJI_JIS_5923			; 0x9d42 (U+622a)
	Chars C_KANJI_JIS_5924			; 0x9d43 (U+622e)
	Chars C_KANJI_JIS_5925			; 0x9d44 (U+6230)
	Chars C_KANJI_JIS_5926			; 0x9d45 (U+6232)
	Chars C_KANJI_JIS_5927			; 0x9d46 (U+6233)
	Chars C_KANJI_JIS_5928			; 0x9d47 (U+6241)
	Chars C_KANJI_JIS_5929			; 0x9d48 (U+624e)
	Chars C_KANJI_JIS_592A			; 0x9d49 (U+625e)
	Chars C_KANJI_JIS_592B			; 0x9d4a (U+6263)
	Chars C_KANJI_JIS_592C			; 0x9d4b (U+625b)
	Chars C_KANJI_JIS_592D			; 0x9d4c (U+6260)
	Chars C_KANJI_JIS_592E			; 0x9d4d (U+6268)
	Chars C_KANJI_JIS_592F			; 0x9d4e (U+627c)
	Chars C_KANJI_JIS_5930			; 0x9d4f (U+6282)
	Chars C_KANJI_JIS_5931			; 0x9d50 (U+6289)
	Chars C_KANJI_JIS_5932			; 0x9d51 (U+627e)
	Chars C_KANJI_JIS_5933			; 0x9d52 (U+6292)
	Chars C_KANJI_JIS_5934			; 0x9d53 (U+6293)
	Chars C_KANJI_JIS_5935			; 0x9d54 (U+6296)
	Chars C_KANJI_JIS_5936			; 0x9d55 (U+62d4)
	Chars C_KANJI_JIS_5937			; 0x9d56 (U+6283)
	Chars C_KANJI_JIS_5938			; 0x9d57 (U+6294)
	Chars C_KANJI_JIS_5939			; 0x9d58 (U+62d7)
	Chars C_KANJI_JIS_593A			; 0x9d59 (U+62d1)
	Chars C_KANJI_JIS_593B			; 0x9d5a (U+62bb)
	Chars C_KANJI_JIS_593C			; 0x9d5b (U+62cf)
	Chars C_KANJI_JIS_593D			; 0x9d5c (U+62ff)
	Chars C_KANJI_JIS_593E			; 0x9d5d (U+62c6)
Section64d0Start	label	Chars
	Chars C_KANJI_JIS_593F			; 0x9d5e (U+64d4)
	Chars C_KANJI_JIS_5940			; 0x9d5f (U+62c8)
	Chars C_KANJI_JIS_5941			; 0x9d60 (U+62dc)
	Chars C_KANJI_JIS_5942			; 0x9d61 (U+62cc)
	Chars C_KANJI_JIS_5943			; 0x9d62 (U+62ca)
	Chars C_KANJI_JIS_5944			; 0x9d63 (U+62c2)
	Chars C_KANJI_JIS_5945			; 0x9d64 (U+62c7)
	Chars C_KANJI_JIS_5946			; 0x9d65 (U+629b)
	Chars C_KANJI_JIS_5947			; 0x9d66 (U+62c9)
	Chars C_KANJI_JIS_5948			; 0x9d67 (U+630c)
	Chars C_KANJI_JIS_5949			; 0x9d68 (U+62ee)
	Chars C_KANJI_JIS_594A			; 0x9d69 (U+62f1)
	Chars C_KANJI_JIS_594B			; 0x9d6a (U+6327)
	Chars C_KANJI_JIS_594C			; 0x9d6b (U+6302)
	Chars C_KANJI_JIS_594D			; 0x9d6c (U+6308)
	Chars C_KANJI_JIS_594E			; 0x9d6d (U+62ef)
	Chars C_KANJI_JIS_594F			; 0x9d6e (U+62f5)
	Chars C_KANJI_JIS_5950			; 0x9d6f (U+6350)
	Chars C_KANJI_JIS_5951			; 0x9d70 (U+633e)
	Chars C_KANJI_JIS_5952			; 0x9d71 (U+634d)
Section6410Start	label	Chars
	Chars C_KANJI_JIS_5953			; 0x9d72 (U+641c)
	Chars C_KANJI_JIS_5954			; 0x9d73 (U+634f)
	Chars C_KANJI_JIS_5955			; 0x9d74 (U+6396)
	Chars C_KANJI_JIS_5956			; 0x9d75 (U+638e)
	Chars C_KANJI_JIS_5957			; 0x9d76 (U+6380)
	Chars C_KANJI_JIS_5958			; 0x9d77 (U+63ab)
	Chars C_KANJI_JIS_5959			; 0x9d78 (U+6376)
	Chars C_KANJI_JIS_595A			; 0x9d79 (U+63a3)
	Chars C_KANJI_JIS_595B			; 0x9d7a (U+638f)
	Chars C_KANJI_JIS_595C			; 0x9d7b (U+6389)
	Chars C_KANJI_JIS_595D			; 0x9d7c (U+639f)
	Chars C_KANJI_JIS_595E			; 0x9d7d (U+63b5)
	Chars C_KANJI_JIS_595F			; 0x9d7e (U+636b)
	Chars 0					; 0x9d7f
	Chars C_KANJI_JIS_5960			; 0x9d80 (U+6369)
	Chars C_KANJI_JIS_5961			; 0x9d81 (U+63be)
	Chars C_KANJI_JIS_5962			; 0x9d82 (U+63e9)
	Chars C_KANJI_JIS_5963			; 0x9d83 (U+63c0)
	Chars C_KANJI_JIS_5964			; 0x9d84 (U+63c6)
	Chars C_KANJI_JIS_5965			; 0x9d85 (U+63e3)
	Chars C_KANJI_JIS_5966			; 0x9d86 (U+63c9)
	Chars C_KANJI_JIS_5967			; 0x9d87 (U+63d2)
	Chars C_KANJI_JIS_5968			; 0x9d88 (U+63f6)
	Chars C_KANJI_JIS_5969			; 0x9d89 (U+63c4)
	Chars C_KANJI_JIS_596A			; 0x9d8a (U+6416)
	Chars C_KANJI_JIS_596B			; 0x9d8b (U+6434)
	Chars C_KANJI_JIS_596C			; 0x9d8c (U+6406)
	Chars C_KANJI_JIS_596D			; 0x9d8d (U+6413)
	Chars C_KANJI_JIS_596E			; 0x9d8e (U+6426)
	Chars C_KANJI_JIS_596F			; 0x9d8f (U+6436)
Section6510Start	label	Chars
	Chars C_KANJI_JIS_5970			; 0x9d90 (U+651d)
	Chars C_KANJI_JIS_5971			; 0x9d91 (U+6417)
	Chars C_KANJI_JIS_5972			; 0x9d92 (U+6428)
	Chars C_KANJI_JIS_5973			; 0x9d93 (U+640f)
	Chars C_KANJI_JIS_5974			; 0x9d94 (U+6467)
	Chars C_KANJI_JIS_5975			; 0x9d95 (U+646f)
	Chars C_KANJI_JIS_5976			; 0x9d96 (U+6476)
	Chars C_KANJI_JIS_5977			; 0x9d97 (U+644e)
	Chars C_KANJI_JIS_5978			; 0x9d98 (U+652a)
	Chars C_KANJI_JIS_5979			; 0x9d99 (U+6495)
	Chars C_KANJI_JIS_597A			; 0x9d9a (U+6493)
	Chars C_KANJI_JIS_597B			; 0x9d9b (U+64a5)
	Chars C_KANJI_JIS_597C			; 0x9d9c (U+64a9)
	Chars C_KANJI_JIS_597D			; 0x9d9d (U+6488)
	Chars C_KANJI_JIS_597E			; 0x9d9e (U+64bc)
	Chars C_KANJI_JIS_5A21			; 0x9d9f (U+64da)
	Chars C_KANJI_JIS_5A22			; 0x9da0 (U+64d2)
	Chars C_KANJI_JIS_5A23			; 0x9da1 (U+64c5)
	Chars C_KANJI_JIS_5A24			; 0x9da2 (U+64c7)
	Chars C_KANJI_JIS_5A25			; 0x9da3 (U+64bb)
	Chars C_KANJI_JIS_5A26			; 0x9da4 (U+64d8)
	Chars C_KANJI_JIS_5A27			; 0x9da5 (U+64c2)
	Chars C_KANJI_JIS_5A28			; 0x9da6 (U+64f1)
	Chars C_KANJI_JIS_5A29			; 0x9da7 (U+64e7)
	Chars C_KANJI_JIS_5A2A			; 0x9da8 (U+8209)
	Chars C_KANJI_JIS_5A2B			; 0x9da9 (U+64e0)
	Chars C_KANJI_JIS_5A2C			; 0x9daa (U+64e1)
	Chars C_KANJI_JIS_5A2D			; 0x9dab (U+62ac)
	Chars C_KANJI_JIS_5A2E			; 0x9dac (U+64e3)
	Chars C_KANJI_JIS_5A2F			; 0x9dad (U+64ef)
	Chars C_KANJI_JIS_5A30			; 0x9dae (U+652c)
	Chars C_KANJI_JIS_5A31			; 0x9daf (U+64f6)
	Chars C_KANJI_JIS_5A32			; 0x9db0 (U+64f4)
	Chars C_KANJI_JIS_5A33			; 0x9db1 (U+64f2)
	Chars C_KANJI_JIS_5A34			; 0x9db2 (U+64fa)
Section6500Start	label	Chars
	Chars C_KANJI_JIS_5A35			; 0x9db3 (U+6500)
	Chars C_KANJI_JIS_5A36			; 0x9db4 (U+64fd)
	Chars C_KANJI_JIS_5A37			; 0x9db5 (U+6518)
	Chars C_KANJI_JIS_5A38			; 0x9db6 (U+651c)
	Chars C_KANJI_JIS_5A39			; 0x9db7 (U+6505)
	Chars C_KANJI_JIS_5A3A			; 0x9db8 (U+6524)
	Chars C_KANJI_JIS_5A3B			; 0x9db9 (U+6523)
	Chars C_KANJI_JIS_5A3C			; 0x9dba (U+652b)
	Chars C_KANJI_JIS_5A3D			; 0x9dbb (U+6534)
	Chars C_KANJI_JIS_5A3E			; 0x9dbc (U+6535)
	Chars C_KANJI_JIS_5A3F			; 0x9dbd (U+6537)
	Chars C_KANJI_JIS_5A40			; 0x9dbe (U+6536)
	Chars C_KANJI_JIS_5A41			; 0x9dbf (U+6538)
	Chars C_KANJI_JIS_5A42			; 0x9dc0 (U+754b)
	Chars C_KANJI_JIS_5A43			; 0x9dc1 (U+6548)
	Chars C_KANJI_JIS_5A44			; 0x9dc2 (U+6556)
	Chars C_KANJI_JIS_5A45			; 0x9dc3 (U+6555)
	Chars C_KANJI_JIS_5A46			; 0x9dc4 (U+654d)
	Chars C_KANJI_JIS_5A47			; 0x9dc5 (U+6558)
	Chars C_KANJI_JIS_5A48			; 0x9dc6 (U+655e)
	Chars C_KANJI_JIS_5A49			; 0x9dc7 (U+655d)
	Chars C_KANJI_JIS_5A4A			; 0x9dc8 (U+6572)
	Chars C_KANJI_JIS_5A4B			; 0x9dc9 (U+6578)
	Chars C_KANJI_JIS_5A4C			; 0x9dca (U+6582)
	Chars C_KANJI_JIS_5A4D			; 0x9dcb (U+6583)
	Chars C_KANJI_JIS_5A4E			; 0x9dcc (U+8b8a)
	Chars C_KANJI_JIS_5A4F			; 0x9dcd (U+659b)
	Chars C_KANJI_JIS_5A50			; 0x9dce (U+659f)
	Chars C_KANJI_JIS_5A51			; 0x9dcf (U+65ab)
	Chars C_KANJI_JIS_5A52			; 0x9dd0 (U+65b7)
	Chars C_KANJI_JIS_5A53			; 0x9dd1 (U+65c3)
	Chars C_KANJI_JIS_5A54			; 0x9dd2 (U+65c6)
	Chars C_KANJI_JIS_5A55			; 0x9dd3 (U+65c1)
	Chars C_KANJI_JIS_5A56			; 0x9dd4 (U+65c4)
	Chars C_KANJI_JIS_5A57			; 0x9dd5 (U+65cc)
	Chars C_KANJI_JIS_5A58			; 0x9dd6 (U+65d2)
	Chars C_KANJI_JIS_5A59			; 0x9dd7 (U+65db)
	Chars C_KANJI_JIS_5A5A			; 0x9dd8 (U+65d9)
	Chars C_KANJI_JIS_5A5B			; 0x9dd9 (U+65e0)
	Chars C_KANJI_JIS_5A5C			; 0x9dda (U+65e1)
	Chars C_KANJI_JIS_5A5D			; 0x9ddb (U+65f1)
	Chars C_KANJI_JIS_5A5E			; 0x9ddc (U+6772)
	Chars C_KANJI_JIS_5A5F			; 0x9ddd (U+660a)
	Chars C_KANJI_JIS_5A60			; 0x9dde (U+6603)
	Chars C_KANJI_JIS_5A61			; 0x9ddf (U+65fb)
	Chars C_KANJI_JIS_5A62			; 0x9de0 (U+6773)
	Chars C_KANJI_JIS_5A63			; 0x9de1 (U+6635)
	Chars C_KANJI_JIS_5A64			; 0x9de2 (U+6636)
	Chars C_KANJI_JIS_5A65			; 0x9de3 (U+6634)
	Chars C_KANJI_JIS_5A66			; 0x9de4 (U+661c)
	Chars C_KANJI_JIS_5A67			; 0x9de5 (U+664f)
	Chars C_KANJI_JIS_5A68			; 0x9de6 (U+6644)
	Chars C_KANJI_JIS_5A69			; 0x9de7 (U+6649)
	Chars C_KANJI_JIS_5A6A			; 0x9de8 (U+6641)
	Chars C_KANJI_JIS_5A6B			; 0x9de9 (U+665e)
	Chars C_KANJI_JIS_5A6C			; 0x9dea (U+665d)
	Chars C_KANJI_JIS_5A6D			; 0x9deb (U+6664)
	Chars C_KANJI_JIS_5A6E			; 0x9dec (U+6667)
	Chars C_KANJI_JIS_5A6F			; 0x9ded (U+6668)
	Chars C_KANJI_JIS_5A70			; 0x9dee (U+665f)
	Chars C_KANJI_JIS_5A71			; 0x9def (U+6662)
	Chars C_KANJI_JIS_5A72			; 0x9df0 (U+6670)
	Chars C_KANJI_JIS_5A73			; 0x9df1 (U+6683)
	Chars C_KANJI_JIS_5A74			; 0x9df2 (U+6688)
	Chars C_KANJI_JIS_5A75			; 0x9df3 (U+668e)
	Chars C_KANJI_JIS_5A76			; 0x9df4 (U+6689)
	Chars C_KANJI_JIS_5A77			; 0x9df5 (U+6684)
	Chars C_KANJI_JIS_5A78			; 0x9df6 (U+6698)
	Chars C_KANJI_JIS_5A79			; 0x9df7 (U+669d)
	Chars C_KANJI_JIS_5A7A			; 0x9df8 (U+66c1)
	Chars C_KANJI_JIS_5A7B			; 0x9df9 (U+66b9)
	Chars C_KANJI_JIS_5A7C			; 0x9dfa (U+66c9)
	Chars C_KANJI_JIS_5A7D			; 0x9dfb (U+66be)
	Chars C_KANJI_JIS_5A7E			; 0x9dfc (U+66bc)
	Chars 0					; 0x9dfd
	Chars 0					; 0x9dfe
	Chars 0					; 0x9dff

	Chars C_KANJI_JIS_5B21			; 0x9e40 (U+66c4)
	Chars C_KANJI_JIS_5B22			; 0x9e41 (U+66b8)
	Chars C_KANJI_JIS_5B23			; 0x9e42 (U+66d6)
	Chars C_KANJI_JIS_5B24			; 0x9e43 (U+66da)
Section66e0Start	label	Chars
	Chars C_KANJI_JIS_5B25			; 0x9e44 (U+66e0)
	Chars C_KANJI_JIS_5B26			; 0x9e45 (U+663f)
	Chars C_KANJI_JIS_5B27			; 0x9e46 (U+66e6)
	Chars C_KANJI_JIS_5B28			; 0x9e47 (U+66e9)
	Chars C_KANJI_JIS_5B29			; 0x9e48 (U+66f0)
	Chars C_KANJI_JIS_5B2A			; 0x9e49 (U+66f5)
	Chars C_KANJI_JIS_5B2B			; 0x9e4a (U+66f7)
	Chars C_KANJI_JIS_5B2C			; 0x9e4b (U+670f)
	Chars C_KANJI_JIS_5B2D			; 0x9e4c (U+6716)
	Chars C_KANJI_JIS_5B2E			; 0x9e4d (U+671e)
	Chars C_KANJI_JIS_5B2F			; 0x9e4e (U+6726)
	Chars C_KANJI_JIS_5B30			; 0x9e4f (U+6727)
	Chars C_KANJI_JIS_5B31			; 0x9e50 (U+9738)
	Chars C_KANJI_JIS_5B32			; 0x9e51 (U+672e)
	Chars C_KANJI_JIS_5B33			; 0x9e52 (U+673f)
	Chars C_KANJI_JIS_5B34			; 0x9e53 (U+6736)
	Chars C_KANJI_JIS_5B35			; 0x9e54 (U+6741)
	Chars C_KANJI_JIS_5B36			; 0x9e55 (U+6738)
	Chars C_KANJI_JIS_5B37			; 0x9e56 (U+6737)
	Chars C_KANJI_JIS_5B38			; 0x9e57 (U+6746)
	Chars C_KANJI_JIS_5B39			; 0x9e58 (U+675e)
	Chars C_KANJI_JIS_5B3A			; 0x9e59 (U+6760)
	Chars C_KANJI_JIS_5B3B			; 0x9e5a (U+6759)
	Chars C_KANJI_JIS_5B3C			; 0x9e5b (U+6763)
	Chars C_KANJI_JIS_5B3D			; 0x9e5c (U+6764)
	Chars C_KANJI_JIS_5B3E			; 0x9e5d (U+6789)
	Chars C_KANJI_JIS_5B3F			; 0x9e5e (U+6770)
	Chars C_KANJI_JIS_5B40			; 0x9e5f (U+67a9)
	Chars C_KANJI_JIS_5B41			; 0x9e60 (U+677c)
	Chars C_KANJI_JIS_5B42			; 0x9e61 (U+676a)
	Chars C_KANJI_JIS_5B43			; 0x9e62 (U+678c)
	Chars C_KANJI_JIS_5B44			; 0x9e63 (U+678b)
	Chars C_KANJI_JIS_5B45			; 0x9e64 (U+67a6)
	Chars C_KANJI_JIS_5B46			; 0x9e65 (U+67a1)
	Chars C_KANJI_JIS_5B47			; 0x9e66 (U+6785)
	Chars C_KANJI_JIS_5B48			; 0x9e67 (U+67b7)
Section67e0Start	label	Chars
	Chars C_KANJI_JIS_5B49			; 0x9e68 (U+67ef)
	Chars C_KANJI_JIS_5B4A			; 0x9e69 (U+67b4)
	Chars C_KANJI_JIS_5B4B			; 0x9e6a (U+67ec)
	Chars C_KANJI_JIS_5B4C			; 0x9e6b (U+67b3)
	Chars C_KANJI_JIS_5B4D			; 0x9e6c (U+67e9)
	Chars C_KANJI_JIS_5B4E			; 0x9e6d (U+67b8)
	Chars C_KANJI_JIS_5B4F			; 0x9e6e (U+67e4)
	Chars C_KANJI_JIS_5B50			; 0x9e6f (U+67de)
	Chars C_KANJI_JIS_5B51			; 0x9e70 (U+67dd)
	Chars C_KANJI_JIS_5B52			; 0x9e71 (U+67e2)
	Chars C_KANJI_JIS_5B53			; 0x9e72 (U+67ee)
	Chars C_KANJI_JIS_5B54			; 0x9e73 (U+67b9)
	Chars C_KANJI_JIS_5B55			; 0x9e74 (U+67ce)
	Chars C_KANJI_JIS_5B56			; 0x9e75 (U+67c6)
	Chars C_KANJI_JIS_5B57			; 0x9e76 (U+67e7)
Section6a90Start	label	Chars
	Chars C_KANJI_JIS_5B58			; 0x9e77 (U+6a9c)
	Chars C_KANJI_JIS_5B59			; 0x9e78 (U+681e)
	Chars C_KANJI_JIS_5B5A			; 0x9e79 (U+6846)
	Chars C_KANJI_JIS_5B5B			; 0x9e7a (U+6829)
	Chars C_KANJI_JIS_5B5C			; 0x9e7b (U+6840)
	Chars C_KANJI_JIS_5B5D			; 0x9e7c (U+684d)
	Chars C_KANJI_JIS_5B5E			; 0x9e7d (U+6832)
	Chars C_KANJI_JIS_5B5F			; 0x9e7e (U+684e)
	Chars 0					; 0x9e7f
	Chars C_KANJI_JIS_5B60			; 0x9e80 (U+68b3)
	Chars C_KANJI_JIS_5B61			; 0x9e81 (U+682b)
	Chars C_KANJI_JIS_5B62			; 0x9e82 (U+6859)
	Chars C_KANJI_JIS_5B63			; 0x9e83 (U+6863)
	Chars C_KANJI_JIS_5B64			; 0x9e84 (U+6877)
	Chars C_KANJI_JIS_5B65			; 0x9e85 (U+687f)
	Chars C_KANJI_JIS_5B66			; 0x9e86 (U+689f)
	Chars C_KANJI_JIS_5B67			; 0x9e87 (U+688f)
	Chars C_KANJI_JIS_5B68			; 0x9e88 (U+68ad)
	Chars C_KANJI_JIS_5B69			; 0x9e89 (U+6894)
	Chars C_KANJI_JIS_5B6A			; 0x9e8a (U+689d)
	Chars C_KANJI_JIS_5B6B			; 0x9e8b (U+689b)
	Chars C_KANJI_JIS_5B6C			; 0x9e8c (U+6883)
Section6aa0Start	label	Chars
	Chars C_KANJI_JIS_5B6D			; 0x9e8d (U+6aae)
	Chars C_KANJI_JIS_5B6E			; 0x9e8e (U+68b9)
	Chars C_KANJI_JIS_5B6F			; 0x9e8f (U+6874)
	Chars C_KANJI_JIS_5B70			; 0x9e90 (U+68b5)
	Chars C_KANJI_JIS_5B71			; 0x9e91 (U+68a0)
	Chars C_KANJI_JIS_5B72			; 0x9e92 (U+68ba)
	Chars C_KANJI_JIS_5B73			; 0x9e93 (U+690f)
	Chars C_KANJI_JIS_5B74			; 0x9e94 (U+688d)
	Chars C_KANJI_JIS_5B75			; 0x9e95 (U+687e)
	Chars C_KANJI_JIS_5B76			; 0x9e96 (U+6901)
	Chars C_KANJI_JIS_5B77			; 0x9e97 (U+68ca)
	Chars C_KANJI_JIS_5B78			; 0x9e98 (U+6908)
	Chars C_KANJI_JIS_5B79			; 0x9e99 (U+68d8)
Section6920Start	label	Chars
	Chars C_KANJI_JIS_5B7A			; 0x9e9a (U+6922)
	Chars C_KANJI_JIS_5B7B			; 0x9e9b (U+6926)
	Chars C_KANJI_JIS_5B7C			; 0x9e9c (U+68e1)
	Chars C_KANJI_JIS_5B7D			; 0x9e9d (U+690c)
	Chars C_KANJI_JIS_5B7E			; 0x9e9e (U+68cd)
	Chars C_KANJI_JIS_5C21			; 0x9e9f (U+68d4)
	Chars C_KANJI_JIS_5C22			; 0x9ea0 (U+68e7)
	Chars C_KANJI_JIS_5C23			; 0x9ea1 (U+68d5)
	Chars C_KANJI_JIS_5C24			; 0x9ea2 (U+6936)
	Chars C_KANJI_JIS_5C25			; 0x9ea3 (U+6912)
	Chars C_KANJI_JIS_5C26			; 0x9ea4 (U+6904)
	Chars C_KANJI_JIS_5C27			; 0x9ea5 (U+68d7)
	Chars C_KANJI_JIS_5C28			; 0x9ea6 (U+68e3)
	Chars C_KANJI_JIS_5C29			; 0x9ea7 (U+6925)
	Chars C_KANJI_JIS_5C2A			; 0x9ea8 (U+68f9)
	Chars C_KANJI_JIS_5C2B			; 0x9ea9 (U+68e0)
	Chars C_KANJI_JIS_5C2C			; 0x9eaa (U+68ef)
	Chars C_KANJI_JIS_5C2D			; 0x9eab (U+6928)
	Chars C_KANJI_JIS_5C2E			; 0x9eac (U+692a)
	Chars C_KANJI_JIS_5C2F			; 0x9ead (U+691a)
	Chars C_KANJI_JIS_5C30			; 0x9eae (U+6923)
	Chars C_KANJI_JIS_5C31			; 0x9eaf (U+6921)
	Chars C_KANJI_JIS_5C32			; 0x9eb0 (U+68c6)
	Chars C_KANJI_JIS_5C33			; 0x9eb1 (U+6979)
	Chars C_KANJI_JIS_5C34			; 0x9eb2 (U+6977)
	Chars C_KANJI_JIS_5C35			; 0x9eb3 (U+695c)
	Chars C_KANJI_JIS_5C36			; 0x9eb4 (U+6978)
	Chars C_KANJI_JIS_5C37			; 0x9eb5 (U+696b)
	Chars C_KANJI_JIS_5C38			; 0x9eb6 (U+6954)
	Chars C_KANJI_JIS_5C39			; 0x9eb7 (U+697e)
	Chars C_KANJI_JIS_5C3A			; 0x9eb8 (U+696e)
	Chars C_KANJI_JIS_5C3B			; 0x9eb9 (U+6939)
	Chars C_KANJI_JIS_5C3C			; 0x9eba (U+6974)
	Chars C_KANJI_JIS_5C3D			; 0x9ebb (U+693d)
	Chars C_KANJI_JIS_5C3E			; 0x9ebc (U+6959)
	Chars C_KANJI_JIS_5C3F			; 0x9ebd (U+6930)
	Chars C_KANJI_JIS_5C40			; 0x9ebe (U+6961)
	Chars C_KANJI_JIS_5C41			; 0x9ebf (U+695e)
	Chars C_KANJI_JIS_5C42			; 0x9ec0 (U+695d)
	Chars C_KANJI_JIS_5C43			; 0x9ec1 (U+6981)
	Chars C_KANJI_JIS_5C44			; 0x9ec2 (U+696a)
Section69b0Start	label	Chars
	Chars C_KANJI_JIS_5C45			; 0x9ec3 (U+69b2)
Section69a0Start	label	Chars
	Chars C_KANJI_JIS_5C46			; 0x9ec4 (U+69ae)
	Chars C_KANJI_JIS_5C47			; 0x9ec5 (U+69d0)
	Chars C_KANJI_JIS_5C48			; 0x9ec6 (U+69bf)
	Chars C_KANJI_JIS_5C49			; 0x9ec7 (U+69c1)
	Chars C_KANJI_JIS_5C4A			; 0x9ec8 (U+69d3)
	Chars C_KANJI_JIS_5C4B			; 0x9ec9 (U+69be)
	Chars C_KANJI_JIS_5C4C			; 0x9eca (U+69ce)
	Chars C_KANJI_JIS_5C4D			; 0x9ecb (U+5be8)
	Chars C_KANJI_JIS_5C4E			; 0x9ecc (U+69ca)
	Chars C_KANJI_JIS_5C4F			; 0x9ecd (U+69dd)
	Chars C_KANJI_JIS_5C50			; 0x9ece (U+69bb)
	Chars C_KANJI_JIS_5C51			; 0x9ecf (U+69c3)
	Chars C_KANJI_JIS_5C52			; 0x9ed0 (U+69a7)
	Chars C_KANJI_JIS_5C53			; 0x9ed1 (U+6a2e)
	Chars C_KANJI_JIS_5C54			; 0x9ed2 (U+6991)
	Chars C_KANJI_JIS_5C55			; 0x9ed3 (U+69a0)
	Chars C_KANJI_JIS_5C56			; 0x9ed4 (U+699c)
	Chars C_KANJI_JIS_5C57			; 0x9ed5 (U+6995)
	Chars C_KANJI_JIS_5C58			; 0x9ed6 (U+69b4)
	Chars C_KANJI_JIS_5C59			; 0x9ed7 (U+69de)
Section69e0Start	label	Chars
	Chars C_KANJI_JIS_5C5A			; 0x9ed8 (U+69e8)
	Chars C_KANJI_JIS_5C5B			; 0x9ed9 (U+6a02)
	Chars C_KANJI_JIS_5C5C			; 0x9eda (U+6a1b)
	Chars C_KANJI_JIS_5C5D			; 0x9edb (U+69ff)
	Chars C_KANJI_JIS_5C5E			; 0x9edc (U+6b0a)
	Chars C_KANJI_JIS_5C5F			; 0x9edd (U+69f9)
	Chars C_KANJI_JIS_5C60			; 0x9ede (U+69f2)
	Chars C_KANJI_JIS_5C61			; 0x9edf (U+69e7)
	Chars C_KANJI_JIS_5C62			; 0x9ee0 (U+6a05)
	Chars C_KANJI_JIS_5C63			; 0x9ee1 (U+69b1)
	Chars C_KANJI_JIS_5C64			; 0x9ee2 (U+6a1e)
	Chars C_KANJI_JIS_5C65			; 0x9ee3 (U+69ed)
	Chars C_KANJI_JIS_5C66			; 0x9ee4 (U+6a14)
	Chars C_KANJI_JIS_5C67			; 0x9ee5 (U+69eb)
	Chars C_KANJI_JIS_5C68			; 0x9ee6 (U+6a0a)
	Chars C_KANJI_JIS_5C69			; 0x9ee7 (U+6a12)
Section6ac0Start	label	Chars
	Chars C_KANJI_JIS_5C6A			; 0x9ee8 (U+6ac1)
	Chars C_KANJI_JIS_5C6B			; 0x9ee9 (U+6a23)
	Chars C_KANJI_JIS_5C6C			; 0x9eea (U+6a13)
	Chars C_KANJI_JIS_5C6D			; 0x9eeb (U+6a44)
	Chars C_KANJI_JIS_5C6E			; 0x9eec (U+6a0c)
	Chars C_KANJI_JIS_5C6F			; 0x9eed (U+6a72)
	Chars C_KANJI_JIS_5C70			; 0x9eee (U+6a36)
	Chars C_KANJI_JIS_5C71			; 0x9eef (U+6a78)
	Chars C_KANJI_JIS_5C72			; 0x9ef0 (U+6a47)
	Chars C_KANJI_JIS_5C73			; 0x9ef1 (U+6a62)
	Chars C_KANJI_JIS_5C74			; 0x9ef2 (U+6a59)
	Chars C_KANJI_JIS_5C75			; 0x9ef3 (U+6a66)
	Chars C_KANJI_JIS_5C76			; 0x9ef4 (U+6a48)
	Chars C_KANJI_JIS_5C77			; 0x9ef5 (U+6a38)
	Chars C_KANJI_JIS_5C78			; 0x9ef6 (U+6a22)
	Chars C_KANJI_JIS_5C79			; 0x9ef7 (U+6a90)
	Chars C_KANJI_JIS_5C7A			; 0x9ef8 (U+6a8d)
	Chars C_KANJI_JIS_5C7B			; 0x9ef9 (U+6aa0)
	Chars C_KANJI_JIS_5C7C			; 0x9efa (U+6a84)
	Chars C_KANJI_JIS_5C7D			; 0x9efb (U+6aa2)
	Chars C_KANJI_JIS_5C7E			; 0x9efc (U+6aa3)
	Chars 0					; 0x9efd
	Chars 0					; 0x9efe
	Chars 0					; 0x9eff

	Chars C_KANJI_JIS_5D21			; 0x9f40 (U+6a97)
Section8610Start	label	Chars
	Chars C_KANJI_JIS_5D22			; 0x9f41 (U+8617)
Section6ab0Start	label	Chars
	Chars C_KANJI_JIS_5D23			; 0x9f42 (U+6abb)
	Chars C_KANJI_JIS_5D24			; 0x9f43 (U+6ac3)
	Chars C_KANJI_JIS_5D25			; 0x9f44 (U+6ac2)
	Chars C_KANJI_JIS_5D26			; 0x9f45 (U+6ab8)
	Chars C_KANJI_JIS_5D27			; 0x9f46 (U+6ab3)
	Chars C_KANJI_JIS_5D28			; 0x9f47 (U+6aac)
	Chars C_KANJI_JIS_5D29			; 0x9f48 (U+6ade)
	Chars C_KANJI_JIS_5D2A			; 0x9f49 (U+6ad1)
	Chars C_KANJI_JIS_5D2B			; 0x9f4a (U+6adf)
	Chars C_KANJI_JIS_5D2C			; 0x9f4b (U+6aaa)
	Chars C_KANJI_JIS_5D2D			; 0x9f4c (U+6ada)
	Chars C_KANJI_JIS_5D2E			; 0x9f4d (U+6aea)
Section6af0Start	label	Chars
	Chars C_KANJI_JIS_5D2F			; 0x9f4e (U+6afb)
	Chars C_KANJI_JIS_5D30			; 0x9f4f (U+6b05)
	Chars C_KANJI_JIS_5D31			; 0x9f50 (U+8616)
	Chars C_KANJI_JIS_5D32			; 0x9f51 (U+6afa)
	Chars C_KANJI_JIS_5D33			; 0x9f52 (U+6b12)
	Chars C_KANJI_JIS_5D34			; 0x9f53 (U+6b16)
	Chars C_KANJI_JIS_5D35			; 0x9f54 (U+9b31)
	Chars C_KANJI_JIS_5D36			; 0x9f55 (U+6b1f)
	Chars C_KANJI_JIS_5D37			; 0x9f56 (U+6b38)
	Chars C_KANJI_JIS_5D38			; 0x9f57 (U+6b37)
	Chars C_KANJI_JIS_5D39			; 0x9f58 (U+76dc)
	Chars C_KANJI_JIS_5D3A			; 0x9f59 (U+6b39)
	Chars C_KANJI_JIS_5D3B			; 0x9f5a (U+98ee)
	Chars C_KANJI_JIS_5D3C			; 0x9f5b (U+6b47)
	Chars C_KANJI_JIS_5D3D			; 0x9f5c (U+6b43)
	Chars C_KANJI_JIS_5D3E			; 0x9f5d (U+6b49)
	Chars C_KANJI_JIS_5D3F			; 0x9f5e (U+6b50)
	Chars C_KANJI_JIS_5D40			; 0x9f5f (U+6b59)
	Chars C_KANJI_JIS_5D41			; 0x9f60 (U+6b54)
	Chars C_KANJI_JIS_5D42			; 0x9f61 (U+6b5b)
	Chars C_KANJI_JIS_5D43			; 0x9f62 (U+6b5f)
	Chars C_KANJI_JIS_5D44			; 0x9f63 (U+6b61)
	Chars C_KANJI_JIS_5D45			; 0x9f64 (U+6b78)
	Chars C_KANJI_JIS_5D46			; 0x9f65 (U+6b79)
	Chars C_KANJI_JIS_5D47			; 0x9f66 (U+6b7f)
	Chars C_KANJI_JIS_5D48			; 0x9f67 (U+6b80)
	Chars C_KANJI_JIS_5D49			; 0x9f68 (U+6b84)
	Chars C_KANJI_JIS_5D4A			; 0x9f69 (U+6b83)
	Chars C_KANJI_JIS_5D4B			; 0x9f6a (U+6b8d)
	Chars C_KANJI_JIS_5D4C			; 0x9f6b (U+6b98)
	Chars C_KANJI_JIS_5D4D			; 0x9f6c (U+6b95)
	Chars C_KANJI_JIS_5D4E			; 0x9f6d (U+6b9e)
Section6ba0Start	label	Chars
	Chars C_KANJI_JIS_5D4F			; 0x9f6e (U+6ba4)
	Chars C_KANJI_JIS_5D50			; 0x9f6f (U+6baa)
	Chars C_KANJI_JIS_5D51			; 0x9f70 (U+6bab)
	Chars C_KANJI_JIS_5D52			; 0x9f71 (U+6baf)
	Chars C_KANJI_JIS_5D53			; 0x9f72 (U+6bb2)
	Chars C_KANJI_JIS_5D54			; 0x9f73 (U+6bb1)
	Chars C_KANJI_JIS_5D55			; 0x9f74 (U+6bb3)
	Chars C_KANJI_JIS_5D56			; 0x9f75 (U+6bb7)
	Chars C_KANJI_JIS_5D57			; 0x9f76 (U+6bbc)
	Chars C_KANJI_JIS_5D58			; 0x9f77 (U+6bc6)
	Chars C_KANJI_JIS_5D59			; 0x9f78 (U+6bcb)
	Chars C_KANJI_JIS_5D5A			; 0x9f79 (U+6bd3)
	Chars C_KANJI_JIS_5D5B			; 0x9f7a (U+6bdf)
Section6be0Start	label	Chars
	Chars C_KANJI_JIS_5D5C			; 0x9f7b (U+6bec)
	Chars C_KANJI_JIS_5D5D			; 0x9f7c (U+6beb)
Section6bf0Start	label	Chars
	Chars C_KANJI_JIS_5D5E			; 0x9f7d (U+6bf3)
	Chars C_KANJI_JIS_5D5F			; 0x9f7e (U+6bef)
	Chars 0					; 0x9f7f
	Chars C_KANJI_JIS_5D60			; 0x9f80 (U+9ebe)
	Chars C_KANJI_JIS_5D61			; 0x9f81 (U+6c08)
	Chars C_KANJI_JIS_5D62			; 0x9f82 (U+6c13)
	Chars C_KANJI_JIS_5D63			; 0x9f83 (U+6c14)
	Chars C_KANJI_JIS_5D64			; 0x9f84 (U+6c1b)
Section6c20Start	label	Chars
	Chars C_KANJI_JIS_5D65			; 0x9f85 (U+6c24)
	Chars C_KANJI_JIS_5D66			; 0x9f86 (U+6c23)
	Chars C_KANJI_JIS_5D67			; 0x9f87 (U+6c5e)
	Chars C_KANJI_JIS_5D68			; 0x9f88 (U+6c55)
	Chars C_KANJI_JIS_5D69			; 0x9f89 (U+6c62)
	Chars C_KANJI_JIS_5D6A			; 0x9f8a (U+6c6a)
	Chars C_KANJI_JIS_5D6B			; 0x9f8b (U+6c82)
	Chars C_KANJI_JIS_5D6C			; 0x9f8c (U+6c8d)
	Chars C_KANJI_JIS_5D6D			; 0x9f8d (U+6c9a)
	Chars C_KANJI_JIS_5D6E			; 0x9f8e (U+6c81)
	Chars C_KANJI_JIS_5D6F			; 0x9f8f (U+6c9b)
	Chars C_KANJI_JIS_5D70			; 0x9f90 (U+6c7e)
	Chars C_KANJI_JIS_5D71			; 0x9f91 (U+6c68)
	Chars C_KANJI_JIS_5D72			; 0x9f92 (U+6c73)
	Chars C_KANJI_JIS_5D73			; 0x9f93 (U+6c92)
	Chars C_KANJI_JIS_5D74			; 0x9f94 (U+6c90)
	Chars C_KANJI_JIS_5D75			; 0x9f95 (U+6cc4)
	Chars C_KANJI_JIS_5D76			; 0x9f96 (U+6cf1)
	Chars C_KANJI_JIS_5D77			; 0x9f97 (U+6cd3)
	Chars C_KANJI_JIS_5D78			; 0x9f98 (U+6cbd)
	Chars C_KANJI_JIS_5D79			; 0x9f99 (U+6cd7)
	Chars C_KANJI_JIS_5D7A			; 0x9f9a (U+6cc5)
	Chars C_KANJI_JIS_5D7B			; 0x9f9b (U+6cdd)
	Chars C_KANJI_JIS_5D7C			; 0x9f9c (U+6cae)
	Chars C_KANJI_JIS_5D7D			; 0x9f9d (U+6cb1)
	Chars C_KANJI_JIS_5D7E			; 0x9f9e (U+6cbe)
	Chars C_KANJI_JIS_5E21			; 0x9f9f (U+6cba)
	Chars C_KANJI_JIS_5E22			; 0x9fa0 (U+6cdb)
	Chars C_KANJI_JIS_5E23			; 0x9fa1 (U+6cef)
	Chars C_KANJI_JIS_5E24			; 0x9fa2 (U+6cd9)
	Chars C_KANJI_JIS_5E25			; 0x9fa3 (U+6cea)
	Chars C_KANJI_JIS_5E26			; 0x9fa4 (U+6d1f)
	Chars C_KANJI_JIS_5E27			; 0x9fa5 (U+884d)
	Chars C_KANJI_JIS_5E28			; 0x9fa6 (U+6d36)
	Chars C_KANJI_JIS_5E29			; 0x9fa7 (U+6d2b)
	Chars C_KANJI_JIS_5E2A			; 0x9fa8 (U+6d3d)
	Chars C_KANJI_JIS_5E2B			; 0x9fa9 (U+6d38)
	Chars C_KANJI_JIS_5E2C			; 0x9faa (U+6d19)
	Chars C_KANJI_JIS_5E2D			; 0x9fab (U+6d35)
	Chars C_KANJI_JIS_5E2E			; 0x9fac (U+6d33)
	Chars C_KANJI_JIS_5E2F			; 0x9fad (U+6d12)
	Chars C_KANJI_JIS_5E30			; 0x9fae (U+6d0c)
	Chars C_KANJI_JIS_5E31			; 0x9faf (U+6d63)
	Chars C_KANJI_JIS_5E32			; 0x9fb0 (U+6d93)
	Chars C_KANJI_JIS_5E33			; 0x9fb1 (U+6d64)
	Chars C_KANJI_JIS_5E34			; 0x9fb2 (U+6d5a)
	Chars C_KANJI_JIS_5E35			; 0x9fb3 (U+6d79)
	Chars C_KANJI_JIS_5E36			; 0x9fb4 (U+6d59)
	Chars C_KANJI_JIS_5E37			; 0x9fb5 (U+6d8e)
	Chars C_KANJI_JIS_5E38			; 0x9fb6 (U+6d95)
	Chars C_KANJI_JIS_5E39			; 0x9fb7 (U+6fe4)
	Chars C_KANJI_JIS_5E3A			; 0x9fb8 (U+6d85)
	Chars C_KANJI_JIS_5E3B			; 0x9fb9 (U+6df9)
	Chars C_KANJI_JIS_5E3C			; 0x9fba (U+6e15)
	Chars C_KANJI_JIS_5E3D			; 0x9fbb (U+6e0a)
	Chars C_KANJI_JIS_5E3E			; 0x9fbc (U+6db5)
	Chars C_KANJI_JIS_5E3F			; 0x9fbd (U+6dc7)
	Chars C_KANJI_JIS_5E40			; 0x9fbe (U+6de6)
	Chars C_KANJI_JIS_5E41			; 0x9fbf (U+6db8)
	Chars C_KANJI_JIS_5E42			; 0x9fc0 (U+6dc6)
	Chars C_KANJI_JIS_5E43			; 0x9fc1 (U+6dec)
	Chars C_KANJI_JIS_5E44			; 0x9fc2 (U+6dde)
	Chars C_KANJI_JIS_5E45			; 0x9fc3 (U+6dcc)
	Chars C_KANJI_JIS_5E46			; 0x9fc4 (U+6de8)
	Chars C_KANJI_JIS_5E47			; 0x9fc5 (U+6dd2)
	Chars C_KANJI_JIS_5E48			; 0x9fc6 (U+6dc5)
	Chars C_KANJI_JIS_5E49			; 0x9fc7 (U+6dfa)
	Chars C_KANJI_JIS_5E4A			; 0x9fc8 (U+6dd9)
	Chars C_KANJI_JIS_5E4B			; 0x9fc9 (U+6de4)
	Chars C_KANJI_JIS_5E4C			; 0x9fca (U+6dd5)
	Chars C_KANJI_JIS_5E4D			; 0x9fcb (U+6dea)
	Chars C_KANJI_JIS_5E4E			; 0x9fcc (U+6dee)
	Chars C_KANJI_JIS_5E4F			; 0x9fcd (U+6e2d)
	Chars C_KANJI_JIS_5E50			; 0x9fce (U+6e6e)
	Chars C_KANJI_JIS_5E51			; 0x9fcf (U+6e2e)
	Chars C_KANJI_JIS_5E52			; 0x9fd0 (U+6e19)
	Chars C_KANJI_JIS_5E53			; 0x9fd1 (U+6e72)
	Chars C_KANJI_JIS_5E54			; 0x9fd2 (U+6e5f)
Section6e30Start	label	Chars
	Chars C_KANJI_JIS_5E55			; 0x9fd3 (U+6e3e)
	Chars C_KANJI_JIS_5E56			; 0x9fd4 (U+6e23)
	Chars C_KANJI_JIS_5E57			; 0x9fd5 (U+6e6b)
	Chars C_KANJI_JIS_5E58			; 0x9fd6 (U+6e2b)
	Chars C_KANJI_JIS_5E59			; 0x9fd7 (U+6e76)
	Chars C_KANJI_JIS_5E5A			; 0x9fd8 (U+6e4d)
	Chars C_KANJI_JIS_5E5B			; 0x9fd9 (U+6e1f)
	Chars C_KANJI_JIS_5E5C			; 0x9fda (U+6e43)
	Chars C_KANJI_JIS_5E5D			; 0x9fdb (U+6e3a)
	Chars C_KANJI_JIS_5E5E			; 0x9fdc (U+6e4e)
	Chars C_KANJI_JIS_5E5F			; 0x9fdd (U+6e24)
	Chars C_KANJI_JIS_5E60			; 0x9fde (U+6eff)
	Chars C_KANJI_JIS_5E61			; 0x9fdf (U+6e1d)
	Chars C_KANJI_JIS_5E62			; 0x9fe0 (U+6e38)
	Chars C_KANJI_JIS_5E63			; 0x9fe1 (U+6e82)
	Chars C_KANJI_JIS_5E64			; 0x9fe2 (U+6eaa)
	Chars C_KANJI_JIS_5E65			; 0x9fe3 (U+6e98)
	Chars C_KANJI_JIS_5E66			; 0x9fe4 (U+6ec9)
	Chars C_KANJI_JIS_5E67			; 0x9fe5 (U+6eb7)
	Chars C_KANJI_JIS_5E68			; 0x9fe6 (U+6ed3)
	Chars C_KANJI_JIS_5E69			; 0x9fe7 (U+6ebd)
	Chars C_KANJI_JIS_5E6A			; 0x9fe8 (U+6eaf)
	Chars C_KANJI_JIS_5E6B			; 0x9fe9 (U+6ec4)
	Chars C_KANJI_JIS_5E6C			; 0x9fea (U+6eb2)
	Chars C_KANJI_JIS_5E6D			; 0x9feb (U+6ed4)
	Chars C_KANJI_JIS_5E6E			; 0x9fec (U+6ed5)
	Chars C_KANJI_JIS_5E6F			; 0x9fed (U+6e8f)
	Chars C_KANJI_JIS_5E70			; 0x9fee (U+6ea5)
	Chars C_KANJI_JIS_5E71			; 0x9fef (U+6ec2)
	Chars C_KANJI_JIS_5E72			; 0x9ff0 (U+6e9f)
	Chars C_KANJI_JIS_5E73			; 0x9ff1 (U+6f41)
	Chars C_KANJI_JIS_5E74			; 0x9ff2 (U+6f11)
Section7040Start	label	Chars
	Chars C_KANJI_JIS_5E75			; 0x9ff3 (U+704c)
Section6ee0Start	label	Chars
	Chars C_KANJI_JIS_5E76			; 0x9ff4 (U+6eec)
	Chars C_KANJI_JIS_5E77			; 0x9ff5 (U+6ef8)
	Chars C_KANJI_JIS_5E78			; 0x9ff6 (U+6efe)
	Chars C_KANJI_JIS_5E79			; 0x9ff7 (U+6f3f)
	Chars C_KANJI_JIS_5E7A			; 0x9ff8 (U+6ef2)
	Chars C_KANJI_JIS_5E7B			; 0x9ff9 (U+6f31)
	Chars C_KANJI_JIS_5E7C			; 0x9ffa (U+6eef)
	Chars C_KANJI_JIS_5E7D			; 0x9ffb (U+6f32)
	Chars C_KANJI_JIS_5E7E			; 0x9ffc (U+6ecc)
	Chars 0					; 0x9ffd
	Chars 0					; 0x9ffe
	Chars 0					; 0x9fff

;
; There is a gap in the SJIS character set between 0xa000-0xe000.
; Considering it is 16K in size, it is worthwhile to skip it.
;
SJISGap		label	Chars
	Chars C_KANJI_JIS_5F21			; 0xe040 (U+6f3e)
	Chars C_KANJI_JIS_5F22			; 0xe041 (U+6f13)
	Chars C_KANJI_JIS_5F23			; 0xe042 (U+6ef7)
	Chars C_KANJI_JIS_5F24			; 0xe043 (U+6f86)
	Chars C_KANJI_JIS_5F25			; 0xe044 (U+6f7a)
	Chars C_KANJI_JIS_5F26			; 0xe045 (U+6f78)
	Chars C_KANJI_JIS_5F27			; 0xe046 (U+6f81)
	Chars C_KANJI_JIS_5F28			; 0xe047 (U+6f80)
	Chars C_KANJI_JIS_5F29			; 0xe048 (U+6f6f)
	Chars C_KANJI_JIS_5F2A			; 0xe049 (U+6f5b)
Section6ff0Start	label	Chars
	Chars C_KANJI_JIS_5F2B			; 0xe04a (U+6ff3)
	Chars C_KANJI_JIS_5F2C			; 0xe04b (U+6f6d)
	Chars C_KANJI_JIS_5F2D			; 0xe04c (U+6f82)
	Chars C_KANJI_JIS_5F2E			; 0xe04d (U+6f7c)
	Chars C_KANJI_JIS_5F2F			; 0xe04e (U+6f58)
	Chars C_KANJI_JIS_5F30			; 0xe04f (U+6f8e)
	Chars C_KANJI_JIS_5F31			; 0xe050 (U+6f91)
	Chars C_KANJI_JIS_5F32			; 0xe051 (U+6fc2)
	Chars C_KANJI_JIS_5F33			; 0xe052 (U+6f66)
	Chars C_KANJI_JIS_5F34			; 0xe053 (U+6fb3)
Section6fa0Start	label	Chars
	Chars C_KANJI_JIS_5F35			; 0xe054 (U+6fa3)
	Chars C_KANJI_JIS_5F36			; 0xe055 (U+6fa1)
	Chars C_KANJI_JIS_5F37			; 0xe056 (U+6fa4)
	Chars C_KANJI_JIS_5F38			; 0xe057 (U+6fb9)
	Chars C_KANJI_JIS_5F39			; 0xe058 (U+6fc6)
	Chars C_KANJI_JIS_5F3A			; 0xe059 (U+6faa)
Section6fd0Start	label	Chars
	Chars C_KANJI_JIS_5F3B			; 0xe05a (U+6fdf)
	Chars C_KANJI_JIS_5F3C			; 0xe05b (U+6fd5)
	Chars C_KANJI_JIS_5F3D			; 0xe05c (U+6fec)
	Chars C_KANJI_JIS_5F3E			; 0xe05d (U+6fd4)
	Chars C_KANJI_JIS_5F3F			; 0xe05e (U+6fd8)
	Chars C_KANJI_JIS_5F40			; 0xe05f (U+6ff1)
	Chars C_KANJI_JIS_5F41			; 0xe060 (U+6fee)
	Chars C_KANJI_JIS_5F42			; 0xe061 (U+6fdb)
Section7000Start	label	Chars
	Chars C_KANJI_JIS_5F43			; 0xe062 (U+7009)
	Chars C_KANJI_JIS_5F44			; 0xe063 (U+700b)
	Chars C_KANJI_JIS_5F45			; 0xe064 (U+6ffa)
	Chars C_KANJI_JIS_5F46			; 0xe065 (U+7011)
	Chars C_KANJI_JIS_5F47			; 0xe066 (U+7001)
	Chars C_KANJI_JIS_5F48			; 0xe067 (U+700f)
	Chars C_KANJI_JIS_5F49			; 0xe068 (U+6ffe)
	Chars C_KANJI_JIS_5F4A			; 0xe069 (U+701b)
	Chars C_KANJI_JIS_5F4B			; 0xe06a (U+701a)
	Chars C_KANJI_JIS_5F4C			; 0xe06b (U+6f74)
	Chars C_KANJI_JIS_5F4D			; 0xe06c (U+701d)
	Chars C_KANJI_JIS_5F4E			; 0xe06d (U+7018)
	Chars C_KANJI_JIS_5F4F			; 0xe06e (U+701f)
Section7030Start	label	Chars
	Chars C_KANJI_JIS_5F50			; 0xe06f (U+7030)
	Chars C_KANJI_JIS_5F51			; 0xe070 (U+703e)
	Chars C_KANJI_JIS_5F52			; 0xe071 (U+7032)
	Chars C_KANJI_JIS_5F53			; 0xe072 (U+7051)
	Chars C_KANJI_JIS_5F54			; 0xe073 (U+7063)
Section7090Start	label	Chars
	Chars C_KANJI_JIS_5F55			; 0xe074 (U+7099)
	Chars C_KANJI_JIS_5F56			; 0xe075 (U+7092)
	Chars C_KANJI_JIS_5F57			; 0xe076 (U+70af)
	Chars C_KANJI_JIS_5F58			; 0xe077 (U+70f1)
	Chars C_KANJI_JIS_5F59			; 0xe078 (U+70ac)
	Chars C_KANJI_JIS_5F5A			; 0xe079 (U+70b8)
	Chars C_KANJI_JIS_5F5B			; 0xe07a (U+70b3)
	Chars C_KANJI_JIS_5F5C			; 0xe07b (U+70ae)
Section70d0Start	label	Chars
	Chars C_KANJI_JIS_5F5D			; 0xe07c (U+70df)
	Chars C_KANJI_JIS_5F5E			; 0xe07d (U+70cb)
	Chars C_KANJI_JIS_5F5F			; 0xe07e (U+70dd)
	Chars 0					; 0xe07f
	Chars C_KANJI_JIS_5F60			; 0xe080 (U+70d9)
Section7100Start	label	Chars
	Chars C_KANJI_JIS_5F61			; 0xe081 (U+7109)
	Chars C_KANJI_JIS_5F62			; 0xe082 (U+70fd)
	Chars C_KANJI_JIS_5F63			; 0xe083 (U+711c)
	Chars C_KANJI_JIS_5F64			; 0xe084 (U+7119)
	Chars C_KANJI_JIS_5F65			; 0xe085 (U+7165)
	Chars C_KANJI_JIS_5F66			; 0xe086 (U+7155)
	Chars C_KANJI_JIS_5F67			; 0xe087 (U+7188)
	Chars C_KANJI_JIS_5F68			; 0xe088 (U+7166)
	Chars C_KANJI_JIS_5F69			; 0xe089 (U+7162)
	Chars C_KANJI_JIS_5F6A			; 0xe08a (U+714c)
	Chars C_KANJI_JIS_5F6B			; 0xe08b (U+7156)
	Chars C_KANJI_JIS_5F6C			; 0xe08c (U+716c)
	Chars C_KANJI_JIS_5F6D			; 0xe08d (U+718f)
Section71f0Start	label	Chars
	Chars C_KANJI_JIS_5F6E			; 0xe08e (U+71fb)
	Chars C_KANJI_JIS_5F6F			; 0xe08f (U+7184)
	Chars C_KANJI_JIS_5F70			; 0xe090 (U+7195)
Section71a0Start	label	Chars
	Chars C_KANJI_JIS_5F71			; 0xe091 (U+71a8)
	Chars C_KANJI_JIS_5F72			; 0xe092 (U+71ac)
	Chars C_KANJI_JIS_5F73			; 0xe093 (U+71d7)
	Chars C_KANJI_JIS_5F74			; 0xe094 (U+71b9)
	Chars C_KANJI_JIS_5F75			; 0xe095 (U+71be)
	Chars C_KANJI_JIS_5F76			; 0xe096 (U+71d2)
	Chars C_KANJI_JIS_5F77			; 0xe097 (U+71c9)
	Chars C_KANJI_JIS_5F78			; 0xe098 (U+71d4)
	Chars C_KANJI_JIS_5F79			; 0xe099 (U+71ce)
	Chars C_KANJI_JIS_5F7A			; 0xe09a (U+71e0)
	Chars C_KANJI_JIS_5F7B			; 0xe09b (U+71ec)
	Chars C_KANJI_JIS_5F7C			; 0xe09c (U+71e7)
	Chars C_KANJI_JIS_5F7D			; 0xe09d (U+71f5)
	Chars C_KANJI_JIS_5F7E			; 0xe09e (U+71fc)
	Chars C_KANJI_JIS_6021			; 0xe09f (U+71f9)
	Chars C_KANJI_JIS_6022			; 0xe0a0 (U+71ff)
	Chars C_KANJI_JIS_6023			; 0xe0a1 (U+720d)
Section7210Start	label	Chars
	Chars C_KANJI_JIS_6024			; 0xe0a2 (U+7210)
	Chars C_KANJI_JIS_6025			; 0xe0a3 (U+721b)
	Chars C_KANJI_JIS_6026			; 0xe0a4 (U+7228)
	Chars C_KANJI_JIS_6027			; 0xe0a5 (U+722d)
	Chars C_KANJI_JIS_6028			; 0xe0a6 (U+722c)
	Chars C_KANJI_JIS_6029			; 0xe0a7 (U+7230)
	Chars C_KANJI_JIS_602A			; 0xe0a8 (U+7232)
	Chars C_KANJI_JIS_602B			; 0xe0a9 (U+723b)
	Chars C_KANJI_JIS_602C			; 0xe0aa (U+723c)
	Chars C_KANJI_JIS_602D			; 0xe0ab (U+723f)
	Chars C_KANJI_JIS_602E			; 0xe0ac (U+7240)
	Chars C_KANJI_JIS_602F			; 0xe0ad (U+7246)
	Chars C_KANJI_JIS_6030			; 0xe0ae (U+724b)
	Chars C_KANJI_JIS_6031			; 0xe0af (U+7258)
	Chars C_KANJI_JIS_6032			; 0xe0b0 (U+7274)
	Chars C_KANJI_JIS_6033			; 0xe0b1 (U+727e)
	Chars C_KANJI_JIS_6034			; 0xe0b2 (U+7282)
	Chars C_KANJI_JIS_6035			; 0xe0b3 (U+7281)
	Chars C_KANJI_JIS_6036			; 0xe0b4 (U+7287)
Section7290Start	label	Chars
	Chars C_KANJI_JIS_6037			; 0xe0b5 (U+7292)
	Chars C_KANJI_JIS_6038			; 0xe0b6 (U+7296)
	Chars C_KANJI_JIS_6039			; 0xe0b7 (U+72a2)
	Chars C_KANJI_JIS_603A			; 0xe0b8 (U+72a7)
	Chars C_KANJI_JIS_603B			; 0xe0b9 (U+72b9)
	Chars C_KANJI_JIS_603C			; 0xe0ba (U+72b2)
	Chars C_KANJI_JIS_603D			; 0xe0bb (U+72c3)
	Chars C_KANJI_JIS_603E			; 0xe0bc (U+72c6)
	Chars C_KANJI_JIS_603F			; 0xe0bd (U+72c4)
	Chars C_KANJI_JIS_6040			; 0xe0be (U+72ce)
	Chars C_KANJI_JIS_6041			; 0xe0bf (U+72d2)
	Chars C_KANJI_JIS_6042			; 0xe0c0 (U+72e2)
	Chars C_KANJI_JIS_6043			; 0xe0c1 (U+72e0)
	Chars C_KANJI_JIS_6044			; 0xe0c2 (U+72e1)
	Chars C_KANJI_JIS_6045			; 0xe0c3 (U+72f9)
	Chars C_KANJI_JIS_6046			; 0xe0c4 (U+72f7)
	Chars C_KANJI_JIS_6047			; 0xe0c5 (U+500f)
	Chars C_KANJI_JIS_6048			; 0xe0c6 (U+7317)
Section7300Start	label	Chars
	Chars C_KANJI_JIS_6049			; 0xe0c7 (U+730a)
	Chars C_KANJI_JIS_604A			; 0xe0c8 (U+731c)
	Chars C_KANJI_JIS_604B			; 0xe0c9 (U+7316)
	Chars C_KANJI_JIS_604C			; 0xe0ca (U+731d)
	Chars C_KANJI_JIS_604D			; 0xe0cb (U+7334)
	Chars C_KANJI_JIS_604E			; 0xe0cc (U+732f)
	Chars C_KANJI_JIS_604F			; 0xe0cd (U+7329)
	Chars C_KANJI_JIS_6050			; 0xe0ce (U+7325)
	Chars C_KANJI_JIS_6051			; 0xe0cf (U+733e)
	Chars C_KANJI_JIS_6052			; 0xe0d0 (U+734e)
	Chars C_KANJI_JIS_6053			; 0xe0d1 (U+734f)
	Chars C_KANJI_JIS_6054			; 0xe0d2 (U+9ed8)
Section7350Start	label	Chars
	Chars C_KANJI_JIS_6055			; 0xe0d3 (U+7357)
	Chars C_KANJI_JIS_6056			; 0xe0d4 (U+736a)
	Chars C_KANJI_JIS_6057			; 0xe0d5 (U+7368)
	Chars C_KANJI_JIS_6058			; 0xe0d6 (U+7370)
	Chars C_KANJI_JIS_6059			; 0xe0d7 (U+7378)
	Chars C_KANJI_JIS_605A			; 0xe0d8 (U+7375)
	Chars C_KANJI_JIS_605B			; 0xe0d9 (U+737b)
	Chars C_KANJI_JIS_605C			; 0xe0da (U+737a)
	Chars C_KANJI_JIS_605D			; 0xe0db (U+73c8)
	Chars C_KANJI_JIS_605E			; 0xe0dc (U+73b3)
	Chars C_KANJI_JIS_605F			; 0xe0dd (U+73ce)
	Chars C_KANJI_JIS_6060			; 0xe0de (U+73bb)
	Chars C_KANJI_JIS_6061			; 0xe0df (U+73c0)
	Chars C_KANJI_JIS_6062			; 0xe0e0 (U+73e5)
	Chars C_KANJI_JIS_6063			; 0xe0e1 (U+73ee)
Section73d0Start	label	Chars
	Chars C_KANJI_JIS_6064			; 0xe0e2 (U+73de)
Section74a0Start	label	Chars
	Chars C_KANJI_JIS_6065			; 0xe0e3 (U+74a2)
	Chars C_KANJI_JIS_6066			; 0xe0e4 (U+7405)
	Chars C_KANJI_JIS_6067			; 0xe0e5 (U+746f)
	Chars C_KANJI_JIS_6068			; 0xe0e6 (U+7425)
	Chars C_KANJI_JIS_6069			; 0xe0e7 (U+73f8)
	Chars C_KANJI_JIS_606A			; 0xe0e8 (U+7432)
	Chars C_KANJI_JIS_606B			; 0xe0e9 (U+743a)
	Chars C_KANJI_JIS_606C			; 0xe0ea (U+7455)
	Chars C_KANJI_JIS_606D			; 0xe0eb (U+743f)
	Chars C_KANJI_JIS_606E			; 0xe0ec (U+745f)
	Chars C_KANJI_JIS_606F			; 0xe0ed (U+7459)
Section7440Start	label	Chars
	Chars C_KANJI_JIS_6070			; 0xe0ee (U+7441)
	Chars C_KANJI_JIS_6071			; 0xe0ef (U+745c)
	Chars C_KANJI_JIS_6072			; 0xe0f0 (U+7469)
	Chars C_KANJI_JIS_6073			; 0xe0f1 (U+7470)
	Chars C_KANJI_JIS_6074			; 0xe0f2 (U+7463)
	Chars C_KANJI_JIS_6075			; 0xe0f3 (U+746a)
	Chars C_KANJI_JIS_6076			; 0xe0f4 (U+7476)
	Chars C_KANJI_JIS_6077			; 0xe0f5 (U+747e)
	Chars C_KANJI_JIS_6078			; 0xe0f6 (U+748b)
Section7490Start	label	Chars
	Chars C_KANJI_JIS_6079			; 0xe0f7 (U+749e)
	Chars C_KANJI_JIS_607A			; 0xe0f8 (U+74a7)
Section74c0Start	label	Chars
	Chars C_KANJI_JIS_607B			; 0xe0f9 (U+74ca)
	Chars C_KANJI_JIS_607C			; 0xe0fa (U+74cf)
	Chars C_KANJI_JIS_607D			; 0xe0fb (U+74d4)
	Chars C_KANJI_JIS_607E			; 0xe0fc (U+73f1)
	Chars 0					; 0xe0fd
	Chars 0					; 0xe0fe
	Chars 0					; 0xe0ff

	Chars C_KANJI_JIS_6121			; 0xe140 (U+74e0)
	Chars C_KANJI_JIS_6122			; 0xe141 (U+74e3)
	Chars C_KANJI_JIS_6123			; 0xe142 (U+74e7)
	Chars C_KANJI_JIS_6124			; 0xe143 (U+74e9)
	Chars C_KANJI_JIS_6125			; 0xe144 (U+74ee)
	Chars C_KANJI_JIS_6126			; 0xe145 (U+74f2)
	Chars C_KANJI_JIS_6127			; 0xe146 (U+74f0)
	Chars C_KANJI_JIS_6128			; 0xe147 (U+74f1)
	Chars C_KANJI_JIS_6129			; 0xe148 (U+74f8)
	Chars C_KANJI_JIS_612A			; 0xe149 (U+74f7)
Section7500Start	label	Chars
	Chars C_KANJI_JIS_612B			; 0xe14a (U+7504)
	Chars C_KANJI_JIS_612C			; 0xe14b (U+7503)
	Chars C_KANJI_JIS_612D			; 0xe14c (U+7505)
	Chars C_KANJI_JIS_612E			; 0xe14d (U+750c)
	Chars C_KANJI_JIS_612F			; 0xe14e (U+750e)
	Chars C_KANJI_JIS_6130			; 0xe14f (U+750d)
	Chars C_KANJI_JIS_6131			; 0xe150 (U+7515)
	Chars C_KANJI_JIS_6132			; 0xe151 (U+7513)
	Chars C_KANJI_JIS_6133			; 0xe152 (U+751e)
	Chars C_KANJI_JIS_6134			; 0xe153 (U+7526)
	Chars C_KANJI_JIS_6135			; 0xe154 (U+752c)
	Chars C_KANJI_JIS_6136			; 0xe155 (U+753c)
	Chars C_KANJI_JIS_6137			; 0xe156 (U+7544)
	Chars C_KANJI_JIS_6138			; 0xe157 (U+754d)
	Chars C_KANJI_JIS_6139			; 0xe158 (U+754a)
	Chars C_KANJI_JIS_613A			; 0xe159 (U+7549)
	Chars C_KANJI_JIS_613B			; 0xe15a (U+755b)
	Chars C_KANJI_JIS_613C			; 0xe15b (U+7546)
	Chars C_KANJI_JIS_613D			; 0xe15c (U+755a)
	Chars C_KANJI_JIS_613E			; 0xe15d (U+7569)
	Chars C_KANJI_JIS_613F			; 0xe15e (U+7564)
	Chars C_KANJI_JIS_6140			; 0xe15f (U+7567)
	Chars C_KANJI_JIS_6141			; 0xe160 (U+756b)
	Chars C_KANJI_JIS_6142			; 0xe161 (U+756d)
	Chars C_KANJI_JIS_6143			; 0xe162 (U+7578)
	Chars C_KANJI_JIS_6144			; 0xe163 (U+7576)
	Chars C_KANJI_JIS_6145			; 0xe164 (U+7586)
	Chars C_KANJI_JIS_6146			; 0xe165 (U+7587)
	Chars C_KANJI_JIS_6147			; 0xe166 (U+7574)
	Chars C_KANJI_JIS_6148			; 0xe167 (U+758a)
	Chars C_KANJI_JIS_6149			; 0xe168 (U+7589)
	Chars C_KANJI_JIS_614A			; 0xe169 (U+7582)
	Chars C_KANJI_JIS_614B			; 0xe16a (U+7594)
	Chars C_KANJI_JIS_614C			; 0xe16b (U+759a)
	Chars C_KANJI_JIS_614D			; 0xe16c (U+759d)
	Chars C_KANJI_JIS_614E			; 0xe16d (U+75a5)
	Chars C_KANJI_JIS_614F			; 0xe16e (U+75a3)
	Chars C_KANJI_JIS_6150			; 0xe16f (U+75c2)
	Chars C_KANJI_JIS_6151			; 0xe170 (U+75b3)
	Chars C_KANJI_JIS_6152			; 0xe171 (U+75c3)
	Chars C_KANJI_JIS_6153			; 0xe172 (U+75b5)
	Chars C_KANJI_JIS_6154			; 0xe173 (U+75bd)
	Chars C_KANJI_JIS_6155			; 0xe174 (U+75b8)
	Chars C_KANJI_JIS_6156			; 0xe175 (U+75bc)
	Chars C_KANJI_JIS_6157			; 0xe176 (U+75b1)
	Chars C_KANJI_JIS_6158			; 0xe177 (U+75cd)
	Chars C_KANJI_JIS_6159			; 0xe178 (U+75ca)
	Chars C_KANJI_JIS_615A			; 0xe179 (U+75d2)
	Chars C_KANJI_JIS_615B			; 0xe17a (U+75d9)
	Chars C_KANJI_JIS_615C			; 0xe17b (U+75e3)
	Chars C_KANJI_JIS_615D			; 0xe17c (U+75de)
	Chars C_KANJI_JIS_615E			; 0xe17d (U+75fe)
	Chars C_KANJI_JIS_615F			; 0xe17e (U+75ff)
	Chars 0					; 0xe17f
	Chars C_KANJI_JIS_6160			; 0xe180 (U+75fc)
Section7600Start	label	Chars
	Chars C_KANJI_JIS_6161			; 0xe181 (U+7601)
	Chars C_KANJI_JIS_6162			; 0xe182 (U+75f0)
	Chars C_KANJI_JIS_6163			; 0xe183 (U+75fa)
	Chars C_KANJI_JIS_6164			; 0xe184 (U+75f2)
	Chars C_KANJI_JIS_6165			; 0xe185 (U+75f3)
	Chars C_KANJI_JIS_6166			; 0xe186 (U+760b)
	Chars C_KANJI_JIS_6167			; 0xe187 (U+760d)
	Chars C_KANJI_JIS_6168			; 0xe188 (U+7609)
Section7610Start	label	Chars
	Chars C_KANJI_JIS_6169			; 0xe189 (U+761f)
Section7620Start	label	Chars
	Chars C_KANJI_JIS_616A			; 0xe18a (U+7627)
	Chars C_KANJI_JIS_616B			; 0xe18b (U+7620)
	Chars C_KANJI_JIS_616C			; 0xe18c (U+7621)
	Chars C_KANJI_JIS_616D			; 0xe18d (U+7622)
	Chars C_KANJI_JIS_616E			; 0xe18e (U+7624)
Section7630Start	label	Chars
	Chars C_KANJI_JIS_616F			; 0xe18f (U+7634)
	Chars C_KANJI_JIS_6170			; 0xe190 (U+7630)
	Chars C_KANJI_JIS_6171			; 0xe191 (U+763b)
	Chars C_KANJI_JIS_6172			; 0xe192 (U+7647)
	Chars C_KANJI_JIS_6173			; 0xe193 (U+7648)
	Chars C_KANJI_JIS_6174			; 0xe194 (U+7646)
	Chars C_KANJI_JIS_6175			; 0xe195 (U+765c)
	Chars C_KANJI_JIS_6176			; 0xe196 (U+7658)
Section7660Start	label	Chars
	Chars C_KANJI_JIS_6177			; 0xe197 (U+7661)
	Chars C_KANJI_JIS_6178			; 0xe198 (U+7662)
	Chars C_KANJI_JIS_6179			; 0xe199 (U+7668)
	Chars C_KANJI_JIS_617A			; 0xe19a (U+7669)
	Chars C_KANJI_JIS_617B			; 0xe19b (U+766a)
	Chars C_KANJI_JIS_617C			; 0xe19c (U+7667)
	Chars C_KANJI_JIS_617D			; 0xe19d (U+766c)
	Chars C_KANJI_JIS_617E			; 0xe19e (U+7670)
	Chars C_KANJI_JIS_6221			; 0xe19f (U+7672)
	Chars C_KANJI_JIS_6222			; 0xe1a0 (U+7676)
	Chars C_KANJI_JIS_6223			; 0xe1a1 (U+7678)
	Chars C_KANJI_JIS_6224			; 0xe1a2 (U+767c)
	Chars C_KANJI_JIS_6225			; 0xe1a3 (U+7680)
	Chars C_KANJI_JIS_6226			; 0xe1a4 (U+7683)
	Chars C_KANJI_JIS_6227			; 0xe1a5 (U+7688)
	Chars C_KANJI_JIS_6228			; 0xe1a6 (U+768b)
	Chars C_KANJI_JIS_6229			; 0xe1a7 (U+768e)
	Chars C_KANJI_JIS_622A			; 0xe1a8 (U+7696)
	Chars C_KANJI_JIS_622B			; 0xe1a9 (U+7693)
	Chars C_KANJI_JIS_622C			; 0xe1aa (U+7699)
	Chars C_KANJI_JIS_622D			; 0xe1ab (U+769a)
	Chars C_KANJI_JIS_622E			; 0xe1ac (U+76b0)
	Chars C_KANJI_JIS_622F			; 0xe1ad (U+76b4)
	Chars C_KANJI_JIS_6230			; 0xe1ae (U+76b8)
	Chars C_KANJI_JIS_6231			; 0xe1af (U+76b9)
	Chars C_KANJI_JIS_6232			; 0xe1b0 (U+76ba)
	Chars C_KANJI_JIS_6233			; 0xe1b1 (U+76c2)
	Chars C_KANJI_JIS_6234			; 0xe1b2 (U+76cd)
	Chars C_KANJI_JIS_6235			; 0xe1b3 (U+76d6)
	Chars C_KANJI_JIS_6236			; 0xe1b4 (U+76d2)
	Chars C_KANJI_JIS_6237			; 0xe1b5 (U+76de)
	Chars C_KANJI_JIS_6238			; 0xe1b6 (U+76e1)
	Chars C_KANJI_JIS_6239			; 0xe1b7 (U+76e5)
	Chars C_KANJI_JIS_623A			; 0xe1b8 (U+76e7)
	Chars C_KANJI_JIS_623B			; 0xe1b9 (U+76ea)
	Chars C_KANJI_JIS_623C			; 0xe1ba (U+862f)
	Chars C_KANJI_JIS_623D			; 0xe1bb (U+76fb)
	Chars C_KANJI_JIS_623E			; 0xe1bc (U+7708)
	Chars C_KANJI_JIS_623F			; 0xe1bd (U+7707)
	Chars C_KANJI_JIS_6240			; 0xe1be (U+7704)
	Chars C_KANJI_JIS_6241			; 0xe1bf (U+7729)
	Chars C_KANJI_JIS_6242			; 0xe1c0 (U+7724)
	Chars C_KANJI_JIS_6243			; 0xe1c1 (U+771e)
	Chars C_KANJI_JIS_6244			; 0xe1c2 (U+7725)
	Chars C_KANJI_JIS_6245			; 0xe1c3 (U+7726)
	Chars C_KANJI_JIS_6246			; 0xe1c4 (U+771b)
	Chars C_KANJI_JIS_6247			; 0xe1c5 (U+7737)
	Chars C_KANJI_JIS_6248			; 0xe1c6 (U+7738)
	Chars C_KANJI_JIS_6249			; 0xe1c7 (U+7747)
Section7750Start	label	Chars
	Chars C_KANJI_JIS_624A			; 0xe1c8 (U+775a)
	Chars C_KANJI_JIS_624B			; 0xe1c9 (U+7768)
	Chars C_KANJI_JIS_624C			; 0xe1ca (U+776b)
	Chars C_KANJI_JIS_624D			; 0xe1cb (U+775b)
	Chars C_KANJI_JIS_624E			; 0xe1cc (U+7765)
Section7770Start	label	Chars
	Chars C_KANJI_JIS_624F			; 0xe1cd (U+777f)
	Chars C_KANJI_JIS_6250			; 0xe1ce (U+777e)
	Chars C_KANJI_JIS_6251			; 0xe1cf (U+7779)
Section7780Start	label	Chars
	Chars C_KANJI_JIS_6252			; 0xe1d0 (U+778e)
	Chars C_KANJI_JIS_6253			; 0xe1d1 (U+778b)
Section7790Start	label	Chars
	Chars C_KANJI_JIS_6254			; 0xe1d2 (U+7791)
	Chars C_KANJI_JIS_6255			; 0xe1d3 (U+77a0)
	Chars C_KANJI_JIS_6256			; 0xe1d4 (U+779e)
	Chars C_KANJI_JIS_6257			; 0xe1d5 (U+77b0)
	Chars C_KANJI_JIS_6258			; 0xe1d6 (U+77b6)
	Chars C_KANJI_JIS_6259			; 0xe1d7 (U+77b9)
	Chars C_KANJI_JIS_625A			; 0xe1d8 (U+77bf)
	Chars C_KANJI_JIS_625B			; 0xe1d9 (U+77bc)
	Chars C_KANJI_JIS_625C			; 0xe1da (U+77bd)
	Chars C_KANJI_JIS_625D			; 0xe1db (U+77bb)
Section77c0Start	label	Chars
	Chars C_KANJI_JIS_625E			; 0xe1dc (U+77c7)
	Chars C_KANJI_JIS_625F			; 0xe1dd (U+77cd)
	Chars C_KANJI_JIS_6260			; 0xe1de (U+77d7)
	Chars C_KANJI_JIS_6261			; 0xe1df (U+77da)
	Chars C_KANJI_JIS_6262			; 0xe1e0 (U+77dc)
	Chars C_KANJI_JIS_6263			; 0xe1e1 (U+77e3)
	Chars C_KANJI_JIS_6264			; 0xe1e2 (U+77ee)
	Chars C_KANJI_JIS_6265			; 0xe1e3 (U+77fc)
	Chars C_KANJI_JIS_6266			; 0xe1e4 (U+780c)
	Chars C_KANJI_JIS_6267			; 0xe1e5 (U+7812)
Section7920Start	label	Chars
	Chars C_KANJI_JIS_6268			; 0xe1e6 (U+7926)
	Chars C_KANJI_JIS_6269			; 0xe1e7 (U+7820)
	Chars C_KANJI_JIS_626A			; 0xe1e8 (U+792a)
Section7840Start	label	Chars
	Chars C_KANJI_JIS_626B			; 0xe1e9 (U+7845)
	Chars C_KANJI_JIS_626C			; 0xe1ea (U+788e)
	Chars C_KANJI_JIS_626D			; 0xe1eb (U+7874)
	Chars C_KANJI_JIS_626E			; 0xe1ec (U+7886)
	Chars C_KANJI_JIS_626F			; 0xe1ed (U+787c)
	Chars C_KANJI_JIS_6270			; 0xe1ee (U+789a)
	Chars C_KANJI_JIS_6271			; 0xe1ef (U+788c)
	Chars C_KANJI_JIS_6272			; 0xe1f0 (U+78a3)
	Chars C_KANJI_JIS_6273			; 0xe1f1 (U+78b5)
	Chars C_KANJI_JIS_6274			; 0xe1f2 (U+78aa)
	Chars C_KANJI_JIS_6275			; 0xe1f3 (U+78af)
	Chars C_KANJI_JIS_6276			; 0xe1f4 (U+78d1)
	Chars C_KANJI_JIS_6277			; 0xe1f5 (U+78c6)
	Chars C_KANJI_JIS_6278			; 0xe1f6 (U+78cb)
	Chars C_KANJI_JIS_6279			; 0xe1f7 (U+78d4)
	Chars C_KANJI_JIS_627A			; 0xe1f8 (U+78be)
	Chars C_KANJI_JIS_627B			; 0xe1f9 (U+78bc)
	Chars C_KANJI_JIS_627C			; 0xe1fa (U+78c5)
	Chars C_KANJI_JIS_627D			; 0xe1fb (U+78ca)
	Chars C_KANJI_JIS_627E			; 0xe1fc (U+78ec)
	Chars 0					; 0xe1fd
	Chars 0					; 0xe1fe
	Chars 0					; 0xe1ff

	Chars C_KANJI_JIS_6321			; 0xe240 (U+78e7)
	Chars C_KANJI_JIS_6322			; 0xe241 (U+78da)
Section78f0Start	label	Chars
	Chars C_KANJI_JIS_6323			; 0xe242 (U+78fd)
	Chars C_KANJI_JIS_6324			; 0xe243 (U+78f4)
	Chars C_KANJI_JIS_6325			; 0xe244 (U+7907)
Section7910Start	label	Chars
	Chars C_KANJI_JIS_6326			; 0xe245 (U+7912)
	Chars C_KANJI_JIS_6327			; 0xe246 (U+7911)
	Chars C_KANJI_JIS_6328			; 0xe247 (U+7919)
	Chars C_KANJI_JIS_6329			; 0xe248 (U+792c)
	Chars C_KANJI_JIS_632A			; 0xe249 (U+792b)
	Chars C_KANJI_JIS_632B			; 0xe24a (U+7940)
	Chars C_KANJI_JIS_632C			; 0xe24b (U+7960)
	Chars C_KANJI_JIS_632D			; 0xe24c (U+7957)
	Chars C_KANJI_JIS_632E			; 0xe24d (U+795f)
	Chars C_KANJI_JIS_632F			; 0xe24e (U+795a)
	Chars C_KANJI_JIS_6330			; 0xe24f (U+7955)
	Chars C_KANJI_JIS_6331			; 0xe250 (U+7953)
	Chars C_KANJI_JIS_6332			; 0xe251 (U+797a)
	Chars C_KANJI_JIS_6333			; 0xe252 (U+797f)
	Chars C_KANJI_JIS_6334			; 0xe253 (U+798a)
Section7990Start	label	Chars
	Chars C_KANJI_JIS_6335			; 0xe254 (U+799d)
	Chars C_KANJI_JIS_6336			; 0xe255 (U+79a7)
Section9f40Start	label	Chars
	Chars C_KANJI_JIS_6337			; 0xe256 (U+9f4b)
	Chars C_KANJI_JIS_6338			; 0xe257 (U+79aa)
	Chars C_KANJI_JIS_6339			; 0xe258 (U+79ae)
	Chars C_KANJI_JIS_633A			; 0xe259 (U+79b3)
	Chars C_KANJI_JIS_633B			; 0xe25a (U+79b9)
	Chars C_KANJI_JIS_633C			; 0xe25b (U+79ba)
	Chars C_KANJI_JIS_633D			; 0xe25c (U+79c9)
	Chars C_KANJI_JIS_633E			; 0xe25d (U+79d5)
	Chars C_KANJI_JIS_633F			; 0xe25e (U+79e7)
	Chars C_KANJI_JIS_6340			; 0xe25f (U+79ec)
	Chars C_KANJI_JIS_6341			; 0xe260 (U+79e1)
	Chars C_KANJI_JIS_6342			; 0xe261 (U+79e3)
	Chars C_KANJI_JIS_6343			; 0xe262 (U+7a08)
	Chars C_KANJI_JIS_6344			; 0xe263 (U+7a0d)
	Chars C_KANJI_JIS_6345			; 0xe264 (U+7a18)
	Chars C_KANJI_JIS_6346			; 0xe265 (U+7a19)
	Chars C_KANJI_JIS_6347			; 0xe266 (U+7a20)
	Chars C_KANJI_JIS_6348			; 0xe267 (U+7a1f)
	Chars C_KANJI_JIS_6349			; 0xe268 (U+7980)
	Chars C_KANJI_JIS_634A			; 0xe269 (U+7a31)
	Chars C_KANJI_JIS_634B			; 0xe26a (U+7a3b)
	Chars C_KANJI_JIS_634C			; 0xe26b (U+7a3e)
	Chars C_KANJI_JIS_634D			; 0xe26c (U+7a37)
	Chars C_KANJI_JIS_634E			; 0xe26d (U+7a43)
	Chars C_KANJI_JIS_634F			; 0xe26e (U+7a57)
	Chars C_KANJI_JIS_6350			; 0xe26f (U+7a49)
	Chars C_KANJI_JIS_6351			; 0xe270 (U+7a61)
	Chars C_KANJI_JIS_6352			; 0xe271 (U+7a62)
	Chars C_KANJI_JIS_6353			; 0xe272 (U+7a69)
Section9f90Start	label	Chars
	Chars C_KANJI_JIS_6354			; 0xe273 (U+9f9d)
	Chars C_KANJI_JIS_6355			; 0xe274 (U+7a70)
	Chars C_KANJI_JIS_6356			; 0xe275 (U+7a79)
	Chars C_KANJI_JIS_6357			; 0xe276 (U+7a7d)
	Chars C_KANJI_JIS_6358			; 0xe277 (U+7a88)
	Chars C_KANJI_JIS_6359			; 0xe278 (U+7a97)
	Chars C_KANJI_JIS_635A			; 0xe279 (U+7a95)
	Chars C_KANJI_JIS_635B			; 0xe27a (U+7a98)
	Chars C_KANJI_JIS_635C			; 0xe27b (U+7a96)
	Chars C_KANJI_JIS_635D			; 0xe27c (U+7aa9)
	Chars C_KANJI_JIS_635E			; 0xe27d (U+7ac8)
	Chars C_KANJI_JIS_635F			; 0xe27e (U+7ab0)
	Chars 0					; 0xe27f
	Chars C_KANJI_JIS_6360			; 0xe280 (U+7ab6)
	Chars C_KANJI_JIS_6361			; 0xe281 (U+7ac5)
	Chars C_KANJI_JIS_6362			; 0xe282 (U+7ac4)
	Chars C_KANJI_JIS_6363			; 0xe283 (U+7abf)
	Chars C_KANJI_JIS_6364			; 0xe284 (U+9083)
	Chars C_KANJI_JIS_6365			; 0xe285 (U+7ac7)
	Chars C_KANJI_JIS_6366			; 0xe286 (U+7aca)
	Chars C_KANJI_JIS_6367			; 0xe287 (U+7acd)
	Chars C_KANJI_JIS_6368			; 0xe288 (U+7acf)
	Chars C_KANJI_JIS_6369			; 0xe289 (U+7ad5)
	Chars C_KANJI_JIS_636A			; 0xe28a (U+7ad3)
	Chars C_KANJI_JIS_636B			; 0xe28b (U+7ad9)
	Chars C_KANJI_JIS_636C			; 0xe28c (U+7ada)
	Chars C_KANJI_JIS_636D			; 0xe28d (U+7add)
	Chars C_KANJI_JIS_636E			; 0xe28e (U+7ae1)
	Chars C_KANJI_JIS_636F			; 0xe28f (U+7ae2)
	Chars C_KANJI_JIS_6370			; 0xe290 (U+7ae6)
	Chars C_KANJI_JIS_6371			; 0xe291 (U+7aed)
	Chars C_KANJI_JIS_6372			; 0xe292 (U+7af0)
	Chars C_KANJI_JIS_6373			; 0xe293 (U+7b02)
	Chars C_KANJI_JIS_6374			; 0xe294 (U+7b0f)
	Chars C_KANJI_JIS_6375			; 0xe295 (U+7b0a)
	Chars C_KANJI_JIS_6376			; 0xe296 (U+7b06)
	Chars C_KANJI_JIS_6377			; 0xe297 (U+7b33)
	Chars C_KANJI_JIS_6378			; 0xe298 (U+7b18)
	Chars C_KANJI_JIS_6379			; 0xe299 (U+7b19)
	Chars C_KANJI_JIS_637A			; 0xe29a (U+7b1e)
	Chars C_KANJI_JIS_637B			; 0xe29b (U+7b35)
	Chars C_KANJI_JIS_637C			; 0xe29c (U+7b28)
	Chars C_KANJI_JIS_637D			; 0xe29d (U+7b36)
	Chars C_KANJI_JIS_637E			; 0xe29e (U+7b50)
Section7b70Start	label	Chars
	Chars C_KANJI_JIS_6421			; 0xe29f (U+7b7a)
	Chars C_KANJI_JIS_6422			; 0xe2a0 (U+7b04)
	Chars C_KANJI_JIS_6423			; 0xe2a1 (U+7b4d)
	Chars C_KANJI_JIS_6424			; 0xe2a2 (U+7b0b)
	Chars C_KANJI_JIS_6425			; 0xe2a3 (U+7b4c)
	Chars C_KANJI_JIS_6426			; 0xe2a4 (U+7b45)
	Chars C_KANJI_JIS_6427			; 0xe2a5 (U+7b75)
Section7b60Start	label	Chars
	Chars C_KANJI_JIS_6428			; 0xe2a6 (U+7b65)
	Chars C_KANJI_JIS_6429			; 0xe2a7 (U+7b74)
	Chars C_KANJI_JIS_642A			; 0xe2a8 (U+7b67)
	Chars C_KANJI_JIS_642B			; 0xe2a9 (U+7b70)
	Chars C_KANJI_JIS_642C			; 0xe2aa (U+7b71)
	Chars C_KANJI_JIS_642D			; 0xe2ab (U+7b6c)
	Chars C_KANJI_JIS_642E			; 0xe2ac (U+7b6e)
	Chars C_KANJI_JIS_642F			; 0xe2ad (U+7b9d)
	Chars C_KANJI_JIS_6430			; 0xe2ae (U+7b98)
	Chars C_KANJI_JIS_6431			; 0xe2af (U+7b9f)
	Chars C_KANJI_JIS_6432			; 0xe2b0 (U+7b8d)
	Chars C_KANJI_JIS_6433			; 0xe2b1 (U+7b9c)
	Chars C_KANJI_JIS_6434			; 0xe2b2 (U+7b9a)
	Chars C_KANJI_JIS_6435			; 0xe2b3 (U+7b8b)
	Chars C_KANJI_JIS_6436			; 0xe2b4 (U+7b92)
	Chars C_KANJI_JIS_6437			; 0xe2b5 (U+7b8f)
	Chars C_KANJI_JIS_6438			; 0xe2b6 (U+7b5d)
	Chars C_KANJI_JIS_6439			; 0xe2b7 (U+7b99)
	Chars C_KANJI_JIS_643A			; 0xe2b8 (U+7bcb)
	Chars C_KANJI_JIS_643B			; 0xe2b9 (U+7bc1)
	Chars C_KANJI_JIS_643C			; 0xe2ba (U+7bcc)
	Chars C_KANJI_JIS_643D			; 0xe2bb (U+7bcf)
	Chars C_KANJI_JIS_643E			; 0xe2bc (U+7bb4)
	Chars C_KANJI_JIS_643F			; 0xe2bd (U+7bc6)
Section7bd0Start	label	Chars
	Chars C_KANJI_JIS_6440			; 0xe2be (U+7bdd)
	Chars C_KANJI_JIS_6441			; 0xe2bf (U+7be9)
	Chars C_KANJI_JIS_6442			; 0xe2c0 (U+7c11)
	Chars C_KANJI_JIS_6443			; 0xe2c1 (U+7c14)
	Chars C_KANJI_JIS_6444			; 0xe2c2 (U+7be6)
	Chars C_KANJI_JIS_6445			; 0xe2c3 (U+7be5)
Section7c60Start	label	Chars
	Chars C_KANJI_JIS_6446			; 0xe2c4 (U+7c60)
Section7c00Start	label	Chars
	Chars C_KANJI_JIS_6447			; 0xe2c5 (U+7c00)
	Chars C_KANJI_JIS_6448			; 0xe2c6 (U+7c07)
	Chars C_KANJI_JIS_6449			; 0xe2c7 (U+7c13)
Section7bf0Start	label	Chars
	Chars C_KANJI_JIS_644A			; 0xe2c8 (U+7bf3)
	Chars C_KANJI_JIS_644B			; 0xe2c9 (U+7bf7)
	Chars C_KANJI_JIS_644C			; 0xe2ca (U+7c17)
	Chars C_KANJI_JIS_644D			; 0xe2cb (U+7c0d)
	Chars C_KANJI_JIS_644E			; 0xe2cc (U+7bf6)
	Chars C_KANJI_JIS_644F			; 0xe2cd (U+7c23)
	Chars C_KANJI_JIS_6450			; 0xe2ce (U+7c27)
	Chars C_KANJI_JIS_6451			; 0xe2cf (U+7c2a)
	Chars C_KANJI_JIS_6452			; 0xe2d0 (U+7c1f)
	Chars C_KANJI_JIS_6453			; 0xe2d1 (U+7c37)
	Chars C_KANJI_JIS_6454			; 0xe2d2 (U+7c2b)
	Chars C_KANJI_JIS_6455			; 0xe2d3 (U+7c3d)
	Chars C_KANJI_JIS_6456			; 0xe2d4 (U+7c4c)
	Chars C_KANJI_JIS_6457			; 0xe2d5 (U+7c43)
Section7c50Start	label	Chars
	Chars C_KANJI_JIS_6458			; 0xe2d6 (U+7c54)
	Chars C_KANJI_JIS_6459			; 0xe2d7 (U+7c4f)
	Chars C_KANJI_JIS_645A			; 0xe2d8 (U+7c40)
	Chars C_KANJI_JIS_645B			; 0xe2d9 (U+7c50)
	Chars C_KANJI_JIS_645C			; 0xe2da (U+7c58)
	Chars C_KANJI_JIS_645D			; 0xe2db (U+7c5f)
	Chars C_KANJI_JIS_645E			; 0xe2dc (U+7c64)
	Chars C_KANJI_JIS_645F			; 0xe2dd (U+7c56)
	Chars C_KANJI_JIS_6460			; 0xe2de (U+7c65)
	Chars C_KANJI_JIS_6461			; 0xe2df (U+7c6c)
	Chars C_KANJI_JIS_6462			; 0xe2e0 (U+7c75)
	Chars C_KANJI_JIS_6463			; 0xe2e1 (U+7c83)
	Chars C_KANJI_JIS_6464			; 0xe2e2 (U+7c90)
	Chars C_KANJI_JIS_6465			; 0xe2e3 (U+7ca4)
	Chars C_KANJI_JIS_6466			; 0xe2e4 (U+7cad)
	Chars C_KANJI_JIS_6467			; 0xe2e5 (U+7ca2)
	Chars C_KANJI_JIS_6468			; 0xe2e6 (U+7cab)
	Chars C_KANJI_JIS_6469			; 0xe2e7 (U+7ca1)
	Chars C_KANJI_JIS_646A			; 0xe2e8 (U+7ca8)
	Chars C_KANJI_JIS_646B			; 0xe2e9 (U+7cb3)
	Chars C_KANJI_JIS_646C			; 0xe2ea (U+7cb2)
	Chars C_KANJI_JIS_646D			; 0xe2eb (U+7cb1)
	Chars C_KANJI_JIS_646E			; 0xe2ec (U+7cae)
	Chars C_KANJI_JIS_646F			; 0xe2ed (U+7cb9)
	Chars C_KANJI_JIS_6470			; 0xe2ee (U+7cbd)
	Chars C_KANJI_JIS_6471			; 0xe2ef (U+7cc0)
	Chars C_KANJI_JIS_6472			; 0xe2f0 (U+7cc5)
	Chars C_KANJI_JIS_6473			; 0xe2f1 (U+7cc2)
	Chars C_KANJI_JIS_6474			; 0xe2f2 (U+7cd8)
	Chars C_KANJI_JIS_6475			; 0xe2f3 (U+7cd2)
	Chars C_KANJI_JIS_6476			; 0xe2f4 (U+7cdc)
	Chars C_KANJI_JIS_6477			; 0xe2f5 (U+7ce2)
	Chars C_KANJI_JIS_6478			; 0xe2f6 (U+9b3b)
	Chars C_KANJI_JIS_6479			; 0xe2f7 (U+7cef)
	Chars C_KANJI_JIS_647A			; 0xe2f8 (U+7cf2)
	Chars C_KANJI_JIS_647B			; 0xe2f9 (U+7cf4)
	Chars C_KANJI_JIS_647C			; 0xe2fa (U+7cf6)
	Chars C_KANJI_JIS_647D			; 0xe2fb (U+7cfa)
	Chars C_KANJI_JIS_647E			; 0xe2fc (U+7d06)
	Chars 0					; 0xe2fd
	Chars 0					; 0xe2fe
	Chars 0					; 0xe2ff

	Chars C_KANJI_JIS_6521			; 0xe340 (U+7d02)
	Chars C_KANJI_JIS_6522			; 0xe341 (U+7d1c)
	Chars C_KANJI_JIS_6523			; 0xe342 (U+7d15)
	Chars C_KANJI_JIS_6524			; 0xe343 (U+7d0a)
	Chars C_KANJI_JIS_6525			; 0xe344 (U+7d45)
	Chars C_KANJI_JIS_6526			; 0xe345 (U+7d4b)
	Chars C_KANJI_JIS_6527			; 0xe346 (U+7d2e)
	Chars C_KANJI_JIS_6528			; 0xe347 (U+7d32)
	Chars C_KANJI_JIS_6529			; 0xe348 (U+7d3f)
	Chars C_KANJI_JIS_652A			; 0xe349 (U+7d35)
	Chars C_KANJI_JIS_652B			; 0xe34a (U+7d46)
	Chars C_KANJI_JIS_652C			; 0xe34b (U+7d73)
	Chars C_KANJI_JIS_652D			; 0xe34c (U+7d56)
	Chars C_KANJI_JIS_652E			; 0xe34d (U+7d4e)
	Chars C_KANJI_JIS_652F			; 0xe34e (U+7d72)
	Chars C_KANJI_JIS_6530			; 0xe34f (U+7d68)
	Chars C_KANJI_JIS_6531			; 0xe350 (U+7d6e)
	Chars C_KANJI_JIS_6532			; 0xe351 (U+7d4f)
	Chars C_KANJI_JIS_6533			; 0xe352 (U+7d63)
	Chars C_KANJI_JIS_6534			; 0xe353 (U+7d93)
Section7d80Start	label	Chars
	Chars C_KANJI_JIS_6535			; 0xe354 (U+7d89)
	Chars C_KANJI_JIS_6536			; 0xe355 (U+7d5b)
	Chars C_KANJI_JIS_6537			; 0xe356 (U+7d8f)
	Chars C_KANJI_JIS_6538			; 0xe357 (U+7d7d)
	Chars C_KANJI_JIS_6539			; 0xe358 (U+7d9b)
	Chars C_KANJI_JIS_653A			; 0xe359 (U+7dba)
	Chars C_KANJI_JIS_653B			; 0xe35a (U+7dae)
	Chars C_KANJI_JIS_653C			; 0xe35b (U+7da3)
	Chars C_KANJI_JIS_653D			; 0xe35c (U+7db5)
	Chars C_KANJI_JIS_653E			; 0xe35d (U+7dc7)
	Chars C_KANJI_JIS_653F			; 0xe35e (U+7dbd)
	Chars C_KANJI_JIS_6540			; 0xe35f (U+7dab)
	Chars C_KANJI_JIS_6541			; 0xe360 (U+7e3d)
	Chars C_KANJI_JIS_6542			; 0xe361 (U+7da2)
	Chars C_KANJI_JIS_6543			; 0xe362 (U+7daf)
	Chars C_KANJI_JIS_6544			; 0xe363 (U+7ddc)
	Chars C_KANJI_JIS_6545			; 0xe364 (U+7db8)
	Chars C_KANJI_JIS_6546			; 0xe365 (U+7d9f)
	Chars C_KANJI_JIS_6547			; 0xe366 (U+7db0)
	Chars C_KANJI_JIS_6548			; 0xe367 (U+7dd8)
	Chars C_KANJI_JIS_6549			; 0xe368 (U+7ddd)
	Chars C_KANJI_JIS_654A			; 0xe369 (U+7de4)
	Chars C_KANJI_JIS_654B			; 0xe36a (U+7dde)
	Chars C_KANJI_JIS_654C			; 0xe36b (U+7dfb)
	Chars C_KANJI_JIS_654D			; 0xe36c (U+7df2)
	Chars C_KANJI_JIS_654E			; 0xe36d (U+7de1)
	Chars C_KANJI_JIS_654F			; 0xe36e (U+7e05)
	Chars C_KANJI_JIS_6550			; 0xe36f (U+7e0a)
	Chars C_KANJI_JIS_6551			; 0xe370 (U+7e23)
	Chars C_KANJI_JIS_6552			; 0xe371 (U+7e21)
	Chars C_KANJI_JIS_6553			; 0xe372 (U+7e12)
	Chars C_KANJI_JIS_6554			; 0xe373 (U+7e31)
	Chars C_KANJI_JIS_6555			; 0xe374 (U+7e1f)
	Chars C_KANJI_JIS_6556			; 0xe375 (U+7e09)
	Chars C_KANJI_JIS_6557			; 0xe376 (U+7e0b)
	Chars C_KANJI_JIS_6558			; 0xe377 (U+7e22)
	Chars C_KANJI_JIS_6559			; 0xe378 (U+7e46)
	Chars C_KANJI_JIS_655A			; 0xe379 (U+7e66)
	Chars C_KANJI_JIS_655B			; 0xe37a (U+7e3b)
	Chars C_KANJI_JIS_655C			; 0xe37b (U+7e35)
	Chars C_KANJI_JIS_655D			; 0xe37c (U+7e39)
	Chars C_KANJI_JIS_655E			; 0xe37d (U+7e43)
	Chars C_KANJI_JIS_655F			; 0xe37e (U+7e37)
	Chars 0					; 0xe37f
	Chars C_KANJI_JIS_6560			; 0xe380 (U+7e32)
	Chars C_KANJI_JIS_6561			; 0xe381 (U+7e3a)
	Chars C_KANJI_JIS_6562			; 0xe382 (U+7e67)
	Chars C_KANJI_JIS_6563			; 0xe383 (U+7e5d)
	Chars C_KANJI_JIS_6564			; 0xe384 (U+7e56)
	Chars C_KANJI_JIS_6565			; 0xe385 (U+7e5e)
	Chars C_KANJI_JIS_6566			; 0xe386 (U+7e59)
	Chars C_KANJI_JIS_6567			; 0xe387 (U+7e5a)
	Chars C_KANJI_JIS_6568			; 0xe388 (U+7e79)
	Chars C_KANJI_JIS_6569			; 0xe389 (U+7e6a)
	Chars C_KANJI_JIS_656A			; 0xe38a (U+7e69)
	Chars C_KANJI_JIS_656B			; 0xe38b (U+7e7c)
	Chars C_KANJI_JIS_656C			; 0xe38c (U+7e7b)
	Chars C_KANJI_JIS_656D			; 0xe38d (U+7e83)
	Chars C_KANJI_JIS_656E			; 0xe38e (U+7dd5)
	Chars C_KANJI_JIS_656F			; 0xe38f (U+7e7d)
	Chars C_KANJI_JIS_6570			; 0xe390 (U+8fae)
	Chars C_KANJI_JIS_6571			; 0xe391 (U+7e7f)
	Chars C_KANJI_JIS_6572			; 0xe392 (U+7e88)
	Chars C_KANJI_JIS_6573			; 0xe393 (U+7e89)
	Chars C_KANJI_JIS_6574			; 0xe394 (U+7e8c)
Section7e90Start	label	Chars
	Chars C_KANJI_JIS_6575			; 0xe395 (U+7e92)
	Chars C_KANJI_JIS_6576			; 0xe396 (U+7e90)
	Chars C_KANJI_JIS_6577			; 0xe397 (U+7e93)
	Chars C_KANJI_JIS_6578			; 0xe398 (U+7e94)
	Chars C_KANJI_JIS_6579			; 0xe399 (U+7e96)
	Chars C_KANJI_JIS_657A			; 0xe39a (U+7e8e)
	Chars C_KANJI_JIS_657B			; 0xe39b (U+7e9b)
	Chars C_KANJI_JIS_657C			; 0xe39c (U+7e9c)
	Chars C_KANJI_JIS_657D			; 0xe39d (U+7f38)
	Chars C_KANJI_JIS_657E			; 0xe39e (U+7f3a)
Section7f40Start	label	Chars
	Chars C_KANJI_JIS_6621			; 0xe39f (U+7f45)
	Chars C_KANJI_JIS_6622			; 0xe3a0 (U+7f4c)
	Chars C_KANJI_JIS_6623			; 0xe3a1 (U+7f4d)
	Chars C_KANJI_JIS_6624			; 0xe3a2 (U+7f4e)
Section7f50Start	label	Chars
	Chars C_KANJI_JIS_6625			; 0xe3a3 (U+7f50)
	Chars C_KANJI_JIS_6626			; 0xe3a4 (U+7f51)
	Chars C_KANJI_JIS_6627			; 0xe3a5 (U+7f55)
	Chars C_KANJI_JIS_6628			; 0xe3a6 (U+7f54)
	Chars C_KANJI_JIS_6629			; 0xe3a7 (U+7f58)
	Chars C_KANJI_JIS_662A			; 0xe3a8 (U+7f5f)
	Chars C_KANJI_JIS_662B			; 0xe3a9 (U+7f60)
	Chars C_KANJI_JIS_662C			; 0xe3aa (U+7f68)
	Chars C_KANJI_JIS_662D			; 0xe3ab (U+7f69)
	Chars C_KANJI_JIS_662E			; 0xe3ac (U+7f67)
	Chars C_KANJI_JIS_662F			; 0xe3ad (U+7f78)
	Chars C_KANJI_JIS_6630			; 0xe3ae (U+7f82)
	Chars C_KANJI_JIS_6631			; 0xe3af (U+7f86)
	Chars C_KANJI_JIS_6632			; 0xe3b0 (U+7f83)
	Chars C_KANJI_JIS_6633			; 0xe3b1 (U+7f88)
	Chars C_KANJI_JIS_6634			; 0xe3b2 (U+7f87)
	Chars C_KANJI_JIS_6635			; 0xe3b3 (U+7f8c)
Section7f90Start	label	Chars
	Chars C_KANJI_JIS_6636			; 0xe3b4 (U+7f94)
	Chars C_KANJI_JIS_6637			; 0xe3b5 (U+7f9e)
	Chars C_KANJI_JIS_6638			; 0xe3b6 (U+7f9d)
	Chars C_KANJI_JIS_6639			; 0xe3b7 (U+7f9a)
	Chars C_KANJI_JIS_663A			; 0xe3b8 (U+7fa3)
	Chars C_KANJI_JIS_663B			; 0xe3b9 (U+7faf)
	Chars C_KANJI_JIS_663C			; 0xe3ba (U+7fb2)
	Chars C_KANJI_JIS_663D			; 0xe3bb (U+7fb9)
	Chars C_KANJI_JIS_663E			; 0xe3bc (U+7fae)
	Chars C_KANJI_JIS_663F			; 0xe3bd (U+7fb6)
	Chars C_KANJI_JIS_6640			; 0xe3be (U+7fb8)
	Chars C_KANJI_JIS_6641			; 0xe3bf (U+8b71)
	Chars C_KANJI_JIS_6642			; 0xe3c0 (U+7fc5)
	Chars C_KANJI_JIS_6643			; 0xe3c1 (U+7fc6)
	Chars C_KANJI_JIS_6644			; 0xe3c2 (U+7fca)
	Chars C_KANJI_JIS_6645			; 0xe3c3 (U+7fd5)
	Chars C_KANJI_JIS_6646			; 0xe3c4 (U+7fd4)
	Chars C_KANJI_JIS_6647			; 0xe3c5 (U+7fe1)
	Chars C_KANJI_JIS_6648			; 0xe3c6 (U+7fe6)
	Chars C_KANJI_JIS_6649			; 0xe3c7 (U+7fe9)
	Chars C_KANJI_JIS_664A			; 0xe3c8 (U+7ff3)
	Chars C_KANJI_JIS_664B			; 0xe3c9 (U+7ff9)
	Chars C_KANJI_JIS_664C			; 0xe3ca (U+98dc)
	Chars C_KANJI_JIS_664D			; 0xe3cb (U+8006)
	Chars C_KANJI_JIS_664E			; 0xe3cc (U+8004)
	Chars C_KANJI_JIS_664F			; 0xe3cd (U+800b)
	Chars C_KANJI_JIS_6650			; 0xe3ce (U+8012)
	Chars C_KANJI_JIS_6651			; 0xe3cf (U+8018)
	Chars C_KANJI_JIS_6652			; 0xe3d0 (U+8019)
	Chars C_KANJI_JIS_6653			; 0xe3d1 (U+801c)
Section8020Start	label	Chars
	Chars C_KANJI_JIS_6654			; 0xe3d2 (U+8021)
	Chars C_KANJI_JIS_6655			; 0xe3d3 (U+8028)
	Chars C_KANJI_JIS_6656			; 0xe3d4 (U+803f)
	Chars C_KANJI_JIS_6657			; 0xe3d5 (U+803b)
Section8040Start	label	Chars
	Chars C_KANJI_JIS_6658			; 0xe3d6 (U+804a)
	Chars C_KANJI_JIS_6659			; 0xe3d7 (U+8046)
	Chars C_KANJI_JIS_665A			; 0xe3d8 (U+8052)
	Chars C_KANJI_JIS_665B			; 0xe3d9 (U+8058)
	Chars C_KANJI_JIS_665C			; 0xe3da (U+805a)
	Chars C_KANJI_JIS_665D			; 0xe3db (U+805f)
	Chars C_KANJI_JIS_665E			; 0xe3dc (U+8062)
	Chars C_KANJI_JIS_665F			; 0xe3dd (U+8068)
	Chars C_KANJI_JIS_6660			; 0xe3de (U+8073)
	Chars C_KANJI_JIS_6661			; 0xe3df (U+8072)
	Chars C_KANJI_JIS_6662			; 0xe3e0 (U+8070)
	Chars C_KANJI_JIS_6663			; 0xe3e1 (U+8076)
	Chars C_KANJI_JIS_6664			; 0xe3e2 (U+8079)
	Chars C_KANJI_JIS_6665			; 0xe3e3 (U+807d)
	Chars C_KANJI_JIS_6666			; 0xe3e4 (U+807f)
	Chars C_KANJI_JIS_6667			; 0xe3e5 (U+8084)
	Chars C_KANJI_JIS_6668			; 0xe3e6 (U+8086)
	Chars C_KANJI_JIS_6669			; 0xe3e7 (U+8085)
	Chars C_KANJI_JIS_666A			; 0xe3e8 (U+809b)
	Chars C_KANJI_JIS_666B			; 0xe3e9 (U+8093)
	Chars C_KANJI_JIS_666C			; 0xe3ea (U+809a)
	Chars C_KANJI_JIS_666D			; 0xe3eb (U+80ad)
	Chars C_KANJI_JIS_666E			; 0xe3ec (U+5190)
	Chars C_KANJI_JIS_666F			; 0xe3ed (U+80ac)
	Chars C_KANJI_JIS_6670			; 0xe3ee (U+80db)
	Chars C_KANJI_JIS_6671			; 0xe3ef (U+80e5)
	Chars C_KANJI_JIS_6672			; 0xe3f0 (U+80d9)
	Chars C_KANJI_JIS_6673			; 0xe3f1 (U+80dd)
	Chars C_KANJI_JIS_6674			; 0xe3f2 (U+80c4)
	Chars C_KANJI_JIS_6675			; 0xe3f3 (U+80da)
	Chars C_KANJI_JIS_6676			; 0xe3f4 (U+80d6)
	Chars C_KANJI_JIS_6677			; 0xe3f5 (U+8109)
	Chars C_KANJI_JIS_6678			; 0xe3f6 (U+80ef)
	Chars C_KANJI_JIS_6679			; 0xe3f7 (U+80f1)
	Chars C_KANJI_JIS_667A			; 0xe3f8 (U+811b)
Section8120Start	label	Chars
	Chars C_KANJI_JIS_667B			; 0xe3f9 (U+8129)
	Chars C_KANJI_JIS_667C			; 0xe3fa (U+8123)
	Chars C_KANJI_JIS_667D			; 0xe3fb (U+812f)
	Chars C_KANJI_JIS_667E			; 0xe3fc (U+814b)
	Chars 0					; 0xe3fd
	Chars 0					; 0xe3fe
	Chars 0					; 0xe3ff

	Chars C_KANJI_JIS_6721			; 0xe440 (U+968b)
	Chars C_KANJI_JIS_6722			; 0xe441 (U+8146)
	Chars C_KANJI_JIS_6723			; 0xe442 (U+813e)
	Chars C_KANJI_JIS_6724			; 0xe443 (U+8153)
	Chars C_KANJI_JIS_6725			; 0xe444 (U+8151)
	Chars C_KANJI_JIS_6726			; 0xe445 (U+80fc)
	Chars C_KANJI_JIS_6727			; 0xe446 (U+8171)
	Chars C_KANJI_JIS_6728			; 0xe447 (U+816e)
	Chars C_KANJI_JIS_6729			; 0xe448 (U+8165)
	Chars C_KANJI_JIS_672A			; 0xe449 (U+8166)
	Chars C_KANJI_JIS_672B			; 0xe44a (U+8174)
	Chars C_KANJI_JIS_672C			; 0xe44b (U+8183)
	Chars C_KANJI_JIS_672D			; 0xe44c (U+8188)
	Chars C_KANJI_JIS_672E			; 0xe44d (U+818a)
	Chars C_KANJI_JIS_672F			; 0xe44e (U+8180)
	Chars C_KANJI_JIS_6730			; 0xe44f (U+8182)
	Chars C_KANJI_JIS_6731			; 0xe450 (U+81a0)
	Chars C_KANJI_JIS_6732			; 0xe451 (U+8195)
	Chars C_KANJI_JIS_6733			; 0xe452 (U+81a4)
	Chars C_KANJI_JIS_6734			; 0xe453 (U+81a3)
	Chars C_KANJI_JIS_6735			; 0xe454 (U+815f)
	Chars C_KANJI_JIS_6736			; 0xe455 (U+8193)
	Chars C_KANJI_JIS_6737			; 0xe456 (U+81a9)
	Chars C_KANJI_JIS_6738			; 0xe457 (U+81b0)
	Chars C_KANJI_JIS_6739			; 0xe458 (U+81b5)
	Chars C_KANJI_JIS_673A			; 0xe459 (U+81be)
	Chars C_KANJI_JIS_673B			; 0xe45a (U+81b8)
	Chars C_KANJI_JIS_673C			; 0xe45b (U+81bd)
	Chars C_KANJI_JIS_673D			; 0xe45c (U+81c0)
	Chars C_KANJI_JIS_673E			; 0xe45d (U+81c2)
	Chars C_KANJI_JIS_673F			; 0xe45e (U+81ba)
	Chars C_KANJI_JIS_6740			; 0xe45f (U+81c9)
	Chars C_KANJI_JIS_6741			; 0xe460 (U+81cd)
	Chars C_KANJI_JIS_6742			; 0xe461 (U+81d1)
	Chars C_KANJI_JIS_6743			; 0xe462 (U+81d9)
	Chars C_KANJI_JIS_6744			; 0xe463 (U+81d8)
	Chars C_KANJI_JIS_6745			; 0xe464 (U+81c8)
	Chars C_KANJI_JIS_6746			; 0xe465 (U+81da)
	Chars C_KANJI_JIS_6747			; 0xe466 (U+81df)
	Chars C_KANJI_JIS_6748			; 0xe467 (U+81e0)
	Chars C_KANJI_JIS_6749			; 0xe468 (U+81e7)
	Chars C_KANJI_JIS_674A			; 0xe469 (U+81fa)
	Chars C_KANJI_JIS_674B			; 0xe46a (U+81fb)
	Chars C_KANJI_JIS_674C			; 0xe46b (U+81fe)
	Chars C_KANJI_JIS_674D			; 0xe46c (U+8201)
	Chars C_KANJI_JIS_674E			; 0xe46d (U+8202)
	Chars C_KANJI_JIS_674F			; 0xe46e (U+8205)
	Chars C_KANJI_JIS_6750			; 0xe46f (U+8207)
	Chars C_KANJI_JIS_6751			; 0xe470 (U+820a)
	Chars C_KANJI_JIS_6752			; 0xe471 (U+820d)
	Chars C_KANJI_JIS_6753			; 0xe472 (U+8210)
	Chars C_KANJI_JIS_6754			; 0xe473 (U+8216)
	Chars C_KANJI_JIS_6755			; 0xe474 (U+8229)
	Chars C_KANJI_JIS_6756			; 0xe475 (U+822b)
	Chars C_KANJI_JIS_6757			; 0xe476 (U+8238)
	Chars C_KANJI_JIS_6758			; 0xe477 (U+8233)
	Chars C_KANJI_JIS_6759			; 0xe478 (U+8240)
Section8250Start	label	Chars
	Chars C_KANJI_JIS_675A			; 0xe479 (U+8259)
	Chars C_KANJI_JIS_675B			; 0xe47a (U+8258)
	Chars C_KANJI_JIS_675C			; 0xe47b (U+825d)
	Chars C_KANJI_JIS_675D			; 0xe47c (U+825a)
	Chars C_KANJI_JIS_675E			; 0xe47d (U+825f)
	Chars C_KANJI_JIS_675F			; 0xe47e (U+8264)
	Chars 0					; 0xe47f
	Chars C_KANJI_JIS_6760			; 0xe480 (U+8262)
	Chars C_KANJI_JIS_6761			; 0xe481 (U+8268)
	Chars C_KANJI_JIS_6762			; 0xe482 (U+826a)
	Chars C_KANJI_JIS_6763			; 0xe483 (U+826b)
	Chars C_KANJI_JIS_6764			; 0xe484 (U+822e)
	Chars C_KANJI_JIS_6765			; 0xe485 (U+8271)
	Chars C_KANJI_JIS_6766			; 0xe486 (U+8277)
	Chars C_KANJI_JIS_6767			; 0xe487 (U+8278)
	Chars C_KANJI_JIS_6768			; 0xe488 (U+827e)
	Chars C_KANJI_JIS_6769			; 0xe489 (U+828d)
	Chars C_KANJI_JIS_676A			; 0xe48a (U+8292)
	Chars C_KANJI_JIS_676B			; 0xe48b (U+82ab)
	Chars C_KANJI_JIS_676C			; 0xe48c (U+829f)
	Chars C_KANJI_JIS_676D			; 0xe48d (U+82bb)
	Chars C_KANJI_JIS_676E			; 0xe48e (U+82ac)
	Chars C_KANJI_JIS_676F			; 0xe48f (U+82e1)
	Chars C_KANJI_JIS_6770			; 0xe490 (U+82e3)
	Chars C_KANJI_JIS_6771			; 0xe491 (U+82df)
	Chars C_KANJI_JIS_6772			; 0xe492 (U+82d2)
	Chars C_KANJI_JIS_6773			; 0xe493 (U+82f4)
	Chars C_KANJI_JIS_6774			; 0xe494 (U+82f3)
	Chars C_KANJI_JIS_6775			; 0xe495 (U+82fa)
	Chars C_KANJI_JIS_6776			; 0xe496 (U+8393)
	Chars C_KANJI_JIS_6777			; 0xe497 (U+8303)
	Chars C_KANJI_JIS_6778			; 0xe498 (U+82fb)
	Chars C_KANJI_JIS_6779			; 0xe499 (U+82f9)
	Chars C_KANJI_JIS_677A			; 0xe49a (U+82de)
	Chars C_KANJI_JIS_677B			; 0xe49b (U+8306)
	Chars C_KANJI_JIS_677C			; 0xe49c (U+82dc)
	Chars C_KANJI_JIS_677D			; 0xe49d (U+8309)
	Chars C_KANJI_JIS_677E			; 0xe49e (U+82d9)
	Chars C_KANJI_JIS_6821			; 0xe49f (U+8335)
	Chars C_KANJI_JIS_6822			; 0xe4a0 (U+8334)
	Chars C_KANJI_JIS_6823			; 0xe4a1 (U+8316)
	Chars C_KANJI_JIS_6824			; 0xe4a2 (U+8332)
	Chars C_KANJI_JIS_6825			; 0xe4a3 (U+8331)
	Chars C_KANJI_JIS_6826			; 0xe4a4 (U+8340)
	Chars C_KANJI_JIS_6827			; 0xe4a5 (U+8339)
	Chars C_KANJI_JIS_6828			; 0xe4a6 (U+8350)
	Chars C_KANJI_JIS_6829			; 0xe4a7 (U+8345)
	Chars C_KANJI_JIS_682A			; 0xe4a8 (U+832f)
	Chars C_KANJI_JIS_682B			; 0xe4a9 (U+832b)
	Chars C_KANJI_JIS_682C			; 0xe4aa (U+8317)
	Chars C_KANJI_JIS_682D			; 0xe4ab (U+8318)
Section8380Start	label	Chars
	Chars C_KANJI_JIS_682E			; 0xe4ac (U+8385)
	Chars C_KANJI_JIS_682F			; 0xe4ad (U+839a)
	Chars C_KANJI_JIS_6830			; 0xe4ae (U+83aa)
	Chars C_KANJI_JIS_6831			; 0xe4af (U+839f)
	Chars C_KANJI_JIS_6832			; 0xe4b0 (U+83a2)
	Chars C_KANJI_JIS_6833			; 0xe4b1 (U+8396)
	Chars C_KANJI_JIS_6834			; 0xe4b2 (U+8323)
	Chars C_KANJI_JIS_6835			; 0xe4b3 (U+838e)
	Chars C_KANJI_JIS_6836			; 0xe4b4 (U+8387)
	Chars C_KANJI_JIS_6837			; 0xe4b5 (U+838a)
	Chars C_KANJI_JIS_6838			; 0xe4b6 (U+837c)
	Chars C_KANJI_JIS_6839			; 0xe4b7 (U+83b5)
	Chars C_KANJI_JIS_683A			; 0xe4b8 (U+8373)
	Chars C_KANJI_JIS_683B			; 0xe4b9 (U+8375)
	Chars C_KANJI_JIS_683C			; 0xe4ba (U+83a0)
	Chars C_KANJI_JIS_683D			; 0xe4bb (U+8389)
	Chars C_KANJI_JIS_683E			; 0xe4bc (U+83a8)
	Chars C_KANJI_JIS_683F			; 0xe4bd (U+83f4)
Section8410Start	label	Chars
	Chars C_KANJI_JIS_6840			; 0xe4be (U+8413)
	Chars C_KANJI_JIS_6841			; 0xe4bf (U+83eb)
	Chars C_KANJI_JIS_6842			; 0xe4c0 (U+83ce)
	Chars C_KANJI_JIS_6843			; 0xe4c1 (U+83fd)
	Chars C_KANJI_JIS_6844			; 0xe4c2 (U+8403)
	Chars C_KANJI_JIS_6845			; 0xe4c3 (U+83d8)
	Chars C_KANJI_JIS_6846			; 0xe4c4 (U+840b)
	Chars C_KANJI_JIS_6847			; 0xe4c5 (U+83c1)
	Chars C_KANJI_JIS_6848			; 0xe4c6 (U+83f7)
	Chars C_KANJI_JIS_6849			; 0xe4c7 (U+8407)
	Chars C_KANJI_JIS_684A			; 0xe4c8 (U+83e0)
	Chars C_KANJI_JIS_684B			; 0xe4c9 (U+83f2)
	Chars C_KANJI_JIS_684C			; 0xe4ca (U+840d)
	Chars C_KANJI_JIS_684D			; 0xe4cb (U+8422)
	Chars C_KANJI_JIS_684E			; 0xe4cc (U+8420)
	Chars C_KANJI_JIS_684F			; 0xe4cd (U+83bd)
	Chars C_KANJI_JIS_6850			; 0xe4ce (U+8438)
	Chars C_KANJI_JIS_6851			; 0xe4cf (U+8506)
	Chars C_KANJI_JIS_6852			; 0xe4d0 (U+83fb)
	Chars C_KANJI_JIS_6853			; 0xe4d1 (U+846d)
	Chars C_KANJI_JIS_6854			; 0xe4d2 (U+842a)
	Chars C_KANJI_JIS_6855			; 0xe4d3 (U+843c)
	Chars C_KANJI_JIS_6856			; 0xe4d4 (U+855a)
	Chars C_KANJI_JIS_6857			; 0xe4d5 (U+8484)
	Chars C_KANJI_JIS_6858			; 0xe4d6 (U+8477)
	Chars C_KANJI_JIS_6859			; 0xe4d7 (U+846b)
Section84a0Start	label	Chars
	Chars C_KANJI_JIS_685A			; 0xe4d8 (U+84ad)
	Chars C_KANJI_JIS_685B			; 0xe4d9 (U+846e)
	Chars C_KANJI_JIS_685C			; 0xe4da (U+8482)
	Chars C_KANJI_JIS_685D			; 0xe4db (U+8469)
	Chars C_KANJI_JIS_685E			; 0xe4dc (U+8446)
	Chars C_KANJI_JIS_685F			; 0xe4dd (U+842c)
	Chars C_KANJI_JIS_6860			; 0xe4de (U+846f)
	Chars C_KANJI_JIS_6861			; 0xe4df (U+8479)
	Chars C_KANJI_JIS_6862			; 0xe4e0 (U+8435)
	Chars C_KANJI_JIS_6863			; 0xe4e1 (U+84ca)
	Chars C_KANJI_JIS_6864			; 0xe4e2 (U+8462)
	Chars C_KANJI_JIS_6865			; 0xe4e3 (U+84b9)
	Chars C_KANJI_JIS_6866			; 0xe4e4 (U+84bf)
	Chars C_KANJI_JIS_6867			; 0xe4e5 (U+849f)
	Chars C_KANJI_JIS_6868			; 0xe4e6 (U+84d9)
	Chars C_KANJI_JIS_6869			; 0xe4e7 (U+84cd)
	Chars C_KANJI_JIS_686A			; 0xe4e8 (U+84bb)
	Chars C_KANJI_JIS_686B			; 0xe4e9 (U+84da)
	Chars C_KANJI_JIS_686C			; 0xe4ea (U+84d0)
	Chars C_KANJI_JIS_686D			; 0xe4eb (U+84c1)
	Chars C_KANJI_JIS_686E			; 0xe4ec (U+84c6)
	Chars C_KANJI_JIS_686F			; 0xe4ed (U+84d6)
	Chars C_KANJI_JIS_6870			; 0xe4ee (U+84a1)
	Chars C_KANJI_JIS_6871			; 0xe4ef (U+8521)
Section84f0Start	label	Chars
	Chars C_KANJI_JIS_6872			; 0xe4f0 (U+84ff)
	Chars C_KANJI_JIS_6873			; 0xe4f1 (U+84f4)
	Chars C_KANJI_JIS_6874			; 0xe4f2 (U+8517)
	Chars C_KANJI_JIS_6875			; 0xe4f3 (U+8518)
	Chars C_KANJI_JIS_6876			; 0xe4f4 (U+852c)
	Chars C_KANJI_JIS_6877			; 0xe4f5 (U+851f)
	Chars C_KANJI_JIS_6878			; 0xe4f6 (U+8515)
	Chars C_KANJI_JIS_6879			; 0xe4f7 (U+8514)
	Chars C_KANJI_JIS_687A			; 0xe4f8 (U+84fc)
	Chars C_KANJI_JIS_687B			; 0xe4f9 (U+8540)
	Chars C_KANJI_JIS_687C			; 0xe4fa (U+8563)
	Chars C_KANJI_JIS_687D			; 0xe4fb (U+8558)
	Chars C_KANJI_JIS_687E			; 0xe4fc (U+8548)
	Chars 0					; 0xe4fd
	Chars 0					; 0xe4fe
	Chars 0					; 0xe4ff

	Chars C_KANJI_JIS_6921			; 0xe540 (U+8541)
	Chars C_KANJI_JIS_6922			; 0xe541 (U+8602)
	Chars C_KANJI_JIS_6923			; 0xe542 (U+854b)
	Chars C_KANJI_JIS_6924			; 0xe543 (U+8555)
	Chars C_KANJI_JIS_6925			; 0xe544 (U+8580)
	Chars C_KANJI_JIS_6926			; 0xe545 (U+85a4)
	Chars C_KANJI_JIS_6927			; 0xe546 (U+8588)
	Chars C_KANJI_JIS_6928			; 0xe547 (U+8591)
	Chars C_KANJI_JIS_6929			; 0xe548 (U+858a)
	Chars C_KANJI_JIS_692A			; 0xe549 (U+85a8)
	Chars C_KANJI_JIS_692B			; 0xe54a (U+856d)
	Chars C_KANJI_JIS_692C			; 0xe54b (U+8594)
	Chars C_KANJI_JIS_692D			; 0xe54c (U+859b)
	Chars C_KANJI_JIS_692E			; 0xe54d (U+85ea)
	Chars C_KANJI_JIS_692F			; 0xe54e (U+8587)
	Chars C_KANJI_JIS_6930			; 0xe54f (U+859c)
Section8570Start	label	Chars
	Chars C_KANJI_JIS_6931			; 0xe550 (U+8577)
	Chars C_KANJI_JIS_6932			; 0xe551 (U+857e)
	Chars C_KANJI_JIS_6933			; 0xe552 (U+8590)
	Chars C_KANJI_JIS_6934			; 0xe553 (U+85c9)
Section85b0Start	label	Chars
	Chars C_KANJI_JIS_6935			; 0xe554 (U+85ba)
	Chars C_KANJI_JIS_6936			; 0xe555 (U+85cf)
	Chars C_KANJI_JIS_6937			; 0xe556 (U+85b9)
Section85d0Start	label	Chars
	Chars C_KANJI_JIS_6938			; 0xe557 (U+85d0)
	Chars C_KANJI_JIS_6939			; 0xe558 (U+85d5)
	Chars C_KANJI_JIS_693A			; 0xe559 (U+85dd)
	Chars C_KANJI_JIS_693B			; 0xe55a (U+85e5)
	Chars C_KANJI_JIS_693C			; 0xe55b (U+85dc)
	Chars C_KANJI_JIS_693D			; 0xe55c (U+85f9)
	Chars C_KANJI_JIS_693E			; 0xe55d (U+860a)
	Chars C_KANJI_JIS_693F			; 0xe55e (U+8613)
	Chars C_KANJI_JIS_6940			; 0xe55f (U+860b)
	Chars C_KANJI_JIS_6941			; 0xe560 (U+85fe)
	Chars C_KANJI_JIS_6942			; 0xe561 (U+85fa)
	Chars C_KANJI_JIS_6943			; 0xe562 (U+8606)
	Chars C_KANJI_JIS_6944			; 0xe563 (U+8622)
	Chars C_KANJI_JIS_6945			; 0xe564 (U+861a)
Section8630Start	label	Chars
	Chars C_KANJI_JIS_6946			; 0xe565 (U+8630)
	Chars C_KANJI_JIS_6947			; 0xe566 (U+863f)
	Chars C_KANJI_JIS_6948			; 0xe567 (U+864d)
	Chars C_KANJI_JIS_6949			; 0xe568 (U+4e55)
	Chars C_KANJI_JIS_694A			; 0xe569 (U+8654)
	Chars C_KANJI_JIS_694B			; 0xe56a (U+865f)
	Chars C_KANJI_JIS_694C			; 0xe56b (U+8667)
	Chars C_KANJI_JIS_694D			; 0xe56c (U+8671)
	Chars C_KANJI_JIS_694E			; 0xe56d (U+8693)
	Chars C_KANJI_JIS_694F			; 0xe56e (U+86a3)
	Chars C_KANJI_JIS_6950			; 0xe56f (U+86a9)
	Chars C_KANJI_JIS_6951			; 0xe570 (U+86aa)
	Chars C_KANJI_JIS_6952			; 0xe571 (U+868b)
	Chars C_KANJI_JIS_6953			; 0xe572 (U+868c)
Section86b0Start	label	Chars
	Chars C_KANJI_JIS_6954			; 0xe573 (U+86b6)
	Chars C_KANJI_JIS_6955			; 0xe574 (U+86af)
	Chars C_KANJI_JIS_6956			; 0xe575 (U+86c4)
	Chars C_KANJI_JIS_6957			; 0xe576 (U+86c6)
	Chars C_KANJI_JIS_6958			; 0xe577 (U+86b0)
	Chars C_KANJI_JIS_6959			; 0xe578 (U+86c9)
Section8820Start	label	Chars
	Chars C_KANJI_JIS_695A			; 0xe579 (U+8823)
	Chars C_KANJI_JIS_695B			; 0xe57a (U+86ab)
	Chars C_KANJI_JIS_695C			; 0xe57b (U+86d4)
	Chars C_KANJI_JIS_695D			; 0xe57c (U+86de)
	Chars C_KANJI_JIS_695E			; 0xe57d (U+86e9)
	Chars C_KANJI_JIS_695F			; 0xe57e (U+86ec)
	Chars 0					; 0xe57f
	Chars C_KANJI_JIS_6960			; 0xe580 (U+86df)
	Chars C_KANJI_JIS_6961			; 0xe581 (U+86db)
	Chars C_KANJI_JIS_6962			; 0xe582 (U+86ef)
	Chars C_KANJI_JIS_6963			; 0xe583 (U+8712)
	Chars C_KANJI_JIS_6964			; 0xe584 (U+8706)
	Chars C_KANJI_JIS_6965			; 0xe585 (U+8708)
	Chars C_KANJI_JIS_6966			; 0xe586 (U+8700)
	Chars C_KANJI_JIS_6967			; 0xe587 (U+8703)
	Chars C_KANJI_JIS_6968			; 0xe588 (U+86fb)
	Chars C_KANJI_JIS_6969			; 0xe589 (U+8711)
	Chars C_KANJI_JIS_696A			; 0xe58a (U+8709)
	Chars C_KANJI_JIS_696B			; 0xe58b (U+870d)
	Chars C_KANJI_JIS_696C			; 0xe58c (U+86f9)
	Chars C_KANJI_JIS_696D			; 0xe58d (U+870a)
Section8730Start	label	Chars
	Chars C_KANJI_JIS_696E			; 0xe58e (U+8734)
	Chars C_KANJI_JIS_696F			; 0xe58f (U+873f)
	Chars C_KANJI_JIS_6970			; 0xe590 (U+8737)
	Chars C_KANJI_JIS_6971			; 0xe591 (U+873b)
Section8720Start	label	Chars
	Chars C_KANJI_JIS_6972			; 0xe592 (U+8725)
	Chars C_KANJI_JIS_6973			; 0xe593 (U+8729)
	Chars C_KANJI_JIS_6974			; 0xe594 (U+871a)
	Chars C_KANJI_JIS_6975			; 0xe595 (U+8760)
	Chars C_KANJI_JIS_6976			; 0xe596 (U+875f)
	Chars C_KANJI_JIS_6977			; 0xe597 (U+8778)
	Chars C_KANJI_JIS_6978			; 0xe598 (U+874c)
	Chars C_KANJI_JIS_6979			; 0xe599 (U+874e)
	Chars C_KANJI_JIS_697A			; 0xe59a (U+8774)
	Chars C_KANJI_JIS_697B			; 0xe59b (U+8757)
	Chars C_KANJI_JIS_697C			; 0xe59c (U+8768)
	Chars C_KANJI_JIS_697D			; 0xe59d (U+876e)
	Chars C_KANJI_JIS_697E			; 0xe59e (U+8759)
	Chars C_KANJI_JIS_6A21			; 0xe59f (U+8753)
	Chars C_KANJI_JIS_6A22			; 0xe5a0 (U+8763)
	Chars C_KANJI_JIS_6A23			; 0xe5a1 (U+876a)
Section8800Start	label	Chars
	Chars C_KANJI_JIS_6A24			; 0xe5a2 (U+8805)
Section87a0Start	label	Chars
	Chars C_KANJI_JIS_6A25			; 0xe5a3 (U+87a2)
Section8790Start	label	Chars
	Chars C_KANJI_JIS_6A26			; 0xe5a4 (U+879f)
	Chars C_KANJI_JIS_6A27			; 0xe5a5 (U+8782)
	Chars C_KANJI_JIS_6A28			; 0xe5a6 (U+87af)
Section87c0Start	label	Chars
	Chars C_KANJI_JIS_6A29			; 0xe5a7 (U+87cb)
	Chars C_KANJI_JIS_6A2A			; 0xe5a8 (U+87bd)
	Chars C_KANJI_JIS_6A2B			; 0xe5a9 (U+87c0)
Section87d0Start	label	Chars
	Chars C_KANJI_JIS_6A2C			; 0xe5aa (U+87d0)
	Chars C_KANJI_JIS_6A2D			; 0xe5ab (U+96d6)
	Chars C_KANJI_JIS_6A2E			; 0xe5ac (U+87ab)
	Chars C_KANJI_JIS_6A2F			; 0xe5ad (U+87c4)
	Chars C_KANJI_JIS_6A30			; 0xe5ae (U+87b3)
	Chars C_KANJI_JIS_6A31			; 0xe5af (U+87c7)
	Chars C_KANJI_JIS_6A32			; 0xe5b0 (U+87c6)
	Chars C_KANJI_JIS_6A33			; 0xe5b1 (U+87bb)
Section87e0Start	label	Chars
	Chars C_KANJI_JIS_6A34			; 0xe5b2 (U+87ef)
	Chars C_KANJI_JIS_6A35			; 0xe5b3 (U+87f2)
	Chars C_KANJI_JIS_6A36			; 0xe5b4 (U+87e0)
	Chars C_KANJI_JIS_6A37			; 0xe5b5 (U+880f)
	Chars C_KANJI_JIS_6A38			; 0xe5b6 (U+880d)
	Chars C_KANJI_JIS_6A39			; 0xe5b7 (U+87fe)
	Chars C_KANJI_JIS_6A3A			; 0xe5b8 (U+87f6)
	Chars C_KANJI_JIS_6A3B			; 0xe5b9 (U+87f7)
	Chars C_KANJI_JIS_6A3C			; 0xe5ba (U+880e)
	Chars C_KANJI_JIS_6A3D			; 0xe5bb (U+87d2)
Section8810Start	label	Chars
	Chars C_KANJI_JIS_6A3E			; 0xe5bc (U+8811)
	Chars C_KANJI_JIS_6A3F			; 0xe5bd (U+8816)
	Chars C_KANJI_JIS_6A40			; 0xe5be (U+8815)
	Chars C_KANJI_JIS_6A41			; 0xe5bf (U+8822)
	Chars C_KANJI_JIS_6A42			; 0xe5c0 (U+8821)
Section8830Start	label	Chars
	Chars C_KANJI_JIS_6A43			; 0xe5c1 (U+8831)
	Chars C_KANJI_JIS_6A44			; 0xe5c2 (U+8836)
	Chars C_KANJI_JIS_6A45			; 0xe5c3 (U+8839)
	Chars C_KANJI_JIS_6A46			; 0xe5c4 (U+8827)
	Chars C_KANJI_JIS_6A47			; 0xe5c5 (U+883b)
	Chars C_KANJI_JIS_6A48			; 0xe5c6 (U+8844)
	Chars C_KANJI_JIS_6A49			; 0xe5c7 (U+8842)
	Chars C_KANJI_JIS_6A4A			; 0xe5c8 (U+8852)
	Chars C_KANJI_JIS_6A4B			; 0xe5c9 (U+8859)
	Chars C_KANJI_JIS_6A4C			; 0xe5ca (U+885e)
	Chars C_KANJI_JIS_6A4D			; 0xe5cb (U+8862)
	Chars C_KANJI_JIS_6A4E			; 0xe5cc (U+886b)
	Chars C_KANJI_JIS_6A4F			; 0xe5cd (U+8881)
	Chars C_KANJI_JIS_6A50			; 0xe5ce (U+887e)
	Chars C_KANJI_JIS_6A51			; 0xe5cf (U+889e)
	Chars C_KANJI_JIS_6A52			; 0xe5d0 (U+8875)
	Chars C_KANJI_JIS_6A53			; 0xe5d1 (U+887d)
	Chars C_KANJI_JIS_6A54			; 0xe5d2 (U+88b5)
	Chars C_KANJI_JIS_6A55			; 0xe5d3 (U+8872)
	Chars C_KANJI_JIS_6A56			; 0xe5d4 (U+8882)
	Chars C_KANJI_JIS_6A57			; 0xe5d5 (U+8897)
	Chars C_KANJI_JIS_6A58			; 0xe5d6 (U+8892)
	Chars C_KANJI_JIS_6A59			; 0xe5d7 (U+88ae)
	Chars C_KANJI_JIS_6A5A			; 0xe5d8 (U+8899)
	Chars C_KANJI_JIS_6A5B			; 0xe5d9 (U+88a2)
	Chars C_KANJI_JIS_6A5C			; 0xe5da (U+888d)
	Chars C_KANJI_JIS_6A5D			; 0xe5db (U+88a4)
	Chars C_KANJI_JIS_6A5E			; 0xe5dc (U+88b0)
	Chars C_KANJI_JIS_6A5F			; 0xe5dd (U+88bf)
	Chars C_KANJI_JIS_6A60			; 0xe5de (U+88b1)
	Chars C_KANJI_JIS_6A61			; 0xe5df (U+88c3)
	Chars C_KANJI_JIS_6A62			; 0xe5e0 (U+88c4)
	Chars C_KANJI_JIS_6A63			; 0xe5e1 (U+88d4)
	Chars C_KANJI_JIS_6A64			; 0xe5e2 (U+88d8)
	Chars C_KANJI_JIS_6A65			; 0xe5e3 (U+88d9)
	Chars C_KANJI_JIS_6A66			; 0xe5e4 (U+88dd)
	Chars C_KANJI_JIS_6A67			; 0xe5e5 (U+88f9)
	Chars C_KANJI_JIS_6A68			; 0xe5e6 (U+8902)
	Chars C_KANJI_JIS_6A69			; 0xe5e7 (U+88fc)
	Chars C_KANJI_JIS_6A6A			; 0xe5e8 (U+88f4)
	Chars C_KANJI_JIS_6A6B			; 0xe5e9 (U+88e8)
	Chars C_KANJI_JIS_6A6C			; 0xe5ea (U+88f2)
	Chars C_KANJI_JIS_6A6D			; 0xe5eb (U+8904)
	Chars C_KANJI_JIS_6A6E			; 0xe5ec (U+890c)
	Chars C_KANJI_JIS_6A6F			; 0xe5ed (U+890a)
	Chars C_KANJI_JIS_6A70			; 0xe5ee (U+8913)
Section8940Start	label	Chars
	Chars C_KANJI_JIS_6A71			; 0xe5ef (U+8943)
	Chars C_KANJI_JIS_6A72			; 0xe5f0 (U+891e)
Section8920Start	label	Chars
	Chars C_KANJI_JIS_6A73			; 0xe5f1 (U+8925)
	Chars C_KANJI_JIS_6A74			; 0xe5f2 (U+892a)
	Chars C_KANJI_JIS_6A75			; 0xe5f3 (U+892b)
	Chars C_KANJI_JIS_6A76			; 0xe5f4 (U+8941)
	Chars C_KANJI_JIS_6A77			; 0xe5f5 (U+8944)
Section8930Start	label	Chars
	Chars C_KANJI_JIS_6A78			; 0xe5f6 (U+893b)
	Chars C_KANJI_JIS_6A79			; 0xe5f7 (U+8936)
	Chars C_KANJI_JIS_6A7A			; 0xe5f8 (U+8938)
	Chars C_KANJI_JIS_6A7B			; 0xe5f9 (U+894c)
	Chars C_KANJI_JIS_6A7C			; 0xe5fa (U+891d)
Section8960Start	label	Chars
	Chars C_KANJI_JIS_6A7D			; 0xe5fb (U+8960)
	Chars C_KANJI_JIS_6A7E			; 0xe5fc (U+895e)
	Chars 0					; 0xe5fd
	Chars 0					; 0xe5fe
	Chars 0					; 0xe5ff

	Chars C_KANJI_JIS_6B21			; 0xe640 (U+8966)
	Chars C_KANJI_JIS_6B22			; 0xe641 (U+8964)
	Chars C_KANJI_JIS_6B23			; 0xe642 (U+896d)
	Chars C_KANJI_JIS_6B24			; 0xe643 (U+896a)
	Chars C_KANJI_JIS_6B25			; 0xe644 (U+896f)
	Chars C_KANJI_JIS_6B26			; 0xe645 (U+8974)
	Chars C_KANJI_JIS_6B27			; 0xe646 (U+8977)
	Chars C_KANJI_JIS_6B28			; 0xe647 (U+897e)
	Chars C_KANJI_JIS_6B29			; 0xe648 (U+8983)
	Chars C_KANJI_JIS_6B2A			; 0xe649 (U+8988)
	Chars C_KANJI_JIS_6B2B			; 0xe64a (U+898a)
	Chars C_KANJI_JIS_6B2C			; 0xe64b (U+8993)
	Chars C_KANJI_JIS_6B2D			; 0xe64c (U+8998)
	Chars C_KANJI_JIS_6B2E			; 0xe64d (U+89a1)
	Chars C_KANJI_JIS_6B2F			; 0xe64e (U+89a9)
	Chars C_KANJI_JIS_6B30			; 0xe64f (U+89a6)
	Chars C_KANJI_JIS_6B31			; 0xe650 (U+89ac)
	Chars C_KANJI_JIS_6B32			; 0xe651 (U+89af)
	Chars C_KANJI_JIS_6B33			; 0xe652 (U+89b2)
	Chars C_KANJI_JIS_6B34			; 0xe653 (U+89ba)
	Chars C_KANJI_JIS_6B35			; 0xe654 (U+89bd)
	Chars C_KANJI_JIS_6B36			; 0xe655 (U+89bf)
Section89c0Start	label	Chars
	Chars C_KANJI_JIS_6B37			; 0xe656 (U+89c0)
	Chars C_KANJI_JIS_6B38			; 0xe657 (U+89da)
	Chars C_KANJI_JIS_6B39			; 0xe658 (U+89dc)
	Chars C_KANJI_JIS_6B3A			; 0xe659 (U+89dd)
	Chars C_KANJI_JIS_6B3B			; 0xe65a (U+89e7)
Section89f0Start	label	Chars
	Chars C_KANJI_JIS_6B3C			; 0xe65b (U+89f4)
	Chars C_KANJI_JIS_6B3D			; 0xe65c (U+89f8)
	Chars C_KANJI_JIS_6B3E			; 0xe65d (U+8a03)
	Chars C_KANJI_JIS_6B3F			; 0xe65e (U+8a16)
	Chars C_KANJI_JIS_6B40			; 0xe65f (U+8a10)
	Chars C_KANJI_JIS_6B41			; 0xe660 (U+8a0c)
	Chars C_KANJI_JIS_6B42			; 0xe661 (U+8a1b)
	Chars C_KANJI_JIS_6B43			; 0xe662 (U+8a1d)
	Chars C_KANJI_JIS_6B44			; 0xe663 (U+8a25)
	Chars C_KANJI_JIS_6B45			; 0xe664 (U+8a36)
Section8a40Start	label	Chars
	Chars C_KANJI_JIS_6B46			; 0xe665 (U+8a41)
	Chars C_KANJI_JIS_6B47			; 0xe666 (U+8a5b)
	Chars C_KANJI_JIS_6B48			; 0xe667 (U+8a52)
	Chars C_KANJI_JIS_6B49			; 0xe668 (U+8a46)
	Chars C_KANJI_JIS_6B4A			; 0xe669 (U+8a48)
	Chars C_KANJI_JIS_6B4B			; 0xe66a (U+8a7c)
	Chars C_KANJI_JIS_6B4C			; 0xe66b (U+8a6d)
	Chars C_KANJI_JIS_6B4D			; 0xe66c (U+8a6c)
	Chars C_KANJI_JIS_6B4E			; 0xe66d (U+8a62)
	Chars C_KANJI_JIS_6B4F			; 0xe66e (U+8a85)
	Chars C_KANJI_JIS_6B50			; 0xe66f (U+8a82)
	Chars C_KANJI_JIS_6B51			; 0xe670 (U+8a84)
	Chars C_KANJI_JIS_6B52			; 0xe671 (U+8aa8)
	Chars C_KANJI_JIS_6B53			; 0xe672 (U+8aa1)
	Chars C_KANJI_JIS_6B54			; 0xe673 (U+8a91)
	Chars C_KANJI_JIS_6B55			; 0xe674 (U+8aa5)
	Chars C_KANJI_JIS_6B56			; 0xe675 (U+8aa6)
	Chars C_KANJI_JIS_6B57			; 0xe676 (U+8a9a)
	Chars C_KANJI_JIS_6B58			; 0xe677 (U+8aa3)
	Chars C_KANJI_JIS_6B59			; 0xe678 (U+8ac4)
	Chars C_KANJI_JIS_6B5A			; 0xe679 (U+8acd)
	Chars C_KANJI_JIS_6B5B			; 0xe67a (U+8ac2)
	Chars C_KANJI_JIS_6B5C			; 0xe67b (U+8ada)
	Chars C_KANJI_JIS_6B5D			; 0xe67c (U+8aeb)
	Chars C_KANJI_JIS_6B5E			; 0xe67d (U+8af3)
	Chars C_KANJI_JIS_6B5F			; 0xe67e (U+8ae7)
	Chars 0					; 0xe67f
	Chars C_KANJI_JIS_6B60			; 0xe680 (U+8ae4)
	Chars C_KANJI_JIS_6B61			; 0xe681 (U+8af1)
	Chars C_KANJI_JIS_6B62			; 0xe682 (U+8b14)
	Chars C_KANJI_JIS_6B63			; 0xe683 (U+8ae0)
	Chars C_KANJI_JIS_6B64			; 0xe684 (U+8ae2)
	Chars C_KANJI_JIS_6B65			; 0xe685 (U+8af7)
	Chars C_KANJI_JIS_6B66			; 0xe686 (U+8ade)
	Chars C_KANJI_JIS_6B67			; 0xe687 (U+8adb)
	Chars C_KANJI_JIS_6B68			; 0xe688 (U+8b0c)
	Chars C_KANJI_JIS_6B69			; 0xe689 (U+8b07)
	Chars C_KANJI_JIS_6B6A			; 0xe68a (U+8b1a)
	Chars C_KANJI_JIS_6B6B			; 0xe68b (U+8ae1)
	Chars C_KANJI_JIS_6B6C			; 0xe68c (U+8b16)
	Chars C_KANJI_JIS_6B6D			; 0xe68d (U+8b10)
	Chars C_KANJI_JIS_6B6E			; 0xe68e (U+8b17)
	Chars C_KANJI_JIS_6B6F			; 0xe68f (U+8b20)
	Chars C_KANJI_JIS_6B70			; 0xe690 (U+8b33)
	Chars C_KANJI_JIS_6B71			; 0xe691 (U+97ab)
	Chars C_KANJI_JIS_6B72			; 0xe692 (U+8b26)
	Chars C_KANJI_JIS_6B73			; 0xe693 (U+8b2b)
	Chars C_KANJI_JIS_6B74			; 0xe694 (U+8b3e)
	Chars C_KANJI_JIS_6B75			; 0xe695 (U+8b28)
Section8b40Start	label	Chars
	Chars C_KANJI_JIS_6B76			; 0xe696 (U+8b41)
	Chars C_KANJI_JIS_6B77			; 0xe697 (U+8b4c)
	Chars C_KANJI_JIS_6B78			; 0xe698 (U+8b4f)
	Chars C_KANJI_JIS_6B79			; 0xe699 (U+8b4e)
	Chars C_KANJI_JIS_6B7A			; 0xe69a (U+8b49)
	Chars C_KANJI_JIS_6B7B			; 0xe69b (U+8b56)
	Chars C_KANJI_JIS_6B7C			; 0xe69c (U+8b5b)
	Chars C_KANJI_JIS_6B7D			; 0xe69d (U+8b5a)
	Chars C_KANJI_JIS_6B7E			; 0xe69e (U+8b6b)
	Chars C_KANJI_JIS_6C21			; 0xe69f (U+8b5f)
	Chars C_KANJI_JIS_6C22			; 0xe6a0 (U+8b6c)
	Chars C_KANJI_JIS_6C23			; 0xe6a1 (U+8b6f)
	Chars C_KANJI_JIS_6C24			; 0xe6a2 (U+8b74)
	Chars C_KANJI_JIS_6C25			; 0xe6a3 (U+8b7d)
	Chars C_KANJI_JIS_6C26			; 0xe6a4 (U+8b80)
	Chars C_KANJI_JIS_6C27			; 0xe6a5 (U+8b8c)
	Chars C_KANJI_JIS_6C28			; 0xe6a6 (U+8b8e)
	Chars C_KANJI_JIS_6C29			; 0xe6a7 (U+8b92)
	Chars C_KANJI_JIS_6C2A			; 0xe6a8 (U+8b93)
	Chars C_KANJI_JIS_6C2B			; 0xe6a9 (U+8b96)
	Chars C_KANJI_JIS_6C2C			; 0xe6aa (U+8b99)
	Chars C_KANJI_JIS_6C2D			; 0xe6ab (U+8b9a)
	Chars C_KANJI_JIS_6C2E			; 0xe6ac (U+8c3a)
	Chars C_KANJI_JIS_6C2F			; 0xe6ad (U+8c41)
	Chars C_KANJI_JIS_6C30			; 0xe6ae (U+8c3f)
	Chars C_KANJI_JIS_6C31			; 0xe6af (U+8c48)
	Chars C_KANJI_JIS_6C32			; 0xe6b0 (U+8c4c)
	Chars C_KANJI_JIS_6C33			; 0xe6b1 (U+8c4e)
	Chars C_KANJI_JIS_6C34			; 0xe6b2 (U+8c50)
	Chars C_KANJI_JIS_6C35			; 0xe6b3 (U+8c55)
	Chars C_KANJI_JIS_6C36			; 0xe6b4 (U+8c62)
	Chars C_KANJI_JIS_6C37			; 0xe6b5 (U+8c6c)
	Chars C_KANJI_JIS_6C38			; 0xe6b6 (U+8c78)
	Chars C_KANJI_JIS_6C39			; 0xe6b7 (U+8c7a)
	Chars C_KANJI_JIS_6C3A			; 0xe6b8 (U+8c82)
	Chars C_KANJI_JIS_6C3B			; 0xe6b9 (U+8c89)
	Chars C_KANJI_JIS_6C3C			; 0xe6ba (U+8c85)
	Chars C_KANJI_JIS_6C3D			; 0xe6bb (U+8c8a)
	Chars C_KANJI_JIS_6C3E			; 0xe6bc (U+8c8d)
	Chars C_KANJI_JIS_6C3F			; 0xe6bd (U+8c8e)
	Chars C_KANJI_JIS_6C40			; 0xe6be (U+8c94)
	Chars C_KANJI_JIS_6C41			; 0xe6bf (U+8c7c)
	Chars C_KANJI_JIS_6C42			; 0xe6c0 (U+8c98)
	Chars C_KANJI_JIS_6C43			; 0xe6c1 (U+621d)
	Chars C_KANJI_JIS_6C44			; 0xe6c2 (U+8cad)
	Chars C_KANJI_JIS_6C45			; 0xe6c3 (U+8caa)
	Chars C_KANJI_JIS_6C46			; 0xe6c4 (U+8cbd)
	Chars C_KANJI_JIS_6C47			; 0xe6c5 (U+8cb2)
	Chars C_KANJI_JIS_6C48			; 0xe6c6 (U+8cb3)
	Chars C_KANJI_JIS_6C49			; 0xe6c7 (U+8cae)
	Chars C_KANJI_JIS_6C4A			; 0xe6c8 (U+8cb6)
	Chars C_KANJI_JIS_6C4B			; 0xe6c9 (U+8cc8)
	Chars C_KANJI_JIS_6C4C			; 0xe6ca (U+8cc1)
	Chars C_KANJI_JIS_6C4D			; 0xe6cb (U+8ce4)
	Chars C_KANJI_JIS_6C4E			; 0xe6cc (U+8ce3)
	Chars C_KANJI_JIS_6C4F			; 0xe6cd (U+8cda)
	Chars C_KANJI_JIS_6C50			; 0xe6ce (U+8cfd)
	Chars C_KANJI_JIS_6C51			; 0xe6cf (U+8cfa)
	Chars C_KANJI_JIS_6C52			; 0xe6d0 (U+8cfb)
	Chars C_KANJI_JIS_6C53			; 0xe6d1 (U+8d04)
	Chars C_KANJI_JIS_6C54			; 0xe6d2 (U+8d05)
	Chars C_KANJI_JIS_6C55			; 0xe6d3 (U+8d0a)
	Chars C_KANJI_JIS_6C56			; 0xe6d4 (U+8d07)
	Chars C_KANJI_JIS_6C57			; 0xe6d5 (U+8d0f)
	Chars C_KANJI_JIS_6C58			; 0xe6d6 (U+8d0d)
Section8d10Start	label	Chars
	Chars C_KANJI_JIS_6C59			; 0xe6d7 (U+8d10)
	Chars C_KANJI_JIS_6C5A			; 0xe6d8 (U+9f4e)
	Chars C_KANJI_JIS_6C5B			; 0xe6d9 (U+8d13)
	Chars C_KANJI_JIS_6C5C			; 0xe6da (U+8ccd)
	Chars C_KANJI_JIS_6C5D			; 0xe6db (U+8d14)
	Chars C_KANJI_JIS_6C5E			; 0xe6dc (U+8d16)
	Chars C_KANJI_JIS_6C5F			; 0xe6dd (U+8d67)
	Chars C_KANJI_JIS_6C60			; 0xe6de (U+8d6d)
	Chars C_KANJI_JIS_6C61			; 0xe6df (U+8d71)
	Chars C_KANJI_JIS_6C62			; 0xe6e0 (U+8d73)
	Chars C_KANJI_JIS_6C63			; 0xe6e1 (U+8d81)
Section8d90Start	label	Chars
	Chars C_KANJI_JIS_6C64			; 0xe6e2 (U+8d99)
Section8dc0Start	label	Chars
	Chars C_KANJI_JIS_6C65			; 0xe6e3 (U+8dc2)
	Chars C_KANJI_JIS_6C66			; 0xe6e4 (U+8dbe)
	Chars C_KANJI_JIS_6C67			; 0xe6e5 (U+8dba)
	Chars C_KANJI_JIS_6C68			; 0xe6e6 (U+8dcf)
	Chars C_KANJI_JIS_6C69			; 0xe6e7 (U+8dda)
	Chars C_KANJI_JIS_6C6A			; 0xe6e8 (U+8dd6)
	Chars C_KANJI_JIS_6C6B			; 0xe6e9 (U+8dcc)
	Chars C_KANJI_JIS_6C6C			; 0xe6ea (U+8ddb)
	Chars C_KANJI_JIS_6C6D			; 0xe6eb (U+8dcb)
	Chars C_KANJI_JIS_6C6E			; 0xe6ec (U+8dea)
	Chars C_KANJI_JIS_6C6F			; 0xe6ed (U+8deb)
	Chars C_KANJI_JIS_6C70			; 0xe6ee (U+8ddf)
	Chars C_KANJI_JIS_6C71			; 0xe6ef (U+8de3)
	Chars C_KANJI_JIS_6C72			; 0xe6f0 (U+8dfc)
	Chars C_KANJI_JIS_6C73			; 0xe6f1 (U+8e08)
	Chars C_KANJI_JIS_6C74			; 0xe6f2 (U+8e09)
	Chars C_KANJI_JIS_6C75			; 0xe6f3 (U+8dff)
Section8e10Start	label	Chars
	Chars C_KANJI_JIS_6C76			; 0xe6f4 (U+8e1d)
	Chars C_KANJI_JIS_6C77			; 0xe6f5 (U+8e1e)
	Chars C_KANJI_JIS_6C78			; 0xe6f6 (U+8e10)
	Chars C_KANJI_JIS_6C79			; 0xe6f7 (U+8e1f)
	Chars C_KANJI_JIS_6C7A			; 0xe6f8 (U+8e42)
Section8e30Start	label	Chars
	Chars C_KANJI_JIS_6C7B			; 0xe6f9 (U+8e35)
	Chars C_KANJI_JIS_6C7C			; 0xe6fa (U+8e30)
	Chars C_KANJI_JIS_6C7D			; 0xe6fb (U+8e34)
	Chars C_KANJI_JIS_6C7E			; 0xe6fc (U+8e4a)
	Chars 0					; 0xe6fd
	Chars 0					; 0xe6fe
	Chars 0					; 0xe6ff

	Chars C_KANJI_JIS_6D21			; 0xe740 (U+8e47)
	Chars C_KANJI_JIS_6D22			; 0xe741 (U+8e49)
	Chars C_KANJI_JIS_6D23			; 0xe742 (U+8e4c)
	Chars C_KANJI_JIS_6D24			; 0xe743 (U+8e50)
	Chars C_KANJI_JIS_6D25			; 0xe744 (U+8e48)
	Chars C_KANJI_JIS_6D26			; 0xe745 (U+8e59)
Section8e60Start	label	Chars
	Chars C_KANJI_JIS_6D27			; 0xe746 (U+8e64)
	Chars C_KANJI_JIS_6D28			; 0xe747 (U+8e60)
Section8e20Start	label	Chars
	Chars C_KANJI_JIS_6D29			; 0xe748 (U+8e2a)
	Chars C_KANJI_JIS_6D2A			; 0xe749 (U+8e63)
	Chars C_KANJI_JIS_6D2B			; 0xe74a (U+8e55)
	Chars C_KANJI_JIS_6D2C			; 0xe74b (U+8e76)
	Chars C_KANJI_JIS_6D2D			; 0xe74c (U+8e72)
	Chars C_KANJI_JIS_6D2E			; 0xe74d (U+8e7c)
	Chars C_KANJI_JIS_6D2F			; 0xe74e (U+8e81)
	Chars C_KANJI_JIS_6D30			; 0xe74f (U+8e87)
	Chars C_KANJI_JIS_6D31			; 0xe750 (U+8e85)
	Chars C_KANJI_JIS_6D32			; 0xe751 (U+8e84)
	Chars C_KANJI_JIS_6D33			; 0xe752 (U+8e8b)
	Chars C_KANJI_JIS_6D34			; 0xe753 (U+8e8a)
Section8e90Start	label	Chars
	Chars C_KANJI_JIS_6D35			; 0xe754 (U+8e93)
	Chars C_KANJI_JIS_6D36			; 0xe755 (U+8e91)
	Chars C_KANJI_JIS_6D37			; 0xe756 (U+8e94)
	Chars C_KANJI_JIS_6D38			; 0xe757 (U+8e99)
	Chars C_KANJI_JIS_6D39			; 0xe758 (U+8eaa)
	Chars C_KANJI_JIS_6D3A			; 0xe759 (U+8ea1)
	Chars C_KANJI_JIS_6D3B			; 0xe75a (U+8eac)
Section8eb0Start	label	Chars
	Chars C_KANJI_JIS_6D3C			; 0xe75b (U+8eb0)
	Chars C_KANJI_JIS_6D3D			; 0xe75c (U+8ec6)
	Chars C_KANJI_JIS_6D3E			; 0xe75d (U+8eb1)
	Chars C_KANJI_JIS_6D3F			; 0xe75e (U+8ebe)
	Chars C_KANJI_JIS_6D40			; 0xe75f (U+8ec5)
	Chars C_KANJI_JIS_6D41			; 0xe760 (U+8ec8)
	Chars C_KANJI_JIS_6D42			; 0xe761 (U+8ecb)
	Chars C_KANJI_JIS_6D43			; 0xe762 (U+8edb)
	Chars C_KANJI_JIS_6D44			; 0xe763 (U+8ee3)
	Chars C_KANJI_JIS_6D45			; 0xe764 (U+8efc)
	Chars C_KANJI_JIS_6D46			; 0xe765 (U+8efb)
	Chars C_KANJI_JIS_6D47			; 0xe766 (U+8eeb)
	Chars C_KANJI_JIS_6D48			; 0xe767 (U+8efe)
	Chars C_KANJI_JIS_6D49			; 0xe768 (U+8f0a)
	Chars C_KANJI_JIS_6D4A			; 0xe769 (U+8f05)
	Chars C_KANJI_JIS_6D4B			; 0xe76a (U+8f15)
	Chars C_KANJI_JIS_6D4C			; 0xe76b (U+8f12)
	Chars C_KANJI_JIS_6D4D			; 0xe76c (U+8f19)
	Chars C_KANJI_JIS_6D4E			; 0xe76d (U+8f13)
	Chars C_KANJI_JIS_6D4F			; 0xe76e (U+8f1c)
	Chars C_KANJI_JIS_6D50			; 0xe76f (U+8f1f)
	Chars C_KANJI_JIS_6D51			; 0xe770 (U+8f1b)
	Chars C_KANJI_JIS_6D52			; 0xe771 (U+8f0c)
	Chars C_KANJI_JIS_6D53			; 0xe772 (U+8f26)
	Chars C_KANJI_JIS_6D54			; 0xe773 (U+8f33)
	Chars C_KANJI_JIS_6D55			; 0xe774 (U+8f3b)
	Chars C_KANJI_JIS_6D56			; 0xe775 (U+8f39)
	Chars C_KANJI_JIS_6D57			; 0xe776 (U+8f45)
	Chars C_KANJI_JIS_6D58			; 0xe777 (U+8f42)
	Chars C_KANJI_JIS_6D59			; 0xe778 (U+8f3e)
	Chars C_KANJI_JIS_6D5A			; 0xe779 (U+8f4c)
	Chars C_KANJI_JIS_6D5B			; 0xe77a (U+8f49)
	Chars C_KANJI_JIS_6D5C			; 0xe77b (U+8f46)
	Chars C_KANJI_JIS_6D5D			; 0xe77c (U+8f4e)
	Chars C_KANJI_JIS_6D5E			; 0xe77d (U+8f57)
	Chars C_KANJI_JIS_6D5F			; 0xe77e (U+8f5c)
	Chars 0					; 0xe77f
	Chars C_KANJI_JIS_6D60			; 0xe780 (U+8f62)
	Chars C_KANJI_JIS_6D61			; 0xe781 (U+8f63)
	Chars C_KANJI_JIS_6D62			; 0xe782 (U+8f64)
	Chars C_KANJI_JIS_6D63			; 0xe783 (U+8f9c)
	Chars C_KANJI_JIS_6D64			; 0xe784 (U+8f9f)
	Chars C_KANJI_JIS_6D65			; 0xe785 (U+8fa3)
	Chars C_KANJI_JIS_6D66			; 0xe786 (U+8fad)
	Chars C_KANJI_JIS_6D67			; 0xe787 (U+8faf)
	Chars C_KANJI_JIS_6D68			; 0xe788 (U+8fb7)
	Chars C_KANJI_JIS_6D69			; 0xe789 (U+8fda)
	Chars C_KANJI_JIS_6D6A			; 0xe78a (U+8fe5)
	Chars C_KANJI_JIS_6D6B			; 0xe78b (U+8fe2)
	Chars C_KANJI_JIS_6D6C			; 0xe78c (U+8fea)
	Chars C_KANJI_JIS_6D6D			; 0xe78d (U+8fef)
	Chars C_KANJI_JIS_6D6E			; 0xe78e (U+9087)
	Chars C_KANJI_JIS_6D6F			; 0xe78f (U+8ff4)
	Chars C_KANJI_JIS_6D70			; 0xe790 (U+9005)
	Chars C_KANJI_JIS_6D71			; 0xe791 (U+8ff9)
	Chars C_KANJI_JIS_6D72			; 0xe792 (U+8ffa)
	Chars C_KANJI_JIS_6D73			; 0xe793 (U+9011)
	Chars C_KANJI_JIS_6D74			; 0xe794 (U+9015)
	Chars C_KANJI_JIS_6D75			; 0xe795 (U+9021)
	Chars C_KANJI_JIS_6D76			; 0xe796 (U+900d)
	Chars C_KANJI_JIS_6D77			; 0xe797 (U+901e)
	Chars C_KANJI_JIS_6D78			; 0xe798 (U+9016)
	Chars C_KANJI_JIS_6D79			; 0xe799 (U+900b)
	Chars C_KANJI_JIS_6D7A			; 0xe79a (U+9027)
	Chars C_KANJI_JIS_6D7B			; 0xe79b (U+9036)
	Chars C_KANJI_JIS_6D7C			; 0xe79c (U+9035)
	Chars C_KANJI_JIS_6D7D			; 0xe79d (U+9039)
	Chars C_KANJI_JIS_6D7E			; 0xe79e (U+8ff8)
	Chars C_KANJI_JIS_6E21			; 0xe79f (U+904f)
	Chars C_KANJI_JIS_6E22			; 0xe7a0 (U+9050)
	Chars C_KANJI_JIS_6E23			; 0xe7a1 (U+9051)
	Chars C_KANJI_JIS_6E24			; 0xe7a2 (U+9052)
	Chars C_KANJI_JIS_6E25			; 0xe7a3 (U+900e)
	Chars C_KANJI_JIS_6E26			; 0xe7a4 (U+9049)
	Chars C_KANJI_JIS_6E27			; 0xe7a5 (U+903e)
	Chars C_KANJI_JIS_6E28			; 0xe7a6 (U+9056)
	Chars C_KANJI_JIS_6E29			; 0xe7a7 (U+9058)
	Chars C_KANJI_JIS_6E2A			; 0xe7a8 (U+905e)
	Chars C_KANJI_JIS_6E2B			; 0xe7a9 (U+9068)
	Chars C_KANJI_JIS_6E2C			; 0xe7aa (U+906f)
	Chars C_KANJI_JIS_6E2D			; 0xe7ab (U+9076)
	Chars C_KANJI_JIS_6E2E			; 0xe7ac (U+96a8)
	Chars C_KANJI_JIS_6E2F			; 0xe7ad (U+9072)
	Chars C_KANJI_JIS_6E30			; 0xe7ae (U+9082)
	Chars C_KANJI_JIS_6E31			; 0xe7af (U+907d)
	Chars C_KANJI_JIS_6E32			; 0xe7b0 (U+9081)
	Chars C_KANJI_JIS_6E33			; 0xe7b1 (U+9080)
	Chars C_KANJI_JIS_6E34			; 0xe7b2 (U+908a)
	Chars C_KANJI_JIS_6E35			; 0xe7b3 (U+9089)
	Chars C_KANJI_JIS_6E36			; 0xe7b4 (U+908f)
	Chars C_KANJI_JIS_6E37			; 0xe7b5 (U+90a8)
	Chars C_KANJI_JIS_6E38			; 0xe7b6 (U+90af)
	Chars C_KANJI_JIS_6E39			; 0xe7b7 (U+90b1)
	Chars C_KANJI_JIS_6E3A			; 0xe7b8 (U+90b5)
	Chars C_KANJI_JIS_6E3B			; 0xe7b9 (U+90e2)
	Chars C_KANJI_JIS_6E3C			; 0xe7ba (U+90e4)
	Chars C_KANJI_JIS_6E3D			; 0xe7bb (U+6248)
Section90d0Start	label	Chars
	Chars C_KANJI_JIS_6E3E			; 0xe7bc (U+90db)
Section9100Start	label	Chars
	Chars C_KANJI_JIS_6E3F			; 0xe7bd (U+9102)
Section9110Start	label	Chars
	Chars C_KANJI_JIS_6E40			; 0xe7be (U+9112)
	Chars C_KANJI_JIS_6E41			; 0xe7bf (U+9119)
Section9130Start	label	Chars
	Chars C_KANJI_JIS_6E42			; 0xe7c0 (U+9132)
	Chars C_KANJI_JIS_6E43			; 0xe7c1 (U+9130)
	Chars C_KANJI_JIS_6E44			; 0xe7c2 (U+914a)
	Chars C_KANJI_JIS_6E45			; 0xe7c3 (U+9156)
	Chars C_KANJI_JIS_6E46			; 0xe7c4 (U+9158)
	Chars C_KANJI_JIS_6E47			; 0xe7c5 (U+9163)
	Chars C_KANJI_JIS_6E48			; 0xe7c6 (U+9165)
	Chars C_KANJI_JIS_6E49			; 0xe7c7 (U+9169)
	Chars C_KANJI_JIS_6E4A			; 0xe7c8 (U+9173)
	Chars C_KANJI_JIS_6E4B			; 0xe7c9 (U+9172)
	Chars C_KANJI_JIS_6E4C			; 0xe7ca (U+918b)
	Chars C_KANJI_JIS_6E4D			; 0xe7cb (U+9189)
	Chars C_KANJI_JIS_6E4E			; 0xe7cc (U+9182)
	Chars C_KANJI_JIS_6E4F			; 0xe7cd (U+91a2)
	Chars C_KANJI_JIS_6E50			; 0xe7ce (U+91ab)
	Chars C_KANJI_JIS_6E51			; 0xe7cf (U+91af)
	Chars C_KANJI_JIS_6E52			; 0xe7d0 (U+91aa)
	Chars C_KANJI_JIS_6E53			; 0xe7d1 (U+91b5)
	Chars C_KANJI_JIS_6E54			; 0xe7d2 (U+91b4)
	Chars C_KANJI_JIS_6E55			; 0xe7d3 (U+91ba)
	Chars C_KANJI_JIS_6E56			; 0xe7d4 (U+91c0)
	Chars C_KANJI_JIS_6E57			; 0xe7d5 (U+91c1)
	Chars C_KANJI_JIS_6E58			; 0xe7d6 (U+91c9)
	Chars C_KANJI_JIS_6E59			; 0xe7d7 (U+91cb)
	Chars C_KANJI_JIS_6E5A			; 0xe7d8 (U+91d0)
	Chars C_KANJI_JIS_6E5B			; 0xe7d9 (U+91d6)
	Chars C_KANJI_JIS_6E5C			; 0xe7da (U+91df)
	Chars C_KANJI_JIS_6E5D			; 0xe7db (U+91e1)
	Chars C_KANJI_JIS_6E5E			; 0xe7dc (U+91db)
Section91f0Start	label	Chars
	Chars C_KANJI_JIS_6E5F			; 0xe7dd (U+91fc)
	Chars C_KANJI_JIS_6E60			; 0xe7de (U+91f5)
	Chars C_KANJI_JIS_6E61			; 0xe7df (U+91f6)
Section9210Start	label	Chars
	Chars C_KANJI_JIS_6E62			; 0xe7e0 (U+921e)
	Chars C_KANJI_JIS_6E63			; 0xe7e1 (U+91ff)
	Chars C_KANJI_JIS_6E64			; 0xe7e2 (U+9214)
Section9220Start	label	Chars
	Chars C_KANJI_JIS_6E65			; 0xe7e3 (U+922c)
	Chars C_KANJI_JIS_6E66			; 0xe7e4 (U+9215)
	Chars C_KANJI_JIS_6E67			; 0xe7e5 (U+9211)
	Chars C_KANJI_JIS_6E68			; 0xe7e6 (U+925e)
	Chars C_KANJI_JIS_6E69			; 0xe7e7 (U+9257)
	Chars C_KANJI_JIS_6E6A			; 0xe7e8 (U+9245)
	Chars C_KANJI_JIS_6E6B			; 0xe7e9 (U+9249)
	Chars C_KANJI_JIS_6E6C			; 0xe7ea (U+9264)
	Chars C_KANJI_JIS_6E6D			; 0xe7eb (U+9248)
	Chars C_KANJI_JIS_6E6E			; 0xe7ec (U+9295)
	Chars C_KANJI_JIS_6E6F			; 0xe7ed (U+923f)
	Chars C_KANJI_JIS_6E70			; 0xe7ee (U+924b)
	Chars C_KANJI_JIS_6E71			; 0xe7ef (U+9250)
	Chars C_KANJI_JIS_6E72			; 0xe7f0 (U+929c)
	Chars C_KANJI_JIS_6E73			; 0xe7f1 (U+9296)
	Chars C_KANJI_JIS_6E74			; 0xe7f2 (U+9293)
	Chars C_KANJI_JIS_6E75			; 0xe7f3 (U+929b)
	Chars C_KANJI_JIS_6E76			; 0xe7f4 (U+925a)
Section92c0Start	label	Chars
	Chars C_KANJI_JIS_6E77			; 0xe7f5 (U+92cf)
Section92b0Start	label	Chars
	Chars C_KANJI_JIS_6E78			; 0xe7f6 (U+92b9)
	Chars C_KANJI_JIS_6E79			; 0xe7f7 (U+92b7)
	Chars C_KANJI_JIS_6E7A			; 0xe7f8 (U+92e9)
	Chars C_KANJI_JIS_6E7B			; 0xe7f9 (U+930f)
	Chars C_KANJI_JIS_6E7C			; 0xe7fa (U+92fa)
	Chars C_KANJI_JIS_6E7D			; 0xe7fb (U+9344)
	Chars C_KANJI_JIS_6E7E			; 0xe7fc (U+932e)
	Chars 0					; 0xe7fd
	Chars 0					; 0xe7fe
	Chars 0					; 0xe7ff

	Chars C_KANJI_JIS_6F21			; 0xe840 (U+9319)
	Chars C_KANJI_JIS_6F22			; 0xe841 (U+9322)
	Chars C_KANJI_JIS_6F23			; 0xe842 (U+931a)
	Chars C_KANJI_JIS_6F24			; 0xe843 (U+9323)
	Chars C_KANJI_JIS_6F25			; 0xe844 (U+933a)
	Chars C_KANJI_JIS_6F26			; 0xe845 (U+9335)
	Chars C_KANJI_JIS_6F27			; 0xe846 (U+933b)
	Chars C_KANJI_JIS_6F28			; 0xe847 (U+935c)
	Chars C_KANJI_JIS_6F29			; 0xe848 (U+9360)
	Chars C_KANJI_JIS_6F2A			; 0xe849 (U+937c)
	Chars C_KANJI_JIS_6F2B			; 0xe84a (U+936e)
	Chars C_KANJI_JIS_6F2C			; 0xe84b (U+9356)
Section93b0Start	label	Chars
	Chars C_KANJI_JIS_6F2D			; 0xe84c (U+93b0)
	Chars C_KANJI_JIS_6F2E			; 0xe84d (U+93ac)
	Chars C_KANJI_JIS_6F2F			; 0xe84e (U+93ad)
	Chars C_KANJI_JIS_6F30			; 0xe84f (U+9394)
	Chars C_KANJI_JIS_6F31			; 0xe850 (U+93b9)
	Chars C_KANJI_JIS_6F32			; 0xe851 (U+93d6)
	Chars C_KANJI_JIS_6F33			; 0xe852 (U+93d7)
	Chars C_KANJI_JIS_6F34			; 0xe853 (U+93e8)
	Chars C_KANJI_JIS_6F35			; 0xe854 (U+93e5)
	Chars C_KANJI_JIS_6F36			; 0xe855 (U+93d8)
Section93c0Start	label	Chars
	Chars C_KANJI_JIS_6F37			; 0xe856 (U+93c3)
	Chars C_KANJI_JIS_6F38			; 0xe857 (U+93dd)
	Chars C_KANJI_JIS_6F39			; 0xe858 (U+93d0)
	Chars C_KANJI_JIS_6F3A			; 0xe859 (U+93c8)
	Chars C_KANJI_JIS_6F3B			; 0xe85a (U+93e4)
	Chars C_KANJI_JIS_6F3C			; 0xe85b (U+941a)
	Chars C_KANJI_JIS_6F3D			; 0xe85c (U+9414)
	Chars C_KANJI_JIS_6F3E			; 0xe85d (U+9413)
Section9400Start	label	Chars
	Chars C_KANJI_JIS_6F3F			; 0xe85e (U+9403)
	Chars C_KANJI_JIS_6F40			; 0xe85f (U+9407)
	Chars C_KANJI_JIS_6F41			; 0xe860 (U+9410)
	Chars C_KANJI_JIS_6F42			; 0xe861 (U+9436)
Section9420Start	label	Chars
	Chars C_KANJI_JIS_6F43			; 0xe862 (U+942b)
	Chars C_KANJI_JIS_6F44			; 0xe863 (U+9435)
	Chars C_KANJI_JIS_6F45			; 0xe864 (U+9421)
	Chars C_KANJI_JIS_6F46			; 0xe865 (U+943a)
Section9440Start	label	Chars
	Chars C_KANJI_JIS_6F47			; 0xe866 (U+9441)
	Chars C_KANJI_JIS_6F48			; 0xe867 (U+9452)
	Chars C_KANJI_JIS_6F49			; 0xe868 (U+9444)
	Chars C_KANJI_JIS_6F4A			; 0xe869 (U+945b)
Section9460Start	label	Chars
	Chars C_KANJI_JIS_6F4B			; 0xe86a (U+9460)
	Chars C_KANJI_JIS_6F4C			; 0xe86b (U+9462)
	Chars C_KANJI_JIS_6F4D			; 0xe86c (U+945e)
	Chars C_KANJI_JIS_6F4E			; 0xe86d (U+946a)
	Chars C_KANJI_JIS_6F4F			; 0xe86e (U+9229)
Section9470Start	label	Chars
	Chars C_KANJI_JIS_6F50			; 0xe86f (U+9470)
	Chars C_KANJI_JIS_6F51			; 0xe870 (U+9475)
	Chars C_KANJI_JIS_6F52			; 0xe871 (U+9477)
	Chars C_KANJI_JIS_6F53			; 0xe872 (U+947d)
	Chars C_KANJI_JIS_6F54			; 0xe873 (U+945a)
	Chars C_KANJI_JIS_6F55			; 0xe874 (U+947c)
	Chars C_KANJI_JIS_6F56			; 0xe875 (U+947e)
Section9480Start	label	Chars
	Chars C_KANJI_JIS_6F57			; 0xe876 (U+9481)
	Chars C_KANJI_JIS_6F58			; 0xe877 (U+947f)
	Chars C_KANJI_JIS_6F59			; 0xe878 (U+9582)
	Chars C_KANJI_JIS_6F5A			; 0xe879 (U+9587)
	Chars C_KANJI_JIS_6F5B			; 0xe87a (U+958a)
	Chars C_KANJI_JIS_6F5C			; 0xe87b (U+9594)
	Chars C_KANJI_JIS_6F5D			; 0xe87c (U+9596)
	Chars C_KANJI_JIS_6F5E			; 0xe87d (U+9598)
	Chars C_KANJI_JIS_6F5F			; 0xe87e (U+9599)
	Chars 0					; 0xe87f
	Chars C_KANJI_JIS_6F60			; 0xe880 (U+95a0)
	Chars C_KANJI_JIS_6F61			; 0xe881 (U+95a8)
	Chars C_KANJI_JIS_6F62			; 0xe882 (U+95a7)
	Chars C_KANJI_JIS_6F63			; 0xe883 (U+95ad)
	Chars C_KANJI_JIS_6F64			; 0xe884 (U+95bc)
	Chars C_KANJI_JIS_6F65			; 0xe885 (U+95bb)
	Chars C_KANJI_JIS_6F66			; 0xe886 (U+95b9)
	Chars C_KANJI_JIS_6F67			; 0xe887 (U+95be)
	Chars C_KANJI_JIS_6F68			; 0xe888 (U+95ca)
	Chars C_KANJI_JIS_6F69			; 0xe889 (U+6ff6)
	Chars C_KANJI_JIS_6F6A			; 0xe88a (U+95c3)
	Chars C_KANJI_JIS_6F6B			; 0xe88b (U+95cd)
	Chars C_KANJI_JIS_6F6C			; 0xe88c (U+95cc)
	Chars C_KANJI_JIS_6F6D			; 0xe88d (U+95d5)
	Chars C_KANJI_JIS_6F6E			; 0xe88e (U+95d4)
	Chars C_KANJI_JIS_6F6F			; 0xe88f (U+95d6)
	Chars C_KANJI_JIS_6F70			; 0xe890 (U+95dc)
Section95e0Start	label	Chars
	Chars C_KANJI_JIS_6F71			; 0xe891 (U+95e1)
	Chars C_KANJI_JIS_6F72			; 0xe892 (U+95e5)
	Chars C_KANJI_JIS_6F73			; 0xe893 (U+95e2)
	Chars C_KANJI_JIS_6F74			; 0xe894 (U+9621)
	Chars C_KANJI_JIS_6F75			; 0xe895 (U+9628)
	Chars C_KANJI_JIS_6F76			; 0xe896 (U+962e)
	Chars C_KANJI_JIS_6F77			; 0xe897 (U+962f)
	Chars C_KANJI_JIS_6F78			; 0xe898 (U+9642)
	Chars C_KANJI_JIS_6F79			; 0xe899 (U+964c)
	Chars C_KANJI_JIS_6F7A			; 0xe89a (U+964f)
	Chars C_KANJI_JIS_6F7B			; 0xe89b (U+964b)
	Chars C_KANJI_JIS_6F7C			; 0xe89c (U+9677)
	Chars C_KANJI_JIS_6F7D			; 0xe89d (U+965c)
	Chars C_KANJI_JIS_6F7E			; 0xe89e (U+965e)
	Chars C_KANJI_JIS_7021			; 0xe89f (U+965d)
	Chars C_KANJI_JIS_7022			; 0xe8a0 (U+965f)
	Chars C_KANJI_JIS_7023			; 0xe8a1 (U+9666)
	Chars C_KANJI_JIS_7024			; 0xe8a2 (U+9672)
	Chars C_KANJI_JIS_7025			; 0xe8a3 (U+966c)
	Chars C_KANJI_JIS_7026			; 0xe8a4 (U+968d)
	Chars C_KANJI_JIS_7027			; 0xe8a5 (U+9698)
	Chars C_KANJI_JIS_7028			; 0xe8a6 (U+9695)
	Chars C_KANJI_JIS_7029			; 0xe8a7 (U+9697)
	Chars C_KANJI_JIS_702A			; 0xe8a8 (U+96aa)
	Chars C_KANJI_JIS_702B			; 0xe8a9 (U+96a7)
	Chars C_KANJI_JIS_702C			; 0xe8aa (U+96b1)
	Chars C_KANJI_JIS_702D			; 0xe8ab (U+96b2)
	Chars C_KANJI_JIS_702E			; 0xe8ac (U+96b0)
	Chars C_KANJI_JIS_702F			; 0xe8ad (U+96b4)
	Chars C_KANJI_JIS_7030			; 0xe8ae (U+96b6)
	Chars C_KANJI_JIS_7031			; 0xe8af (U+96b8)
	Chars C_KANJI_JIS_7032			; 0xe8b0 (U+96b9)
	Chars C_KANJI_JIS_7033			; 0xe8b1 (U+96ce)
	Chars C_KANJI_JIS_7034			; 0xe8b2 (U+96cb)
	Chars C_KANJI_JIS_7035			; 0xe8b3 (U+96c9)
	Chars C_KANJI_JIS_7036			; 0xe8b4 (U+96cd)
	Chars C_KANJI_JIS_7037			; 0xe8b5 (U+894d)
	Chars C_KANJI_JIS_7038			; 0xe8b6 (U+96dc)
	Chars C_KANJI_JIS_7039			; 0xe8b7 (U+970d)
	Chars C_KANJI_JIS_703A			; 0xe8b8 (U+96d5)
	Chars C_KANJI_JIS_703B			; 0xe8b9 (U+96f9)
	Chars C_KANJI_JIS_703C			; 0xe8ba (U+9704)
	Chars C_KANJI_JIS_703D			; 0xe8bb (U+9706)
	Chars C_KANJI_JIS_703E			; 0xe8bc (U+9708)
	Chars C_KANJI_JIS_703F			; 0xe8bd (U+9713)
	Chars C_KANJI_JIS_7040			; 0xe8be (U+970e)
	Chars C_KANJI_JIS_7041			; 0xe8bf (U+9711)
	Chars C_KANJI_JIS_7042			; 0xe8c0 (U+970f)
	Chars C_KANJI_JIS_7043			; 0xe8c1 (U+9716)
	Chars C_KANJI_JIS_7044			; 0xe8c2 (U+9719)
	Chars C_KANJI_JIS_7045			; 0xe8c3 (U+9724)
	Chars C_KANJI_JIS_7046			; 0xe8c4 (U+972a)
	Chars C_KANJI_JIS_7047			; 0xe8c5 (U+9730)
	Chars C_KANJI_JIS_7048			; 0xe8c6 (U+9739)
	Chars C_KANJI_JIS_7049			; 0xe8c7 (U+973d)
	Chars C_KANJI_JIS_704A			; 0xe8c8 (U+973e)
Section9740Start	label	Chars
	Chars C_KANJI_JIS_704B			; 0xe8c9 (U+9744)
	Chars C_KANJI_JIS_704C			; 0xe8ca (U+9746)
	Chars C_KANJI_JIS_704D			; 0xe8cb (U+9748)
	Chars C_KANJI_JIS_704E			; 0xe8cc (U+9742)
	Chars C_KANJI_JIS_704F			; 0xe8cd (U+9749)
	Chars C_KANJI_JIS_7050			; 0xe8ce (U+975c)
	Chars C_KANJI_JIS_7051			; 0xe8cf (U+9760)
	Chars C_KANJI_JIS_7052			; 0xe8d0 (U+9764)
	Chars C_KANJI_JIS_7053			; 0xe8d1 (U+9766)
	Chars C_KANJI_JIS_7054			; 0xe8d2 (U+9768)
	Chars C_KANJI_JIS_7055			; 0xe8d3 (U+52d2)
	Chars C_KANJI_JIS_7056			; 0xe8d4 (U+976b)
	Chars C_KANJI_JIS_7057			; 0xe8d5 (U+9771)
	Chars C_KANJI_JIS_7058			; 0xe8d6 (U+9779)
	Chars C_KANJI_JIS_7059			; 0xe8d7 (U+9785)
	Chars C_KANJI_JIS_705A			; 0xe8d8 (U+977c)
	Chars C_KANJI_JIS_705B			; 0xe8d9 (U+9781)
	Chars C_KANJI_JIS_705C			; 0xe8da (U+977a)
	Chars C_KANJI_JIS_705D			; 0xe8db (U+9786)
	Chars C_KANJI_JIS_705E			; 0xe8dc (U+978b)
	Chars C_KANJI_JIS_705F			; 0xe8dd (U+978f)
	Chars C_KANJI_JIS_7060			; 0xe8de (U+9790)
	Chars C_KANJI_JIS_7061			; 0xe8df (U+979c)
	Chars C_KANJI_JIS_7062			; 0xe8e0 (U+97a8)
	Chars C_KANJI_JIS_7063			; 0xe8e1 (U+97a6)
	Chars C_KANJI_JIS_7064			; 0xe8e2 (U+97a3)
Section97b0Start	label	Chars
	Chars C_KANJI_JIS_7065			; 0xe8e3 (U+97b3)
	Chars C_KANJI_JIS_7066			; 0xe8e4 (U+97b4)
Section97c0Start	label	Chars
	Chars C_KANJI_JIS_7067			; 0xe8e5 (U+97c3)
	Chars C_KANJI_JIS_7068			; 0xe8e6 (U+97c6)
	Chars C_KANJI_JIS_7069			; 0xe8e7 (U+97c8)
	Chars C_KANJI_JIS_706A			; 0xe8e8 (U+97cb)
	Chars C_KANJI_JIS_706B			; 0xe8e9 (U+97dc)
	Chars C_KANJI_JIS_706C			; 0xe8ea (U+97ed)
	Chars C_KANJI_JIS_706D			; 0xe8eb (U+9f4f)
	Chars C_KANJI_JIS_706E			; 0xe8ec (U+97f2)
	Chars C_KANJI_JIS_706F			; 0xe8ed (U+7adf)
	Chars C_KANJI_JIS_7070			; 0xe8ee (U+97f6)
	Chars C_KANJI_JIS_7071			; 0xe8ef (U+97f5)
	Chars C_KANJI_JIS_7072			; 0xe8f0 (U+980f)
	Chars C_KANJI_JIS_7073			; 0xe8f1 (U+980c)
	Chars C_KANJI_JIS_7074			; 0xe8f2 (U+9838)
	Chars C_KANJI_JIS_7075			; 0xe8f3 (U+9824)
	Chars C_KANJI_JIS_7076			; 0xe8f4 (U+9821)
	Chars C_KANJI_JIS_7077			; 0xe8f5 (U+9837)
	Chars C_KANJI_JIS_7078			; 0xe8f6 (U+983d)
	Chars C_KANJI_JIS_7079			; 0xe8f7 (U+9846)
	Chars C_KANJI_JIS_707A			; 0xe8f8 (U+984f)
	Chars C_KANJI_JIS_707B			; 0xe8f9 (U+984b)
	Chars C_KANJI_JIS_707C			; 0xe8fa (U+986b)
	Chars C_KANJI_JIS_707D			; 0xe8fb (U+986f)
Section9870Start	label	Chars
	Chars C_KANJI_JIS_707E			; 0xe8fc (U+9870)
	Chars 0					; 0xe8fd
	Chars 0					; 0xe8fe
	Chars 0					; 0xe8ff

	Chars C_KANJI_JIS_7121			; 0xe940 (U+9871)
	Chars C_KANJI_JIS_7122			; 0xe941 (U+9874)
	Chars C_KANJI_JIS_7123			; 0xe942 (U+9873)
	Chars C_KANJI_JIS_7124			; 0xe943 (U+98aa)
	Chars C_KANJI_JIS_7125			; 0xe944 (U+98af)
Section98b0Start	label	Chars
	Chars C_KANJI_JIS_7126			; 0xe945 (U+98b1)
	Chars C_KANJI_JIS_7127			; 0xe946 (U+98b6)
Section98c0Start	label	Chars
	Chars C_KANJI_JIS_7128			; 0xe947 (U+98c4)
	Chars C_KANJI_JIS_7129			; 0xe948 (U+98c3)
	Chars C_KANJI_JIS_712A			; 0xe949 (U+98c6)
	Chars C_KANJI_JIS_712B			; 0xe94a (U+98e9)
	Chars C_KANJI_JIS_712C			; 0xe94b (U+98eb)
	Chars C_KANJI_JIS_712D			; 0xe94c (U+9903)
	Chars C_KANJI_JIS_712E			; 0xe94d (U+9909)
	Chars C_KANJI_JIS_712F			; 0xe94e (U+9912)
	Chars C_KANJI_JIS_7130			; 0xe94f (U+9914)
	Chars C_KANJI_JIS_7131			; 0xe950 (U+9918)
	Chars C_KANJI_JIS_7132			; 0xe951 (U+9921)
	Chars C_KANJI_JIS_7133			; 0xe952 (U+991d)
	Chars C_KANJI_JIS_7134			; 0xe953 (U+991e)
	Chars C_KANJI_JIS_7135			; 0xe954 (U+9924)
	Chars C_KANJI_JIS_7136			; 0xe955 (U+9920)
	Chars C_KANJI_JIS_7137			; 0xe956 (U+992c)
	Chars C_KANJI_JIS_7138			; 0xe957 (U+992e)
Section9930Start	label	Chars
	Chars C_KANJI_JIS_7139			; 0xe958 (U+993d)
	Chars C_KANJI_JIS_713A			; 0xe959 (U+993e)
Section9940Start	label	Chars
	Chars C_KANJI_JIS_713B			; 0xe95a (U+9942)
	Chars C_KANJI_JIS_713C			; 0xe95b (U+9949)
	Chars C_KANJI_JIS_713D			; 0xe95c (U+9945)
	Chars C_KANJI_JIS_713E			; 0xe95d (U+9950)
	Chars C_KANJI_JIS_713F			; 0xe95e (U+994b)
	Chars C_KANJI_JIS_7140			; 0xe95f (U+9951)
	Chars C_KANJI_JIS_7141			; 0xe960 (U+9952)
	Chars C_KANJI_JIS_7142			; 0xe961 (U+994c)
	Chars C_KANJI_JIS_7143			; 0xe962 (U+9955)
	Chars C_KANJI_JIS_7144			; 0xe963 (U+9997)
	Chars C_KANJI_JIS_7145			; 0xe964 (U+9998)
	Chars C_KANJI_JIS_7146			; 0xe965 (U+99a5)
	Chars C_KANJI_JIS_7147			; 0xe966 (U+99ad)
	Chars C_KANJI_JIS_7148			; 0xe967 (U+99ae)
	Chars C_KANJI_JIS_7149			; 0xe968 (U+99bc)
	Chars C_KANJI_JIS_714A			; 0xe969 (U+99df)
	Chars C_KANJI_JIS_714B			; 0xe96a (U+99db)
	Chars C_KANJI_JIS_714C			; 0xe96b (U+99dd)
	Chars C_KANJI_JIS_714D			; 0xe96c (U+99d8)
	Chars C_KANJI_JIS_714E			; 0xe96d (U+99d1)
Section99e0Start	label	Chars
	Chars C_KANJI_JIS_714F			; 0xe96e (U+99ed)
	Chars C_KANJI_JIS_7150			; 0xe96f (U+99ee)
	Chars C_KANJI_JIS_7151			; 0xe970 (U+99f1)
	Chars C_KANJI_JIS_7152			; 0xe971 (U+99f2)
	Chars C_KANJI_JIS_7153			; 0xe972 (U+99fb)
	Chars C_KANJI_JIS_7154			; 0xe973 (U+99f8)
	Chars C_KANJI_JIS_7155			; 0xe974 (U+9a01)
	Chars C_KANJI_JIS_7156			; 0xe975 (U+9a0f)
	Chars C_KANJI_JIS_7157			; 0xe976 (U+9a05)
	Chars C_KANJI_JIS_7158			; 0xe977 (U+99e2)
	Chars C_KANJI_JIS_7159			; 0xe978 (U+9a19)
	Chars C_KANJI_JIS_715A			; 0xe979 (U+9a2b)
	Chars C_KANJI_JIS_715B			; 0xe97a (U+9a37)
Section9a40Start	label	Chars
	Chars C_KANJI_JIS_715C			; 0xe97b (U+9a45)
	Chars C_KANJI_JIS_715D			; 0xe97c (U+9a42)
	Chars C_KANJI_JIS_715E			; 0xe97d (U+9a40)
	Chars C_KANJI_JIS_715F			; 0xe97e (U+9a43)
	Chars 0					; 0xe97f
	Chars C_KANJI_JIS_7160			; 0xe980 (U+9a3e)
	Chars C_KANJI_JIS_7161			; 0xe981 (U+9a55)
	Chars C_KANJI_JIS_7162			; 0xe982 (U+9a4d)
	Chars C_KANJI_JIS_7163			; 0xe983 (U+9a5b)
	Chars C_KANJI_JIS_7164			; 0xe984 (U+9a57)
	Chars C_KANJI_JIS_7165			; 0xe985 (U+9a5f)
Section9a60Start	label	Chars
	Chars C_KANJI_JIS_7166			; 0xe986 (U+9a62)
	Chars C_KANJI_JIS_7167			; 0xe987 (U+9a65)
	Chars C_KANJI_JIS_7168			; 0xe988 (U+9a64)
	Chars C_KANJI_JIS_7169			; 0xe989 (U+9a69)
	Chars C_KANJI_JIS_716A			; 0xe98a (U+9a6b)
	Chars C_KANJI_JIS_716B			; 0xe98b (U+9a6a)
	Chars C_KANJI_JIS_716C			; 0xe98c (U+9aad)
	Chars C_KANJI_JIS_716D			; 0xe98d (U+9ab0)
	Chars C_KANJI_JIS_716E			; 0xe98e (U+9abc)
	Chars C_KANJI_JIS_716F			; 0xe98f (U+9ac0)
	Chars C_KANJI_JIS_7170			; 0xe990 (U+9acf)
	Chars C_KANJI_JIS_7171			; 0xe991 (U+9ad1)
	Chars C_KANJI_JIS_7172			; 0xe992 (U+9ad3)
	Chars C_KANJI_JIS_7173			; 0xe993 (U+9ad4)
	Chars C_KANJI_JIS_7174			; 0xe994 (U+9ade)
	Chars C_KANJI_JIS_7175			; 0xe995 (U+9adf)
	Chars C_KANJI_JIS_7176			; 0xe996 (U+9ae2)
	Chars C_KANJI_JIS_7177			; 0xe997 (U+9ae3)
	Chars C_KANJI_JIS_7178			; 0xe998 (U+9ae6)
	Chars C_KANJI_JIS_7179			; 0xe999 (U+9aef)
	Chars C_KANJI_JIS_717A			; 0xe99a (U+9aeb)
	Chars C_KANJI_JIS_717B			; 0xe99b (U+9aee)
Section9af0Start	label	Chars
	Chars C_KANJI_JIS_717C			; 0xe99c (U+9af4)
	Chars C_KANJI_JIS_717D			; 0xe99d (U+9af1)
	Chars C_KANJI_JIS_717E			; 0xe99e (U+9af7)
	Chars C_KANJI_JIS_7221			; 0xe99f (U+9afb)
Section9b00Start	label	Chars
	Chars C_KANJI_JIS_7222			; 0xe9a0 (U+9b06)
Section9b10Start	label	Chars
	Chars C_KANJI_JIS_7223			; 0xe9a1 (U+9b18)
	Chars C_KANJI_JIS_7224			; 0xe9a2 (U+9b1a)
	Chars C_KANJI_JIS_7225			; 0xe9a3 (U+9b1f)
Section9b20Start	label	Chars
	Chars C_KANJI_JIS_7226			; 0xe9a4 (U+9b22)
	Chars C_KANJI_JIS_7227			; 0xe9a5 (U+9b23)
	Chars C_KANJI_JIS_7228			; 0xe9a6 (U+9b25)
	Chars C_KANJI_JIS_7229			; 0xe9a7 (U+9b27)
	Chars C_KANJI_JIS_722A			; 0xe9a8 (U+9b28)
	Chars C_KANJI_JIS_722B			; 0xe9a9 (U+9b29)
	Chars C_KANJI_JIS_722C			; 0xe9aa (U+9b2a)
	Chars C_KANJI_JIS_722D			; 0xe9ab (U+9b2e)
	Chars C_KANJI_JIS_722E			; 0xe9ac (U+9b2f)
	Chars C_KANJI_JIS_722F			; 0xe9ad (U+9b32)
	Chars C_KANJI_JIS_7230			; 0xe9ae (U+9b44)
	Chars C_KANJI_JIS_7231			; 0xe9af (U+9b43)
	Chars C_KANJI_JIS_7232			; 0xe9b0 (U+9b4f)
	Chars C_KANJI_JIS_7233			; 0xe9b1 (U+9b4d)
	Chars C_KANJI_JIS_7234			; 0xe9b2 (U+9b4e)
	Chars C_KANJI_JIS_7235			; 0xe9b3 (U+9b51)
	Chars C_KANJI_JIS_7236			; 0xe9b4 (U+9b58)
Section9b70Start	label	Chars
	Chars C_KANJI_JIS_7237			; 0xe9b5 (U+9b74)
	Chars C_KANJI_JIS_7238			; 0xe9b6 (U+9b93)
	Chars C_KANJI_JIS_7239			; 0xe9b7 (U+9b83)
	Chars C_KANJI_JIS_723A			; 0xe9b8 (U+9b91)
	Chars C_KANJI_JIS_723B			; 0xe9b9 (U+9b96)
	Chars C_KANJI_JIS_723C			; 0xe9ba (U+9b97)
	Chars C_KANJI_JIS_723D			; 0xe9bb (U+9b9f)
	Chars C_KANJI_JIS_723E			; 0xe9bc (U+9ba0)
	Chars C_KANJI_JIS_723F			; 0xe9bd (U+9ba8)
Section9bb0Start	label	Chars
	Chars C_KANJI_JIS_7240			; 0xe9be (U+9bb4)
	Chars C_KANJI_JIS_7241			; 0xe9bf (U+9bc0)
	Chars C_KANJI_JIS_7242			; 0xe9c0 (U+9bca)
	Chars C_KANJI_JIS_7243			; 0xe9c1 (U+9bb9)
	Chars C_KANJI_JIS_7244			; 0xe9c2 (U+9bc6)
	Chars C_KANJI_JIS_7245			; 0xe9c3 (U+9bcf)
	Chars C_KANJI_JIS_7246			; 0xe9c4 (U+9bd1)
	Chars C_KANJI_JIS_7247			; 0xe9c5 (U+9bd2)
	Chars C_KANJI_JIS_7248			; 0xe9c6 (U+9be3)
	Chars C_KANJI_JIS_7249			; 0xe9c7 (U+9be2)
	Chars C_KANJI_JIS_724A			; 0xe9c8 (U+9be4)
	Chars C_KANJI_JIS_724B			; 0xe9c9 (U+9bd4)
	Chars C_KANJI_JIS_724C			; 0xe9ca (U+9be1)
	Chars C_KANJI_JIS_724D			; 0xe9cb (U+9c3a)
	Chars C_KANJI_JIS_724E			; 0xe9cc (U+9bf2)
	Chars C_KANJI_JIS_724F			; 0xe9cd (U+9bf1)
	Chars C_KANJI_JIS_7250			; 0xe9ce (U+9bf0)
	Chars C_KANJI_JIS_7251			; 0xe9cf (U+9c15)
	Chars C_KANJI_JIS_7252			; 0xe9d0 (U+9c14)
	Chars C_KANJI_JIS_7253			; 0xe9d1 (U+9c09)
	Chars C_KANJI_JIS_7254			; 0xe9d2 (U+9c13)
	Chars C_KANJI_JIS_7255			; 0xe9d3 (U+9c0c)
	Chars C_KANJI_JIS_7256			; 0xe9d4 (U+9c06)
	Chars C_KANJI_JIS_7257			; 0xe9d5 (U+9c08)
	Chars C_KANJI_JIS_7258			; 0xe9d6 (U+9c12)
	Chars C_KANJI_JIS_7259			; 0xe9d7 (U+9c0a)
	Chars C_KANJI_JIS_725A			; 0xe9d8 (U+9c04)
	Chars C_KANJI_JIS_725B			; 0xe9d9 (U+9c2e)
	Chars C_KANJI_JIS_725C			; 0xe9da (U+9c1b)
	Chars C_KANJI_JIS_725D			; 0xe9db (U+9c25)
	Chars C_KANJI_JIS_725E			; 0xe9dc (U+9c24)
	Chars C_KANJI_JIS_725F			; 0xe9dd (U+9c21)
	Chars C_KANJI_JIS_7260			; 0xe9de (U+9c30)
	Chars C_KANJI_JIS_7261			; 0xe9df (U+9c47)
	Chars C_KANJI_JIS_7262			; 0xe9e0 (U+9c32)
	Chars C_KANJI_JIS_7263			; 0xe9e1 (U+9c46)
	Chars C_KANJI_JIS_7264			; 0xe9e2 (U+9c3e)
	Chars C_KANJI_JIS_7265			; 0xe9e3 (U+9c5a)
Section9c60Start	label	Chars
	Chars C_KANJI_JIS_7266			; 0xe9e4 (U+9c60)
	Chars C_KANJI_JIS_7267			; 0xe9e5 (U+9c67)
Section9c70Start	label	Chars
	Chars C_KANJI_JIS_7268			; 0xe9e6 (U+9c76)
	Chars C_KANJI_JIS_7269			; 0xe9e7 (U+9c78)
	Chars C_KANJI_JIS_726A			; 0xe9e8 (U+9ce7)
	Chars C_KANJI_JIS_726B			; 0xe9e9 (U+9cec)
	Chars C_KANJI_JIS_726C			; 0xe9ea (U+9cf0)
	Chars C_KANJI_JIS_726D			; 0xe9eb (U+9d09)
	Chars C_KANJI_JIS_726E			; 0xe9ec (U+9d08)
	Chars C_KANJI_JIS_726F			; 0xe9ed (U+9ceb)
	Chars C_KANJI_JIS_7270			; 0xe9ee (U+9d03)
	Chars C_KANJI_JIS_7271			; 0xe9ef (U+9d06)
	Chars C_KANJI_JIS_7272			; 0xe9f0 (U+9d2a)
	Chars C_KANJI_JIS_7273			; 0xe9f1 (U+9d26)
Section9da0Start	label	Chars
	Chars C_KANJI_JIS_7274			; 0xe9f2 (U+9daf)
	Chars C_KANJI_JIS_7275			; 0xe9f3 (U+9d23)
	Chars C_KANJI_JIS_7276			; 0xe9f4 (U+9d1f)
Section9d40Start	label	Chars
	Chars C_KANJI_JIS_7277			; 0xe9f5 (U+9d44)
	Chars C_KANJI_JIS_7278			; 0xe9f6 (U+9d15)
	Chars C_KANJI_JIS_7279			; 0xe9f7 (U+9d12)
	Chars C_KANJI_JIS_727A			; 0xe9f8 (U+9d41)
	Chars C_KANJI_JIS_727B			; 0xe9f9 (U+9d3f)
	Chars C_KANJI_JIS_727C			; 0xe9fa (U+9d3e)
	Chars C_KANJI_JIS_727D			; 0xe9fb (U+9d46)
	Chars C_KANJI_JIS_727E			; 0xe9fc (U+9d48)
	Chars 0					; 0xe9fd
	Chars 0					; 0xe9fe
	Chars 0					; 0xe9ff

	Chars C_KANJI_JIS_7321			; 0xea40 (U+9d5d)
	Chars C_KANJI_JIS_7322			; 0xea41 (U+9d5e)
	Chars C_KANJI_JIS_7323			; 0xea42 (U+9d64)
	Chars C_KANJI_JIS_7324			; 0xea43 (U+9d51)
	Chars C_KANJI_JIS_7325			; 0xea44 (U+9d50)
	Chars C_KANJI_JIS_7326			; 0xea45 (U+9d59)
Section9d70Start	label	Chars
	Chars C_KANJI_JIS_7327			; 0xea46 (U+9d72)
	Chars C_KANJI_JIS_7328			; 0xea47 (U+9d89)
	Chars C_KANJI_JIS_7329			; 0xea48 (U+9d87)
	Chars C_KANJI_JIS_732A			; 0xea49 (U+9dab)
	Chars C_KANJI_JIS_732B			; 0xea4a (U+9d6f)
	Chars C_KANJI_JIS_732C			; 0xea4b (U+9d7a)
Section9d90Start	label	Chars
	Chars C_KANJI_JIS_732D			; 0xea4c (U+9d9a)
	Chars C_KANJI_JIS_732E			; 0xea4d (U+9da4)
	Chars C_KANJI_JIS_732F			; 0xea4e (U+9da9)
	Chars C_KANJI_JIS_7330			; 0xea4f (U+9db2)
Section9dc0Start	label	Chars
	Chars C_KANJI_JIS_7331			; 0xea50 (U+9dc4)
	Chars C_KANJI_JIS_7332			; 0xea51 (U+9dc1)
	Chars C_KANJI_JIS_7333			; 0xea52 (U+9dbb)
	Chars C_KANJI_JIS_7334			; 0xea53 (U+9db8)
	Chars C_KANJI_JIS_7335			; 0xea54 (U+9dba)
	Chars C_KANJI_JIS_7336			; 0xea55 (U+9dc6)
	Chars C_KANJI_JIS_7337			; 0xea56 (U+9dcf)
	Chars C_KANJI_JIS_7338			; 0xea57 (U+9dc2)
Section9dd0Start	label	Chars
	Chars C_KANJI_JIS_7339			; 0xea58 (U+9dd9)
	Chars C_KANJI_JIS_733A			; 0xea59 (U+9dd3)
	Chars C_KANJI_JIS_733B			; 0xea5a (U+9df8)
Section9de0Start	label	Chars
	Chars C_KANJI_JIS_733C			; 0xea5b (U+9de6)
	Chars C_KANJI_JIS_733D			; 0xea5c (U+9ded)
	Chars C_KANJI_JIS_733E			; 0xea5d (U+9def)
	Chars C_KANJI_JIS_733F			; 0xea5e (U+9dfd)
Section9e10Start	label	Chars
	Chars C_KANJI_JIS_7340			; 0xea5f (U+9e1a)
	Chars C_KANJI_JIS_7341			; 0xea60 (U+9e1b)
	Chars C_KANJI_JIS_7342			; 0xea61 (U+9e1e)
	Chars C_KANJI_JIS_7343			; 0xea62 (U+9e75)
	Chars C_KANJI_JIS_7344			; 0xea63 (U+9e79)
	Chars C_KANJI_JIS_7345			; 0xea64 (U+9e7d)
Section9e80Start	label	Chars
	Chars C_KANJI_JIS_7346			; 0xea65 (U+9e81)
	Chars C_KANJI_JIS_7347			; 0xea66 (U+9e88)
	Chars C_KANJI_JIS_7348			; 0xea67 (U+9e8b)
	Chars C_KANJI_JIS_7349			; 0xea68 (U+9e8c)
	Chars C_KANJI_JIS_734A			; 0xea69 (U+9e92)
	Chars C_KANJI_JIS_734B			; 0xea6a (U+9e95)
	Chars C_KANJI_JIS_734C			; 0xea6b (U+9e91)
	Chars C_KANJI_JIS_734D			; 0xea6c (U+9e9d)
	Chars C_KANJI_JIS_734E			; 0xea6d (U+9ea5)
	Chars C_KANJI_JIS_734F			; 0xea6e (U+9ea9)
	Chars C_KANJI_JIS_7350			; 0xea6f (U+9eb8)
	Chars C_KANJI_JIS_7351			; 0xea70 (U+9eaa)
	Chars C_KANJI_JIS_7352			; 0xea71 (U+9ead)
	Chars C_KANJI_JIS_7353			; 0xea72 (U+9761)
	Chars C_KANJI_JIS_7354			; 0xea73 (U+9ecc)
	Chars C_KANJI_JIS_7355			; 0xea74 (U+9ece)
	Chars C_KANJI_JIS_7356			; 0xea75 (U+9ecf)
	Chars C_KANJI_JIS_7357			; 0xea76 (U+9ed0)
	Chars C_KANJI_JIS_7358			; 0xea77 (U+9ed4)
	Chars C_KANJI_JIS_7359			; 0xea78 (U+9edc)
	Chars C_KANJI_JIS_735A			; 0xea79 (U+9ede)
	Chars C_KANJI_JIS_735B			; 0xea7a (U+9edd)
Section9ee0Start	label	Chars
	Chars C_KANJI_JIS_735C			; 0xea7b (U+9ee0)
	Chars C_KANJI_JIS_735D			; 0xea7c (U+9ee5)
	Chars C_KANJI_JIS_735E			; 0xea7d (U+9ee8)
	Chars C_KANJI_JIS_735F			; 0xea7e (U+9eef)
	Chars 0					; 0xea7f
Section9ef0Start	label	Chars
	Chars C_KANJI_JIS_7360			; 0xea80 (U+9ef4)
	Chars C_KANJI_JIS_7361			; 0xea81 (U+9ef6)
	Chars C_KANJI_JIS_7362			; 0xea82 (U+9ef7)
	Chars C_KANJI_JIS_7363			; 0xea83 (U+9ef9)
	Chars C_KANJI_JIS_7364			; 0xea84 (U+9efb)
	Chars C_KANJI_JIS_7365			; 0xea85 (U+9efc)
	Chars C_KANJI_JIS_7366			; 0xea86 (U+9efd)
	Chars C_KANJI_JIS_7367			; 0xea87 (U+9f07)
	Chars C_KANJI_JIS_7368			; 0xea88 (U+9f08)
	Chars C_KANJI_JIS_7369			; 0xea89 (U+76b7)
	Chars C_KANJI_JIS_736A			; 0xea8a (U+9f15)
	Chars C_KANJI_JIS_736B			; 0xea8b (U+9f21)
	Chars C_KANJI_JIS_736C			; 0xea8c (U+9f2c)
	Chars C_KANJI_JIS_736D			; 0xea8d (U+9f3e)
	Chars C_KANJI_JIS_736E			; 0xea8e (U+9f4a)
Section9f50Start	label	Chars
	Chars C_KANJI_JIS_736F			; 0xea8f (U+9f52)
	Chars C_KANJI_JIS_7370			; 0xea90 (U+9f54)
	Chars C_KANJI_JIS_7371			; 0xea91 (U+9f63)
	Chars C_KANJI_JIS_7372			; 0xea92 (U+9f5f)
	Chars C_KANJI_JIS_7373			; 0xea93 (U+9f60)
	Chars C_KANJI_JIS_7374			; 0xea94 (U+9f61)
	Chars C_KANJI_JIS_7375			; 0xea95 (U+9f66)
	Chars C_KANJI_JIS_7376			; 0xea96 (U+9f67)
	Chars C_KANJI_JIS_7377			; 0xea97 (U+9f6c)
	Chars C_KANJI_JIS_7378			; 0xea98 (U+9f6a)
Section9f70Start	label	Chars
	Chars C_KANJI_JIS_7379			; 0xea99 (U+9f77)
	Chars C_KANJI_JIS_737A			; 0xea9a (U+9f72)
	Chars C_KANJI_JIS_737B			; 0xea9b (U+9f76)
	Chars C_KANJI_JIS_737C			; 0xea9c (U+9f95)
	Chars C_KANJI_JIS_737D			; 0xea9d (U+9f9c)
Section9fa0Start	label	Chars
	Chars C_KANJI_JIS_737E			; 0xea9e (U+9fa0)
	Chars C_KANJI_JIS_7421			; 0xea9f (U+582f)
	Chars C_KANJI_JIS_7422			; 0xeaa0 (U+69c7)
	Chars C_KANJI_JIS_7423			; 0xeaa1 (U+9059)
	Chars C_KANJI_JIS_7424			; 0xeaa2 (U+7464)
	Chars C_KANJI_JIS_7425			; 0xeaa3 (U+51dc)
	Chars C_KANJI_JIS_7426			; 0xeaa4 (U+7199)
	Chars 0					; 0xeaa5
	Chars 0					; 0xeaa6
	Chars 0					; 0xeaa7
	Chars 0					; 0xeaa8
	Chars 0					; 0xeaa9
	Chars 0					; 0xeaaa
	Chars 0					; 0xeaab
	Chars 0					; 0xeaac
	Chars 0					; 0xeaad
	Chars 0					; 0xeaae
EndSJISKanjiToUnicodeTable	label	Chars


Resident	ends
