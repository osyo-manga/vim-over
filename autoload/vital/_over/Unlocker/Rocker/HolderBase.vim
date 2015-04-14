scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:locker = {}
function! s:locker.lock()
	let self.__old = self.get()
	return self
endfunction


function! s:locker.unlock()
	if !has_key(self, "__old")
		return -1
	endif
	call self.set(self.__old)
	unlet self.__old
endfunction


function! s:locker.relock()
	call self.unlock()
	call self.lock()
endfunction


function! s:has_concept(obj)
	return type(a:obj) == type({})
\		&& type(get(a:obj, "get", "")) == type(function("tr"))
\		&& type(get(a:obj, "set", "")) == type(function("tr"))
endfunction


function! s:make(derived)
	if !s:has_concept(a:derived)
		throw "vital-unlocker Unlocker.Rocker.HolderBase.make() : Don't has locker concept."
	endif
	let result = extend(deepcopy(s:locker), a:derived)
	return result
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
