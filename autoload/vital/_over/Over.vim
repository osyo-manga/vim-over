scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:error(text)
	echohl ErrorMsg
	echom "vital-over:" . a:text
	echohl None
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
