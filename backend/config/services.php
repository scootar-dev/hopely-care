<?php
return [
    "ai" => [
        "url" => env("AI_SERVICE_URL", "http://127.0.0.1:8001"),
        "key" => env("INTERNAL_SERVICE_KEY"),
    ],
    "firebase" => [
        "project_id" => env("FCM_PROJECT_ID"),
        "credentials" => env("GOOGLE_APPLICATION_CREDENTIALS"),
    ],
];
