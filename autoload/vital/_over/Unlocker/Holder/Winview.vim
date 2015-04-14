scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:obj = {}

function! s:obj.get()
	return winsaveview()
endfunction


function! s:obj.set(value)
	call winrestview(a:value)
	return self
endfunction


function! s:is_makeable(expr)
	return 0
endfunction


function! s:make()
	let result = deepcopy(s:obj)
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
