<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;

class ImageCompressionService
{
    /**
     * Comprimi un'immagine per risparmiare spazio disco
     * 
     * @param UploadedFile $file File immagine da comprimere
     * @param int $maxSizeBytes Dimensione massima target in bytes (default 1MB per risparmiare spazio)
     * @param int $maxWidth Larghezza massima in pixel (default 1920)
     * @param int $maxHeight Altezza massima in pixel (default 1920)
     * @param bool $alwaysCompress Se true, comprime sempre anche se sotto il limite (default true)
     * @return string|null Percorso del file compresso o null se non è un'immagine
     */
    public function compressImage(
        UploadedFile $file,
        int $maxSizeBytes = 1024 * 1024, // 1MB default per risparmiare spazio
        int $maxWidth = 1920,
        int $maxHeight = 1920,
        bool $alwaysCompress = true
    ): ?string {
        // Verifica che GD sia disponibile
        if (!extension_loaded('gd')) {
            Log::warning('Estensione GD non disponibile, impossibile comprimere immagini');
            return null;
        }

        // Verifica che sia un'immagine
        if (!str_starts_with($file->getMimeType(), 'image/')) {
            return null;
        }

        $mimeType = $file->getMimeType();
        $originalPath = $file->getRealPath();
        $originalSize = $file->getSize();
        
        // Se il file è già piccolo e non vogliamo comprimere sempre, salta
        if (!$alwaysCompress && $originalSize <= $maxSizeBytes) {
            return $originalPath;
        }

        // Carica l'immagine in base al tipo
        $image = match ($mimeType) {
            'image/jpeg', 'image/jpg' => imagecreatefromjpeg($originalPath),
            'image/png' => imagecreatefrompng($originalPath),
            'image/gif' => imagecreatefromgif($originalPath),
            'image/webp' => imagecreatefromwebp($originalPath),
            default => null,
        };

        if (!$image) {
            Log::warning('Tipo immagine non supportato per compressione', ['mime' => $mimeType]);
            return null;
        }

        // Ottieni dimensioni originali
        $originalWidth = imagesx($image);
        $originalHeight = imagesy($image);

        // Calcola nuove dimensioni mantenendo le proporzioni
        $ratio = min($maxWidth / $originalWidth, $maxHeight / $originalHeight, 1.0);
        $newWidth = (int)($originalWidth * $ratio);
        $newHeight = (int)($originalHeight * $ratio);

        // Crea nuova immagine ridimensionata
        $compressedImage = imagecreatetruecolor($newWidth, $newHeight);

        // Mantieni trasparenza per PNG e GIF
        if ($mimeType === 'image/png' || $mimeType === 'image/gif') {
            imagealphablending($compressedImage, false);
            imagesavealpha($compressedImage, true);
            $transparent = imagecolorallocatealpha($compressedImage, 255, 255, 255, 127);
            imagefilledrectangle($compressedImage, 0, 0, $newWidth, $newHeight, $transparent);
        }

        // Ridimensiona l'immagine con alta qualità
        imagecopyresampled(
            $compressedImage,
            $image,
            0, 0, 0, 0,
            $newWidth,
            $newHeight,
            $originalWidth,
            $originalHeight
        );

        imagedestroy($image);

        // Crea file temporaneo per la compressione
        $tempPath = sys_get_temp_dir() . '/' . uniqid('compressed_') . '.' . $file->getClientOriginalExtension();
        
        // Comprimi progressivamente fino a raggiungere la dimensione target
        // Qualità iniziale più bassa per risparmiare spazio (80 invece di 85)
        $quality = 80; // Qualità iniziale (bilanciata tra qualità e dimensione)
        $minQuality = 60; // Qualità minima accettabile
        $step = 5; // Step di riduzione qualità

        do {
            // Salva con qualità corrente
            switch ($mimeType) {
                case 'image/jpeg':
                case 'image/jpg':
                    imagejpeg($compressedImage, $tempPath, $quality);
                    break;
                case 'image/png':
                    // PNG usa compressione 0-9 (invertito rispetto a JPEG)
                    // Per PNG, usiamo compressione più aggressiva (livello 6-7)
                    $pngQuality = max(6, (int)(9 - ($quality / 10)));
                    imagepng($compressedImage, $tempPath, $pngQuality);
                    break;
                case 'image/gif':
                    imagegif($compressedImage, $tempPath);
                    break;
                case 'image/webp':
                    imagewebp($compressedImage, $tempPath, $quality);
                    break;
                default:
                    break;
            }

            clearstatcache(true, $tempPath);
            $fileSize = filesize($tempPath);

            // Se abbiamo raggiunto la dimensione target o qualità minima, esci
            if ($fileSize <= $maxSizeBytes || $quality <= $minQuality) {
                break;
            }

            // Riduci qualità per il prossimo tentativo
            $quality -= $step;
        } while ($quality >= $minQuality);
        
        // Log del risparmio spazio
        if (file_exists($tempPath)) {
            $compressedSize = filesize($tempPath);
            $savings = $originalSize - $compressedSize;
            $savingsPercent = $originalSize > 0 ? round(($savings / $originalSize) * 100, 1) : 0;
            
            Log::info('Immagine compressa', [
                'original_size' => round($originalSize / 1024, 2) . ' KB',
                'compressed_size' => round($compressedSize / 1024, 2) . ' KB',
                'savings' => round($savings / 1024, 2) . ' KB',
                'savings_percent' => $savingsPercent . '%',
            ]);
        }

        imagedestroy($compressedImage);

        // Se ancora troppo grande, riduci ulteriormente le dimensioni
        if (filesize($tempPath) > $maxSizeBytes && $newWidth > 800 && $newHeight > 800) {
            // Ricorsione con dimensioni più piccole
            $smallerFile = new UploadedFile(
                $tempPath,
                $file->getClientOriginalName(),
                $mimeType,
                null,
                true
            );
            
            unlink($tempPath);
            return $this->compressImage($smallerFile, $maxSizeBytes, 800, 800);
        }

        return $tempPath;
    }

    /**
     * Sostituisce il file originale con quello compresso
     * 
     * @param string $compressedPath Percorso del file compresso
     * @param string $originalPath Percorso del file originale
     * @return bool True se la sostituzione è riuscita
     */
    public function replaceOriginal(string $compressedPath, string $originalPath): bool
    {
        if (!file_exists($compressedPath)) {
            return false;
        }

        return copy($compressedPath, $originalPath) && unlink($compressedPath);
    }
}

