use Zef;
use Zef::Distribution::DependencySpecification;
use Zef::Utils::SystemQuery;

class Zef::Distribution does Distribution is Zef::Distribution::DependencySpecification {

    =begin pod

    =title class Zef::Distribution

    =subtitle A generic Distribution implementation

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef::Distribution;
        use JSON::Fast;

        my %meta = from-json("META6.json".IO.slurp);
        my $dist = Zef::Distribution.new(|%meta);

        # Show the meta data
        say $dist.meta.perl;

        # Output if the $dist contains a namespace matching Foo::Bar:ver<1>
        say $dist.contains-spec("Foo::Bar:ver<1>");

    =end code

    =head1 Description

    A C<Distribution> implementation that is used to represent not-yet-downloaded distributions.
    Generally you should use this class using the C<Distribution> interface and not as a struct representation
    of META6 data -- i.e. use C<$dist.meta.hash{"version"}> instead of <$dist.ver>. These variations are a wart
    included mostly for backwards compatibility purposes (or just leftover from years of changes to e.g. C<CompUnit::Repository>
    and friends).

    When using this class "best practice" would be to consider the following methods are the public api:
    C<meta> and C<content> (the C<Distribution> interface methods), C<depends-specs>, C<test-depends-specs>, C<build-depends-specs>, C<provides-specs>, C<provides-spec-matcher>, C<contains-spec>, C<Str>

    =head1 Methods

    =head2 method meta

        method meta(--> Hash:D)

    Returns the meta data that represents the distribution.

    =head2 method content

        method content()

    Will always throw an exception. This class is primarily used to represent a distribution when all we have it meta data; use
    a class like C<Zef::Distribution::Local> (which subclasses this class) if or when you need access to the content of files
    besides C<META6.json>.

    =head2 method depends-specs

        method depends-specs(--> Array[Zef::Distribution::DependencySpecification])

    Return an C<Array> of C<DependencySpecification> for the runtime dependencies of the distribution.

    =head2 method test-depends-specs

        method test-depends-specs(--> Array[Zef::Distribution::DependencySpecification])

    Return an C<Array> of C<DependencySpecification> for the test dependencies of the distribution.

    =head2 method depends-specs

        method build-depends-specs(--> Array[Zef::Distribution::DependencySpecification])

    Return an C<Array> of C<DependencySpecification> for the build dependencies of the distribution.

    =head2 method provides-specs

        method provides-specs(--> Array[Zef::Distribution::DependencySpecification])

    Return an C<Array> of C<DependencySpecification> for the namespaces in the distributions C<provides>.

    =head2 method provides-spec-matcher

        method provides-spec-matcher(Zef::Distribution::DependencySpecification $spec, :$strict --> Bool:D) { self.provides-specs.first({ ?$_.spec-matcher($spec, :$strict) }) }

    Returns C<True> if C<$spec> matches any namespaces this distribution provides (but not the name of the distribution itself).
    If C<$strict> is C<False> then partial name matches will be allowed (i.e. C<HTTP> matching C<HTTP::UserAgent>).

    =head2 method contains-spec

        multi method contains-spec(Str $spec, |c --> Bool:D)
        multi method contains-spec(Zef::Distribution::DependencySpecification $spec, Bool :$strict = True --> Bool:D)
        multi method contains-spec(Zef::Distribution::DependencySpecification::Any $spec, Bool :$strict = True --> Bool:D)

    Returns C<True> if C<$spec> matches any namespace this distribution provides, including the name of the distribution itself.
    If C<$strict> is C<False> then partial name matches will be allowed (i.e. C<HTTP> matching C<HTTP::UserAgent>).

    When given a C<Str> C<$spec> the C<$spec> will be turned into a C<Zef::Distribution::DependencySpecification>.

    =head2 method Str

        method Str(--> Str)

    Returns the explicit full name of the distribution, i.e. C<Foo> -> C<Foo:ver<>:auth<>:api<>>

    =head2 method id

        method id(--> Str)

    Returns a file system safe unique string identifier for the distribution. This is generally meant for internal use only.

    Note: This should not publicly be relied on for matching any C<Raku> implementation details this may appear to be emulating.

    =end pod


    has $.meta-version;
    has $.name;
    has $.auth;
    has $.author;
    has $.authority;
    has $.api;
    has $.ver;
    has $.version;
    has $.description;
    has $.depends;
    has %.provides;
    has %.files;
    has $.source-url;
    has $.license;
    has $.build-depends;
    has $.test-depends;
    has @.resources;
    has %.support;
    has $.builder;

    has %!meta;

    # attach arbitrary data, like for topological sort, that won't be saved on install
    has %.metainfo is rw;

    method new(*%_) { self.bless(|%_, :meta(%_)) }

    submethod TWEAK(:%!meta, :@!resources --> Nil) {
        @!resources = @!resources.flatmap(*.flat);
    }

    method auth { with $!auth { .Str } else { Nil } }
    method ver  { with $!ver // $!version { $!ver ~~ Version ?? $_ !! $!ver = Version.new($_ // 0) } }
    method api  { with $!api { $!api ~~ Version ?? $_ !! $!api = Version.new($_ // 0) } }

    # 'new-depends' refers to the hash form of `depends`
    has $!new-depends-cache;
    method !new-depends($type) {
        return Empty unless $.depends ~~ Hash;
        $!new-depends-cache := system-collapse($.depends) unless $!new-depends-cache.defined;
        return system-collapse($.depends){$type}.grep(*.defined).grep(*.<requires>).map(*.<requires>).map(*.Slip).Slip;
    }
    method !depends2specs(*@depends --> Array[DependencySpecification]) {
        my $depends := @depends.map({$_ ~~ List ?? $_.Slip !! $_ }).grep(*.defined);
        my DependencySpecification @depends-specs = $depends.map({ Zef::Distribution::DependencySpecification.new($_) }).grep(*.name);
        return @depends-specs;
    }

    method depends-specs(--> Array[DependencySpecification]) {
        my $depends := system-collapse($.depends);
        my $deps    := $.depends ~~ Hash ?? self!new-depends('runtime') !! $depends;
        return self!depends2specs($deps);
    }
    method build-depends-specs(--> Array[DependencySpecification]) {
        my $orig-build-depends := system-collapse($.build-depends);
        my $new-build-depends  := self!new-depends('build');
        return self!depends2specs(|$orig-build-depends, $new-build-depends);
    }
    method test-depends-specs(--> Array[DependencySpecification]) {
        my $orig-test-depends := system-collapse($.test-depends);
        my $new-test-depends  := self!new-depends('test');
        return self!depends2specs(|$orig-test-depends, $new-test-depends);
    }

    # make locating a module that is part of a distribution (ex. URI::Escape of URI) easier.
    # it doesn't need to be a hash mapping as its just for matching
    has @!provides-specs;
    method provides-specs(--> Array[DependencySpecification]) {
        return @!provides-specs if @!provides-specs.elems;
        my DependencySpecification @provides-specs = self.meta<provides>.grep(*.defined).map({
            # if $spec.name is not defined then .key (the module name of the current provides)
            # is not a valid module name (according to Zef::Identity grammar anyway). I ran into
            # this problem with `NativeCall::Errno` where one of the provides was: `X:NativeCall::Errorno`
            # The single colon cannot just be fixed to DWIM because that could just as easily denote
            # an identity part (identity parts are separated by a *single* colon; double colon is left alone)
            my $spec = Zef::Distribution::DependencySpecification.new(self!long-name(.key));
            next unless defined($spec.name);
            $spec;
        }).grep(*.defined).Slip;
        return @!provides-specs := @provides-specs;
    }

    method provides-spec-matcher(DependencySpecification  $spec, :$strict --> Bool:D) {
        return so self.provides-specs.first({ ?$_.spec-matcher($spec, :$strict) })
    }

    proto method contains-spec(|) {*}
    multi method contains-spec(Str $spec, |c --> Bool:D)
        { samewith( Zef::Distribution::DependencySpecification.new($spec, |c) ) }
    multi method contains-spec(Zef::Distribution::DependencySpecification $spec, Bool :$strict = True --> Bool:D)
        { return so self.spec-matcher($spec, :$strict) || self.provides-spec-matcher($spec, :$strict)  }
    multi method contains-spec(Zef::Distribution::DependencySpecification::Any $spec, Bool :$strict = True --> Bool:D)
        { return so self.contains-spec(any($spec.specs), :$strict) }

    method Str(--> Str) {
        return self!long-name($!name);
    }

    method !long-name($name --> Str) {
        return sprintf '%s:ver<%s>:auth<%s>:api<%s>',
            $name,
            (self.ver  // ''),
            (self.auth // '').trans(['<', '>'] => ['\<', '\>']),
            (self.api  // ''),
        ;
    }

    method id(--> Str) {
        use nqp;
        return nqp::sha1(self.Str);
    }

    method meta(--> Hash:D) { return %!meta }

    method content(|) {
        die "this method must be subclassed by something that can read from a content store";
    }
}
