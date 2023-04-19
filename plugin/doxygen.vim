" doxygen.vim - Automatic doxygen management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0

" Globals {{{

if (&cp || get(g:, 'doxygen_dont_load', 0))
    finish
endif

if v:version < 704
    echoerr "doxygen: this plugin requires vim >= 7.4."
    finish
endif

if !(has('job') || (has('nvim') && exists('*jobwait')))
    echoerr "doxygen: this plugin requires the job API from Vim8 or Neovim."
    finish
endif

let g:doxygen_debug = get(g:, 'doxygen_debug', 0)

if (exists('g:loaded_doxygen') && !g:doxygen_debug)
    finish
endif
if (exists('g:loaded_doxygen') && g:doxygen_debug)
    echom "Reloaded doxygen."
endif
let g:loaded_doxygen = 1

let g:doxygen_trace = get(g:, 'doxygen_trace', 0)
let g:doxygen_fake = get(g:, 'doxygen_fake', 0)
let g:doxygen_background_update = get(g:, 'doxygen_background_update', 1)
let g:doxygen_pause_after_update = get(g:, 'doxygen_pause_after_update', 0)
let g:doxygen_enabled = get(g:, 'doxygen_enabled', 1)
let g:doxygen_modules = get(g:, 'doxygen_modules', ['ctags'])

let g:doxygen_init_user_func = get(g:, 'doxygen_init_user_func', 
            \get(g:, 'doxygen_enabled_user_func', ''))

let g:doxygen_add_ctrlp_root_markers = get(g:, 'doxygen_add_ctrlp_root_markers', 1)
let g:doxygen_add_default_project_roots = get(g:, 'doxygen_add_default_project_roots', 1)
let g:doxygen_project_root = get(g:, 'doxygen_project_root', [])
if g:doxygen_add_default_project_roots
    let g:doxygen_project_root += ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout']
endif

let g:doxygen_project_root_finder = get(g:, 'doxygen_project_root_finder', '')

let g:doxygen_project_info = get(g:, 'doxygen_project_info', [])
call add(g:doxygen_project_info, {'type': 'python', 'file': 'setup.py'})
call add(g:doxygen_project_info, {'type': 'ruby', 'file': 'Gemfile'})

let g:doxygen_exclude_project_root = get(g:, 'doxygen_exclude_project_root', 
            \['/usr/local', '/opt/homebrew', '/home/linuxbrew/.linuxbrew'])

let g:doxygen_exclude_filetypes = get(g:, 'doxygen_exclude_filetypes', [])
let g:doxygen_resolve_symlinks = get(g:, 'doxygen_resolve_symlinks', 0)
let g:doxygen_generate_on_new = get(g:, 'doxygen_generate_on_new', 1)
let g:doxygen_generate_on_missing = get(g:, 'doxygen_generate_on_missing', 1)
let g:doxygen_generate_on_write = get(g:, 'doxygen_generate_on_write', 1)
let g:doxygen_generate_on_empty_buffer = get(g:, 'doxygen_generate_on_empty_buffer', 0)
let g:doxygen_file_list_command = get(g:, 'doxygen_file_list_command', '')

let g:doxygen_use_jobs = get(g:, 'doxygen_use_jobs', has('job'))

if !exists('g:doxygen_cache_dir')
    let g:doxygen_cache_dir = ''
elseif !empty(g:doxygen_cache_dir)
    " Make sure we get an absolute/resolved path (e.g. expanding `~/`), and
    " strip any trailing slash.
    let g:doxygen_cache_dir = fnamemodify(g:doxygen_cache_dir, ':p')
    let g:doxygen_cache_dir = fnamemodify(g:doxygen_cache_dir, ':s?[/\\]$??')
endif

let g:doxygen_define_advanced_commands = get(g:, 'doxygen_define_advanced_commands', 0)

if g:doxygen_cache_dir != '' && !isdirectory(g:doxygen_cache_dir)
    call mkdir(g:doxygen_cache_dir, 'p')
endif

if has('win32')
    let g:doxygen_plat_dir = expand('<sfile>:h:h:p') . "\\plat\\win32\\"
    let g:doxygen_res_dir = expand('<sfile>:h:h:p') . "\\res\\"
    let g:doxygen_script_ext = '.cmd'
else
    let g:doxygen_plat_dir = expand('<sfile>:h:h:p') . '/plat/unix/'
    let g:doxygen_res_dir = expand('<sfile>:h:h:p') . '/res/'
    let g:doxygen_script_ext = '.sh'
endif

let g:__doxygen_vim_is_leaving = 0

" }}}

" doxygen Setup {{{

augroup doxygen_detect
    autocmd!
    autocmd BufNewFile,BufReadPost *  call doxygen#setup_doxygen()
    autocmd VimEnter               *  if expand('<amatch>')==''|call doxygen#setup_doxygen()|endif
    autocmd VimLeavePre            *  call doxygen#on_vim_leave_pre()
    autocmd VimLeave               *  call doxygen#on_vim_leave()
augroup end

" }}}

" Toggles and Miscellaneous Commands {{{

if g:doxygen_define_advanced_commands
    command! DoxygenToggleEnabled :let g:doxygen_enabled=!g:doxygen_enabled
    command! DoxygenToggleTrace   :call doxygen#toggletrace()
endif

if g:doxygen_debug
    command! DoxygenToggleFake    :call doxygen#fake()
endif

" }}}

