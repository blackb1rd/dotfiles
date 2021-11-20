" file:     ~/.vim/filetype.vim
" author:   blackb1rd
" ----------------------------------------------------------------------------

" DETECTION {{{1
" ----------------------------
au BufNewFile,BufRead *.nfo setf nfo
au BufNewFile,BufRead *.txt setf txt

au BufReadPost *.doc silent %!catdoc "%"
au BufWriteCmd *.doc setl readonly
au BufReadPost *.odt,*.odp silent %!odt2txt "%"
au BufWriteCmd *.odt setl readonly
au BufReadPost *.pdf silent %!pdftotext -nopgbrk -layout -q -eol unix "%" - | fmt -w72
au BufWriteCmd *.pdf setl readonly
au BufReadPost *.rtf silent %!unrtf --text "%"
au BufWriteCmd *.rtf setl readonly

" CODING {{{1
" ----------------------------
au FileType vim                 setl sw=4 ts=4 et
au FileType c,cpp               setl cino=(0 sw=2 ts=2
au FileType html,xhtml,xml,php  setl sw=2 ts=2 et
au FileType perl,python,ruby    setl sw=4 ts=4 et
au FileType bash,sh,zsh         setl sw=2 ts=2 et
au FileType javascript          setl sw=2 ts=2 et
au FileType proto               setl sw=2 ts=2 et

" Ctrl+X O
au FileType python              setl omnifunc=pythoncomplete#Complete
au FileType javascript          setl omnifunc=javascriptcomplete#CompleteJS
au FileType html                setl omnifunc=htmlcomplete#CompleteTags
au FileType css                 setl omnifunc=csscomplete#CompleteCSS
au FileType xml                 setl omnifunc=xmlcomplete#CompleteTags
au FileType php                 setl omnifunc=phpcomplete#CompletePHP
au FileType c                   setl omnifunc=ccomplete#Complete

" TEXT {{{1
" ----------------------------
au FileType gitcommit,mail setl spell et fo+=ct
au FileType plaintex,pod   setl spell et fo+=ct
au FileType pandoc,tex     setl spell et sw=2 ts=2 fo+=ct

" PARENTHESE {{{1
" ----------------------------
au VimEnter * RainbowParentheses
