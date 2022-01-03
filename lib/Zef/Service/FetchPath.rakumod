use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::FetchPath does Fetcher does Extractor does Messenger {

    =begin pod

    =title class Zef::Service::FetchPath

    =subtitle A file system based implementation of the Fetcher and Extractor interfaces

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::FetchPath;

        my $fetch-path = Zef::Service::FetchPath.new;

        # Copy the content of the current directory to ./backup_dir/$random/*
        my $source   = $*CWD;
        my $save-to  = $*CWD.child("backup_dir");
        my $saved-to = $fetch-path.fetch($source, $save-to);

        die "Failed to copy paths" unless $saved-to;
        say "The following top level paths now exist:";
        say "\t{$_.Str}" for $saved-to.dir;

        my $extract-to   = $*CWD.child("extracted_backup_dir");
        my $extracted-to = $fetch-path.extract($saved-to, $extract-to);

        die "Failed to extract paths" unless $extracted-to;
        say "The following top level paths now exist:";
        say "\t{$_.Str}" for $extracted-to.dir;

    =end code

    =head1 Description

    C<Fetcher> and C<Extractor> class for handling local file paths.

    You probably never want to use this unless its indirectly through C<Zef::Fetch> or C<Zef::Extractor>;
    handling files will generally be easier using core language functionality. This class exists to provide
    the means for fetching local paths using the C<Fetcher> and C<Extractor> interfaces that the e.g. git/http/tar
    fetching/extracting adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module believes all run time prerequisites are met. Since the only prerequisite
    is a file system this always returns C<True>

    =head2 method fetch-matcher

        method fetch-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to fetch C<$uri>, which it decides based on if C<$uri> looks like
    a file path (i.e. C<$uri> starts with a C<.> or C</>) and if that file path exists.

    =head2 method extract-matcher

        method extract-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to extract C<$uri>, which it decides based on if C<$uri> looks like
    a file path (i.e. C<$uri> starts with a C<.> or C</>) and if that file path exists as a directory.

    =head2 method fetch

        method fetch(IO() $source-path, IO() $save-to --> IO::Path)

    Fetches the given C<$source-path> from the file system and copies it to C<$save-to> (+ timestamp if C<$source-path>
    is a directory) directory.

    On success it returns the C<IO::Path> where the data was actually saved to (usually a subdirectory under the passed-in
    C<$save-to>). On failure it returns C<Nil>.

    =head2 method extract

        method extract(IO() $source-path, IO() $save-to --> IO::Path)

    Extracts the given C<$source-path> from the file system and copies it to C<$save-to>.

    On success it returns the C<IO::Path> where the data was actually extracted to. On failure it returns C<Nil>.

    =head2 method ls-files

        method ls-files(IO() $path --> Array[Str])

    On success it returns an C<Array> of relative paths that are available to be extracted from C<$path>.

    =end pod


    #| Always return true since a file system is required
    method probe(--> Bool:D) { return True }

    #| Return true if this Fetcher understands the given uri/path
    method fetch-matcher(Str() $uri --> Bool:D) {
        # .is-absolute lets the app pass around absolute paths on windows and still work as expected
        my $is-pathy = so <. />.first({ $uri.starts-with($_) }) || $uri.IO.is-absolute;
        return so $is-pathy && $uri.IO.e;
    }

    #| Return true if this Extractor understands the given uri/path
    method extract-matcher(Str() $uri --> Bool:D) {
        # .is-absolute lets the app pass around absolute paths on windows and still work as expected
        my $is-pathy = so <. />.first({ $uri.starts-with($_) }) || $uri.IO.is-absolute;
        return so $is-pathy && $uri.IO.d;
    }

    #| Fetch (copy) the given source path to the $save-to (+ timestamp if source-path is a directory) directory
    method fetch(IO() $source-path, IO() $save-to --> IO::Path) {
        return Nil if !$source-path.e;
        return $source-path if $source-path.absolute eq $save-to.absolute; # fakes a fetch
        my $dest-path = $source-path.d ?? $save-to.child("{$source-path.IO.basename}_{time}") !! $save-to;
        mkdir($dest-path) if $source-path.d && !$save-to.e;
        return $dest-path if copy-paths($source-path, $dest-path).elems;
        return Nil;
    }

    #| Extract (copy) the files located in $source-path directory to $save-to directory.
    #| This is mostly the same as fetch, and essentially allows the workflow to treat
    #| any uri type (including paths) as if they can be extracted.
    method extract(IO() $source-path, IO() $save-to --> IO::Path) {
        my $extracted-to = $save-to.child($source-path.basename);
        my @extracted = copy-paths($source-path, $extracted-to);
        return +@extracted ?? $extracted-to !! Nil;
    }

    #| List all files and directories, recursively, for the given path
    method ls-files(IO() $path --> Array[Str]) {
        my Str @results = list-paths($path, :f, :!d, :r).map(*.Str);
        return @results;
    }
}
