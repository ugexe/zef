use v6;
use Test;
plan 35;

use Zef;
use Zef::Config;
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
ok any($dist.depends-specs.map(*.name)) ~~ 'Zef::Client';
ok any($dist.depends-specs.map(*.from-matcher)) ~~ 'Perl6';
ok any($dist.depends-specs.map(*.name)) ~~ any('mac', 'win', 'linux', 'unknown');
ok any($dist.depends-specs.map(*.from-matcher)) ~~ 'native';

with Zef::Distribution.new(|Rakudo::Internals::JSON.from-json(q:to/META6/)) -> $dist {
    {
        "perl":"6",
        "name":"Test::Complex::Depends",
        "version":"0",
        "auth":"github:stranger",
        "description":"Test hash-based depends and native depends parsing",
        "license":"none",
        "depends": {
            "runtime" : {
                "requires" : [
                    {
                        "by-distro.name": {
                            "win32": ["Foo::Win32_1", "Foo::Win32_2"],
                            "linux": ["Foo::Linux_1", "Foo::Linux_2"],
                            "" : ["Foo::Unknown_1", "Foo::Unknown_2"]
                        }
                    }
                ]
            }
        },
        "provides": { }
    }
    META6
    is $dist.depends-specs.elems, 2;
    ok any($dist.depends-specs.map(*.name)) ~~ any("Foo::Win32_1", "Foo::Linux_1", "Foo::Unknown_1");
    ok any($dist.depends-specs.map(*.name)) ~~ any("Foo::Win32_2", "Foo::Linux_2", "Foo::Unknown_2");
    ok any($dist.depends-specs.map(*.from-matcher)) ~~ 'Perl6';
}

# mixed depends types
with Zef::Distribution.new(|Rakudo::Internals::JSON.from-json(q:to/META6/)) -> $dist {
    {
        "perl":"6",
        "name":"Test::Complex::Depends",
        "version":"0",
        "auth":"github:stranger",
        "description":"Test hash-based depends and native depends parsing",
        "license":"none",
        "build-depends" : [ "Foo::Build" ],
        "test-depends" : [ "Foo::Test" ],
        "depends": {
            "runtime" : {
                "requires" : [
                    {
                        "by-distro.name": {
                            "win32": "Win32::Runtime",
                            "linux": "Linux::Runtime",
                            "" : "Unknown::Runtime"
                        }
                    }
                ]
            },
            "build" : {
                "requires" : [ "Foo::BuildX" ]
            },
            "test" : {
                "requires" : [ "Foo::TestX" ]
            }
        },
        "provides": { }
    }
    META6
    is $dist.depends-specs.elems, 1;
    is $dist.build-depends-specs.elems, 2;
    is $dist.test-depends-specs.elems, 2;
    ok any($dist.depends-specs.map(*.name)) ~~ any("Win32::Runtime", "Linux::Runtime", "Unknown::Runtime");
    ok any($dist.build-depends-specs.map(*.name)) ~~ 'Foo::Build';
    ok any($dist.build-depends-specs.map(*.name)) ~~ 'Foo::BuildX';
    ok any($dist.test-depends-specs.map(*.name)) ~~ 'Foo::Test';
    ok any($dist.test-depends-specs.map(*.name)) ~~ 'Foo::TestX';
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
        method list-installed(*@) { [] }
    }
    my $client = Zef::Client::Fake.CREATE;
    $client.depends = True;
    is $client.list-dependencies(
        Candidate.new(:$dist),
    )[1].specs[0].name, "Bar";
}


my $guess-path = $?FILE.IO.parent.parent.child('resources/config.json');
my $config-file = $guess-path.e ?? ~$guess-path !! Zef::Config::guess-path();
my $config = Zef::Config::parse-file($config-file);
my $recommendation-manager = (
    Zef::Repository but role :: {
        method plugins(*@) {
            [
                [
                    class :: does PackageRepository {
                        method search(*@identities --> Seq) {
                            gather for @identities -> $as {
                                take Candidate.new(:dist(Zef::Distribution.new(:name($as))), :$as, :from<Test>)
                                    if $as ∈ <Available AvailableToo>;
                                take Candidate.new(:dist(Zef::Distribution.new(:name($as), :depends['Unsatisfiable'])), :$as, :from<Test>)
                                    if $as eq 'HasUnsatisfiableDep';
                                take Candidate.new(:dist(Zef::Distribution.new(:name($as), :depends['HasUnsatisfiableDep'])), :$as, :from<Test>)
                                    if $as eq 'HasTransitivelyUnsatisfiableDep';
                                take Candidate.new(:dist(Zef::Distribution.new(:name($as), :depends[{:any["AvailableToo", "Available"]},])), :$as, :from<Test>)
                                    if $as eq 'DependsOnAvailableTooOrAvailable';
                            }
                        }
                    },
                ],
            ]
        }
    }
).new(:backends[]);

for (
    ["Available", {:any["Unavailable", "Installed"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 1;
        is $prereq-candidates[0].dist.name, "Available";
    },
    [{:any["Unavailable", "Available"]},] => -> $prereq-candidates {
        is $prereq-candidates.elems, 1;
        is $prereq-candidates[0].dist.name, "Available";
    },
    ["Available", {:any["Unavailable", "AvailableToo"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available AvailableToo>;
    },
    [{:any["AvailableToo", "Available"]}, "Available"] => -> $prereq-candidates {
        is $prereq-candidates.elems, 1;
        is $prereq-candidates.map(*.dist.name).sort, <Available>;
    },
    ["DependsOnAvailableTooOrAvailable", "Available"] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available DependsOnAvailableTooOrAvailable>;
    },
    ["DependsOnAvailableTooOrAvailable"] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <AvailableToo DependsOnAvailableTooOrAvailable>;
    },
    ["Available", {:any["HasUnsatisfiableDep", "AvailableToo"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available AvailableToo>;
    },
    ["Available", {:any["HasTransitivelyUnsatisfiableDep", "AvailableToo"]}] => -> $prereq-candidates {
        is $prereq-candidates.elems, 2;
        is $prereq-candidates.map(*.dist.name).sort, <Available AvailableToo>;
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
            method list-installed(*@) {
                [Candidate.new(:dist(Zef::Distribution.new(:name<Installed>)))]
            }
            method logger() {
                class :: { method emit($) { } }
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

subtest 'X::Zef::UnsatisfiableDependency' => {
    for (
        ["Unavailable"],
        ["Available", "Unavailable"],
        ["Available", {:any["Unavailable", "Unavailable2"]}],
        ["Available", {:any[{:name<Unavailable>, :from<native>}, {:name<Unavailable2>, :from<native>}]}],
    ) -> $test {
        with Zef::Distribution.new(
                :perl(6),
                :name<Test::Complex::Depends>,
                :version<0>,
                :auth('github:stranger'),
                :description('Test hash-based depends and native depends parsing'),
                :license<none>,
                :depends($test),
                :provides{ },
            ) -> $dist {
            my class Zef::Client::Fake is Zef::Client {
                method list-installed(*@) {
                    [Candidate.new(:dist(Zef::Distribution.new(:name<Installed>)))]
                }
                method logger() {
                    class :: { method emit($) { } }
                }
            }

            my $client = Zef::Client::Fake.new(:$config, :$recommendation-manager);

            $client.depends = True;
            throws-like { $client.find-prereq-candidates(Candidate.new(:$dist)) }, X::Zef::UnsatisfiableDependency;
        }
    }
}
