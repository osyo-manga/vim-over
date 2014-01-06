scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! over#command_line#substitute#load()
	" load
endfunction


function! s:init()
	if &modifiable == 0
		return
	endif
	let s:undo_flag = 0
	let s:old_pos = getpos(".")
	let s:old_scrolloff = &scrolloff
	let &scrolloff = 0
	let s:old_conceallevel = &l:conceallevel
	let s:old_concealcursor = &l:concealcursor
	let s:old_modified = &l:modified

	syntax match OverCmdLineSubstituteHiddenBegin  '`os`' conceal containedin=ALL
	syntax match OverCmdLineSubstituteHiddenMiddle '`om`' conceal containedin=ALL
	syntax match OverCmdLineSubstituteHiddenEnd    '`oe`' conceal containedin=ALL
	
	let s:buffer_text = getline(1, "$")
	let s:undo_file = tempname()
	execute "wundo" s:undo_file
	echom s:undo_file
endfunction


function! s:finish()
	if &modifiable == 0
		return
	endif
	call s:reset_match()
	call setpos(".", s:old_pos)
	let &scrolloff = s:old_scrolloff
	let &l:conceallevel = s:old_conceallevel
	let &l:concealcursor = s:old_concealcursor
	let &l:modified = s:old_modified
	highlight link OverCmdLineSubstitute NONE
	highlight link OverCmdLineSubstitutePattern NONE
	highlight link OverCmdLineSubstituteString  NONE
endfunction


function! s:undojoin()
	if exists("s:buffer_text")
\	&& exists("s:undo_file")
		call setline(1, s:buffer_text)
		if filereadable(s:undo_file)
			silent execute "rundo" s:undo_file
		endif
		unlet s:buffer_text
		unlet s:undo_file
	endif
endfunction


function! s:silent_undo()
	if !exists("s:buffer_text")
		return
	endif
	call setline(1, s:buffer_text)
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
		let old_search = @/
		let check = b:changedtick
		silent execute printf('%ss/%s/%s/%s', a:range, a:pattern, a:string, a:flags)
		call histdel("search", -1)
	catch /\v^Vim%(\(\a+\))=:(E121)|(E117)|(E110)|(E112)|(E113)|(E731)|(E475)|(E15)/
		return 0
	catch
	finally
		call setpos(".", old_pos)
		let @/ = old_search
	endtry
	return check != b:changedtick
endfunction


function! s:substitute_preview(line)
	call s:silent_undo()

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

	let &l:concealcursor = "nvic"
	let &l:conceallevel = 3
	silent! call add(s:matchlist, matchadd("Search", '`os`\zs\_.\{-}\ze`om`', 1))
	silent! call add(s:matchlist, matchadd("Error",  '`om`\zs\_.\{-}\ze`oe`', 1))
endfunction


function! s:on_charpre()
	if over#command_line#is_input("\<Plug>(over-cmdline-substitute-jump-string)")
		let result = over#parse_substitute(over#command_line#getline())
		if empty(result)
			return
		endif
		let [range, pattern, string, flags] = result
		call over#command_line#setpos(strchars(range . pattern) + 3)
		call over#command_line#setchar("")
	endif
	if over#command_line#is_input("\<Plug>(over-cmdline-substitute-jump-pattern)")
		let result = over#parse_substitute(over#command_line#getline())
		if empty(result)
			return
		endif
		let [range, pattern, string, flags] = result
		call over#command_line#setpos(strchars(range ) + 2)
		call over#command_line#setchar("")
	endif
endfunction


augroup over-cmdline-substitute
	autocmd!
	autocmd User OverCmdLineEnter call s:init()
" 	autocmd User OverCmdLineExecutePre call s:finish()
	autocmd User OverCmdLineLeave call s:finish()
	autocmd User OverCmdLineExecutePre call s:undojoin()
	autocmd User OverCmdLineCancel call s:undojoin()
	autocmd User OverCmdLineChar call s:substitute_preview(over#command_line#getline())
	autocmd user OverCmdLineCharPre call s:on_charpre()
augroup END



let &cpo = s:save_cpo
unlet s:save_cpo

