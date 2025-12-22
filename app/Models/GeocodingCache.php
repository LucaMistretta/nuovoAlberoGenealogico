<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GeocodingCache extends Model
{
    protected $table = 'geocoding_cache';
    
    protected $fillable = [
        'luogo',
        'lat',
        'lng',
        'display_name',
    ];
    
    protected $casts = [
        'lat' => 'decimal:8',
        'lng' => 'decimal:8',
    ];
}
