let s:subfile = escape(fnameescape('Tori Amos - Smells Like Teen Spirit (Nirvana).srt'), '()')
let s:vidfile = escape(fnameescape('Tori Amos - Smells Like Teen Spirit (Nirvana).mp4'), '()')

let s:player='"mplayer -identify -osdlevel 2 -ss " . s:player_seconds . " -slang -noautosub -sub " . s:subfile . " -utf8 " . s:vidfile . " < /dev/null &"'

let s:rx_time = '^\d\d:\d\d:\d\d,\d\d\d'
let s:zero_time = '00:00:00'

" hack, but it might just work
function! s:subtract_seconds(seconds, amount)
  let s = split(a:seconds, ':')
  if s[2] > a:amount
    let s[2] -= a:amount
  else
    if s[1] > 0
      let s[1] -= 1
      let s[2] += (60 - a:amount)
    else
      let s[0] -= 1
      let s[1] = 59
      let s[2] += (60 - a:amount)
    endif
  endif
  return printf('%02d:%02d:%02d', s[0], s[1], s[2])
endfunction

function! s:get_seconds()
  if search(s:rx_time, 'cbW') == -1
    let seconds = s:zero_time
  else
    let seconds = substitute(getline('.'), '\zs .*', '', '')
  endif
  return seconds
endfunction

function! s:play()
  let s:seconds = s:get_seconds()
  let s:player_seconds = s:subtract_seconds(
        \ substitute(s:seconds, '\zs,.*', '', '')
        \ , 5)
  let s:seconds = s:player_seconds . substitute(s:seconds, '.*\ze,', '', '')
  silent call system(eval(s:player))
  let s:start_time = reltime()
endfunction

function! Elapsed_reltime(offset)
  let r = reltime(s:start_time)
  let x = split(s:seconds, ',')
  let y = split(x[0], ':')
  let x[0] = (y[0] * 3600) + (y[1] * 60) + y[2] + a:offset
  return [r[0] + x[0], r[1]]
  "+ x[1]]   "bad overflow
endfunction

function! Reltime2secs(r)
  let ts = a:r
  let s_min = 60
  let s_hour = 60 * s_min
  let s_day = 24 * s_hour

  let hs = ts[0] % s_day
  let h = float2nr(floor(hs / s_hour))

  let ms = hs % s_hour
  let m = float2nr(floor(ms / s_min))

  let s = float2nr(ceil(ms % s_min))
  let us = ts[1]
  return printf("%02d:%02d:%02d,%03d", h, m, s, strpart(us, 0, 3))
endfunction

function! s:start_subtitle_line()
  let start_time = Reltime2secs(Elapsed_reltime(0))
  let end_time = Reltime2secs(Elapsed_reltime(1))
  if getline('.') == ''
    normal! o
  endif
  call setline(line('.'), printf("%s --> %s", start_time, end_time))
endfunction

function! s:next_entry()
  normal! }j
  if (getline('.') =~ '^\d\+$') && getline(line('.')+1) =~ s:rx_time
    normal! j
  elseif getline('.') =~ s:rx_time
  else
    normal! k
  endif
endfunction

nnoremap <up>    :call <SID>play()<cr>
nnoremap <down>  :call <SID>next_entry()<cr>
nnoremap <right> :call <SID>start_subtitle_line()<cr>
nnoremap <left>  :call <SID>end_subtitle_line()<cr>
