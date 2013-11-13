scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" http://d.hatena.ne.jp/thinca/20131104/1383498883
" {range}s/{pattern}/{string}/{flags}
function! s:parse_substitute(word)
	let very_magic   = '\v'
	let range        = '(.{-})'
	let command      = 's%[ubstitute]'
	let first_slash  = '([\x00-\xff]&[^\\"|[:alnum:][:blank:]])'
	let pattern      = '(%(\\.|.){-})'
	let second_slash = '\2'
	let string       = '(%(\\.|.){-})'
	let flags        = '%(\2([&cegiInp#lr]*))?'
	let parse_pattern
\		= very_magic
\		. '^:*'
\		. range
\		. command
\		. first_slash
\		. pattern
\		. '%('
\		. second_slash
\		. string
\		. flags
\		. ')?$'
	let result = matchlist(a:word, parse_pattern)[1:5]
	if type(result) == type(0) || empty(result)
		return []
	endif
	unlet result[1]
	return result
endfunction




" base code
" https://github.com/thinca/vim-ambicmd/blob/78fa88c5647071e73a3d21e5f575ed408f68aaaf/autoload/ambicmd.vim#L26
function! over#parse_range(string)
	let search_pattern = '\v/[^/]*\\@<!%(\\\\)*/|\?[^?]*\\@<!%(\\\\)*\?'
	let line_specifier =
	\   '\v%(\d+|[.$]|''\S|\\[/?&])?%([+-]\d*|' . search_pattern . ')*'
	let range_pattern = '\v%((\%|' . line_specifier . ')' .
	\              '%([;,](' . line_specifier . '))*)'
	return matchlist(a:string, range_pattern)
endfunction



function! s:search_highlight(line)
	let result = s:parse_substitute(a:line)
	if empty(result)
		return
	endif
	if !s:set_flag
		let s:search_highlighted = 1
		let s:set_flag = 1
		call feedkeys("\<C-o>:set hlsearch | set incsearch\<CR>", 'n')
	endif
	let @/ = result[1]
endfunction


function! s:set_options()
	if s:search_highlighted
		let s:search_highlighted = 0
		return
	endif

	let s:old_incsearch = &incsearch
	let s:old_hlsearch  = &hlsearch
	let s:old_search_pattern = @/
endfunction


function! s:restore_options()
	if s:search_highlighted
		return
	endif

	let s:set_flag = 0
	let &incsearch = s:old_incsearch
	let &hlsearch  = s:old_hlsearch
	if g:over_enable_auto_nohlsearch
		call feedkeys(":nohlsearch\<CR>", 'n')
	endif
	call feedkeys(":let @/ = " . string(s:old_search_pattern) . "\<CR>", 'n')
endfunction


function! over#setup()
	let s:set_flag = 0
	let s:search_highlighted = 0
	augroup over-cmdwindow
		autocmd!
		autocmd InsertCharPre * call s:search_highlight(getline(".") . v:char)
		autocmd InsertEnter   * call s:set_options()
		autocmd InsertLeave   * call s:restore_options()
	augroup END
endfunction


function! over#unsetup()
	augroup over-cmdwindow
		autocmd!
	augroup END
endfunction


function! over#command_line(prompt, input)
	return over#command_line#start(a:prompt, a:input)
endfunction


function! over#parse_substitute(word)
	return s:parse_substitute(a:word)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
