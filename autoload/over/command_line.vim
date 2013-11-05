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


let s:command_line = ""
function! over#command_line#getline()
	return s:command_line
endfunction

function! over#command_line#setline(line)
	let s:command_line = a:line
endfunction

function! over#command_line#char()
	return s:char
endfunction


function! s:echo_cmdline(line)
	redraw
	echo a:line
endfunction


function! s:getchar()
	let char = getchar()
	return type(char) == type(0) ? nr2char(char) : char
endfunction

function! s:main(prompt, input)
	call s:doautocmd_user("OverCmdLineEnter")
	let s:flag = 0
	let input = a:input
	call s:echo_cmdline(a:prompt . input)
	let s:char = s:getchar()
	call s:doautocmd_user("OverCmdLineCharPre")
	try
		while s:char != "\<Esc>"
			if s:char == "\<CR>"
				call s:doautocmd_user("OverCmdLineExecutePre")
				execute input
				call histadd("cmd", input)
				call s:doautocmd_user("OverCmdLineExecute")
				return
			elseif s:char == "\<BS>" || s:char == "\<C-h>"
				let input = join(split(input, '\zs')[ : -2], '')
			elseif s:char == "\<C-w>"
				let input = matchstr(input, '^\zs.\{-}\ze\(\(\w*\)\|\(.\)\)$')
			elseif s:char == "\<C-v>"
				let input .= @"
			else
				let input .= s:char
			endif

			let s:command_line = input
			call s:doautocmd_user("OverCmdLineChar")

			call s:echo_cmdline(a:prompt . input)
			let s:char = s:getchar()
			call s:doautocmd_user("OverCmdLineCharPre")
		endwhile
		if s:flag
			call s:silent_undo()
		endif
		call s:doautocmd_user("OverCmdLineCancel")
	finally
		call s:doautocmd_user("OverCmdLineLeave")
	endtry
endfunction



function! s:init()
	let s:old_pos = getpos(".")
	unlet! s:matchid_pattern
	unlet! s:matchid_string
	let s:old_scrolloff = &scrolloff
	let &scrolloff = 0
endfunction


function! s:finish()
	if exists("s:matchid_pattern")
		call matchdelete(s:matchid_pattern)
		unlet s:matchid_pattern
	endif
	if exists("s:matchid_string")
		call matchdelete(s:matchid_string)
		unlet s:matchid_string
	endif
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
	if s:flag
		call s:silent_undo()
	endif
endfunction


function! s:substitute_preview(line)
	call s:undo()

	if exists("s:matchid_pattern")
		call matchdelete(s:matchid_pattern)
		unlet! s:matchid_pattern
	endif

	if exists("s:matchid_string")
		call matchdelete(s:matchid_string)
		unlet! s:matchid_string
	endif

	let result = over#parse_substitute(a:line)
	if empty(result)
		return
	endif
	let [range, pattern, string, flags] = result
	if empty(pattern)
		let s:flag = 0
		return
	endif

	let s:matchid_pattern = matchadd("Search", pattern, 2)
	if empty(string)
		let s:flag = 0
		return
	endif

	let s:matchid_string = matchadd("Error", pattern . string, 1)

	let range = (empty(range) || range ==# "%") ? printf("%d,%d", line("w0"), line("w$")) : range
	silent execute range . 's/\(' . pattern . '\)/\1' .  string . "/g"
	let s:flag = 1
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
