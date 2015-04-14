scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_as_list(value)
	return type(a:value) ==  type([]) ? a:value : [a:value]
endfunction

let s:obj = {}

function! s:obj.get()
	return map(copy(self.__holders), "v:val.get()")
endfunction


function! s:obj.set(values)
	call map(copy(self.__holders), "v:val.set(a:values[v:key])")
	return self
endfunction


function! s:make(holders)
	let result = deepcopy(s:obj)
	let result.__holders = s:_as_list(a:holders)
	return result
endfunction





let &cpo = s:save_cpo
unlet s:save_cpo
