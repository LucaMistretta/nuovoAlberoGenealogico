<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SyncConflict extends Model
{
    protected $fillable = [
        'table_name',
        'record_id',
        'server_data',
        'app_data',
        'server_updated_at',
        'app_updated_at',
        'resolution',
        'resolved_data',
        'resolved_by',
        'resolved_at',
    ];

    protected $casts = [
        'server_data' => 'array',
        'app_data' => 'array',
        'resolved_data' => 'array',
        'server_updated_at' => 'datetime',
        'app_updated_at' => 'datetime',
        'resolved_at' => 'datetime',
    ];

    public function resolvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}
