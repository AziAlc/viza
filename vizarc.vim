
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git etc. anyway...
set nobackup
set nowb
set noswapfile


"#####
"syntax match mdLink /\[.\{-}\](.\{-})/ conceal cchar=link
"syntax match lineStart /\<\a/ conceal cchar=>
"set statusline=%f
"set statusline=%#StatusLineNC#\ %<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
"set conceallevel=1
"syntax on






          
" some funky status bar code its seems
" https://stackoverflow.com/questions/9065941/how-can-i-change-vim-status-line-colour
set laststatus=2            " set the bottom status bar

function! ModifiedColor()
    if &mod == 1
        hi statusline guibg=White ctermfg=8 guifg=OrangeRed4 ctermbg=15
    else
        hi statusline guibg=White ctermfg=8 guifg=DarkSlateGray ctermbg=15
    endif
endfunction

au InsertLeave,InsertEnter,BufWritePost   * call ModifiedColor()
" default the statusline when entering Vim
hi statusline guibg=White ctermfg=8 guifg=DarkSlateGray ctermbg=15

" Formats the statusline
set statusline=%f                           " file name
set statusline+=[%{strlen(&fenc)?&fenc:'none'}, "file encoding
set statusline+=%{&ff}] "file format
set statusline+=%y      "filetype
set statusline+=%h      "help file flag test
set statusline+=TESTING      "help file flag test
set statusline+=[%{getbufvar(bufnr('%'),'&mod')?'modified':'saved'}]      
"modified flag

set statusline+=%r      "read only flag

set statusline+=\ %=                        " align left
set statusline+=Line:%l/%L[%p%%]            " line X of Y [percent of file]
set statusline+=\ Col:%c                    " current column
set statusline+=\ Buf:%n                    " Buffer number
set statusline+=\ [%b][0x%B]\               " ASCII and byte code under cursor

"nnoremap i <Nop>
"nnoremap I <Nop>
"nnoremap a <Nop>
"nnoremap A <Nop>
"nnoremap o <Nop>
"nnoremap O <Nop>
" enter now executes shell
"nnoremap O :.!sh<Cr>
"nnoremap A :.!ls<Cr>


"nnoremap <CR> :execute 'split ' . getline('.')<CR>

"nnoremap <Leader>x :execute 'new | read !' . getline('.')<CR>
"nnoremap O :execute 'new | read !' . getline('.')
"nnoremap O :execute 'new' | read !cat ~/test.sh
"| setlocal buftype=nofile bufhidden=hide noswapfile 


" will pwd when press O in new vim sess
"nnoremap O :new<CR>:read !pwd<CR>:setlocal buftype=nofile<CR>:setlocal bufhidden=hide<CR>:setlocal noswapfile<CR>gg
" will list files when press O in new vim sess
" nnoremap O :new<CR>:read !ls<CR>:setlocal buftype=nofile<CR>:setlocal bufhidden=hide<CR>:setlocal noswapfile<CR>gg


"nnoremap O :new<CR>:call setline(1, '#!/bin/sh')<CR>o<Esc>:setlocal buftype=nofile bufhidden=hide noswapfile<CR>:set filetype=sh<CR>a

" vim 
"!vim

" File: enhanced_file_list_popup.vim
" Description: An enhanced Vim plugin for file navigation with in-popup real-time fuzzy search



" File: enhanced_file_list_popup.vim
" Description: An enhanced Vim plugin for file navigation with in-popup real-time fuzzy search

" These are script local scoped variables. 
" Won't conflict is sourced by another file with same names.
" think of these like private methods to a class
" There are also actual local scoped variables. which is diff 'l;'
" source path/to/your/script.vim
let s:files = []
let s:curr_view_data = []
let s:search_query = ''
let s:popup_winid = 0
let s:view_mode = 'recent'  " 'ls', 'recent', or 'process'
let s:debug = 1  " Set to 1 to enable debug messages
let s:max_height = 20  " Maximum height of the popup window
let s:max_files = 1000  " Maximum number of files to list
let s:ignore_patterns = ['.git', 'node_modules', '*.pyc']  " Patterns to ignore
let s:search_mode = 0  " 0: normal mode, 1: search mode
let s:last_cursor_pos = 1  " New variable to store the last cursor position

let s:pages_data = {
    \ 'ls':      {'title': 'Current Directory', 'search_query': '', 'selected_line': 1},
    \ 'recent':  {'title': 'Recent Files',      'search_query': '', 'selected_line': 1},
    \ 'marks':   {'title': 'Marks',             'search_query': '', 'selected_line': 1},
    \ 'process': {'title': 'Vim Processes',     'search_query': '', 'selected_line': 1}
    \ }
" 'get_files': function('GetCurrDirFiles')
" 'get_files': function('GetRecentFiles'  )
" 'get_files': function('GetMarksList'    )
" 'get_files': function('GetProcesses'    )

" All these functions are global functions. to make local, do `function s:DebugMsg(msg)`
" the '!' means override. if there are functions with same name (from same or source file), it won't conflict.
function! DebugMsg(msg)
  if s:debug
    " benefit of echom is its saved in :messages
    " The . operator in Vim script is used to concatenate (combine) two strings.
    " a:msg is a variable that represents an argument passed to a function in Vim script.
    " while echom LOOKS like it is a built in funciton, it is not,  we don't call it with "call"
    " The echom is a vim command . itself is not a function but a command that outputs messages
    " :help :echom #verifies its a vim command
    echom "Debug: " . a:msg
  endif
endfunction

function! InitPopup()
  " copy does a shallow copy. 
  " changes to dict and list of list will effect both lists. But not simple primitive types like strings or int
  " this is because primitive types are immutable so they are essentially deep copied
  " a list of primitive types affects only one of the lists.
  " but a list of list will change both list.
  let s:curr_view_data = GetRecentFiles()
  let s:search_query = ''
  let s:view_mode = 'recent'
  let s:search_mode = 0
  
  call UpdatePopup()
  redraw!
endfunction

function! IgnoreFile(file)
  for l:pattern in s:ignore_patterns
    " =~ means regex pattern search 
    " and again a:file, 'a:' means its the argument variable
    if a:file =~ l:pattern
      return 1
    endif
  endfor
  return 0
endfunction

function! UpdatePopup()
  let l:lines = copy(s:curr_view_data)
  " show Search as the first line.
  if s:search_mode || len(s:search_query)
    call insert(l:lines, 'Search: ' . s:search_query . '_', 0)
  endif

  " Calculate the width of the popup
  let l:content_width = max([max(map(copy(l:lines), 'len(v:val)')), len(s:search_query)])
  let l:width = l:content_width + 4  " +4 for padding and borders
  
  " Calculate the height of the popup (max s:max_height lines, +2 for title and bottom padding)
  let l:height = min([len(l:lines), s:max_height]) + 2
  
  " Calculate center position
  let l:row = ((&lines - l:height) / 2) + 1
  let l:col = ((&columns - l:width) / 2) + 1
  
  let l:title = s:view_mode == 'ls' ? 'Current Directory' : (s:view_mode == 'recent' ? 'Recent Files' : 'Process List')
  let l:title .= ' (j/k:navigate, e:edit, v:vsplit, /:search, l/r/p:switch view, q:quit)'
  if s:view_mode == 'process'
    let l:title .= ', d:destroy process'
  endif
  
  let l:options = {
        \ 'line': l:row,
        \ 'col': l:col,
        \ 'minwidth': l:width,
        \ 'minheight': l:height,
        \ 'maxheight': l:height,
        \ 'border': [],
        \ 'padding': [1,1,1,1],
        \ 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
        \ 'callback': 'ClosePopup',
        \ 'filter': 'PopupFilter',
        \ 'cursorline': 1,
        \ 'title': l:title,
        \ 'wrap': 0,
        \ 'scrollbar': 1
        \ }
" 'border': []: Defines the border of the popup window. An empty list means no border.
" 'padding': [1,1,1,1]: Sets padding around the contents of the popup window. The list represents padding for top, right, bottom, and left.
" 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└']: Defines the characters used for the border of the popup window (horizontal, vertical, and corner characters).
" 'callback': 'ClosePopup': Specifies the function (ClosePopup) to call when the popup window is closed.
" 'filter': 'PopupFilter': Specifies a function (PopupFilter) to filter input events while the popup is open.
" 'cursorline': 1: If set to 1, highlights the line under the cursor.
" 'title': l:title: Sets the title of the popup window.
" 'wrap': 0: If set to 0, text in the popup will not wrap.
" 'scrollbar': 1: If set to 1, shows a scrollbar in the popup.

  " Create or update the popup
  " Checks if script local s:popup_winid is 0 (indicating no popup is currently created) or winbufnr -1 invalid winid
  if s:popup_winid == 0 || winbufnr(s:popup_winid) == -1
    let s:popup_winid = popup_create(l:lines, l:options) " returns an id of window
  else
    call popup_setoptions(s:popup_winid, l:options)
    call popup_settext(s:popup_winid, l:lines)
  endif
  
  " Set cursor position
  if s:search_mode
  " win_execute() is a function that executes a command in the context of the window 
  " with ID s:popup_winid.
  " 'call cursor(1, ' . (9 + len(s:search_query)) . ')'sets the cursor position.
  " 9 is a fixed offset padding cuz of UI elements. maybe I dn't need this. 
    call win_execute(s:popup_winid, 'call cursor(1, ' . (9 + len(s:search_query)) . ')')
  elseif !empty(s:curr_view_data)
    " Use the last known cursor position, but ensure it's within bounds

    let l:selected_line = s:pages_data[s:view_mode].selected_line
    if l:selected_line > 0 && l:selected_line <= len(s:curr_view_data) "|| a:mode == s:view_mode
      let s:last_cursor_pos = l:selected_line  " Remember the cursor position
    endif

    " let s:last_cursor_pos = s:pages_data[s:view_mode].selected_line
    let l:cursor_pos = min([s:last_cursor_pos, len(s:curr_view_data)])
    call win_execute(s:popup_winid, 'call cursor(' . l:cursor_pos . ', 1)')
  endif
 
  " call DebugMsg("UpdatePopup: view_mode=" . s:view_mode . ", curr_view_data_count=" . len(s:curr_view_data) . ", cursor_line=" . line('.', s:popup_winid))
endfunction

function! PopupFilter(winid, key)
  call DebugMsg("PopupFilter: winid=" . a:winid)
  call DebugMsg("PopupFilter: key=" . a:key . ", search_mode=" . s:search_mode)

  let l:line = line('.', a:winid) " . means current line number
  let l:lastline = line('$', a:winid) " $ meanas last line


  " If we want to REFRESH/keep the popup, don't return so we kill updatePopup
  " for j/k, we return 1 because we want to keep the same instance of the pop up
  " for kill process, we want it to call update popup at the end of this func because it needs to update view
  if s:search_mode 
    if a:key == "\<CR>" || a:key == "\<C-j>"
    " if nothing is typed, move to first line. otherwise second line because search line is visible
      let s:pages_data[s:view_mode].selected_line = len(s:search_query) ? 2 : 1
      let s:search_mode = 0
    elseif a:key == "\<BS>"
      let s:search_query = s:search_query[:-2]
    elseif a:key =~ '^[A-Za-z0-9]$'
      let s:search_query .= a:key
    elseif a:key == "\<Esc>"
      " set to 1 here because the search line disappears
      let s:pages_data[s:view_mode].selected_line = 1
      let s:search_mode = 0
      let s:search_query = ''
      " call fuzz search with empty string so we can update the list 
      call FuzzySearch()
    else
      return 0
    endif

    call FuzzySearch()
  else
    if s:view_mode == 'process' && a:key == 'd'
        call P_DestroySelectedProcess(a:winid)
    elseif s:view_mode == 'marks' && a:key == 'e'
        call M_EditFileMarkSelection(a:winid)
    elseif a:key == 'j' || a:key == "\<C-j>"
      if l:line < l:lastline
        call win_execute(a:winid, 'normal! j')
        " call DebugMsg("Moved down to line " . line('.', a:winid))
      endif
      return 1
    elseif a:key == 'k' || a:key == "\<C-k>"
      if l:line > 1
        call win_execute(a:winid, 'normal! k')
        " call DebugMsg("Moved up to line " . line('.', a:winid))
      endif
      return 1
    elseif a:key == ':'
      " make this a noop. maybe later can use to switch pages? this is vim's command pallete key
      call DebugMsg(": is disabled while window is up")
      return 1
      " condisder making this ctrl /
      " so the default can still be used.
    elseif a:key == '/'
      let s:search_mode = 1
      let s:search_query = s:search_query
    elseif a:key == 'v'
      call s:OpenFileAction(a:winid, 'vsplit')
    elseif a:key == 'e'
      call s:OpenFileAction(a:winid, 'edit')
    elseif a:key == 'r'
      call ToggleViewMode('recent')
    elseif a:key == 'l'
      call ToggleViewMode('ls')
    elseif a:key == 'm'
      call ToggleViewMode('marks')
    elseif a:key == 'p'
      call ToggleViewMode('process')
    elseif a:key == 'q' || a:key == "\<Esc>"
      call DebugMsg("Closing popup due to 'q' or <Esc>")
      call popup_close(a:winid)
      call DebugMsg("popup_close called with winid: " . a:winid)
      return 1
    elseif a:key == "\<C-d>"
      let l:new_line = min([l:line + 10, l:lastline])
      call win_execute(a:winid, 'normal! ' . l:new_line . 'G')
      " call DebugMsg("Moved down 10 lines (or to last line)" . l:new_line)
      return 1
    elseif a:key == "\<C-u>"
      let l:new_line = max([l:line - 10, 1])
      call win_execute(a:winid, 'normal! ' . l:new_line . 'G')
      " call DebugMsg("Moved up 10 lines (or to first line)")
      return 1
    else
      call DebugMsg("Default behavior " . a:key)
      return 0
    endif
  endif

  call DebugMsg("Calling UpdatePopup after " . a:key)
  call UpdatePopup()
  return 1
endfunction

" made this locally scoped because it's a helper function. not to be used outside this script.
function! s:OpenFileAction(winid, action)
  call DebugMsg("OpenFileAction: winid=" . a:winid . ", cursor_line=" . line('.', a:winid))
  call DebugMsg("curr_view_data count: " . len(s:curr_view_data))

  " . the line number of the current line we are on
  if has_key(s:pages_data, s:view_mode)
     let s:pages_data[s:view_mode].selected_line = line('.', a:winid)
  endif
  let l:selected_line = s:pages_data[s:view_mode].selected_line
  call DebugMsg("Open file: Selected line is  " . l:selected_line)
  
  if l:selected_line > 0 && l:selected_line <= len(s:curr_view_data)
    let s:last_cursor_pos = l:selected_line  " Remember the cursor position
    let l:filename = s:curr_view_data[l:selected_line - 1]
    call DebugMsg("Opening file: " . l:filename)
    call popup_close(a:winid)
    execute a:action . " " . fnameescape(l:filename)
  else
    call DebugMsg("Error: Invalid selected line " . l:selected_line)
  endif
endfunction

function! FuzzySearch()
" TODO: Do I want to requery after every press? Seems expensive
" I could just save the results in pages.data
" downside is we don't get real time updates while searching"
  let l:query_parts = split(tolower(s:search_query), '\zs')
  let l:source = 
    \s:view_mode == 'ls' ? GetCurrDirFiles() : 
    \s:view_mode == 'recent' ? GetRecentFiles() :
    \s:view_mode == 'marks' ? GetMarksList() :
    \GetProcesses(empty(s:search_query) ? '""' : s:search_query)  
    "s:view_mode == 'process' ?
    "process is not using fuzzy search. instead using grep -i

  let s:curr_view_data = filter(copy(l:source), 'FuzzyMatch(tolower(v:val), l:query_parts) != -1')
  call DebugMsg("FuzzySearch: query=" . s:search_query . ", filtered_count=" . len(s:curr_view_data))
endfunction

function! FuzzyMatch(str, query_parts)
  let l:idx = 0
  for char in a:query_parts
    let l:newidx = stridx(a:str, char, l:idx)
    if l:newidx == -1
      return -1
    endif
    let l:idx = l:newidx + 1
  endfor
  return l:idx
endfunction

function! GetCurrDirFiles()
  let s:files = []
  let l:count = 0
  " search curr dir '*'', ('**' means recurse to subdirs) for all files, 1 = include hidden files, and return the result as a List instead of a String
  let l:glob_result = globpath('.', '*', 1, 1)
  
  " Ensure l:glob_result is a list because of vim compatability reason. glob could return a string even if called with arg 1.
  if type(l:glob_result) == v:t_string
    let l:glob_result = split(l:glob_result, "\n")
  endif
  
  for l:file in l:glob_result
    if l:count >= s:max_files
      break
    endif
    " not using 'call' for IgnoredFIle because it returns a value. so this is a direct func call
    " call is used when there's no ret value or has side effects such as the DebugMsg or internal vim built in func such as 'add'
    if !IgnoreFile(l:file)
    "fnamemodify(l:file, ':.') extracts just the base name of the file from l:file.
      call add(s:files, fnamemodify(l:file, ':.'))
      let l:count += 1
    endif
  endfor
  call DebugMsg("GetCurrDirFiles: Found " . l:count . " files.")
  return s:files
endfunction

function! GetMarksList()
  return split(execute('marks'), "\n")
endfunction

function! GetRecentFiles()
  let l:recent_files = []
  for l:file in v:oldfiles
    " The function filters out files that are not readable,
    " which is useful if some files have been moved or deleted since they were last opened.
    if filereadable(expand(l:file))
      " fnamemodify() with the ':p' flag, ensures that all file paths are returned as absolute paths.
      call add(l:recent_files, fnamemodify(l:file, ':p'))
    endif
  endfor
  call DebugMsg("GetRecentFiles: Returning " . len(l:recent_files) . " readable recent files")
  return l:recent_files[:49]  " Return up to 50 most recent files
endfunction

function! GetProcesses(grepBy)
  let l:output = systemlist('ps -aef | grep -i ' . a:grepBy)
  return l:output  
endfunction

function! ToggleViewMode(mode)
  if has_key(s:pages_data, s:view_mode)
     " . the line number of the current line we are on
     " save the current line of the page we are leaving from"
     let s:pages_data[s:view_mode].selected_line = line('.', s:popup_winid)
  endif

  let s:view_mode = a:mode
  if s:view_mode == 'ls'
    let s:curr_view_data = GetCurrDirFiles()
  elseif s:view_mode == 'recent'
    let s:curr_view_data = GetRecentFiles()
  elseif s:view_mode == 'marks'
    let s:curr_view_data = GetMarksList()
  elseif s:view_mode == 'process'
    let s:curr_view_data = GetProcesses('""')
  endif

  let s:search_query = ''
  " turn everything to use this pages_data for better control/functionality for each page created
  if has_key(s:pages_data, s:view_mode)
     let s:pages_data[s:view_mode].search_query = ''
  endif

  let s:search_mode = 0
  call DebugMsg("ToggleViewMode: New view_mode=" . s:view_mode . ", curr_view_data_count=" . len(s:curr_view_data))
  call UpdatePopup()
endfunction

function! M_EditFileMarkSelection(winid)
  "TODO should open the file list from the marks list. 3rd column i think
  " need to edit this to not assume the whole line is a file name. not sure for marks.
  " call s:OpenFileAction(a:winid, 'edit')
endfunction

" naming convention for actions specific to a page
function! P_DestroySelectedProcess(winid)
  let l:line = line('.', a:winid)
  if l:line > 0 && l:line <= len(s:curr_view_data)
    let l:process_info = s:curr_view_data[l:line - 1]
    let l:pid = split(l:process_info)[1]  " Assuming PID is the second field in ps output
    call DebugMsg("Attempting to kill process with PID: " . l:pid)
    let l:kill_output = system('kill -9 ' . l:pid)
    if v:shell_error
      call DebugMsg("Failed to kill process: " . l:kill_output)
    else
      call DebugMsg("Process killed successfully")
      let s:curr_view_data = GetProcesses('"'.s:search_query.'"')
      " call ToggleViewMode('process')  " Refresh the process list
    endif
  else
    call DebugMsg("Error: Invalid selected line " . l:line)
  endif
    call DebugMsg("the search query is " .s:search_query)
  call UpdatePopup()

endfunction

function! ClosePopup(id, result)
  let s:popup_winid = 0
  call DebugMsg("ClosePopup: Popup closed")
endfunction


" Command to create the popup
command! -bar FileList call InitPopup()

" Key mapping to open the file list popup
nnoremap <silent> <C-p> :FileList<CR>

" Configuration commands
" :setMaxFiles 100    . this will set s:max_files is now set to 100
command! -nargs=1 SetMaxFiles let s:max_files = <args>
" :AddIgnorePattern .tmp
command! -nargs=1 AddIgnorePattern call add(s:ignore_patterns, <args>)
" :ClearIgnorePatterns . This will clear the list ignore_patterns and doesn't take any arguments
command! -nargs=0 ClearIgnorePatterns let s:ignore_patterns = []

