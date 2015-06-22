scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let g:over#command_line#search#enable_incsearch = get(g:, "over#command_line#search#enable_incsearch", 1)
let g:over#command_line#search#enable_move_cursor = get(g:, "over#command_line#search#enable_move_cursor", 0)
let g:over#command_line#search#keep_search = get(g:, "over#command_line#search#keep_search", 1)


function! over#command_line#search#load()
	" load
endfunction


function! s:search_hl_off()
	if get(s:, "search_id", -1) != -1
		call matchdelete(s:search_id)
		unlet s:search_id
	endif
	if get(s:, "current_search_id", -1) != -1
		call matchdelete(s:current_search_id)
		unlet s:current_search_id
	endif
	if get(s:, "cursor_search_id", -1) != -1
		call matchdelete(s:cursor_search_id)
		unlet s:cursor_search_id
	endif
endfunction


function! s:search_hl_on(pattern)
	call s:search_hl_off()
	silent! let s:search_id = matchadd("IncSearch", a:pattern)
	silent! let s:current_search_id = matchadd(
		\ "Search",
		\ '\%#' . a:pattern
	\ )
	silent! let s:cursor_search_id = matchadd("Cursor", '\%#')
endfunction


function! s:main()
	call s:search_hl_off()
	let line = over#command_line#backward()

	let visual = 0
	if line[0:4] == "'<,'>"
		let visual = 1
		let line = line[5:]
	endif

	if line =~ '^/.\+'
\	|| line =~ '^?.\+'

		let s:pattern = matchstr(line, '^\(/\|?\)\zs.\+')

		if visual
			let s:pattern = over#command_line#bind_pattern_by_visual(
				\ s:pattern
			\ )
		endif

		nohlsearch

		if g:over#command_line#search#enable_incsearch
			call s:search_hl_on((&ignorecase ? '\c' : "") . s:pattern)
		endif
		if g:over#command_line#search#enable_move_cursor
			call setpos(".", s:old_pos)
			if line =~ '^/.\+'
				silent! call search(s:pattern, "")
			else
				silent! call search(s:pattern, "b")
			endif
		endif
	endif
endfunction


augroup over-cmdline-search
	autocmd!
	autocmd User OverCmdLineChar call s:main()
	autocmd User OverCmdLineLeave call s:search_hl_off()
	autocmd User OverCmdLineEnter let s:old_pos = getpos(".")
	autocmd User OverCmdLineExecute if g:over#command_line#search#keep_search
		\ | let @/ = s:pattern | endif
augroup END



let &cpo = s:save_cpo
unlet s:save_cpo

