<?php
namespace App\Http\Controllers;
abstract class Controller
{
    protected function ok(mixed $data = null, int $status = 200)
    {
        return response()->json(["success" => true, "message" => "OK", "data" => $data], $status);
    }
}
