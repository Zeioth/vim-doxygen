" Cscope module for doxygen

if !has('cscope')
    throw "Can't enable the cscope module for doxygen, this Vim has ".
                \"no support for cscope files."
endif

" Global Options {{{

if !exists('g:doxygen_cscope_executable')
    let g:doxygen_cscope_executable = 'cscope'
endif

if !exists('g:doxygen_scopefile')
    let g:doxygen_scopefile = 'cscope.out'
endif

if !exists('g:doxygen_auto_add_cscope')
    let g:doxygen_auto_add_cscope = 1
endif

if !exists('g:doxygen_cscope_build_inverted_index')
    let g:doxygen_cscope_build_inverted_index = 0
endif

" }}}

" doxygen Module Interface {{{

let s:runner_exe = doxygen#get_plat_file('update_scopedb')
let s:unix_redir = (&shellredir =~# '%s') ? &shellredir : &shellredir . ' %s'
let s:added_dbs = []

function! doxygen#cscope#init(project_root) abort
    let l:dbfile_path = doxygen#get_cachefile(
                \a:project_root, g:doxygen_scopefile)
    let b:doxygen_files['cscope'] = l:dbfile_path

    if g:doxygen_auto_add_cscope && filereadable(l:dbfile_path)
        if index(s:added_dbs, l:dbfile_path) < 0
            call add(s:added_dbs, l:dbfile_path)
            silent! execute 'cs add ' . fnameescape(l:dbfile_path)
        endif
    endif
endfunction

function! doxygen#cscope#generate(proj_dir, tags_file, gen_opts) abort
    let l:cmd = [s:runner_exe]
    let l:cmd += ['-e', g:doxygen_cscope_executable]
    let l:cmd += ['-p', a:proj_dir]
    let l:cmd += ['-f', a:tags_file]
    let l:file_list_cmd =
        \ doxygen#get_project_file_list_cmd(a:proj_dir)
    if !empty(l:file_list_cmd)
        let l:cmd += ['-L', '"' . l:file_list_cmd . '"']
    endif
    if g:doxygen_cscope_build_inverted_index
        let l:cmd += ['-I']
    endif
    let l:cmd = doxygen#make_args(l:cmd)

    call doxygen#trace("Running: " . string(l:cmd))
    call doxygen#trace("In:      " . getcwd())
    if !g:doxygen_fake
		let l:job_opts = doxygen#build_default_job_options('cscope')
        let l:job = doxygen#start_job(l:cmd, l:job_opts)
        call doxygen#add_job('cscope', a:tags_file, l:job)
    else
        call doxygen#trace("(fake... not actually running)")
    endif
endfunction

function! doxygen#cscope#on_job_exit(job, exit_val) abort
    let l:job_idx = doxygen#find_job_index_by_data('cscope', a:job)
    let l:dbfile_path = doxygen#get_job_tags_file('cscope', l:job_idx)
    call doxygen#remove_job('cscope', l:job_idx)

    if a:exit_val == 0
        if index(s:added_dbs, l:dbfile_path) < 0
            call add(s:added_dbs, l:dbfile_path)
            silent! execute 'cs add ' . fnameescape(l:dbfile_path)
        else
            silent! execute 'cs reset'
        endif
    elseif !g:__doxygen_vim_is_leaving
        call doxygen#warning(
                    \"cscope job failed, returned: ".
                    \string(a:exit_val))
    endif
    if has('win32') && g:__doxygen_vim_is_leaving
        " The process got interrupted because Vim is quitting.
        " Remove the db file on Windows because there's no `trap`
        " statement in the update script.
        try | call delete(l:dbfile_path) | endtry
    endif
endfunction

" }}}

