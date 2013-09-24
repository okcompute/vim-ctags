NOTE: This plugin is obsolete. I personaly don't use it anymore. I have found a better way using git hooks to generate tags. I'm keeping the repository for the history.

Automatic generation of tags file (Exhuberant Ctags)

Description:
============

This script look for .ctags file in the current
directory hiearchy up to the root and build the tags file 
when one is found. This process is executed only for the 
first file opened in the whole directory tree. 

Notes:
======

- Combine this plugin and the AutoTags plugin and you won't
need to think about generating tags anymore.
- For further details on the .ctags file, see Exhuberant Ctags
  documentations.

Requirements:
============

Exhuberant Ctags must be installed on your system.
