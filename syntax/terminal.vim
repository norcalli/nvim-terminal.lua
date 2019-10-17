" Start: Standard vim script cruft {{{2
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf8
if version < 600
    syn clear
elseif exists("b:current_syntax")
    finish
endif

" I've been debating whether or not to enumerate the possibilities or just hide
" them all with ^[\[[0-9:;]*m, because it might overshadow cases I don't cover,
" but I think that concealing anyway is a good idea.
syn match TerminalCSIColorCode /\[[:;0-9]*m/ conceal

" Set the syntax variable
let b:current_syntax="terminal"

" End: Standard vim script cruft {{{2
let &cpo = s:cpo_save
unlet s:cpo_save

