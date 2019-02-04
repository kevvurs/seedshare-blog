# Action Hugo
Github action to build SSG with Hugo. The Go-based Docker image included in
this action installs GCC, C libraries, and Git. Then it pulls a specific
version of Hugo from the official repository. Hugo is built locally from
source and installed via go. Finally, hugo executes the build command with
optional arguments supplied to generate the static site.
