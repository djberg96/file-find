[![Ruby](https://github.com/djberg96/file-find/actions/workflows/ruby.yml/badge.svg)](https://github.com/djberg96/file-find/actions/workflows/ruby.yml)

## Description

This is a drop-in replacement for the find module currently in the standard
library. It is modeled on a typical 'find' command found on most Unix systems.

## Installation

`gem install file-find`

## Specs

Although this gem will work with Ruby 2.x or 3.x, you will need Ruby 3.x to
run the specs locally because of development dependencies.

## Adding the trusted cert
`gem cert --add <(curl -Ls https://raw.githubusercontent.com/djberg96/file-find/main/certs/djberg96_pub.pem)`

## Synopsis
```ruby
  require 'file/find' # 'file-find' also works

  rule = File::Find.new(
    :pattern => "*.rb",
    :follow  => false,
    :path    => ['/usr/local/lib', '/opt/local/lib']
  )

  rule.find{ |f|
    puts f
  }
```

## Rationale

The current find module in the standard library is inadequate. It is, quite
frankly, not much more than a plain Dir.glob call. This library provides an
interface based on options typically available on your command line 'find'
command, thus allowing you much greater control over how you find your files.

## Options

* atime
* ctime
* follow
* ftype
* inum
* group (name or id)
* maxdepth
* mindepth
* mount
* mtime
* name (or 'pattern')
* path
* perm
* prune
* size
* user (name or id)

In addition to the above options, `FileTest` methods such as `readable?` and
`writable?` may be used as keys, with true or false for their values.

See the documentation for more details about these options.

## Future Plans

None at this time. Please log any feature requests on the project page at:

http://github.com/djberg96/file-find

## Options I won't support

Generally speaking, anything that would require mucking around with C code
or is just too difficult to implement in a cross platform manner will not be
supported. These include the following options:

* acl/xattr - Way too difficult to implement in a cross platform manner, and
  a rarely used option in practice.

* cpio/ncpio - I will not shell out to this or any other 3rd party
  application.

* ls/print - Use Ruby's builtin printing methods to print as you see fit.

* ok - This is not interactive software.

## Known Issues

The `:perm` option is limited to 0644 and 0444 on MS Windows.

The `:user`, `:group`, and `:inum` options require the win32-file gem to work
properly on MS Windows. However, win32-file is not officially a dependency.

Some specs on Windows are marked pending for now because there's some issue
interacting with the FakeFS gem on Windows.

## Bugs

None that I'm aware of beyond the ones mentioned in the Known Issues. Please
log any bug reports on the project page at:

http://github.com/djberg96/file-find

## Acknowledgements

* Richard Clamp's File::Find::Rule Perl module for additional ideas and
  inspiration.
* Bill Kleb for ideas regarding name, group and perm enhancements.
* Hal Fulton for his implementation of symbolic permissions.

## License

Apache-2.0

## Copyright

(C) 2007-2026, Daniel J. Berger, All Rights Reserved

## Author

Daniel J. Berger
