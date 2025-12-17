<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateTipoLegameRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tipoLegameId = $this->route('id');
        
        return [
            'nome' => [
                'required',
                'string',
                'max:255',
                Rule::unique('tipi_di_legame', 'nome')->ignore($tipoLegameId),
            ],
            'descrizione' => 'nullable|string|max:500',
        ];
    }
}

