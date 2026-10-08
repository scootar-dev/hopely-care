<?php
return [
    "default" => env("DB_CONNECTION", "mysql"),
    "connections" => [
        "mysql" => [
            "driver" => "mysql",
            "host" => env("DB_HOST", "mysql"),
            "port" => env("DB_PORT", 3306),
            "database" => env("DB_DATABASE", "hopely"),
            "username" => env("DB_USERNAME", "hopely"),
            "password" => env("DB_PASSWORD"),
            "unix_socket" => "",
            "charset" => "utf8mb4",
            "collation" => "utf8mb4_unicode_ci",
            "prefix" => "",
            "strict" => true,
        ],
        "sqlite" => [
            "driver" => "sqlite",
            "database" => env("DB_DATABASE", ":memory:"),
            "prefix" => "",
            "foreign_key_constraints" => true,
        ],
    ],
    "migrations" => ["table" => "migrations", "update_date_on_publish" => true],
];
