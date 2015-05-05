use Zef::Phase::Reporting;

BEGIN {
    try require Panda::Reporter;
    try require Panda::Project;
}

role Zef::Plugin::PandaReporter does Zef::Phase::Reporting {
    has $!reporter = ENTER { 
        if ::('Panda::Reporter') ~~ Failure  {
            #X::NYI::Available.new(:available("panda"), :feature("sending reports to testers.p6c.org")).message.say;            
        }
        else {
            return Panda::Reporter.new;
        }
    };
    has $!project = ENTER { 
        if ::('Panda::Project') ~~ Failure  {
            #X::NYI::Available.new(:available("panda"), :feature("sending reports to testers.p6c.org")).message.say;            
        }
        else {
            return Panda::Project.new;
        }
    };


    method report { };
}
