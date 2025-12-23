<?php

/**
 * `.env` loader:
 * - Prefer `vlucas/phpdotenv` when installed (handles edge cases better)
 * - Fallback to a minimal parser to avoid hard-coded secrets
 */
function loadEnvFile(string $path): void
{
    $autoload = __DIR__ . '/vendor/autoload.php';
    if (is_file($autoload) && is_readable($autoload)) {
        require_once $autoload;
    }

    if (!is_file($path) || !is_readable($path)) {
        return;
    }

    if (class_exists(\Dotenv\Dotenv::class)) {
        try {
            $dir = dirname($path);
            $file = basename($path);
            \Dotenv\Dotenv::createImmutable($dir, $file)->safeLoad();
        } catch (\Throwable $e) {
            // Fall back to the minimal parser below.
        }
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
