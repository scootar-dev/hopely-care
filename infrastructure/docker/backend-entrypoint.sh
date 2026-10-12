#!/bin/sh
set -eu
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
php artisan migrate --force
php artisan db:seed --class=CommunitySeeder --force
exec php artisan serve --host=0.0.0.0 --port=8000
