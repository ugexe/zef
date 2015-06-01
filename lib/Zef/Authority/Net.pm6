use Zef::Authority;


# Interface for network based authority additions?
role Zef::Authority::Net does Zef::Authority {
    method get(*@paths) { ... }
    method report       { ... }    
}