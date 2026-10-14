<?php
return [
    "driver" => env("SESSION_DRIVER", "file"),
    "files" => storage_path("framework/sessions"),
    "lottery" => [2, 100],
    "lifetime" => 120,
    "encrypt" => true,
    "cookie" => "hopely_session",
    "path" => "/",
    "secure" => env("SESSION_SECURE_COOKIE", env("APP_ENV", "production") === "production"),
    "http_only" => true,
    "same_site" => "strict"
];
