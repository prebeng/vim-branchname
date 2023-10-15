# Fossil plugin for vim

A [Vim][vim] plugin to find a branchname, e.g. to show in the status line.

The BranchName() function returns the name of the branch, optionally adding
a prefix, the version control system name and a suffix.

The implementation aims to be light weight in use by caching branchnames
until the mtime of the identified repository changes.

Currently supported version control systems are [Fossil][fossil], [Git][git]
and [Mercurial][mercurial].

Please see [`:help branchname`][help] for more information.

## Installation

Vim pluging managers using get can use the [GitHub mirror][github] with e.g.

```
    :Plug 'prebeng/vim-branchname'
```

Using fossil:

1. Create directory `~/.vim/pack/simple/start/vim-branchname/`, where `simple`
   can be any directory name (I use this for simple plugins).
2. Clone [the officieal repository][repourl] in a location of your liking.
3. In the directory in step 1, use `fossil open` to check out the reposository.
3. Run `:helptags ~/.vim/pack/simple/start/vim-branchname/doc`.

Manual installation:

- Optionally use a directory as with step 1 for fossil, otherwise use `~/.vim`.
- Copy the [doc, plugin and syntax folders][dirs] to the directory.

[dirs]: https://fossil.guldberg.org/vim-branchname/dir?ci=tip&type=tree
[fossil]: https://fossil-scm.org/
[git]: https://git-scm.com/
[help]: https://fossil.guldberg.org/vim-branchname/doc/trunk/doc/branchname.txt
[github]: https://github.com/prebeng/vim-branchname.git
[mercurial]: https://www.mercurial-scm.org/
[repourl]: https://fossil.guldberg.org/vim-branchname/
[vim]: https://vim.org/
