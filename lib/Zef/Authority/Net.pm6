use Zef::Authority;

role Zef::Authority::Net does Zef::Authority {
    method get(*@paths) { ... }
    method report       { ... }    
}