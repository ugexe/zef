use Zef;

class Zef::Service::Shell::InstallPM5 does Installer does Messenger {
    method install-matcher($dist) { $dist ~~ Distribution && $dist.meta<from> eq 'Perl5' }

    method probe { True }

    method install($dist, :$cur, :$force) {
        my $ok;
        my $stdout = Buf.new;
        my $stderr = Buf.new;
        react {
            my $ENV := %*ENV;
            my $proc = zrun-async('cpanm', ($force ?? '--force' !! ''), $dist.version ?? sprintf('%s~%s', $dist.name, $dist.version) !! $dist.name);
            whenever $proc.stdout(:bin) { $stdout.append($_) }
            whenever $proc.stderr(:bin) { $stderr.append($_) }
            whenever $proc.start(:$ENV) { $ok = $_.so }
        }
        return $ok;
    }
}
