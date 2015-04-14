scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim
let s:obj = {}


function! s:obj.get()
	execute "wundo!" self.__file
	return self.__file
endfunction


function! s:obj.set(value)
	if filereadable(a:value)
		silent execute "rundo" a:value
	else
		throw "vital-unlocker Unlocker.Holder.Buffer.Undofile : No filereadable '" . a:value . "'."
	endif
	return self
endfunction


function! s:is_makeable(rhs)
	return filereadable(a:rhs)
endfunction


function! s:make(...)
	let result = deepcopy(s:obj)
	let result.__file = get(a:, 1, tempname())
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
