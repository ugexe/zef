use v6;
use Test;
plan 2;

subtest {
    use-ok("Zef");
    # Just `use Zef::CLI` will make it output usage
    # use-ok("Zef::CLI");
    use-ok("Zef::Shell");
    use-ok("Zef::Build");
    use-ok("Zef::Config");
    use-ok("Zef::Extract");
    use-ok("Zef::Identity");
    use-ok("Zef::Test");
    use-ok("Zef::Fetch");
    use-ok("Zef::Client");

    use-ok("Zef::Repository");
    use-ok("Zef::Repository::MetaCPAN");
    use-ok("Zef::Repository::LocalCache");
    use-ok("Zef::Repository::Ecosystems");

    use-ok("Zef::Distribution");
    use-ok("Zef::Distribution::DependencySpecification");
    use-ok("Zef::Distribution::Local");

    use-ok("Zef::Utils::FileSystem");
    use-ok("Zef::Utils::SystemInfo");
    use-ok("Zef::Utils::URI");
}, 'Core';

subtest {
    use-ok("Zef::Service::FetchPath");
    use-ok("Zef::Service::TAP");
    use-ok("Zef::Service::Shell::Build");
    use-ok("Zef::Service::Shell::Test");
    use-ok("Zef::Service::Shell::prove");
    use-ok("Zef::Service::Shell::unzip");
    use-ok("Zef::Service::Shell::tar");
    use-ok("Zef::Service::Shell::p5tar");
    use-ok("Zef::Service::Shell::curl");
    use-ok("Zef::Service::Shell::git");
    use-ok("Zef::Service::Shell::wget");
    use-ok("Zef::Service::Shell::PowerShell");
    use-ok("Zef::Service::Shell::PowerShell::download");
    use-ok("Zef::Service::Shell::PowerShell::unzip");
}, 'Plugins';
