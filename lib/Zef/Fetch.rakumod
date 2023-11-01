use Zef:ver($?DISTRIBUTION.meta<version> // '*'):api($?DISTRIBUTION.meta<api> // '*'):auth($?DISTRIBUTION.meta<auth> // '');
use Zef::Utils::FileSystem:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);

class Zef::Fetch does Fetcher does Pluggable {

    =begin pod

    =title class Zef::Fetch

    =subtitle A configurable implementation of the Fetcher interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Fetch;

        # Setup with a single fetcher backend
        my $fetcher = Zef::Fetch.new(
            backends => [
                { module => "Zef::Service::Shell::curl" },
                { module => "Zef::Service::Shell::wget" },
            ],
        );

        # Save the content of $uri to $save-to
        my $uri      = "https://httpbin.org/ip";
        my $save-to  = $*CWD.child("output.txt");
        my $saved-to = $fetcher.fetch(Candidate.new(:$uri), $save-to);

        say $saved-to ?? $saved-to.slurp !! "Failed to download and save";

    =end code

    =head1 Description

    A C<Fetcher> class that uses 1 or more other C<Fetcher> instances as backends. It abstracts the logic
    to do 'grab this uri with the first backend that supports the given uri'.

    =head1 Methods

    =head2 method fetch-matcher

        method fetch-matcher($path --> Bool:D)

    Returns C<True> if any of the probeable C<self.plugins> know how to fetch C<$path>.

    =head2 method fetch

        method fetch(Candidate $candi, IO() $save-to, Supplier :$logger, Int :$timeout --> IO::Path)

    Fetches the files for C<$candi> (usually as C<$candi.uri>) to C<$save-to>. If a backend fails to fetch
    for some reason (such as going over its C<:$timeout>) the next matching backend will be used. Failure occurs
    when no backend was able to fetch the C<$candi>.

    An optional C<:$logger> can be supplied to receive events about what is occurring.

    An optional C<:$timeout> can be passed to denote the number of seconds after which we'll assume failure.

    On success it returns the C<IO::Path> where the data was actually fetched to. On failure it returns C<Nil>.

    Note this differs from other 'Fetcher' adapters C<method fetch> (i.e. the fetchers this uses as backends) which
    take a C<Str $uri> as the first parameter, not a C<Candidate $candi>.

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| Returns true if any of the backends 'fetch-matcher' understand the given uri/path
    method fetch-matcher($uri --> Bool:D) { return so self!fetch-matcher($uri) }

    #| Returns the backends that understand the given uri based on their fetch-matcher result
    method !fetch-matcher($uri --> Array[Fetcher]) {
        my @matching-backends = self.plugins.grep(*.fetch-matcher($uri));

        my Fetcher @results = @matching-backends;
        return @results;
    }

    #| Fetch the given url.
    #| Will return the first successful result while attempting to fetch the given $candi.
    method fetch(Candidate $candi, IO() $save-to, Supplier :$logger, Int :$timeout --> IO::Path) {
        my $uri      = $candi.uri;
        my @fetchers = self!fetch-matcher($uri).cache;

        unless +@fetchers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled fetching backends [{@report_enabled}] don't understand $uri\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        if ?$logger {
            $stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, candi => $candi, message => $out }) }
            $stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $got := @fetchers.map: -> $fetcher {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => FETCH, phase => START, candi => $candi, message => "Fetching $uri with plugin: {$fetcher.^name}" });
            }

            my $ret = lock-file-protect("{$save-to}.lock", -> {
                my $todo    = start { try $fetcher.fetch($uri, $save-to, :$stdout, :$stderr) };
                my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
                await Promise.anyof: $todo, $time-up;
                $logger.emit({ level => DEBUG, stage => FETCH, phase => LIVE, candi => $candi, message => "Fetching $uri timed out" })
                    if ?$logger && $time-up.so && $todo.not;
                $todo.so ?? $todo.result !! Nil;
            });

            $ret;
        }

        my IO::Path $result = $got.grep(*.so).map(*.IO).head;

        $stdout.done();
        $stderr.done();

        return $result;
    }
}

