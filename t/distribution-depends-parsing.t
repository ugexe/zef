use v6;
use Test;
plan 16;

use Zef;
use Zef::Client;
use Zef::Distribution;

my $json = q:to/META6/;
    {
        "perl":"6",
        "name":"Test::Complex::Depends",
        "version":"0",
        "auth":"github:stranger",
        "description":"Test hash-based depends and native depends parsing",
        "license":"none",
        "depends": [
            "Zef::Client",
            {
                "from": "native",
                "name": {
                    "by-distro.name": {
                        "macosx": "mac",
                        "win32" : "win",
                        "linux" : "linux",
                        ""      : "unknown"
                    }
                }
            }
        ],
        "build-depends": [ "Zef::Build" ],
        "test-depends": [ "Zef::Test" ],
        "provides": { }
    }
    META6

my $dist = Zef::Distribution.new(|Rakudo::Internals::JSON.from-json($json));
is $dist.depends-specs[0].name, 'Zef::Client';
is $dist.depends-specs[0].from-matcher, 'Perl6';
ok $dist.depends-specs[1].name ~~ any('mac', 'win', 'linux', 'unknown');
is $dist.depends-specs[1].from-matcher, 'native';

with Zef::Distribution.new(|Rakudo::Internals::JSON.from-json(q:to/META6/)) -> $dist {
    {
        "perl":"6",
        "name":"Test::Complex::Depends",
        "version":"0",
        "auth":"github:stranger",
        "description":"Test hash-based depends and native depends parsing",
        "license":"none",
        "depends": {
            "by-distro.name": {
                "win32": [ "Foo::Win32" ],
                "linux": [ "Foo::Linux" ],
                "" : [ "Foo::Unknown" ]
            }
        },
        "provides": { }
    }
    META6
    ok $dist.depends-specs[0].name ~~ any("Foo::Win32", "Foo::Linux", "Foo::Unknown")
        or note $dist.depends-specs;
}

with Zef::Distribution.new(|Rakudo::Internals::JSON.from-json(q:to/META6/)) -> $dist {
    {
        "perl":"6",
        "name":"Test::Complex::Depends",
        "version":"0",
        "auth":"github:stranger",
        "description":"Test hash-based depends and native depends parsing",
        "license":"none",
        "depends": [
            "Foo",
            {"any": ["Bar", "Baz"]}
        ],
        "provides": { }
    }
    META6
    is $dist.depends-specs()[1].specs[1].name, "Baz"
        or note $dist.depends-specs;
}

with Zef::Distribution.new(|Rakudo::Internals::JSON.from-json(q:to/META6/)) -> $dist {
    {
        "perl":"6",
        "name":"Test::Complex::Depends",
        "version":"0",
        "auth":"github:stranger",
        "description":"Test hash-based depends and native depends parsing",
        "license":"none",
        "depends": [
            "Foo",
            {"any": ["Bar", "Baz"]}
        ],
        "provides": { }
    }
    META6
    my class Zef::Client::Fake is Zef::Client {
        method list-installed(*@curis) { [] }
    }
    my $client = Zef::Client::Fake.CREATE;
    $client.depends = True;
    is $client.list-dependencies(
        Candidate.new(:$dist),
    )[1].specs[0].name, "Bar";
}

use Zef::Config;
my $guess-path = $?FILE.IO.parent.parent.child('resources/config.json');
my $config-file = $guess-path.e ?? ~$guess-path !! Zef::Config::guess-path();
my $config = Zef::Config::parse-file($config-file);
my $recommendation-manager = (
    Zef::Repository but role :: {
        method plugins(*@names) {
            [
                class :: does Repository {
                    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields --> Seq) {
                        gather for @identities -> $as {
                            take Candidate.new(:dist(Zef::Distribution.new(:name($as))), :$as, :from<Test>)
                                if $as ∈ <Available AvailableToo>;
                            take Candidate.new(:dist(Zef::Distribution.new(:name($as), :depends['Unsatisfiable'])), :$as, :from<Test>)
                                if $as eq 'HasUnsatisfiableDep';
                            take Candidate.new(:dist(Zef::Distribution.new(:name($as), :depends['HasUnsatisfiableDep'])), :$as, :from<Test>)
                                if $as eq 'HasTransitivelyUnsatisfiableDep';
                        }
                    }
                },
            ]
        }
    }
).new(:backends[]);

for (
    ["Available", {:any["Unavailable", "Installed"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 1;
        is $prereq-candidates[0].dist.name, "Available";
    },
    ["Available", {:any["Unavailable", "AvailableToo"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available AvailableToo>;
    },
    ["Available", {:any["HasUnsatisfiableDep", "AvailableToo"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available AvailableToo>;
    },
    ["Available", {:any["HasTransitivelyUnsatisfiableDep", "AvailableToo"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available AvailableToo>;
    },
    ["Available", {:any["Unavailable", "Unavailable2"]}] => -> $exception {
        try sink $exception;
        isa-ok $!, X::Zef::UnsatisfiableDependency;
    },
) -> $test {
    with Zef::Distribution.new(
            :perl(6),
            :name<Test::Complex::Depends>,
            :version<0>,
            :auth('github:stranger'),
            :description('Test hash-based depends and native depends parsing'),
            :license<none>,
            :depends($test.key),
            :provides{ },
        ) -> $dist {
        my class Zef::Client::Fake is Zef::Client {
            method list-installed(*@curis) {
                [Candidate.new(:dist(Zef::Distribution.new(:name<Installed>)))]
            }
            method logger() {
                class :: { method emit($m) { } }
            }
        }

        my $client = Zef::Client::Fake.new(:$config, :$recommendation-manager);

        $client.depends = True;
        my $prereq-candidates = $client.find-prereq-candidates(
            Candidate.new(:$dist),
        );
        $test.value.($prereq-candidates);
    }
}
