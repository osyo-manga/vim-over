
function! over#command_line#substitute#load()
	" load
endfunction


function! s:init()
	let s:undo_flag = 0
	let s:old_pos = getpos(".")
	let s:old_scrolloff = &scrolloff
	let &scrolloff = 0

endfunction


function! s:finish()
	call s:reset_match()
	call setpos(".", s:old_pos)
	let &scrolloff = s:old_scrolloff
	
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
		let old_search_pattern = @/
		silent execute printf('%ss/%s/%s/%s', a:range, a:pattern, a:string, a:flags)
		call histdel("search", -1)
		return 1
	catch
		return 0
	finally
		let @/ = old_search_pattern
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

	let [range, pattern, string, flags] = result
	if empty(pattern)
		return
	endif

	silent! call add(s:matchlist, matchadd("Search", pattern, 1))
	if empty(string)
		return
	endif

	let range = (empty(range) || range ==# "%") ? printf("%d,%d", line("w0"), line("w$")) : range
	let s:undo_flag = s:silent_substitute(range, '\(' . pattern . '\)', '\1' . string, 'g')

	silent! call add(s:matchlist, matchadd("Error", '\(' . pattern . '\)\zs' . string . '\ze', 2))
endfunction


augroup over-cmdline-substitute
	autocmd!
	autocmd User OverCmdLineEnter call s:init()
	autocmd User OverCmdLineLeave call s:finish()
	autocmd User OverCmdLineExecutePre call s:undo()
	autocmd User OverCmdLineCancel call s:undo()
	autocmd User OverCmdLineChar call s:substitute_preview(over#command_line#getline())
augroup END


