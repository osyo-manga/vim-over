scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! over#command_line#substitute#load()
	" load
endfunction


function! s:init()
	let s:undo_flag = 0
	let s:old_pos = getpos(".")
	let s:old_scrolloff = &scrolloff
	let &scrolloff = 0
	let s:old_conceallevel = &l:conceallevel
	let &l:conceallevel = 3
	let s:old_concealcursor = &l:concealcursor
	let &l:concealcursor = "nvic"

	syntax match OverCmdLineSubstituteHiddenBegin  '`os`' conceal containedin=ALL
	syntax match OverCmdLineSubstituteHiddenMiddle '`om`' conceal containedin=ALL
	syntax match OverCmdLineSubstituteHiddenEnd    '`oe`' conceal containedin=ALL
endfunction


function! s:finish()
	call s:reset_match()
	call setpos(".", s:old_pos)
	let &scrolloff = s:old_scrolloff
	let &l:conceallevel = s:old_conceallevel
	let &l:concealcursor = s:old_concealcursor
	highlight link OverCmdLineSubstitute NONE
	highlight link OverCmdLineSubstitutePattern NONE
	highlight link OverCmdLineSubstituteString  NONE
endfunction


function! s:silent_undo()
	let pos = getpos(".")
	redir => _
	silent undo
	redir END
	call setpos(".", pos)
endfunction


function! s:undo()
	if s:undo_flag
		call s:silent_undo()
	endif
endfunction


let s:matchlist = []
function! s:reset_match()
	for id in s:matchlist
		if id != -1
			call matchdelete(id)
		endif
	endfor
	let s:matchlist = []
endfunction


function! s:silent_substitute(range, pattern, string, flags)
	try
		let old_pos = getpos(".")
		silent execute printf('%ss/%s/%s/%s', a:range, a:pattern, a:string, a:flags)
		call histdel("search", -1)
		return 1
	catch /^Vim\%((\a\+)\)\=:E15/
		call s:silent_undo()
	catch /^Vim\%((\a\+)\)\=:E121/
		call s:silent_undo()
	catch
	finally
		call setpos(".", old_pos)
	endtry
endfunction


function! s:substitute_preview(line)
	call s:undo()
	let s:undo_flag = 0

	call s:reset_match()

	let result = over#parse_substitute(a:line)
	if empty(result)
		return
	endif
	nohlsearch

	let [range, pattern, string, flags] = result
	if empty(pattern)
		return
	endif

	if empty(string)
		silent! call add(s:matchlist, matchadd("Search", (&ignorecase ? '\c' : '') . pattern, 1))
		return
	endif

	let range = (range ==# "%") ? printf("%d,%d", line("w0"), line("w$")) : range
	if string =~ '^\\=.\+'
		let string = substitute(string, '^\\=\ze.\+', '\\="`os`" . submatch(0) . "`om`" . (', "") . ') . "`oe`"'
	else
		let string = '`os`\0`om`' . string . '`oe`'
	endif
	let s:undo_flag = s:silent_substitute(range, pattern, string, 'g')

	silent! call add(s:matchlist, matchadd("Search", '`os`\zs\_.\{-}\ze`om`', 1))
	silent! call add(s:matchlist, matchadd("Error",  '`om`\zs\_.\{-}\ze`oe`', 1))
endfunction


augroup over-cmdline-substitute
	autocmd!
	autocmd User OverCmdLineEnter call s:init()
	autocmd User OverCmdLineLeave call s:finish()
	autocmd User OverCmdLineExecutePre call s:undo()
	autocmd User OverCmdLineCancel call s:undo()
	autocmd User OverCmdLineChar call s:substitute_preview(over#command_line#getline())
augroup END



let &cpo = s:save_cpo
unlet s:save_cpo

