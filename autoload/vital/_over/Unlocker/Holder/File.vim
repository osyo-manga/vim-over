scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:obj = {}

function! s:obj.get()
	return readfile(self.__file)
endfunction


function! s:obj.set(value)
	call writefile(a:value, self.__file)
	return self
endfunction


function! s:is_makeable(expr)
	return filereadable(a:expr)
endfunction


function! s:make(expr)
	let result = deepcopy(s:obj)
	let result.__file = a:expr
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
