use Zef;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    has %!replacements = 
        '>' => '%3E', '#' => '%23',
        '%' => '%25', '{' => '%7B',
        '}' => '%7D', '|' => '%7C',
        '\\' => '%5C', '^' => '%5E',
        '~' => '%7E', '[' => '%5B',
        ']' => '%5D', '`' => '%60',
        ';' => '%3B', '/' => '%2F',
        '?' => '%3F', ':' => '%3A',
        '@' => '%40', '=' => '%3D',
        '&' => '%26', '$' => '%24',
        '+' => '%2B', '"' => '%22',
        ' ' => '%20'; 

    method fetch($uri, $save-as, Supplier :$logger, :%query-string = { }) {
        my $fetchers := self.plugins.grep(*.fetch-matcher($uri)).cache;
        die "No fetching backend available" unless $fetchers.head(1);

        my $got := $fetchers.map: -> $fetcher {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => FETCH, phase => START, payload => self, message => "Fetching with plugin: {$fetcher.^name}" });
                $fetcher.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, message => $out }) }
                $fetcher.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, message => $err }) }
            }

            my $qs  = self!encode-querystring(%query-string);
            my $ret = try $fetcher.fetch($uri ~ $qs, $save-as);

            $fetcher.stdout.done;
            $fetcher.stderr.done;

            $ret;
        }

        return $got.first(*.so);
    }

    method !encode-querystring(%query) {
        return '' if %query.keys.elems == 0;
        my $qs = '?';
        for %query.keys -> $lval {
            $qs ~= "$lval=" ~
                %query{$lval}.comb.map({
                  %!replacements{$_} ?? %!replacements{$_} !! $_
                }).join.split("\n").join;
        }
        return $qs;
    }
}
