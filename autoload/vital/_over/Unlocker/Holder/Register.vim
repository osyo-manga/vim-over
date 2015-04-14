scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:obj = {}

function! s:obj.get()
	return getreg(self.__name)
endfunction


function! s:obj.set(value)
	if self.__option == ""
		call setreg(self.__name, a:value)
	else
		call setreg(self.__name, a:value, self.__option)
	endif
	return self
endfunction


function! s:is_makeable(expr)
	return type(a:expr) == type("") && a:expr =~# '^@.\+'
endfunction


function! s:make(expr, ...)
	let result = deepcopy(s:obj)
	let result.__name = (strlen(a:expr) == 1 ? a:expr : a:expr[1:])
	let result.__option = get(a:, 1, "")
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
