# Can Opener

Can Opener is a programmable URL handler for Mac OS X. If you often find
yourself switching back and forth between Safari and Chrome, for example,
you can program Can Opener to open the URL in whichever browser is currently
running at the moment. Or, if use Safari most of the time, but have a few
websites you want to always open in Chrome, you can program Can Opener to
do that, too.

I say "program" because at the heart of Can Opener is a script that _you_
write. Every time Can Opener is asked to open a URL, it runs your script,
and does what the script tells it to do.

## Free Software

Can Opener is free software. It is licensed under the GNU General Public
License, which protects your freedoms as a user of the software.

For example, you can inspect the source code to verify that it doesn't track
which websites you visit and transmit that information without your consent.

## Script API

You can write your URL opening script in whatever language you choose: Ruby,
Python, Bash, C, C++, PHP, etc. As long as the script can read environment
variables and write to standard output, it is supported.

The URL to be opened is passed in as the first command line argument, and also
in the environment with the name `URL`.

If any applications are installed which claim to handle URLs of that scheme,
their bundle identifiers are provided as a colon-separated list in the
environment variable `AVAILABLE_APPS`.

The subset of those apps that are running are provided in the environment
variable `RUNNING_APPS`, in the same format.

The script communicates back to Can Opener by printing to standard output.

If the script prints `Use:`, followed by a space, followed by a bundle
identifier, then the corresponding app will be used to open the URL.

For example, for Safari:

    Use: com.apple.Safari

If the script prints multiple `Use:` lines, then the user will be prompted to
choose from the options. For example, to give the option of Safari or Chrome:

    Use: com.apple.Safari
    Use: com.google.Chrome

The script must print at least one `Use:` line.

Optionally, the script can choose a different URL to open by printing `URL:`,
followed by a space, followed by the new URL. This is useful, for example, if
you want to redirect `feed:` URLs to a web app like NewsBlur.

### Ruby Support

Can Opener has built in support for Ruby. If you `require 'can_opener'` at the
top of your script, you can write code like `Safari.running?`.

## TODO

Apply GPL.

Make an icon.

Allow user to select location of script using a standard Open panel.

Offer to install an example script if none found.

The Chooser Window could be a whole lot more slick looking.

This should probably be one of those little no-icon, menu-bar-only apps.

Protect against infinite loops, if a script is dumb enough to invoke CanOpener
to open the same URL it is opening. (Could easily happen if CanOpener is the
default handler and the script simply calls `open $URL`.)

URL schemes must be declared in the Info.plist file; that is, they can't be
changed without hacking the app.

_See the source code for more TODO comments._

# References

[Choosy: a smarter default browser][choosy]. This app is very similar to Can
Opener, but it hasn't been updated in a while and the source is not available.

[choosy]: http://www.choosyosx.com/

[Bwana: A man page reader for your browser][bwana]. The source code was a useful
reference for handling GetURL Apple Events.

[bwana]: https://bitbucket.org/bruji/bwana/

[Make Your Own URL Protocol and Handler][macguy]. A similar idea, in AppleScript.

[macguy]: https://yourmacguy.wordpress.com/2013/07/17/make-your-own-url-handler/
