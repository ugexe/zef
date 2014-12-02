#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 0;

zef 'CSV::Parser':ver<5>;

