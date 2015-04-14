scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim
let s:obj = {}


function! s:obj.get()
	return eval(self.__name)
endfunction


function! s:obj.set(value)
	execute "let " . self.__name . " = a:value"
	return self
endfunction


function! s:is_makeable(rhs)
	return type(a:rhs) == type("")
\		&& a:rhs =~ '^[a-zA-Z&]'
\		&& exists(a:rhs)
endfunction


function! s:make(name)
	let result = deepcopy(s:obj)
	let result.__name = a:name
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
