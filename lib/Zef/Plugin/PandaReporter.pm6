use Zef::Phase::Reporting;


role Zef::Plugin::PandaReporter does Zef::Phase::Reporting {
    has $!reporter = ENTER { 
        try {
                require Panda::Reporter;
                return ::('Panda::Reporter');
        }
        X::NYI::Available.new(:available("panda"), :feature("sending reports to testers.p6c.org")).message.say;            
    }

    has $!project = ENTER { 
        try {
                require Panda::Project;
                return ::('Panda::Project');
        }
        X::NYI::Available.new(:available("panda"), :feature("sending reports to testers.p6c.org")).message.say;            
    }


    method report { };
}
