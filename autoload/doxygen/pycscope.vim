" Pycscope module for doxygen

if !has('cscope')
    throw "Can't enable the pycscope module for doxygen, this Vim has ".
                \"no support for cscope files."
endif

" Global Options {{{

if !exists('g:doxygen_pycscope_executable')
    let g:doxygen_pycscope_executable = 'pycscope'
endif

if !exists('g:doxygen_pyscopefile')
    let g:doxygen_pyscopefile = 'pycscope.out'
endif

if !exists('g:doxygen_auto_add_pycscope')
    let g:doxygen_auto_add_pycscope = 1
endif

" }}}

" doxygen Module Interface {{{

let s:runner_exe = doxygen#get_plat_file('update_pyscopedb')
let s:unix_redir = (&shellredir =~# '%s') ? &shellredir : &shellredir . ' %s'
let s:added_dbs = []

function! doxygen#pycscope#init(project_root) abort
    let l:dbfile_path = doxygen#get_cachefile(
                \a:project_root, g:doxygen_pyscopefile)
    let b:doxygen_files['pycscope'] = l:dbfile_path

    if g:doxygen_auto_add_pycscope && filereadable(l:dbfile_path)
        if index(s:added_dbs, l:dbfile_path) < 0
            call add(s:added_dbs, l:dbfile_path)
            silent! execute 'cs add ' . fnameescape(l:dbfile_path)
        endif
    endif
endfunction

function! doxygen#pycscope#generate(proj_dir, tags_file, gen_opts) abort
    let l:cmd = [s:runner_exe]
    let l:cmd += ['-e', g:doxygen_pycscope_executable]
    let l:cmd += ['-p', a:proj_dir]
    let l:cmd += ['-f', a:tags_file]
    let l:file_list_cmd =
        \ doxygen#get_project_file_list_cmd(a:proj_dir)
    if !empty(l:file_list_cmd)
        let l:cmd += ['-L', '"' . l:file_list_cmd . '"']
    endif
    let l:cmd = doxygen#make_args(l:cmd)

    call doxygen#trace("Running: " . string(l:cmd))
    call doxygen#trace("In:      " . getcwd())
    if !g:doxygen_fake
		let l:job_opts = doxygen#build_default_job_options('pycscope')
        let l:job = doxygen#start_job(l:cmd, l:job_opts)
        call doxygen#add_job('pycscope', a:tags_file, l:job)
    else
        call doxygen#trace("(fake... not actually running)")
    endif
endfunction

function! doxygen#pycscope#on_job_exit(job, exit_val) abort
    let l:job_idx = doxygen#find_job_index_by_data('pycscope', a:job)
    let l:dbfile_path = doxygen#get_job_tags_file('pycscope', l:job_idx)
    call doxygen#remove_job('pycscope', l:job_idx)

    if a:exit_val == 0
        if index(s:added_dbs, l:dbfile_path) < 0
            call add(s:added_dbs, l:dbfile_path)
            silent! execute 'cs add ' . fnameescape(l:dbfile_path)
        else
            silent! execute 'cs reset'
        endif
    else
        call doxygen#warning(
                    \"doxygen: pycscope job failed, returned: ".
                    \string(a:exit_val))
    endif
endfunction

" }}}

