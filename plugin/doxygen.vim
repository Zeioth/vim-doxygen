" doxygen.vim - Automatic doxygen management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0




" Globals - Boiler plate {{{

if (&cp || get(g:, 'doxygen_dont_load', 0))
    finish
endif

if v:version < 704
    echoerr "doxygen: this plugin requires vim >= 7.4."
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

let g:doxygen_enabled = get(g:, 'doxygen_enabled', 1)

" }}}




" Globals - For border cases {{{


let g:doxygen_project_root = get(g:, 'doxygen_project_root', ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout'])

let g:doxygen_project_root_finder = get(g:, 'doxygen_project_root_finder', '')

let g:doxygen_exclude_project_root = get(g:, 'doxygen_exclude_project_root', 
            \['/usr/local', '/opt/homebrew', '/home/linuxbrew/.linuxbrew'])

let g:doxygen_exclude_filetypes = get(g:, 'doxygen_exclude_filetypes', [])
let g:doxygen_resolve_symlinks = get(g:, 'doxygen_resolve_symlinks', 0)
let g:doxygen_generate_on_new = get(g:, 'doxygen_generate_on_new', 1)
let g:doxygen_generate_on_write = get(g:, 'doxygen_generate_on_write', 1)
let g:doxygen_generate_on_empty_buffer = get(g:, 'doxygen_generate_on_empty_buffer', 0)

let g:doxygen_init_user_func = get(g:, 'doxygen_init_user_func', 
            \get(g:, 'doxygen_enabled_user_func', ''))

let g:doxygen_define_advanced_commands = get(g:, 'doxygen_define_advanced_commands', 0)


" }}}




" Globals - The important stuff {{{

let g:doxygen_auto_setup = get(g:, 'doxygen_auto_setup', 1)

let g:doxygen_clone_config_repo = get(g:, 'doxygen_clone_config_repo', 'https://github.com/Zeioth/vim-doxygen-template.git')
let g:doxygen_clone_cmd = get(g:, 'doxygen_clone_cmd', 'git clone')
let g:doxygen_clone_destiny_dir = get(g:, 'doxygen_clone_destiny_dir', './.project-documentation')
let g:doxygen_clone_post_cmd = get(g:, 'doxygen_clone_post_cmd', '&& rm -r ' . g:doxygen_clone_destiny_dir . '/.git')

" Doxygen - Auto regen
let g:doxygen_auto_regen = get(g:, 'doxygen_auto_regen', 1)
let g:doxygen_cmd = get(g:, 'doxygen_cmd', 'cd ./.project-documentation/doxygen-conf/ && doxygen ./DoxyFile')

" Doxygen - Open on browser
let g:doxygen_browser_cmd = get(g:, 'doxygen_browser_cmd', 'xdg-open')
let g:doxygen_browser_file = get(g:, 'doxygen_browser_file', '/.project-documentation/html/index.html')

" Doxygen - Keyboard | Keybindings | kb
" (recomended: <C-h> and <C-k>)
let g:doxygen_shortcut_regen = get(g:, 'doxygen_shortcut_regen', '')
let g:doxygen_shortcut_open = get(g:, 'doxygen_shortcut_open', '')

" }}}




" doxygen Setup {{{

augroup doxygen_detect
    autocmd!
    autocmd BufNewFile,BufReadPost *  call doxygen#setup_doxygen()
    autocmd VimEnter               *  if expand('<amatch>')==''|call doxygen#setup_doxygen()|endif
augroup end

" }}}




" Misc Commands {{{

if g:doxygen_define_advanced_commands
    command! DoxygenToggleEnabled :let g:doxygen_enabled=!g:doxygen_enabled
    command! DoxygenToggleTrace   :call doxygen#toggletrace()
endif

" }}}

