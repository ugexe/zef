module Zef::Reporter;
use Zef::Reporter::Zef;
use Zef::Reporter::Feather;

has @.reporters = <Zef Feather>;

# default report to stdout/file