
# The WebGUI8 Content Management System

## About

WebGUI is a mature, feature rich Content Management System.  It's written in Perl and licensed under the GNU GPL.  Some features include:

* Hierarchical permissions
* Groups of groups of groups (etc)
* Asset versioning
* A workflow builder that can do things like require two Content Managers to give approval before user submitted content goes online
* Selectable workflows for new/edited assets
* Assets create other assets; almost everything is an asset
* Easily, cleanly extensible OO architecture
* Discussion boards, shops, image galleries, ticket trackers, and various other types of interactive content
* Scalable architecture suitable for busy sites

## Installation

On Mac OSX, Debian, and CentOS (CentOS support currently broken), the interactive installer script is recommended.

    wget https://raw.githubusercontent.com/AlliumCepa/webgui/master/installer/webgui_installer.pl
    perl webgui_installer.pl

Or from an existing git checkout of WebGUI, do:

    cd installer
    perl webgui_installer.pl

Then answer the questions about site URL, installation directory, what MySQL password to use, and so on.

If the installer encounters any errors, it will offer to automatically send a problem report.  Please allow it to
do so if this happens.
The problem report contains several autodetected values (such as operating system and machine architecture) as well as the text
of the fatal error message.  No user identifying information is sent.  Passwords may be sent if the failed command includes a password.

After the installer completes, a `webgui.sh` file will be left in the install directory you picked, along with the
`WebGUI` directory containing the install.
`webgui.sh` allows you to manually start the MySQL, nginx, and WebGUI8.

If you have SysVInit, the installer will write startup files in `/etc/init.d/webgui8` and `/etc/rc4.d/S45webgui8`.
It will also use those startup files to start WebGUI.
If your operating system's package manager wrote startup files for nginx and MySQL, those services should be running
and should start on boot as well.

These commands may be used to stop and start WebGUI8 on systems that use SysVInit:

    /etc/init.d/webgui8 stop
    /etc/init.d/webgui8 start

Go to http://your.server:8081 to access the site directly, or http://your.server will work if nginx was probably 
configured and started.

The admin user is `Admin` and the default starting password is `123qwe`.

## Manual Installation

For OSX, FreeBSD, and other systems, or for those who like to see exactly what is happening, use the manual install process.

Many perl modulues require system librarys, such as libexpat1-dev on Debian; you have to figure out which system packages you need to install for your system.
If you do that, please tell us what they are so we can document that for other people on the same system.

For example, on Debian, the following system packages are needed:
perlmagick libssl-dev libexpat1-dev git curl nginx build-essential  libpng-dev mysql-server mysql-client

This assumes that your site is "www.example.com".  If it's something else, change the commands to match.

Generic source install instructions:

* Load share/create.sql into your MySQL/MariaDB/Percona
* Run ./sbin/testEnvironment.pl to install all new requirements
* Get a new wgd, the wG command line tool, from http://haarg.org/wgd
* Copy [etc/WebGUI.conf.original](etc/WebGUI.conf.original) to etc/www.whatever.com.conf
* Edit the conf file and set dbuser, dbpass, dsn, uploadsPath (eg to /data/domains/www.example.com/public/uploads/), extrasPath, maintenancePage and siteName
* Copy [etc/log.conf.original](etc/log.conf.original) to etc/log.conf .
* Edit etc/log.conf such that log4perl.appender.mainlog.filename points to a writable path.  For example: ```log4perl.appender.mainlog.filename = webgui.log``` works for local development.
* Set WEBGUI_CONFIG to point at your new config file.  For example: ```export WEBGUI_CONFIG=www.whatever.com.conf``` .
* Run upgrades (yes, even for brand new install):  wgd reset --upgrade
* Copy the "extras" directory from whereever you unpacked it to whereever you pointed extrasPath to in the config file.  For example, if you unpacked the source in /data/WebGUI and the extrasPath to /data/domains/www.example.com/public/, you'd run: rsync -r -a /data/WebGUI/www/extras /data/domains/www.example.com/public/

More detailed (but less well maintained) instructions are in [docs/install.txt](docs/install.txt).

[docs/wre_install.txt](docs/wre_install.txt) (also unmaintained) has instructions for using the "WebGUI Runtime Environment" to run wG8.  This is a nearly complete 32-bit binary distribution
of everything you need to run WebGUI 7 on Linux.  It can be updated with additional Perl modules required to run 8, but the setup/management scripts are likely non-functional.
Patches are welcome from interested parties.

The old manual source instructions for 7.x are at [http://www.webgui.org/wiki/source-install].

## To start WebGUI

To test or develop:

* Set the PERL5LIB environment variable:  export PERL5LIB='/data/WebGUI/lib'
* Launch it:   plackup app.psgi

See docs/install.txt for more detailed installation instructions.

A production site or a dev site that tests sending email or workflows will also need the spectre daemon running.

A proxy server such as nginx or Apache configured to proxy is highly recommended for production sites.
The proxy server should serve /extras and /uploads and pass everything else to the plack server process.
See docs/install.txt for a recommended plack configuration for production.

## Using WebGUI

* Setting up a new site after you've installed and started wG:  https://www.youtube.com/watch?v=spPQsD4uAAs
* Help forums:  http://webgui.org/forums
* Content Managers Guide:  https://www.webgui.org/community/webgui-user-guides/content-managers-guide
* Administrators Guide:  https://www.webgui.org/user-guides/webgui-administrators-guide

## Developing Applications on top of WebGUI

* Doug Bell's talk for MadMongers:  http://preaction.github.io/WebGUI/8-apps.html
* Developers Guide for wG7 (out of date with respect to 8):  https://www.webgui.org/user-guides/developers-guide

## Community Process

We welcome contributions.

Where things are at:

* The bug tracker is here:  http://www.webgui.org/8
* Developer discussion forums, for conversations relating to the code itself, are here:  http://www.webgui.org/webgui/dev/discuss
* Community process discussion is here:  https://github.com/AlliumCepa/webgui/issues/
* IRC chat is at #webgui on FreeNode; use your favorite IRC-enabled chat client or see irc.org for more info
* The Wiki is at http://webgui.org/wiki
* The official PlainBlack WebGUI repo is at http://github.org/plainblack/webgui
* The (an?) unofficial community process repo is at http://github.org/AlliumCepa/webgui

As a general rule, if you're fixing a bug mentioned in http://www.webgui.org/8, discuss it at http://www.webgui.org/webgui/dev/discuss.
If you're adding a new feature or want to talk about the community process itself, discuss it on https://github.com/AlliumCepa/webgui/issues/.

If you're adding a new feature, improving wG, or fixing bugs, please fork http://github.org/AlliumCepa/webgui.
If you're only fixing bugs, you may wish to fork http://github.org/plainblack/webgui.

There are plenty of ways to help:

* Install wG8, test it or just try to use it, and report bugs
* Discuss ideas for the community process
* Help update the Wiki
* Fix bugs
* Work on code

Fork http://github.org/AlliumCepa/webgui, make changes in master or in a branch, commit them, push them up, and then use github to send a "pull request".
If the request is accepted, your code goes into http://github.org/AlliumCepa/webgui.

Here are some specific tasks to be done:

* Merge in Haarg's work on replacing ImageMagick with something that installs reliably 
* Work on an importer for WordPress sites:  https://github.com/AlliumCepa/webgui/issues/9
* Merge in the experimental installer from https://gist.github.com/scrottie/2973558 and update the documentation to suggest using it
* Create a new, modern theme; documentation for doing this is in the _WebGUI Designers Guide_ at https://www.webgui.org/documentation2/webgui-designers-guide
* Merge in various projects people have started:  https://github.com/AlliumCepa/webgui/issues/3
* Forward port relevant bug fixes from the 7.x branch to 8.x.
* Fix up the Developer's Guide for 8.

Rules and process:

* This fork is run as a (hopefully) benevolent dictatorship, with scrottie having final say on matters
* For most matters, a rough consensus process between active developers will be used
* Everyone is welcome to participate provided they are kind to their fellow developers
* This fork and project are unofficial and not managed by PlainBlack Corp
* This project exists to support developers and to seek out and include work from different efforts to create a possible base for wG8.1
* The master branch should be kept in a working state; if you're doing something risky or want to commit something unfinished, please use a branch
* If you get on IRC, we can help you use git to create branches, fork, and so forth
* Code included into and developed through this community process may or may not be merged into the official PlainBlack WebGUI at their sole discretion
* Unit tests are requested where appropriate for code submissions (recommended for most new features and bug fixes) as they're officially required for code committed to official PlainBlack WebGUI
* To minimize merge conflicts, contributions should not cause undue numbers of changes; please do not reformat code, change whitespace, or make significant number of global replacements except by special arrangement among all concerned
* I (scrottie) may hand out and revoke commit bits as I deem predudent
* If you don't have a commit bit, don't worry, just send a pull request from your fork
* Generally, commit bits will be taken back if you're idle, or if you commit major things to the master branch without to discussion and wind up upsetting people
* The project is GPL licensed (see http://www.gnu.org/licenses/gpl.html for exact terms and conditions); use and modification of this code constitutes agreement to the terms; one of the terms is that code added to the project must also be released as GPL

## The Request Cycle

This needs to be moved to a design document.

* The root level app.psgi file loads all the config files found and loads the site specific psgi file for each, linking them to the proper host names.
* The site psgi file uses the WEBGUI_CONFIG environment variable to find the config.
* It instantiates the $wg WebGUI object (one per app).
* $wg creates and stores the WebGUI::Config (one per app)
* $wg creates the $app PSGI app code ref (one per app)
* WebGUI::Middleware::Session is wrapped around $app at the outer-most layer so that it can open and close the $session WebGUI::Session. Any other wG middleware that needs $session should go in between it and $app ($session created one per request)
* $session creates the $request WebGUI::Session::Request and $response WebGUI::Session::Response objects (one per request)
* lib/WebGUI.pm does basic dispatch, first checking for a content handler, and then as a last resort (but the usual case), defaulting to the asset content handler
* The content handlers are configured in the .conf file
* The asset content handler, lib/WebGUI/Content/Asset.pm, looks up the asset by URL in the database


