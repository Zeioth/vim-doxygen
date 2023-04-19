" doxygen.vim - Automatic doxygen management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0

" Utilities {{{

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

" Gets a file path in the correct `plat` folder.
function! doxygen#get_plat_file(filename) abort
    return g:doxygen_plat_dir . a:filename . g:doxygen_script_ext
endfunction

" Gets a file path in the resource folder.
function! doxygen#get_res_file(filename) abort
    return g:doxygen_res_dir . a:filename
endfunction

" Generate a path for a given filename in the cache directory.
function! doxygen#get_cachefile(root_dir, filename) abort
    if doxygen#is_path_rooted(a:filename)
        return a:filename
    endif
    let l:tag_path = doxygen#stripslash(a:root_dir) . '/' . a:filename
    if g:doxygen_cache_dir != ""
        " Put the tag file in the cache dir instead of inside the
        " project root.
        let l:tag_path = g:doxygen_cache_dir . '/' .
                    \tr(l:tag_path, '\/: ', '---_')
        let l:tag_path = substitute(l:tag_path, '/\-', '/', '')
        let l:tag_path = substitute(l:tag_path, '[\-_]*$', '', '')
    endif
    let l:tag_path = doxygen#normalizepath(l:tag_path)
    return l:tag_path
endfunction

" Makes sure a given command starts with an executable that's in the PATH.
function! doxygen#validate_cmd(cmd) abort
    if !empty(a:cmd) && executable(split(a:cmd)[0])
        return a:cmd
    endif
    return ""
endfunction

" Makes an appropriate command line for use with `job_start` by converting
" a list of possibly quoted arguments into a single string on Windows, or
" into a list of unquoted arguments on Unix/Mac.
if has('win32') || has('win64')
    function! doxygen#make_args(cmd) abort
        return join(a:cmd, ' ')
    endfunction
else
    function! doxygen#make_args(cmd) abort
        let l:outcmd = []
        for cmdarg in a:cmd
            " Thanks Vimscript... you can use negative integers for strings
            " in the slice notation, but not for indexing characters :(
            let l:arglen = strlen(cmdarg)
            if (cmdarg[0] == '"' && cmdarg[l:arglen - 1] == '"') || 
                        \(cmdarg[0] == "'" && cmdarg[l:arglen - 1] == "'")
                " This was quoted, so there are probably things to escape.
                let l:escapedarg = cmdarg[1:-2] " substitute(cmdarg[1:-2], '\ ', '\\ ', 'g')
                call add(l:outcmd, l:escapedarg)
            else
                call add(l:outcmd, cmdarg)
            endif
        endfor
        return l:outcmd
    endfunction
endif

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

" doxygen Setup {{{

let s:known_files = []
let s:known_projects = {}

function! s:cache_project_root(path) abort
    let l:result = {}

    for proj_info in g:doxygen_project_info
        let l:filematch = get(proj_info, 'file', '')
        if l:filematch != '' && filereadable(a:path . '/'. l:filematch)
            let l:result = copy(proj_info)
            break
        endif

        let l:globmatch = get(proj_info, 'glob', '')
        if l:globmatch != '' && glob(a:path . '/' . l:globmatch) != ''
            let l:result = copy(proj_info)
            break
        endif
    endfor

    let s:known_projects[a:path] = l:result
endfunction

function! doxygen#get_project_file_list_cmd(path) abort
    if type(g:doxygen_file_list_command) == type("")
        return doxygen#validate_cmd(g:doxygen_file_list_command)
    elseif type(g:doxygen_file_list_command) == type({})
        let l:markers = get(g:doxygen_file_list_command, 'markers', [])
        if type(l:markers) == type({})
            for [marker, file_list_cmd] in items(l:markers)
                if !empty(globpath(a:path, marker, 1))
                    return doxygen#validate_cmd(file_list_cmd)
                endif
            endfor
        endif
        return get(g:doxygen_file_list_command, 'default', "")
    endif
    return ""
endfunction

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
    if g:doxygen_add_ctrlp_root_markers && exists('g:ctrlp_root_markers')
        for crm in g:ctrlp_root_markers
            if index(l:markers, crm) < 0
                call add(l:markers, crm)
            endif
        endfor
    endif
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
    call doxygen#throw("Can't figure out what tag file to use for: " . a:path)
endfunction

" Get info on the project we're inside of.
function! doxygen#get_project_info(path) abort
    return get(s:known_projects, a:path, {})
endfunction

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

    " Try and find what tags file we should manage.
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
        if filereadable(b:doxygen_root . '/.notags')
            call doxygen#trace("'.notags' file found... no doxygen support.")
            return
        endif

        if !has_key(s:known_projects, b:doxygen_root)
            call s:cache_project_root(b:doxygen_root)
        endif
        if g:doxygen_trace
            let l:projnfo = doxygen#get_project_info(b:doxygen_root)
            if l:projnfo != {}
                call doxygen#trace("Setting project type to ".l:projnfo['type'])
            else
                call doxygen#trace("No specific project type.")
            endif
        endif

        let b:doxygen_files = {}
        for module in g:doxygen_modules
            call call("doxygen#".module."#init", [b:doxygen_root])
        endfor
    catch /^doxygen\:/
        call doxygen#trace("No doxygen support for this buffer.")
        return
    endtry

    " We know what tags file to manage! Now set things up.
    call doxygen#trace("Setting doxygen for buffer '".bufname('%')."'")

    " Autocommands for updating the tags on save.
    " We need to pass the buffer number to the callback function in the rare
    " case that the current buffer is changed by another `BufWritePost`
    " callback. This will let us get that buffer's variables without causing
    " errors.
    let l:bn = bufnr('%')
    execute 'augroup doxygen_buffer_' . l:bn
    execute '  autocmd!'
    execute '  autocmd BufWritePost <buffer=' . l:bn . '> call s:write_triggered_update_doxyfile(' . l:bn . ')'
    execute 'augroup end'

    " Miscellaneous commands.
    command! -buffer -bang DoxygenUpdate :call s:manual_update_doxyfile(<bang>0)

    " Add these tags files to the known tags files.
    for module in keys(b:doxygen_files)
        let l:tagfile = b:doxygen_files[module]
        let l:found = index(s:known_files, l:tagfile)
        if l:found < 0
            call add(s:known_files, l:tagfile)

            " Generate this new file depending on settings and stuff.
            if g:doxygen_enabled
                if g:doxygen_generate_on_missing && !filereadable(l:tagfile)
                    call doxygen#trace("Generating missing tags file: " . l:tagfile)
                    call s:update_doxyfile(l:bn, module, 1, 1)
                elseif g:doxygen_generate_on_new
                    call doxygen#trace("Generating tags file: " . l:tagfile)
                    call s:update_doxyfile(l:bn, module, 1, 1)
                endif
            endif
        endif
    endfor
endfunction

" Set a variable on exit so that we don't complain when a job gets killed.
function! doxygen#on_vim_leave_pre() abort
    let g:__doxygen_vim_is_leaving = 1
endfunction

function! doxygen#on_vim_leave() abort
    if has('win32') && !has('nvim')
        " Vim8 doesn't seem to be killing child processes soon enough for
        " us to clean things up inside this plugin, so do it ourselves.
        " TODO: test other platforms and other vims
        for module in g:doxygen_modules
            for upd_info in s:update_in_progress[module]
                let l:job = upd_info[1]
                call job_stop(l:job, "term")
                let l:status = job_status(l:job)
                if l:status == "run"
                    call job_stop(l:job, "kill")
                endif
            endfor
        endfor
    endif
endfunction

" }}}

"  Job Management {{{

" List of queued-up jobs, and in-progress jobs, per module.
let s:update_queue = {}
let s:update_in_progress = {}
for module in g:doxygen_modules
    let s:update_queue[module] = []
    let s:update_in_progress[module] = []
endfor

" Adds a started job to the list of ongoing updates.
" Must pass the tags file being created/updated, and the job data as
" returned by the doxygen#start_job function
function! doxygen#add_job(module, tags_file, data) abort
    call add(s:update_in_progress[a:module], [a:tags_file, a:data])
endfunction

" Finds an ongoing job by tags file
function! doxygen#find_job_index_by_tags_file(module, tags_file) abort
    let l:idx = -1
    for upd_info in s:update_in_progress[a:module]
        let l:idx += 1
        if upd_info[0] == a:tags_file
            return l:idx
        endif
    endfor
    return -1
endfunction

" Finds an ongoing job by job data
function! doxygen#find_job_index_by_data(module, data) abort
    let l:idx = -1
    for upd_info in s:update_in_progress[a:module]
        let l:idx += 1
        if upd_info[1] == a:data
            return l:idx
        endif
    endfor
    return -1
endfunction

" Gets the tags file of a given job
function! doxygen#get_job_tags_file(module, job_idx) abort
    return s:update_in_progress[a:module][a:job_idx][0]
endfunction

" Gets the job data of the i-th job
function! doxygen#get_job_data(module, job_idx) abort
    return s:update_in_progress[a:module][a:job_idx][1]
endfunction

" Removes the i-th job from the ongoing jobs
function! doxygen#remove_job(module, job_idx) abort
    let [l:tags_file, l:job_data] = s:update_in_progress[a:module][a:job_idx]
    call remove(s:update_in_progress[a:module], a:job_idx)

    " Run the user callback for finished jobs.
    silent doautocmd User doxygenUpdated

    " See if we had any more updates queued up for this.
    let l:qu_idx = -1
    for qu_info in s:update_queue[a:module]
        let l:qu_idx += 1
        if qu_info[0] == l:tags_file
            break
        endif
    endfor
    if l:qu_idx >= 0
        let l:qu_info = s:update_queue[a:module][l:qu_idx]
        call remove(s:update_queue[a:module], l:qu_idx)

        if bufexists(l:qu_info[1])
            call doxygen#trace("Finished ".a:module." job, ".
                        \"running queued update for '".l:tags_file."'.")
            call s:update_doxyfile(l:qu_info[1], a:module, l:qu_info[2], 2)
        else
            call doxygen#trace("Finished ".a:module." job, ".
                        \"but skipping queued update for '".l:tags_file."' ".
                        \"because originating buffer doesn't exist anymore.")
        endif
    else
        call doxygen#trace("Finished ".a:module." job.")
    endif

    return [l:tags_file, l:job_data]
endfunction

" Removes the job from the ongoing jobs given its job data
function! doxygen#remove_job_by_data(module, data) abort
    let l:idx = doxygen#find_job_index_by_data(a:module, a:data)
    return doxygen#remove_job(a:module, l:idx)
endfunction

" }}}

"  Tags File Management {{{

" (Re)Generate the tags file for the current buffer's file.
function! s:manual_update_doxyfile(bang) abort
    let l:restore_prev_trace = 0
    let l:prev_trace = g:doxygen_trace
    if &verbose > 0
        let g:doxygen_trace = 1
        let l:restore_prev_trace = 1
    endif

    try
        let l:bn = bufnr('%')
        for module in g:doxygen_modules
            call s:update_doxyfile(l:bn, module, a:bang, 0)
        endfor
        silent doautocmd User doxygenUpdating
    finally
        if l:restore_prev_trace
            let g:doxygen_trace = l:prev_trace
        endif
    endtry
endfunction

" (Re)Generate the tags file for a buffer that just go saved.
function! s:write_triggered_update_doxyfile(bufno) abort
    if g:doxygen_enabled && g:doxygen_generate_on_write
        for module in g:doxygen_modules
            call s:update_doxyfile(a:bufno, module, 0, 2)
        endfor
    endif
    silent doautocmd User doxygenUpdating
endfunction

" Update the doxyfile for the current buffer's file.
" write_mode:
"   0: update the doxyfile if it exists, generate it otherwise.
"   1: always generate (overwrite) the doxyfile.
"
" queue_mode:
"   0: if an update is already in progress, report it and abort.
"   1: if an update is already in progress, abort silently.
"   2: if an update is already in progress, queue another one.
function! s:update_doxyfile(bufno, module, write_mode, queue_mode) abort
    " Figure out where to save.
    let l:buf_doxygen_files = getbufvar(a:bufno, 'doxygen_files')
    let l:tags_file = l:buf_doxygen_files[a:module]
    let l:proj_dir = getbufvar(a:bufno, 'doxygen_root')

    " Check that there's not already an update in progress.
    let l:in_progress_idx = doxygen#find_job_index_by_tags_file(
                \a:module, l:tags_file)
    if l:in_progress_idx >= 0
        if a:queue_mode == 2
            let l:needs_queuing = 1
            for qu_info in s:update_queue[a:module]
                if qu_info[0] == l:tags_file
                    let l:needs_queuing = 0
                    break
                endif
            endfor
            if l:needs_queuing
                call add(s:update_queue[a:module], 
                            \[l:tags_file, a:bufno, a:write_mode])
            endif
            call doxygen#trace("Tag file '" . l:tags_file . 
                        \"' is already being updated. Queuing it up...")
        elseif a:queue_mode == 1
            call doxygen#trace("Tag file '" . l:tags_file .
                        \"' is already being updated. Skipping...")
        elseif a:queue_mode == 0
            echom "doxygen: The tags file is already being updated, " .
                        \"please try again later."
        else
            call doxygen#throw("Unknown queue mode: " . a:queue_mode)
        endif

        " Don't update the tags right now.
        return
    endif

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

        " Generate dos the doxygen docs into the project where specified.
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

" Utility Functions {{{

function! doxygen#rescan(...)
    if exists('b:doxygen_files')
        unlet b:doxygen_files
    endif
    if a:0 && a:1
        let l:trace_backup = g:doxygen_trace
        let l:doxygen_trace = 1
    endif
    call doxygen#setup_doxygen()
    if a:0 && a:1
        let g:doxygen_trace = l:trace_backup
    endif
endfunction

function! doxygen#toggletrace(...)
    let g:doxygen_trace = !g:doxygen_trace
    if a:0 > 0
        let g:doxygen_trace = a:1
    endif
    if g:doxygen_trace
        echom "doxygen: Tracing is enabled."
    else
        echom "doxygen: Tracing is disabled."
    endif
    echom ""
endfunction

function! doxygen#fake(...)
    let g:doxygen_fake = !g:doxygen_fake
    if a:0 > 0
        let g:doxygen_fake = a:1
    endif
    if g:doxygen_fake
        echom "doxygen: Now faking doxygen."
    else
        echom "doxygen: Now running doxygen for real."
    endif
    echom ""
endfunction

function! doxygen#default_stdout_cb(chan, msg) abort
    call doxygen#trace('[job stdout]: '.string(a:msg))
endfunction

function! doxygen#default_stderr_cb(chan, msg) abort
    call doxygen#trace('[job stderr]: '.string(a:msg))
endfunction

if has('nvim')
    " Neovim job API.
    function! s:nvim_job_exit_wrapper(real_cb, job, exit_code, event_type) abort
        call call(a:real_cb, [a:job, a:exit_code])
    endfunction

    function! s:nvim_job_out_wrapper(real_cb, job, lines, event_type) abort
        call call(a:real_cb, [a:job, a:lines])
    endfunction

    function! doxygen#build_default_job_options(module) abort
       " Neovim kills jobs on exit, which is what we want.
       let l:job_opts = {
                \'on_exit': function(
                \    '<SID>nvim_job_exit_wrapper',
                \    ['doxygen#'.a:module.'#on_job_exit']),
                \'on_stdout': function(
                \    '<SID>nvim_job_out_wrapper',
                \    ['doxygen#default_stdout_cb']),
                \'on_stderr': function(
                \    '<SID>nvim_job_out_wrapper',
                \    ['doxygen#default_stderr_cb'])
                \}
       return l:job_opts
    endfunction

    function! doxygen#start_job(cmd, opts) abort
        return jobstart(a:cmd, a:opts)
    endfunction
else
    " Vim8 job API.
    function! doxygen#build_default_job_options(module) abort
        let l:job_opts = {
                 \'exit_cb': 'doxygen#'.a:module.'#on_job_exit',
                 \'out_cb': 'doxygen#default_stdout_cb',
                 \'err_cb': 'doxygen#default_stderr_cb',
                 \'stoponexit': 'term'
                 \}
        return l:job_opts
    endfunction

    function! doxygen#start_job(cmd, opts) abort
        return job_start(a:cmd, a:opts)
    endfunction
endif

" Returns which modules are currently generating something for the
" current buffer.
function! doxygen#inprogress()
    " Does this buffer have doxygen enabled?
    if !exists('b:doxygen_files')
        return []
    endif

    " Find any module that has a job in progress for any of this buffer's
    " tags files.
    let l:modules_in_progress = []
    for [module, tags_file] in items(b:doxygen_files)
        let l:jobidx = doxygen#find_job_index_by_tags_file(module, tags_file)
        if l:jobidx >= 0
            call add(l:modules_in_progress, module)
        endif
    endfor
    return l:modules_in_progress
endfunction

" }}}

" Statusline Functions {{{

" Prints whether a tag file is being generated right now for the current
" buffer in the status line.
"
" Arguments can be passed:
" - args 1 and 2 are the prefix and suffix, respectively, of whatever output,
"   if any, is going to be produced.
"   (defaults to empty strings)
" - arg 3 is the text to be shown if tags are currently being generated.
"   (defaults to the name(s) of the modules currently generating).

function! doxygen#statusline(...) abort
    let l:modules_in_progress = doxygen#inprogress()
    if empty(l:modules_in_progress)
       return ''
    endif

    let l:prefix = ''
    let l:suffix = ''
    if a:0 > 0
       let l:prefix = a:1
    endif
    if a:0 > 1
       let l:suffix = a:2
    endif

    if a:0 > 2
       let l:genmsg = a:3
    else
       let l:genmsg = join(l:modules_in_progress, ',')
    endif

    return l:prefix.l:genmsg.l:suffix
endfunction

" Same as `doxygen#statusline`, but the only parameter is a `Funcref` or
" function name that will get passed the list of modules currently generating
" something. This formatter function should return the string to display in
" the status line.

function! doxygen#statusline_cb(fmt_cb, ...) abort
    let l:modules_in_progress = doxygen#inprogress()

    if (a:0 == 0 || !a:1) && empty(l:modules_in_progress)
       return ''
    endif

    return call(a:fmt_cb, [l:modules_in_progress])
endfunction

" }}}

