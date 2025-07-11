## 0.5.1 - 17-Jun-2025
* Updated, fixed or skipped some specs on Windows.
* Some rubocop cleanup and minor refactors.
* Added a github workflow matrix to the repo.
* Added a rubocop config to the repo.
* Minor tweaks to the Rakefile.
* Added more information to the README.

## 0.5.0 - 19-Jan-2021
* Switched from test-unit to rspec, with an added development
  dependency on the fakefs gem.
* Switched from rdoc to markdown because github doesn't render rdoc
  properly any more.
* Fixed a bug in the maxdepth option with root paths.
* Added a Gemfile.

## 0.4.4 - 6-Aug-2020
* Added .rdoc extensions to the CHANGES, README and MANIFEST files.

## 0.4.3 - 8-Jun-2020
* Fixed a bug with ELOOP handling. Thanks go to joast for the spot and fix.

## 0.4.2 - 6-May-2020
* Added LICENSE file as required by the Apache-2.0 license.

## 0.4.1 - 23-Jan-2019
* Added metadata to the gemspec.

## 0.4.0 - 26-Dec-2018
* License changed to Apache-2.0.
* Fixed a bug where mindepth and maxdepth would break if more than one
  path was specified as part of the rule. Thanks go to flagos for the spot.
* The VERSION constant is now frozen.
* The cert has been updated.

## 0.3.9 - 16-Dec-2015
* This gem is now signed.
* Added a file-find.rb file for convenience.
* Updates to the Rakefile and gemspec.

## 0.3.8 - 12-Feb-2014
* Removed all references to the Etc module since the sys-admin library now uses
  FFI and works with JRuby.
* The :user, :group, and :inum options will now work on MS Windows if you have
  the win32-file gem installed.
* Fixed the perm option on Windows for its limited subset of available perms.
* You can now include a leading zero for the perm option if you wish.
* Some tests that were previously omitted on Windows are now included.
* Updates to the test suite, readme, etc.

## 0.3.7 - 15-Jan-2014
* Fixed a bug with brackets in the path name. Thanks go to Jeremy Lawler
  for the spot and the patch.

## 0.3.6 - 6-Sep-2013
* Removed rbconfig from library and test file. Just use File::ALT_SEPARATOR
  to check for Windows instead.
* Removed unused variables.
* Updated dev dependencies.

## 0.3.5 - 15-Jul-2011
* Fixed a bug with the :follow option.
* Gemspec, Rakefile and test cleanup.

## 0.3.4 - 19-Sep-2009
* Fixed a packaging bug. Thanks go to Gabriel Horner for the spot.
* Added the 'gem' task to the Rakefile for building the gem. Removed the
  gem builder code that was in the gemspec itself.
* Updated the dependency for sys-admin to 1.5.2.

## 0.3.3 - 3-Aug-2009
* Now compatible with Ruby 1.9.x.
* Added support for the :links option
* Updated the :mount accessor to work properly if the value is changed
  after the File::Find object is initially created.
* Eliminated some 'shadowed variable' warnings in Ruby 1.9.x.
* Added a fuller description to the gemspec.
* Minor test refactoring.

## 0.3.2 - 20-Feb-2009
* Added support for the :mount option.
* Added some basic tests for the :mount option.

## 0.3.1 - 9-Jan-2009
* Now defaults to using Etc instead of Sys::Admin for implementations
  that don't support building C extensions, e.g. JRuby.
* Updated the test suite to work with JRuby.
* Minor optimizations for symbolic perms and atime/ctime/mtime checks.
  Thanks go in part to Ryan Davis' flay library.

## 0.3.0 - 30-Dec-2008
* Added support for FileTest operations. All options passed to the constructor
  that end with '?' are now validated and treated as FileTest operations.

## 0.2.5 - 29-Dec-2008
* Added maxdepth and mindepth support.
* Added a 'clean' rake task to cleanup any test-unit results files.

## 0.2.4 - 10-Dec-2008
* Added support for symbolic permissions. Thanks go to Bill Kleb for the
  suggestion and to Hal Fulton for providing the solution.

## 0.2.3 - 25-Nov-2008
* Added mtime support. My previous concerns, which I believe stemmed from
  the find(2) man page on Solaris 10 with regards to atime checks modifying
  the mtime, appear have been unfounded.

## 0.2.2 - 19-Nov-2008
* The :user and :group options now accept a name or a numeric id. Thanks go
  to Bill Kleb for the suggestion.
* Fixed yet another path bug for MS Windows.
* Updated platform check to use CONFIG instead of RUBY_PLATFORM, because the
  latter does not work as I intended with other implementations, e.g. JRuby.
* Added sys-admin and test-unit as prerequisites.
* Added tests for the :user and :group options.

## 0.2.1 - 4-Oct-2007
* Added the File::Find#previous method, which lets you see the previous
  match, if any.
* Path name bug fix for MS Windows.
* Test suite bug fixes for MS Windows (perm test now skipped).
* Inaccessible directories are now skipped instead of raising an error.

## 0.2.0 - 26-Apr-2007
* Fixed a bug where it was not traversing subdirectories.
* Added support for the perm and prune options.

## 0.1.1 - 25-Apr-2007
* The default for name is now '*', i.e. everything.
* Fixed a bug where directories were not matched. Thanks go to Leslie Viljoen
  for the spot.
* The size option now accepts strings with comparable operators. For example,
  you can now look for files greater than 400 bytes with the string "> 400".

## 0.1.0 - 24-Apr-2007
* Initial release
