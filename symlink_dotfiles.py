#!/usr/bin/env python3
#
# Copyright © 2017 Lukas Kluft <lukas.kluft@gmail.com>
#
# Distributed under terms of the MIT license.
"""Conveniently symlinks dotfiles in user's home directory.
"""
import os
from sys import platform


home = os.getenv('HOME')
gitrepo = os.path.join(home, 'git')

dotfiles = [
    'bash_aliases',
    'bash_completion',
    'bash_functions',
    'bashrc',
    'condarc',
    'ctags',
    'dircolors',
    'gitconfig',
    'inputrc',
    'msmtprc',
    'pythonrc',
    'profile',
    'tmux.conf',
]

dotdirectories = [
    'vim',
    'scripts',
]

# Symlink common dotfiles.
for f in dotfiles:
    src = os.path.join(gitrepo, 'config_files', f)
    dst = os.path.join(home, '.' + f)
    os.symlink(src, dst)

# Symlink SSH configuration.
sshdir = os.path.join(home, '.ssh')
if not os.path.isdir(sshdir):
    # Ensure that the .ssh directory is present.
    os.mkdir(sshdir)
src = os.path.join(gitrepo, 'ssh_config')
dst = os.path.join(sshdir, 'config')
os.symlink(src, dst)

# Symlink mail settings depending on operatins system.
if platform == "linux" or platform == "linux2":  # linux
    mailrc = 'mail.rc'
elif platform == "darwin":  # OS X
    mailrc = 'mailrc'

src = os.path.join(gitrepo, 'config_files', mailrc)
dst = os.path.join(home, '.' + mailrc)
os.symlink(src, dst)

# Symlink scripts directory.
for d in dotdirectories:
    src = os.path.join(gitrepo, d)
    dst = os.path.join(home, '.' + d)
    os.symlink(src, dst)
