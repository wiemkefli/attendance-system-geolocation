<?php

/**
 * Minimal `.env` loader to avoid hard-coded secrets without requiring extra dependencies.
 * Loads variables into getenv()/$_ENV if `attendance_api/.env` exists.
 */
function loadEnvFile(string $path): void
{
    if (!is_file($path) || !is_readable($path)) {
        return;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($lines === false) {
        return;
    }

    foreach ($lines as $line) {
        $trimmed = trim($line);
        if ($trimmed === '' || str_starts_with($trimmed, '#')) {
            continue;
        }

        $eqPos = strpos($trimmed, '=');
        if ($eqPos === false) {
            continue;
        }

        $key = trim(substr($trimmed, 0, $eqPos));
        if ($key === '') {
            continue;
        }

        $value = trim(substr($trimmed, $eqPos + 1));
        if ($value !== '' && ($value[0] === '"' || $value[0] === "'")) {
            $quote = $value[0];
            if (str_ends_with($value, $quote) && strlen($value) >= 2) {
                $value = substr($value, 1, -1);
            } else {
                $value = ltrim($value, $quote);
            }
        }

        if (getenv($key) !== false) {
            continue;
        }

        $_ENV[$key] = $value;
        putenv("$key=$value");
    }
}

