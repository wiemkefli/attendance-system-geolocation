<?php

/**
 * Returns the JWT secret key material for HS256.
 *
 * firebase/php-jwt v7 enforces minimum HMAC key sizes. If `JWT_SECRET` is not
 * set (or is too short), we derive a stable 32-byte key from the fallback.
 */
function getJwtSecretKey(): string
{
    static $warned = false;

    $secret = getenv('JWT_SECRET');
    if ($secret === false || trim((string)$secret) === '') {
        $secret = 'dev_only_change_me_to_a_long_random_string';
    }

    $secret = (string)$secret;

    // HS256 requires >= 256-bit (32-byte) key material. If a shorter string is
    // provided, derive a stable 32-byte key via SHA-256.
    if (strlen($secret) < 32) {
        if (!$warned) {
            $warned = true;
            error_log('JWT_SECRET is shorter than 32 bytes; deriving a 32-byte key (dev only). Set JWT_SECRET in attendance_api/.env.');
        }
        return hash('sha256', $secret, true);
    }

    return $secret;
}

