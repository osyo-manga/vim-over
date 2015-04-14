scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim
let s:obj = {}



function! s:_vital_loaded(V)
	let s:Buffer = a:V.import("Coaster.Buffer")
endfunction


function! s:_vital_depends()
	return [
\		"Coaster.Buffer",
\	]
endfunction



function! s:obj.get()
	return getbufline(self.__expr, self.__lnum, self.__end)
endfunction


function! s:obj.set(value)
	if bufnr(self.__expr) == bufnr("%")
		call setline(self.__lnum, a:value)
	else
		call s:Buffer.setbufline(self.__expr, self.__lnum, a:value)
	endif
	return self
endfunction


function! s:is_makeable(rhs)
	return bufexists(a:rhs)
endfunction


function! s:make(expr, ...)
	let result = deepcopy(s:obj)
	let result.__expr = a:expr
	let result.__lnum = get(a:, 1, 1)
	let result.__end  = get(a:, 2, "$")
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
