" doxygen.vim - Automatic doxygen management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0




" Path helper methods {{{

function! doxygen#chdir(path)
    if has('nvim')
        let chdir = haslocaldir() ? 'lcd' : haslocaldir(-1, 0) ? 'tcd' : 'cd'
    else
        let chdir = haslocaldir() ? ((haslocaldir() == 1) ? 'lcd' : 'tcd') : 'cd'
    endif
    execute chdir fnameescape(a:path)
endfunction

" Throw an exception message.
function! doxygen#throw(message)
    throw "doxygen: " . a:message
endfunction

" Show an error message.
function! doxygen#error(message)
    let v:errmsg = "doxygen: " . a:message
    echoerr v:errmsg
endfunction

" Show a warning message.
function! doxygen#warning(message)
    echohl WarningMsg
    echom "doxygen: " . a:message
    echohl None
endfunction

" Prints a message if debug tracing is enabled.
function! doxygen#trace(message, ...)
    if g:doxygen_trace || (a:0 && a:1)
        let l:message = "doxygen: " . a:message
        echom l:message
    endif
endfunction

" Strips the ending slash in a path.
function! doxygen#stripslash(path)
    return fnamemodify(a:path, ':s?[/\\]$??')
endfunction

" Normalizes the slashes in a path.
function! doxygen#normalizepath(path)
    if exists('+shellslash') && &shellslash
        return substitute(a:path, '\v/', '\\', 'g')
    elseif has('win32')
        return substitute(a:path, '\v/', '\\', 'g')
    else
        return a:path
    endif
endfunction

" Shell-slashes the path (opposite of `normalizepath`).
function! doxygen#shellslash(path)
    if exists('+shellslash') && !&shellslash
        return substitute(a:path, '\v\\', '/', 'g')
    else
        return a:path
    endif
endfunction

" Returns whether a path is rooted.
if has('win32') || has('win64')
    function! doxygen#is_path_rooted(path) abort
        return len(a:path) >= 2 && (
                    \a:path[0] == '/' || a:path[0] == '\' || a:path[1] == ':')
    endfunction
else
    function! doxygen#is_path_rooted(path) abort
        return !empty(a:path) && a:path[0] == '/'
    endfunction
endif

" }}}




" Doxygen helper methods {{{

let s:known_files = []
let s:known_projects = {}

" Finds the first directory with a project marker by walking up from the given
" file path.
function! doxygen#get_project_root(path) abort
    if g:doxygen_project_root_finder != ''
        return call(g:doxygen_project_root_finder, [a:path])
    endif
    return doxygen#default_get_project_root(a:path)
endfunction

" Default implementation for finding project markers... useful when a custom
" finder (`g:doxygen_project_root_finder`) wants to fallback to the default
" behaviour.
function! doxygen#default_get_project_root(path) abort
    let l:path = doxygen#stripslash(a:path)
    let l:previous_path = ""
    let l:markers = g:doxygen_project_root[:]
    while l:path != l:previous_path
        for root in l:markers
            if !empty(globpath(l:path, root, 1))
                let l:proj_dir = simplify(fnamemodify(l:path, ':p'))
                let l:proj_dir = doxygen#stripslash(l:proj_dir)
                if l:proj_dir == ''
                    call doxygen#trace("Found project marker '" . root .
                                \"' at the root of your file-system! " .
                                \" That's probably wrong, disabling " .
                                \"doxygen for this file...",
                                \1)
                    call doxygen#throw("Marker found at root, aborting.")
                endif
                for ign in g:doxygen_exclude_project_root
                    if l:proj_dir == ign
                        call doxygen#trace(
                                    \"Ignoring project root '" . l:proj_dir .
                                    \"' because it is in the list of ignored" .
                                    \" projects.")
                        call doxygen#throw("Ignore project: " . l:proj_dir)
                    endif
                endfor
                return l:proj_dir
            endif
        endfor
        let l:previous_path = l:path
        let l:path = fnamemodify(l:path, ':h')
    endwhile
    call doxygen#throw("Can't figure out what file to use for: " . a:path)
endfunction

" }}}




" ============================================================================
" YOU PROBABLY ONLY CARE FROM HERE
" ============================================================================

" Doxygen Setup {{{

" Setup doxygen for the current buffer.
function! doxygen#setup_doxygen() abort
    if exists('b:doxygen_files') && !g:doxygen_debug
        " This buffer already has doxygen support.
        return
    endif

    " Don't setup doxygen for anything that's not a normal buffer
    " (so don't do anything for help buffers and quickfix windows and
    "  other such things)
    " Also don't do anything for the default `[No Name]` buffer you get
    " after starting Vim.
    if &buftype != '' || 
          \(bufname('%') == '' && !g:doxygen_generate_on_empty_buffer)
        return
    endif

    " Don't setup doxygen for things that don't need it, or that could
    " cause problems.
    if index(g:doxygen_exclude_filetypes, &filetype) >= 0
        return
    endif

    " Let the user specify custom ways to disable doxygen.
    if g:doxygen_init_user_func != '' &&
                \!call(g:doxygen_init_user_func, [expand('%:p')])
        call doxygen#trace("Ignoring '" . bufname('%') . "' because of " .
                    \"custom user function.")
        return
    endif

    " Try and find what file we should manage.
    call doxygen#trace("Scanning buffer '" . bufname('%') . "' for doxygen setup...")
    try
        let l:buf_dir = expand('%:p:h', 1)
        if g:doxygen_resolve_symlinks
            let l:buf_dir = fnamemodify(resolve(expand('%:p', 1)), ':p:h')
        endif
        if !exists('b:doxygen_root')
            let b:doxygen_root = doxygen#get_project_root(l:buf_dir)
        endif
        if !len(b:doxygen_root)
            call doxygen#trace("no valid project root.. no doxygen support.")
            return
        endif
        if filereadable(b:doxygen_root . '/.nodoxygen')
            call doxygen#trace("'.nodoxygen' file found... no doxygen support.")
            return
        endif

        let b:doxygen_files = {}
        " for module in g:doxygen_modules
        "     call call("doxygen#".module."#init", [b:doxygen_root])
        " endfor
    catch /^doxygen\:/
        call doxygen#trace("No doxygen support for this buffer.")
        return
    endtry

    " We know what file to manage! Now set things up.
    call doxygen#trace("Setting doxygen for buffer '".bufname('%')."'")

    " Autocommands for updating doxygen on save.
    " We need to pass the buffer number to the callback function in the rare
    " case that the current buffer is changed by another `BufWritePost`
    " callback. This will let us get that buffer's variables without causing
    " errors.
    let l:bn = bufnr('%')
    execute 'augroup doxygen_buffer_' . l:bn
    execute '  autocmd!'
    execute '  autocmd BufWritePost <buffer=' . l:bn . '> call s:write_triggered_update_doxygen(' . l:bn . ')'
    execute 'augroup end'

    " Miscellaneous commands.
    command! -buffer -bang DoxygenRegen :call s:manual_doxygen_regen(<bang>0)
    command! -buffer -bang DoxygenOpen :call s:doxygen_open()

    " Keybindings
    nmap <silent> g:doxygen_shortcut_regen :<C-u>DoxygenRegen<CR>
    nmap <silent> g:doxygen_shortcut_open :<C-u>DoxygenOpen<CR>

endfunction

" }}}




"  Doxygen Management {{{

" (Re)Generate the docs for the current project.
function! s:manual_doxygen_regen(bang) abort
    let l:restore_prev_trace = 0
    let l:prev_trace = g:doxygen_trace
    if &verbose > 0
        let g:doxygen_trace = 1
        let l:restore_prev_trace = 1
    endif

    try
        let l:bn = bufnr('%')
        for module in g:doxygen_modules
            call s:update_doxygen(l:bn, module, a:bang, 0)
        endfor
        silent doautocmd User doxygenUpdating
    finally
        if l:restore_prev_trace
            let g:doxygen_trace = l:prev_trace
        endif
    endtry
endfunction

" Open doxygen in the browser.
function! s:doxygen_open() abort
    try
        let l:bn = bufnr('%')
        let l:proj_dir = getbufvar(l:bn, 'doxygen_root')
        echo g:doxygen_browser_cmd . ' ' . l:proj_dir . g:doxygen_browser_file
        call system(g:doxygen_browser_cmd . ' ' . l:proj_dir . g:doxygen_browser_file)
    endtry
endfunction

" (re)generate doxygen for a buffer that just go saved.
function! s:write_triggered_update_doxygen(bufno) abort
    if g:doxygen_enabled && g:doxygen_generate_on_write
      call s:update_doxygen(a:bufno, 0, 2)
    endif
    silent doautocmd user doxygenupdating
endfunction

" update doxygen for the current buffer's file.
" write_mode:
"   0: update doxygen if it exists, generate it otherwise.
"   1: always generate (overwrite) doxygen.
"
" queue_mode:
"   0: if an update is already in progress, report it and abort.
"   1: if an update is already in progress, abort silently.
"   2: if an update is already in progress, queue another one.
function! s:update_doxygen(bufno, write_mode, queue_mode) abort
    " figure out where to save.
    let l:buf_doxygen_files = getbufvar(a:bufno, 'doxygen_files')
    let l:proj_dir = getbufvar(a:bufno, 'doxygen_root')

    " Switch to the project root to make the command line smaller, and make
    " it possible to get the relative path of the filename.
    let l:prev_cwd = getcwd()
    call doxygen#chdir(l:proj_dir)
    try

        " Clone the doxygen config into the project where specified.
        " TODO: Only if directory doesn't exist already
        if g:doxygen_auto_setup == 1
          let g:doxygen_clone_template_cmd = g:doxygen_clone_cmd . " " . g:doxygen_clone_config_repo . " " . g:doxygen_clone_destiny_dir
          call system(g:doxygen_clone_template_cmd)
        endif       

        " Generate the doxygen docs where specified.
        if g:doxygen_auto_regen == 1
          call system(g:doxygen_cmd)
        endif       


    catch /^doxygen\:/
        echom "Error while generating ".a:module." file:"
        echom v:exception
    finally
        " Restore the current directory...
        call doxygen#chdir(l:prev_cwd)
    endtry
endfunction

" }}}
