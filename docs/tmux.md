# Tmux - Getting Started

tmux is a terminal multiplexer for Unix-like operating systems. It allows multiple terminal sessions to be accessed simultaneously in a single window. It is useful for running more than one command-line program at the same time. It can also be used to detach processes from their controlling terminals, allowing SSH sessions to remain active without being visible.

## Installation

### OSx
`brew install tmux reattach-to-user-namespace`

#### Enable Copy/Paste
iTerm2 > Preferences > General > Selection > Applications in terminal may access clipboard

### Debian / Ubuntu
`sudo apt install tmux xsel`

### Install TPM
`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

## Initial Configuration
Copy the following to `~/.tmux.conf`

```
set -g mouse on

unbind-key C-b
unbind-key C-x
set-option -g prefix C-a
bind C-x setw synchronize-panes
bind-key h split-window -h
bind-key v split-window -v

set -g status-justify "centre"
set -g set-titles on
set -g base-index 1
set -g status-bg black
set -g status-fg white
setw -g automatic-rename on
setw -g window-status-current-format "#{?pane_synchronized,#[bg=red],#[fg=white, bg=blue]} #I #W #[fg=blue, bg=black]"

set -g @plugin "tmux-plugins/tpm"
set -g @plugin "tmux-plugins/tmux-sensible"
set -g @plugin "tmux-plugins/tmux-resurrect"
set -g @plugin "tmux-plugins/tmux-continuum"
set -g @plugin "tmux-plugins/tmux-yank"
set -g @yank_selection_mouse "clipboard"
set -g @resurrect-processes ":all:"
set -g @resurrect-capture-pane-contents "on"
run "~/.tmux/plugins/tpm/tpm"
```
## Commands
```
tmux                          start a new session
tmux ls                       list all sessions
tmux a                        attach to an existing session
tmux a -t <name>              attach to a named session
tmux new -s <name>            start a new named session
tmux kill-session -t <name>   kill a named session
tmux kill-server              kill all sessions
```
## Keyboard Shortcuts
The modifier prefix has been changed from the default `ctrl-b` to `ctrl-a` which is more convenient.

Use the modifier prefix `ctrl-a` with these keyboard shortcuts.

```
?             list shortcuts                         
R             reload the configuration               
I             install new pluginx                    
d             detach the session                     
h             split horizontally                     
v             split vertically                       
c             create a new window                    
p             switch to the previous window          
n             switch to the next window              
w             list the windows                       
1-9           switch to the window number            
,             rename the window                      
$             rename the session                     
ctrl-s        save the environment to the disk       
ctrl-r        restore the environment from the disk  
arrows        switch between panes                   
ctrl+arrows   resize pane                            
space         switch pane layout                     
z             maximize/minimize pane                 
ctrl-x        synchronize panes                     
```
## Automation Example
```
tmux new-window -n status
tmux split-window -h
tmux select-pane -t 0
tmux send-keys "htop" C-m
tmux split-window -v
tmux select-pane -t 1
tmux send-keys "docker stats" C-m
tmux select-pane -t 2
```
## Convenient Aliases
Copy the following to `~/.zshrc`

```
alias t='tmux'
alias ts='tmux new -s'
alias tks='tmux kill-session -t'
alias tka='tmux kill-server'
```
## Links
Find more ways to use Tmux - [Awesome Tmux](https://github.com/rothgar/awesome-tmux)

 