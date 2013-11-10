scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


augroup plugin-over-dummy
	autocmd!
augroup END


let s:cache_command = {}
function! s:doautocmd_user(command)
	if !has_key(s:cache_command, a:command)
		execute "autocmd plugin-over-dummy"
\			. " User " . a:command." silent! execute ''"

		if v:version > 703 || v:version == 703 && has("patch438")
			let s:cache_command[a:command] = "doautocmd <nomodeline> User " . a:command
		else
			let s:cache_command[a:command] = "doautocmd User " . a:command
		endif
	endif

	execute s:cache_command[a:command]
endfunction


function! over#command_line#start(prompt, input)
	call s:main(a:prompt, a:input)
endfunction


function! s:clamp(x, max, min)
	return min([max([a:x, a:max]), a:min])
endfunction


function! s:string_with_pos(...)
	let default = get(a:, 1, "")
	let self = {}
	
	function! self.set(item)
		return type(a:item) == type("") ? self.set_str(a:item)
\			 : type(a:item) == type(0)  ? self.set_pos(a:item)
\			 : self
	endfunction

	function! self.str()
		return join(self.list, "")
	endfunction

	function! self.set_pos(pos)
		let self.col = s:clamp(a:pos, 0, self.length())
		return self
	endfunction

	function! self.backward()
		return self.col > 0 ? join(self.list[ : self.col-1], '') : ""
	endfunction

	function! self.forward()
		return join(self.list[self.col+1 : ], '')
	endfunction

	function! self.pos_word()
		return get(self.list, self.col, "")
	endfunction

	function! self.set_str(str)
		let self.list = split(a:str, '\zs')
		let self.col  = strchars(a:str)
		return self
	endfunction

	function! self.pos()
		return self.col
	endfunction

	function! self.input(str)
		call extend(self.list, split(a:str, '\zs'), self.col)
		let self.col += len(split(a:str, '\zs'))
		return self
	endfunction

	function! self.length()
		return len(self.list)
	endfunction

	function! self.next()
		return self.set_pos(self.col + 1)
	endfunction

	function! self.prev()
		return self.set_pos(self.col - 1)
	endfunction

	function! self.remove(index)
		if a:index < 0 || self.length() <= a:index
			return self
		endif
		unlet self.list[a:index]
		if a:index < self.col
			call self.set(self.col - 1)
		endif
		return self
	endfunction

	function! self.remove_pos()
		return self.remove(self.col)
	endfunction

	function! self.remove_prev()
		return self.remove(self.col - 1)
	endfunction

	function! self.remove_next()
		return self.remove(self.col + 1)
	endfunction

	call self.set(default)
	return self
endfunction


let s:command_line = s:string_with_pos("")
function! over#command_line#getline()
	return s:command_line.str()
endfunction

function! over#command_line#setline(line)
	call s:command_line.set(a:line)
endfunction

function! over#command_line#char()
	return s:char
endfunction


function! s:echo_cmdline(prompt, pstr)
	redraw
	echon a:prompt . a:pstr.backward()
	if empty(a:pstr.pos_word())
		echohl OverCommandLineCursor
		echon  ' '
	else
		echohl OverCommandLineCursorInsert
		echon a:pstr.pos_word()
	endif
	echohl NONE
	echon a:pstr.forward()
endfunction


function! s:getchar()
	let char = getchar()
	return type(char) == type(0) ? nr2char(char) : char
endfunction

function! s:main(prompt, input)
	call s:doautocmd_user("OverCmdLineEnter")
	let s:command_line = s:string_with_pos(a:input)
" 	let input = s:string_with_pos(a:input)
	call s:echo_cmdline(a:prompt, s:command_line)
	let s:char = s:getchar()
	call s:doautocmd_user("OverCmdLineCharPre")
	try
		while s:char != "\<Esc>"
			if s:char == "\<CR>"
				call s:doautocmd_user("OverCmdLineExecutePre")
				try
					execute over#command_line#getline()
				finally
					call histadd("cmd", over#command_line#getline())
					call s:doautocmd_user("OverCmdLineExecute")
				endtry
				return
			elseif s:char == "\<BS>" || s:char == "\<C-h>"
				call s:command_line.remove_prev()
			elseif s:char == "\<C-w>"
				let backward = matchstr(s:command_line.backward(), '^\zs.\{-}\ze\(\(\w*\)\|\(.\)\)$')
				call s:command_line.set(backward . s:command_line.pos_word() . s:command_line.forward())
				call s:command_line.set(strchars(backward))
			elseif s:char == "\<C-v>"
				call s:command_line.input(@*)
			elseif s:char == "\<Right>" || s:char == "\<C-f>"
				call s:command_line.next()
			elseif s:char == "\<Left>" || s:char == "\<C-b>"
				call s:command_line.prev()
			elseif s:char == "\<Del>" || s:char == "\<C-d>"
				call s:command_line.remove_pos()
			elseif s:char == "\<Home>" || s:char == "\<C-a>"
				call s:command_line.set(0)
			elseif s:char == "\<End>" || s:char == "\<C-e>"
				call s:command_line.set(s:command_line.length())
			else
				call s:command_line.input(s:char)
			endif

			call s:doautocmd_user("OverCmdLineChar")

			call s:echo_cmdline(a:prompt, s:command_line)
			let s:char = s:getchar()
			call s:doautocmd_user("OverCmdLineCharPre")
		endwhile
		if s:undo_flag
			call s:silent_undo()
		endif
		call s:doautocmd_user("OverCmdLineCancel")
	finally
		redraw
		echo ""
		call s:doautocmd_user("OverCmdLineLeave")
	endtry
endfunction



function! s:init()
	let s:undo_flag = 0
	let s:old_pos = getpos(".")
	unlet! s:matchid_pattern
	unlet! s:matchid_string
	let s:old_scrolloff = &scrolloff
	let &scrolloff = 0

	redir => cursor
	silent highlight Cursor
	redir END
	let s:old_hi_cursor = matchstr(cursor, 'xxx \zs.*')
	highlight Cursor NONE

	if !hlexists("OverCommandLineCursor")
		execute "highlight OverCommandLineCursor " . s:old_hi_cursor
	endif
	if !hlexists("OverCommandLineCursorInsert")
		execute "highlight OverCommandLineCursorInsert " . s:old_hi_cursor . " term=underline gui=underline"
	endif
endfunction


function! s:finish()
	call setpos(".", s:old_pos)
	let &scrolloff = s:old_scrolloff
	execute ":highlight Cursor " . s:old_hi_cursor

	if exists("s:matchid_pattern") && s:matchid_pattern != -1
		call matchdelete(s:matchid_pattern)
		unlet s:matchid_pattern
	endif
	if exists("s:matchid_string") && s:matchid_string != -1
		call matchdelete(s:matchid_string)
		unlet s:matchid_string
	endif
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

	silent! call add(s:matchlist, matchadd("Error", pattern . '\zs' . string . '\ze', 2))
endfunction


augroup over-cmdline
	autocmd!
	autocmd User OverCmdLineEnter call s:init()
	autocmd User OverCmdLineLeave call s:finish()
	autocmd User OverCmdLineExecutePre call s:undo()
	autocmd User OverCmdLineChar call s:substitute_preview(over#command_line#getline())
augroup END



let &cpo = s:save_cpo
unlet s:save_cpo
