scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:modules = [
\	'BufferComplete',
\	'Cancel',
\	'CursorMove',
\	'Delete',
\	'Enter',
\	'ExecuteFailedMessage',
\	'HighlightBufferCursor',
\	'HistAdd',
\	'History',
\	'Incsearch',
\	'InsertRegister',
\	'KeyMapping',
\	'NoInsert',
\	'Paste',
\	'Scroll',
\	'Doautocmd'
\]


function! s:_vital_depends()
	return map(copy(s:modules), "'Over.Commandline.Modules.' . v:val")
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
