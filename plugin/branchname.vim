" Vim plugin for obtaining branch names for different version control systems
" Maintainer:	Preben Guldberg <preben@guldberg.org>
" Last Change:	2023 Oct 15
" License:      MIT

vim9script

if exists('g:loaded_branchname') || &cp
  finish
endif
g:loaded_branchname = 1

# Cache for directories encountered
var Cache = {}

# Default configuration
var Config = {
    'default': {
        'pre': '',
        'post': '',
        'showref': 0,
        'ttl': 300
    },
    'fossil': {
        'cmd': 'fossil',
        'ref': 'fsl:'
    },
    'git': {
        'cmd': 'git',
        'ref': 'git:'
    },
    'mercurial': {
        'cmd': 'hg',
        'ref': 'hg:'
    }
}

# Global error message for debugging
var GlobalError = ''

def GetConfig(cvs: string, key: string, usedefault: bool = 1): any
    var configs = [Config]
    if exists('g:branchname_config')
        call insert(configs, g:branchname_config)
    endif
    for cfg in configs
        if has_key(cfg, cvs) && has_key(cfg[cvs], key)
            return cfg[cvs][key]
        elseif usedefault
            if has_key(cfg, 'default') && has_key(cfg['default'], key)
                return cfg['default'][key]
            endif
        endif
    endfor
    return null
enddef

# Caller has checked has_key(Cache, dir) first!
# TODO: use localtime() to see if we want to expire cached info?
def LookupBranch(dir: string): string
    var val = Cache[dir]
    if has_key(val, 'repodir')
        return LookupBranch(val['repodir'])
    endif
    if !has_key(val, 'repo')
        # Should only really only happen for '/'
        return ''
    endif
    var info = Cache[dir]
    var branch = info['branch']
    var cvs = info['cvs']
    var mtime = getftime(info['repo'])
    if mtime > info['mtime']
        var cmd = GetConfig(cvs, 'cmd')
        if !empty(cmd)
            var shelldir = shellescape(dir)
            if cvs == 'fossil'
                cmd ..= ' branch current --chdir ' .. shelldir
            elseif cvs == 'git'
                cmd ..= ' -C ' .. shelldir .. ' branch --show-current'
            elseif cvs == 'mercurial'
                cmd ..= ' branch -R ' .. shelldir
            endif
            branch = system(cmd)
            if v:shell_error != 0
                GlobalError = branch
                branch = ''
            else
                info['branch'] = substitute(branch, '\n.*', '', 'e')
                info['mtime'] = mtime
            endif
        endif
    endif
    if !empty(branch)
        if GetConfig(cvs, 'showref')
            branch = GetConfig(cvs, 'ref') .. branch
        endif
        branch = GetConfig(cvs, 'pre') .. branch .. GetConfig(cvs, 'post')
    endif
    return branch
enddef

def CheckForRepo(dir: string): dict<any>
    var repo = dir .. '/.git'
    if isdirectory(repo)
        return { 'repo': repo, 'cvs': 'git' }
    endif
    repo = dir .. '/.hg'
    if isdirectory(repo)
        return { 'repo': repo, 'cvs': 'mercurial' }
    endif
    repo = dir .. '/.fslckout'
    if filereadable(repo)
        return { 'repo': repo, 'cvs': 'fossil' }
    endif
    repo = dir .. '/_FOSSIL_'
    if filereadable(repo)
        return { 'repo': repo, 'cvs': 'fossil' }
    endif
    return {}
enddef

def CacheBranchName(info: dict<any>, repodir: string, fpath: string): string
    var now = localtime()
    info['mtime'] = 0
    info['branch'] = ''
    info['inserted'] = now
    Cache[repodir] = info
    var dir = fpath
    while dir != repodir
        Cache[dir] = { 'repodir': repodir, 'inserted': now }
        dir = fnamemodify(dir, ':h')
    endwhile
    return LookupBranch(repodir)
enddef

def g:BranchNameFromPath(fname: string): string
    if empty(fname)
        return ''
    endif
    # TODO: Cache eviction is odd to do here, but otherwise return codes for
    # LookupBranch needs to include a status, or we need LookupBranch to go
    # back through this function after evicting items from the cache.
    var ttl = GetConfig('default', 'ttl')
    if ttl > 0
        filter(Cache, 'v:val[''inserted''] > ' .. (localtime() - ttl))
    endif
    var fpath = fnamemodify(fname, ':p:h')
    if has_key(Cache, fpath)
        return LookupBranch(fpath)
    endif
    var dir = fpath
    while 1
        var info = CheckForRepo(dir)
        if dir == '/' || !empty(info)
            return CacheBranchName(info, dir, fpath)
        endif
        dir = fnamemodify(dir, ':h')
    endwhile
    return ''
enddef

def g:BranchName(): string
    return g:BranchNameFromPath(expand('%'))
enddef

def g:BranchNameClearCache()
    Cache = {}
enddef

def g:BranchNameDumpCache()
    echo '{'
    for dir in sort(keys(Cache))
        var info = Cache[dir]
        echo '  ''' .. dir .. ''': {'
        for k in sort(keys(info))
            var v = info[k]
            if type(v) == type('')
                v = '''' .. v .. ''''
            endif
            echo '    ''' .. k .. ''': ' .. v .. ','
        endfor
        echo '  },'
    endfor
    echo '}'
enddef

def g:BranchNameGlobalError(): string
    return GlobalError
enddef
