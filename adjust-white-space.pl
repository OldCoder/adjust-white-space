#!/usr/bin/env perl
# detab, entab, setdos, setunix, trimws - Multi-purpose program
# License:  Creative Commons Attribution-NonCommercial-ShareAlike 3.0
# Revision: 120711

#---------------------------------------------------------------------
#                           important note
#---------------------------------------------------------------------

# This software is provided on an  AS IS basis with ABSOLUTELY NO WAR-
# RANTY.  The  entire risk as to the  quality and  performance of  the
# software is with you.  Should the software prove defective,  you as-
# sume the cost of all necessary  servicing, repair or correction.  In
# no event will any of the developers,  or any other party, be  liable
# to anyone for damages arising out of use of the software, or inabil-
# ity to use the software.

#---------------------------------------------------------------------
#                         setup instructions
#---------------------------------------------------------------------

# This is  five  programs in one.  To set up the programs,  proceed as
# follows:
#
#     (a) Name this file "adjust-white-space".
#
#     (b) Create eight symbolic links to "adjust-white-space" with the
#         following names:
#
#         detab      entab       setdos   setunix
#         trimspace  trimspaces  trimspc  trimws
#
#         Note: The "trim..." commands are interchangeable. These com-
#         mands do the same thing.  Therefore, there's a total of five
#         unique programs here  (detab, entab,  setdos,  setunix,  and
#         trim...).
#
#     (c) Make "adjust-white-space" executable. For example:
#
#         chmod 755 adjust-white-space

# For usage instructions,  execute the commands  listed in (b) without
# any parameters.

#---------------------------------------------------------------------
#                        "detab" documentation
#---------------------------------------------------------------------

my $USAGE_TEXT_DETAB = << 'END';
__PROGNAME__ rev. __REVISION__ - Replaces tabs with spaces

Usage:    __PROGNAME__ file1 file2 ...
or        __PROGNAME__ -t directory
or        __PROGNAME__ -t directory 'Perl_pattern'

Options:  -t Process everything stored in the specified directory tree
             Note:   "-t" doesn't traverse symbolic links
          -T Disable "-t" mode (default)

This program skips over binary files, missing files, devices, symbolic
links, and directory arguments (unless "-t" is used). Additionally, it
preserves permissions and timestamps (if possible).

Limitation:  This version doesn't provide  the ability to specify tab-
field width.

__PROGNAME__ foo bar                  Process "foo" and "bar"
__PROGNAME__ -t /dir '\.(asc|txt)\z'  Search tree for .asc and .txt files
END

#---------------------------------------------------------------------

my $USAGE_TEXT_ENTAB = << 'END';
__PROGNAME__ rev. __REVISION__ - Replaces some spaces with tabs

Usage:    __PROGNAME__ file1 file2 ...
or        __PROGNAME__ -t directory
or        __PROGNAME__ -t directory 'Perl_pattern'

Options:  -t Process everything stored in the specified directory tree
             Note:   "-t" doesn't traverse symbolic links
          -T Disable "-t" mode (default)

This program replaces leading groups of eight spaces on each text line
with single tabs. It skips over binary files, missing files,  devices,
symbolic links, and directory arguments  (unless "-t" is used).  Addi-
tionally, it preserves permissions and timestamps (if possible).

Limitation:  This version doesn't provide  the ability to specify tab-
field width.

__PROGNAME__ foo bar                  Process "foo" and "bar"
__PROGNAME__ -t /dir '\.(asc|txt)\z'  Search tree for .asc and .txt files
END

#---------------------------------------------------------------------
#                       "setdos" documentation
#---------------------------------------------------------------------

my $USAGE_TEXT_SETDOS = << 'END';
__PROGNAME__ rev. __REVISION__
- Converts newlines to Microsoft format

Usage:    __PROGNAME__ file1 file2 ...
or        __PROGNAME__ -t directory
or        __PROGNAME__ -t directory 'Perl_pattern'

Options:  -t Process everything stored in the specified directory tree
             Note:   "-t" doesn't traverse symbolic links
          -T Disable "-t" mode (default)

This program skips over binary files, missing files, devices, symbolic
links, and directory arguments (unless "-t" is used). Additionally, it
preserves permissions and timestamps (if possible).

__PROGNAME__ foo bar                  Process "foo" and "bar"
__PROGNAME__ -t /dir '\.(asc|txt)\z'  Search tree for .asc and .txt files
END

#---------------------------------------------------------------------
#                       "setunix" documentation
#---------------------------------------------------------------------

my $USAGE_TEXT_SETUNIX = << 'END';
__PROGNAME__ rev. __REVISION__
- Converts newlines to UNIX format

Usage:    __PROGNAME__ file1 file2 ...
or        __PROGNAME__ -t directory
or        __PROGNAME__ -t directory 'Perl_pattern'

Options:  -t Process everything stored in the specified directory tree
             Note:   "-t" doesn't traverse symbolic links
          -T Disable "-t" mode (default)

This program skips over binary files, missing files, devices, symbolic
links, and directory arguments (unless "-t" is used). Additionally, it
preserves permissions and timestamps (if possible).

__PROGNAME__ foo bar                  Process "foo" and "bar"
__PROGNAME__ -t /dir '\.(asc|txt)\z'  Search tree for .asc and .txt files
END

#---------------------------------------------------------------------
#                       "trimws" documentation
#---------------------------------------------------------------------

my $USAGE_TEXT_TRIMWS = << 'END';
__PROGNAME__ rev. __REVISION__
- Removes trailing spaces/tabs from lines

Usage:    __PROGNAME__ file1 file2 ...
or        __PROGNAME__ -t directory
or        __PROGNAME__ -t directory 'Perl_pattern'

Options:  -t Process everything stored in the specified directory tree
             Note:   "-t" doesn't traverse symbolic links
          -T Disable "-t" mode (default)

This program skips over binary files, missing files, devices, symbolic
links, and directory arguments (unless "-t" is used). Additionally, it
preserves permissions and timestamps (if possible).

__PROGNAME__ foo bar                  Process "foo" and "bar"
__PROGNAME__ -t /dir '\.(asc|txt)\z'  Search tree for .asc and .txt files
END

#---------------------------------------------------------------------
#                        standard module setup
#---------------------------------------------------------------------

require 5.10.1;
use strict;
use Carp;
use warnings;
use Cwd;
use File::Find;
                                # Trap warnings
$SIG {__WARN__} = sub { die @_; };

#---------------------------------------------------------------------
#                           basic constants
#---------------------------------------------------------------------

use constant ZERO  => 0;        # Zero
use constant ONE   => 1;        # One
use constant TWO   => 2;        # Two

use constant FALSE => 0;        # Boolean FALSE
use constant TRUE  => 1;        # Boolean TRUE

#---------------------------------------------------------------------
#                         program parameters
#---------------------------------------------------------------------

my $FW       = 8;               # Tab-field width
my $MAXSIZE  = 25000000;        # Max. file size supported (in bytes)
my $REVISION = '120711';        # Revision string

#---------------------------------------------------------------------

# If the "help" screen(s) used are more than about 23 lines long,  set
# $USE_LESS to TRUE. Otherwise, set this parameter to FALSE.

my $USE_LESS = FALSE;

#---------------------------------------------------------------------
#                          global variables
#---------------------------------------------------------------------

my $PROGNAME;                   # Single-word program name

$PROGNAME =  $0;                # Obtain program name
$PROGNAME =~ s@^.*/@@;          # Remove path component (if any)
$PROGNAME =~ s@\.pl\z@@i;       # Remove trailing ".pl" (if any)

#---------------------------------------------------------------------

                                # Program-mode flags
my $FlagDETAB  = ($PROGNAME =~ m@(^|/)detab?\z@i   ) ? TRUE : FALSE;
my $FlagDOS    = ($PROGNAME =~ m@(^|/)setdos?\z@i  ) ? TRUE : FALSE;
my $FlagENTAB  = ($PROGNAME =~ m@(^|/)entab?\z@i   ) ? TRUE : FALSE;
my $FlagTRIMWS = ($PROGNAME =~ m@(^|/)trim\w+?\z@i ) ? TRUE : FALSE;
my $FlagUNIX   = ($PROGNAME =~ m@(^|/)setunix\z@i  ) ? TRUE : FALSE;

#---------------------------------------------------------------------

                                # Consistency check
if (!$FlagDETAB && !$FlagDOS    && !$FlagENTAB &&
                   !$FlagTRIMWS && !$FlagUNIX)
{                               # Program has an unsupported name
    print STDERR << 'END';

Internal error:  Program has been executed using an  unsupported name.
The following names are supported:

      detab      entab       setdos   setunix
      trimspace  trimspaces  trimspc  trimws

Note:  The "trim..." commands are  interchangeable.  These commands do
the same thing.

END
    exit ONE;                   # Terminate the program
}

#---------------------------------------------------------------------

my $CWD;                        # Current working directory
my @Entries = ();               # Pathnames obtained using "find"
my $TreePattern;                # Perl pattern string

#---------------------------------------------------------------------
#                         low-level routines
#---------------------------------------------------------------------

# "UsageError" prints  usage text for the current program,  then term-
# inates the program with exit status one.

#---------------------------------------------------------------------

sub UsageError
{
    my $UsageText;              # Usage text
                                # Copy appropriate text block
    $UsageText = $USAGE_TEXT_DETAB   if $FlagDETAB  ;
    $UsageText = $USAGE_TEXT_ENTAB   if $FlagENTAB  ;
    $UsageText = $USAGE_TEXT_SETDOS  if $FlagDOS    ;
    $UsageText = $USAGE_TEXT_TRIMWS  if $FlagTRIMWS ;
    $UsageText = $USAGE_TEXT_SETUNIX if $FlagUNIX   ;

                                # Adjust the usage text
    $UsageText =~ s@(__)(META_|)(REVISION__)\s+(-)@$1$2$3 $4@;
    $UsageText =~ s@__(META_|)PROG(NAME|RAM)__@$PROGNAME@g;
    $UsageText =~ s@__(META_|)REVISION__@$REVISION@g;
    $UsageText =~ s@^\s+@@s;
    $UsageText =~ s@\s*\z@\n@s;

    if ($USE_LESS && (-t STDOUT) && open (OFD, "|/usr/bin/less"))
    {                           # Display usage text using "less"
        $UsageText .= << 'END'; # 'END' should be single-quoted here

To exit this "help" text, press "q" or "Q".

END
        print OFD $UsageText;
        close OFD;
    }
    else
    {                           # Print usage text directly
        print "\n", $UsageText, "\n";
    }

    exit ONE;                   # Terminate the program
}

#---------------------------------------------------------------------

# "AdjustList"  is a  "find"-compatible  list  preprocessor. This pre-
# processor is used by a "find" command in the main routine.

#---------------------------------------------------------------------

sub AdjustList
{
    my (@list) = @_;
                                # Safety measure
    @list = grep { !-l && !m@^\.{1,2}\z@; } @list;

    if ($CWD eq '/')            # More safety measures
    {
        @list = grep { !/^proc\z/; } @list;
    }
    elsif ($CWD =~ m@^/proc(/|\z)@)
    {
        @list = ();
    }

    @list;
}

#---------------------------------------------------------------------

# "ProcEntry"  is a  "find"-compatible file processor that's used by a
# "find" command in the main routine. Note: This routine must preserve
# "$_".

#---------------------------------------------------------------------

sub ProcEntry
{
    my $path;                   # Absolute pathname
                                # Filename (provided by "File::Find")
    my $name = "$File::Find::name";

    $name =~ s@^(\./)+@@;       # Strip leading occurrences of "./"
    $path =  "$CWD/$name";      # Absolute pathname
    $path =~ s@^//+@/@;         # Kludge

                                # Check path against pattern (if any)
    return if defined ($TreePattern) && ($path !~ m@$TreePattern@);

                                # Check entry type
    return unless (-f $path) && (!-l $path) && (-T $path);

    push (@Entries, $path);     # Save path
    undef;
}

#---------------------------------------------------------------------
#                           file processor
#---------------------------------------------------------------------

# This routine takes one argument, which specifies the  name  or path-
# name of a regular file. It processes the file in question.

#---------------------------------------------------------------------

sub ProcFile
{
    my ($path) = @_;            # Argument list
    my $data;                   # Data buffer
    my $str;                    # Scratch

#---------------------------------------------------------------------
# Save file-status values.

    my @stat = (stat $path);

#---------------------------------------------------------------------
# Initial checks.

# Note #1:  In theory, since we just did a "stat",  these checks could
# use the special Perl filehandle "_" instead of explicit paths.  How-
# ever, in practice, this would complicate things due to symbolic-link
# rules.

# Note #2: In certain cases,  some of the following checks will be re-
# dundant. However, this shouldn't cause any significant problems.

    return unless (!-l $path) && (-f $path) && (-T $path);

    die "Error: Missing read or write access to file:\n$path\n"
        unless (-r $path) && (-w $path);

#---------------------------------------------------------------------
# Check access rights to enclosing directory.

    $str = $path;
    $str = "./$path" unless $path =~ m@/@;
    return unless $str =~ s@/[^/]+\z@/@;

    if ((!-r $str) || (!-w $str) || (!-x $str))
    {
        die "Error: Insufficient privileges for directory:\n$str\n";
    }

#---------------------------------------------------------------------
# Check file size.

    my $bsize = $stat [7];      # File size (in bytes)

    if ($bsize > $MAXSIZE)      # Is file too large to process?
    {                           # Yes
        print "Warning: File is too large to process:\n$path\n";
        return;
    }

#---------------------------------------------------------------------
# Record additional attributes.

    my $mtime = $stat [9];      # Original timestamp
                                # Original permissions
    my $xperm = 07777 & $stat [2];

#---------------------------------------------------------------------
# Read entire file.

    open (IFD, "<$path") ||
        die "Error: Couldn't open file for reading: $!\n$path\n";
    binmode (IFD);
    undef $/;
    $data = <IFD>;
    $data = "" unless defined $data;
    close IFD;

#---------------------------------------------------------------------
# Handle "detab" mode.

    if ($FlagDETAB)
    {
        my @lines = split (/\n/, $data);

        for (@lines)
        {
            while (/\t/)
            {
                $_ = $` . (' ' x ($FW - length ($`) % $FW)) . $';
            }
        }

        $data  = join "\n", @lines;
        $data .= "\n";
    }

#---------------------------------------------------------------------
# Handle "entab" mode.

    if ($FlagENTAB)
    {
        my @lines = split (/\n/, $data);

        for (@lines)
        {
            $_ =~ s@^(( {$FW})+)@"\t" x int (length ($1) / $FW)@e;
        }

        $data  = join "\n", @lines;
        $data .= "\n";
    }

#---------------------------------------------------------------------
# Handle Microsoft-newlines mode.

    if ($FlagDOS)
    {
        $data =~ s@\015*\012@\015\012@gs;
        $data =~ s@\s*\z@\015\012@s;
    }

#---------------------------------------------------------------------
# Handle UNIX-newlines mode.

    if ($FlagUNIX)
    {
        $data =~ s@\015*\012@\n@gs;
        $data =~ s@\s*\z@\n@s;
    }

#---------------------------------------------------------------------
# Handle "trim white space" mode.

    if ($FlagTRIMWS)
    {
        $data =~ s@\s*\z@\n@s;
        $data =~ s@[\000\011\040]+([\015\012])@$1@gs;
    }

#---------------------------------------------------------------------
# Write result to a temporary file (in the target filesystem).

    my $tmpfile = $path . "-$>-$$.tmp";
    my $ok      = FALSE;

    eval
    {
        if (open (OFD, ">$tmpfile") &&
            (print OFD $data) && close (OFD))
        {
            $ok = TRUE;
        }
    };

    $ok = FALSE if $@;

    if (!$ok)
    {
        eval { close OFD; };
        unlink ($tmpfile);
        die "Error: Write to temporary file failed:\n$tmpfile\n";
    }

#---------------------------------------------------------------------
# Replace original file with modified copy.

    if (!unlink ($path))
    {
        die "Error: Couldn't remove original file: $!:\n$path\n";
    }

    if (!rename ($tmpfile, $path))
    {
        die "Error: Couldn't rename temporary file: $!:\n$tmpfile\n";
    }

#---------------------------------------------------------------------
# Wrap it up.

                                # Restore timestamp
    utime ($mtime, $mtime, $path) ||
        die "Error: Couldn't set timestamp: $!:\n$path\n";

    if (!chmod ($xperm, $path)) # Try to restore original permissions
    {                           # Error (treated as non-fatal)
        print STDERR << "END";  # "END" must be double-quoted here
Warning: Couldn't restore original permissions: $!\n$path\n";
END
    }

    print "$path\n";            # Echo filename (or pathname)
    undef;
}

#---------------------------------------------------------------------
#                            main routine
#---------------------------------------------------------------------

sub Main
{
    my @Objects = ();           # Objects to process
    my @Output  = ();           # Output lines
    my $OptTree = FALSE;        # Option flag: Process entire tree

    my $n;                      # Scratch (integer)
    my $str;                    # Scratch (string )

#---------------------------------------------------------------------
# Initial setup.

                                # Note: STDERR must be set first here
    select STDERR; $| = ONE;    # Set flush-on-write mode for STDERR
    select STDOUT; $| = ONE;    # Set flush-on-write mode for STDOUT
                                # Fix problems for some filesystems
    $File::Find::dont_use_nlink = ONE;

#---------------------------------------------------------------------
# Process the command line (1st pass).

    for my $arg (@ARGV)
    {
        next unless $arg =~ s@^(-+)(.*)\z@@s;
        my ($dashes, $option) = ($1, $2);

        $OptTree = FALSE if $option =~ s@T@@;
        $OptTree = TRUE  if $option =~ s@t@@;

        die "Error: $PROGNAME: Invalid option: $dashes$arg\n"
            if length $option;
    }

#---------------------------------------------------------------------
# Process the command line (2nd pass).

    for my $arg (@ARGV)
    {
        next unless length $arg;

        if ($OptTree)           # Was "-t" specified?
        {                       # Yes - This mode has its own rules
            if ($arg =~ m@[\?\*\{\}\(\)\[\]\\]@)
            {                   # Pattern string
                                # Check the pattern
                eval { "foo" =~ m@$arg@; };

                if ($@)         # Is it a valid Perl pattern?
                {               # No  - Error
                                # "END" must be double-quoted here
                    print STDERR << "END";
Error: This isn't a valid Perl pattern:

$arg
END
                    exit ONE;   # Terminate the program
                }

                $TreePattern = $arg;
                next;
            }

            $n = TRUE;          # Object is checked at a later point
        }
        else
        {                       # No  - "-t" wasn't specified
            next unless (-f $arg) && (!-l $arg) && (-T $arg);
        }

        push (@Objects, $arg);
    }

    &UsageError() unless scalar @Objects;

#---------------------------------------------------------------------
# Handle the "-t" switch.

    if ($OptTree)               # Process an entire directory tree?
    {                           # Yes
        my $BaseDir;            # Starting-point directory

        if (((scalar @Objects) != ONE) ||
            !-d ($BaseDir = shift @Objects))
        {
            $str = << 'END';
__META_PROGNAME__ -t . "[ijk].*\.(asc|txt)\z"
END
            $str =~ s@__META_PROGNAME__@$PROGNAME@g;
            $str =~ s@\s+\z@@s;

            print STDERR << "END";

Error:  If  "-t" is used, the command line should specify  exactly one
directory (and no files).

Note: In this mode, the command line may include an optional Perl pat-
tern string.  For example, the following command will search the  cur-
rent directory tree for ".asc" or ".txt" objects that have  one of the
letters "ijk" in their pathname:

      $str

__META_PROGNAME__ skips over files that appear to be binary data.

END
            exit ONE;           # Terminate the program
        }
                                # Adjust the specified path
        $BaseDir =~ s@^(.+)/\z@$1@;
        while ($BaseDir =~ s@/(\./)+@/@g) {}
        while ($BaseDir =~ s@/[^/]+/\.\./@/@g) {}

                                # Go to specified directory
        chdir ($BaseDir) ||
            die "Error: Can't access directory: $!\n$BaseDir";

        $CWD = getcwd();        # Save absolute pathname

        my %args =              # Arguments for "find" command
        (
            bydepth    => TRUE         ,
            preprocess => \&AdjustList ,
            wanted     => \&ProcEntry
        );

        find (\%args, '.');     # Execute a "find" command
        @Objects = @Entries;    # Copy  the list obtained
        @Entries = ();          # Reset the original list
    }

#---------------------------------------------------------------------
# Main loop.

    for my $object (@Objects)   # Process all  objects
    {                           # Process next object
        &ProcFile ($object);
    }

    undef;
}

#---------------------------------------------------------------------
#                            main program
#---------------------------------------------------------------------

&Main();                        # Call the main routine
exit ZERO;                      # Normal exit
