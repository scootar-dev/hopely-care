<?php
return [
    "name" => "Hopely Care",
    "env" => env("APP_ENV", "production"),
    "debug" => false,
    "url" => env("APP_URL", "http://localhost:8000"),
    "timezone" => "UTC",
    "locale" => "id",
    "fallback_locale" => "en",
    "key" => env("APP_KEY"),
    "cipher" => "AES-256-CBC",
    "previous_keys" => array_filter(explode(",", env("APP_PREVIOUS_KEYS", ""))),
];
