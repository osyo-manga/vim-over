scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_as_list(value)
	return type(a:value) ==  type([]) ? a:value : [a:value]
endfunction

let s:obj = {}

function! s:obj.lock()
	call map(copy(self.__rockers), "v:val.lock()")
	return self
endfunction


function! s:obj.unlock()
	call map(copy(self.__rockers), "v:val.unlock()")
endfunction


function! s:obj.relock()
	call map(copy(self.__rockers), "v:val.relock()")
endfunction


function! s:make(rockers)
	let result = deepcopy(s:obj)
	let result.__rockers = s:_as_list(a:rockers)
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
