<?php
return [
    "stateful" => [],
    "guard" => ["web"],
    // Mobile sessions remain valid until the user logs out, resets the password,
    // deletes the account, or an administrator revokes the token.
    "expiration" => env("SANCTUM_EXPIRATION"),
    "token_prefix" => "",
    "middleware" => [],
];
