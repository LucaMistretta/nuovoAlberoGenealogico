<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePersonaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nome' => 'nullable|string|max:255',
            'cognome' => 'nullable|string|max:255',
            'nato_a' => 'nullable|string|max:255',
            'nato_il' => 'nullable|date',
            'deceduto_a' => 'nullable|string|max:255',
            'deceduto_il' => 'nullable|date',
            'relazioni' => 'nullable|array',
            'relazioni.*.persona_collegata_id' => 'required|integer|exists:persone,id',
            'relazioni.*.tipo_legame_id' => 'required|integer|exists:tipi_di_legame,id',
            'genitori' => 'nullable|array',
            'genitori.padre_id' => 'nullable|integer|exists:persone,id',
            'genitori.madre_id' => 'nullable|integer|exists:persone,id',
        ];
    }
}

