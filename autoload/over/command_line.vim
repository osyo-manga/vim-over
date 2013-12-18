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
	if exists("*strchars") && has("conceal")
		call s:main(a:prompt, a:input)
	else
		echohl ErrorMsg
		echo "Vim 7.3 or above."
		echo "Need strchars() and +conceal."
		echohl NONE
	endif
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

function! over#command_line#setchar(char)
	let s:input = a:char
endfunction

function! over#command_line#getpos()
	return s:command_line.pos()
endfunction

function! over#command_line#setpos(pos)
	return s:command_line.set_pos(a:pos)
endfunction


function! over#command_line#wait_keyinpu_on(key)
	let s:wait_key = a:key
endfunction

function! over#command_line#wait_keyinpu_off(key)
	if s:wait_key == a:key
		let s:wait_key = ""
	endif
" 	let s:wait_key = a:key
endfunction

function! over#command_line#get_wait_keyinput()
	return s:wait_key
endfunction


function! over#command_line#is_input(key, ...)
	let prekey = get(a:, 1, "")
	return s:wait_key == prekey
\		&& over#command_line#keymap(over#command_line#char()) == a:key
endfunction

function! over#command_line#insert(word, pos)
	call s:command_line.set(a:pos)
	call s:command_line.input(a:word)
endfunction

function! over#command_line#forward()
	return s:command_line.forward()
endfunction

function! over#command_line#backward()
	return s:command_line.backward()
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

function! over#command_line#redraw()
	redraw
	echo ""
endfunction

let s:plugin_root = expand('<sfile>:p:h:h') . '/tools/'
function! s:func()
	call system(s:plugin_root . "/shell.sh")
endfunction

function! s:main(prompt, input)
	call s:doautocmd_user("OverCmdLineEnter")
	let s:command_line = s:string_with_pos(a:input)
" 	let input = s:string_with_pos(a:input)
	call s:echo_cmdline(a:prompt, s:command_line)
	let s:char = s:getchar()
	let keymap = over#command_line#keymap(s:char)
	let s:input = s:char
	call s:doautocmd_user("OverCmdLineCharPre")
	try
		while !over#command_line#is_input("\<Esc>")
			if over#command_line#is_input("\<CR>")
				call s:doautocmd_user("OverCmdLineExecutePre")
				try
					execute over#command_line#getline()
				catch
					echohl ErrorMsg
					echo matchstr(v:exception, 'Vim\((\w*)\)\?:\zs.*\ze')
					echohl None
				finally
					call s:doautocmd_user("OverCmdLineExecute")
				endtry
				return
			elseif over#command_line#is_input("\<C-h>")
				call s:command_line.remove_prev()
			elseif over#command_line#is_input("\<C-w>")
				let backward = matchstr(s:command_line.backward(), '^\zs.\{-}\ze\(\(\w*\)\|\(.\)\)$')
				call s:command_line.set(backward . s:command_line.pos_word() . s:command_line.forward())
				call s:command_line.set(strchars(backward))
			elseif over#command_line#is_input("\<C-u>")
				call s:command_line.set(s:command_line.pos_word() . s:command_line.forward())
				call s:command_line.set(0)
			elseif over#command_line#is_input("\<C-v>")
				call s:command_line.input(@*)
			elseif over#command_line#is_input("\<C-f>")
				call s:command_line.next()
			elseif over#command_line#is_input("\<C-b>")
				call s:command_line.prev()
			elseif over#command_line#is_input("\<C-d>")
				call s:command_line.remove_pos()
			elseif over#command_line#is_input("\<C-a>")
				call s:command_line.set(0)
			elseif over#command_line#is_input("\<C-e>")
				call s:command_line.set(s:command_line.length())
			else
				call s:command_line.input(s:input)
			endif

			call s:doautocmd_user("OverCmdLineChar")

			call s:echo_cmdline(a:prompt, s:command_line)
			let s:char = s:getchar()
			let keymap = over#command_line#keymap(s:char)
			let s:input = s:char
			call s:doautocmd_user("OverCmdLineCharPre")
		endwhile
		call s:doautocmd_user("OverCmdLineCancel")
		call over#command_line#redraw()
	finally
		call histadd("cmd", over#command_line#getline())
		call s:doautocmd_user("OverCmdLineLeave")
	endtry
endfunction


function! over#command_line#hl_cursor_on()
	if exists("s:old_hi_cursor")
		execute "highlight Cursor " . s:old_hi_cursor
		unlet s:old_hi_cursor
	endif
endfunction


function! over#command_line#hl_cursor_off()
	if exists("s:old_hi_cursor")
		return s:old_hi_cursor
	endif
	let s:old_hi_cursor = "cterm=reverse"
	if hlexists("Cursor")
		redir => cursor
		silent highlight Cursor
		redir END
		let hl = substitute(matchstr(cursor, 'xxx \zs.*'), '[ \t\n]\+\|cleared', ' ', 'g')
		if !empty(substitute(hl, '\s', '', 'g'))
			let s:old_hi_cursor = hl
		endif
		highlight Cursor NONE
	endif
	return s:old_hi_cursor
endfunction


function! s:init()
	let s:wait_key = ""
	let s:input = ""
	let hl_cursor = over#command_line#hl_cursor_off()
	if !hlexists("OverCommandLineCursor")
		execute "highlight OverCommandLineCursor " . hl_cursor
	endif
	if !hlexists("OverCommandLineCursorInsert")
		execute "highlight OverCommandLineCursorInsert " . hl_cursor . " term=underline gui=underline"
	endif
	let s:old_t_ve = &t_ve
	set t_ve=
endfunction


function! s:finish()
" 	execute "highlight Cursor " . s:old_hi_cursor
	call over#command_line#hl_cursor_on()
	let &t_ve = s:old_t_ve
endfunction


call over#command_line#substitute#load()
" call over#command_line#backspace#load()
call over#command_line#command_history#load()
call over#command_line#insert_register#load()
call over#command_line#complete#load()


augroup over-cmdline
	autocmd!
	autocmd User OverCmdLineEnter call s:init()
	autocmd User OverCmdLineLeave call s:finish()
augroup END



let s:default_key_mapping = {
\	"\<Right>" : "\<C-f>",
\	"\<Left>"  : "\<C-b>",
\	"\<Up>"    : "\<C-p>",
\	"\<Down>"  : "\<C-n>",
\	"\<BS>"    : "\<C-h>",
\	"\<Del>"   : "\<C-d>",
\	"\<Home>"  : "\<C-a>",
\	"\<End>"   : "\<C-e>",
\}


function! over#command_line#keymap(key)
	return get(extend(deepcopy(s:default_key_mapping), g:over_command_line_key_mappings), a:key, a:key)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
