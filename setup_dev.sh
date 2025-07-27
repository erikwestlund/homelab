#!/bin/bash

# Tmux development session setup for homelab

SESSION_NAME="homelab"

# Check if session already exists
tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? != 0 ]; then
    # Create new session with first window (0) named "shell"
    tmux new-session -d -s $SESSION_NAME -n shell
    
    # Create second window (1) named "claude" and start claude
    tmux new-window -t $SESSION_NAME:1 -n claude
    tmux send-keys -t $SESSION_NAME:claude "claude" C-m
    
    # Select first window
    tmux select-window -t $SESSION_NAME:0
fi

# Attach to session
tmux attach-session -t $SESSION_NAME