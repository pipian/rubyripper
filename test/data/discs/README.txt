All sample testdata

Sample discs
001: No disc in drive
002: Wrong parameters
003: Not existing drive
004: A pure audio disc
005: An audio disc with a data track at the end
006: An audio disc with CD-TEXT
007: An audio disc with a hidden part before track 1 TODO
008: An audio disc with a data track at the start TODO

Each directory has files for:
* cdparanoia (cdparanoia -vQ -d /dev/cdrom)
* cd-info (cd-info -C /dev/cdrom)
* cdrdao (cdrdao read-toc --device /dev/cdrom cdrdao)
