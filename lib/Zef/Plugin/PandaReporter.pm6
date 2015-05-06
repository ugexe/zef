use Zef::Phase::Reporting;


role Zef::Plugin::PandaReporter does Zef::Phase::Reporting {
    ENTER { 
        try {
                require Panda::Reporter;
                return ::('Panda::Reporter');
        }
        try {
                require Panda::Project;
                return ::('Panda::Project');
        }
        X::NYI::Available.new(:available("panda"), :feature("sending reports to testers.p6c.org")).message.say;            
    }


    method report(*@results) {
        for @results -> %meta {
            my $bone = Panda::Project.new(
                name         => %meta.<name>,
                version      => %meta.version,
                dependencies => %meta.<dependencies>.list,
                metainfo     => %meta,
                build-output => %meta.<build-output>,
                build-passed => %meta.<ok>,
                test-output  => %meta.<test-output>,
                test-passed  => %meta.<ok>
            );

            Panda::Reporter.new( :$bone, reports-file => %meta.<report-file> ).submit            
        }
    }
}
