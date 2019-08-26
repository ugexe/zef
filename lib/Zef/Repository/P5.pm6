use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

class Zef::Repository::P5 does Repository {
    has $.mirrors;
    has $.fetcher;
    has $.cache;

    method probe {
        state $probe = try { so zrun('cpanm', '--help', :!out, :!err) };
    }

    method IO {
        my $dir = $!cache.IO.child('perl5');
        $dir.mkdir unless $dir.e;
        $dir;
    }

    method search(:%params is copy, *@identities, *%fields) {
        return ().Seq unless @identities || %fields;

        my @matches = @identities.map(-> $identity {
            my $spec = Zef::Distribution::DependencySpecification.new($identity);
            next unless $spec.from-matcher eq 'Perl5';

            my $ok;
            my $stdout = Buf.new;
            my $stderr = Buf.new;
            react {
                my $ENV := %*ENV;
                say $spec.version-matcher.perl;
                my $proc = zrun-async('cpanm', '--info', "{$spec.name}{$spec.version-matcher.?chars ?? (q|~| ~ $spec.version-matcher) !! ''}");
                whenever $proc.stdout(:bin) { $stdout.append($_) }
                whenever $proc.stderr(:bin) { $stderr.append($_) }
                whenever $proc.start(:$ENV) { say $_.perl; $ok = $_.so }
            }
            next unless $ok;

            my $name-path = $stdout.decode.lines.tail;
            my $dist = Zef::Distribution.new(:from<Perl5>, :name($spec.name), :version($spec.version-matcher), :meta-version(5));
            my $uri = 'http://www.cpan.org/authors/id'
                    ~ '/' ~ $name-path.substr(0,1)
                    ~ '/' ~ $name-path.substr(0,2)
                    ~ '/' ~ $name-path;
            Candidate.new(
                dist => $dist,
                uri  => $uri,
                as   => $identity,
                from => self.id,
            );
        });

        return @matches;
    }
}
