" Start: Standard vim script cruft {{{2
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf8
if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

" Simple syntax highlighting for UnicodeTable command {{{2
syn match TerminalCSIColorCode1 /\[\d\+m/ conceal
syn match TerminalCSIColorCode2 /\[\d\+\(;\d\+\)\+m/ conceal

" Set the syntax variable
let b:current_syntax="terminal"

" End: Standard vim script cruft {{{2
let &cpo = s:cpo_save
unlet s:cpo_save

