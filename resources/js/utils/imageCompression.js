/**
 * Comprimi un'immagine lato client prima dell'upload
 * @param {File} file File immagine da comprimere
 * @param {number} maxSizeBytes Dimensione massima in bytes (default 2MB)
 * @param {number} maxWidth Larghezza massima in pixel (default 1920)
 * @param {number} maxHeight Altezza massima in pixel (default 1920)
 * @param {number} quality Qualità iniziale (0-1, default 0.85)
 * @returns {Promise<File>} File compresso
 */
export async function compressImage(
    file,
    maxSizeBytes = 2 * 1024 * 1024, // 2MB default
    maxWidth = 1920,
    maxHeight = 1920,
    quality = 0.85
) {
    return new Promise((resolve, reject) => {
        // Verifica che sia un'immagine
        if (!file.type.startsWith('image/')) {
            resolve(file); // Restituisci il file originale se non è un'immagine
            return;
        }

        // Se il file è già sotto il limite, restituiscilo così com'è
        if (file.size <= maxSizeBytes) {
            resolve(file);
            return;
        }

        const reader = new FileReader();
        
        reader.onload = (e) => {
            const img = new Image();
            
            img.onload = () => {
                // Calcola nuove dimensioni mantenendo le proporzioni
                let width = img.width;
                let height = img.height;
                
                if (width > maxWidth || height > maxHeight) {
                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width = width * ratio;
                    height = height * ratio;
                }

                // Crea canvas
                const canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');

                // Disegna l'immagine ridimensionata
                ctx.drawImage(img, 0, 0, width, height);

                // Determina il tipo MIME corretto per la compressione
                // JPEG usa 'image/jpeg' e supporta qualità, PNG no
                let outputType = file.type;
                if (file.type === 'image/jpg' || file.type === 'image/jpeg') {
                    outputType = 'image/jpeg';
                }

                // Funzione per comprimere progressivamente
                const compress = (currentQuality) => {
                    // Converti canvas in blob
                    // Per JPEG: usa qualità (0-1)
                    // Per PNG: qualità viene ignorata, usa sempre PNG
                    // Per WebP: usa qualità (0-1)
                    const blobOptions = outputType === 'image/png' 
                        ? undefined 
                        : currentQuality;
                    
                    canvas.toBlob(
                        (blob) => {
                            if (!blob) {
                                reject(new Error('Errore nella compressione dell\'immagine'));
                                return;
                            }

                            console.log('Tentativo compressione:', {
                                quality: currentQuality,
                                blobSize: blob.size,
                                targetSize: maxSizeBytes,
                                type: outputType
                            });

                            // Se la dimensione è accettabile o qualità minima raggiunta, restituisci
                            if (blob.size <= maxSizeBytes || currentQuality <= 0.5) {
                                // Crea un nuovo File dal blob con il nome originale
                                const compressedFile = new File(
                                    [blob],
                                    file.name,
                                    {
                                        type: outputType,
                                        lastModified: Date.now()
                                    }
                                );
                                
                                console.log('Immagine compressa:', {
                                    originalSize: file.size,
                                    compressedSize: blob.size,
                                    reduction: ((1 - blob.size / file.size) * 100).toFixed(1) + '%',
                                    quality: currentQuality,
                                    dimensions: `${width}x${height}`,
                                    type: outputType
                                });
                                
                                resolve(compressedFile);
                            } else {
                                // Riduci qualità e riprova (solo per formati che supportano qualità)
                                if (outputType === 'image/png') {
                                    // PNG non supporta qualità, riduci dimensioni invece
                                    if (width > 800 || height > 800) {
                                        const newRatio = Math.min(800 / width, 800 / height);
                                        width = Math.floor(width * newRatio);
                                        height = Math.floor(height * newRatio);
                                        canvas.width = width;
                                        canvas.height = height;
                                        ctx.drawImage(img, 0, 0, width, height);
                                        compress(1.0); // Riprova con nuove dimensioni
                                    } else {
                                        // Dimensioni minime raggiunte, accetta il file
                                        const compressedFile = new File(
                                            [blob],
                                            file.name,
                                            {
                                                type: outputType,
                                                lastModified: Date.now()
                                            }
                                        );
                                        resolve(compressedFile);
                                    }
                                } else {
                                    // Riduci qualità per JPEG/WebP
                                    const newQuality = Math.max(0.5, currentQuality - 0.1);
                                    compress(newQuality);
                                }
                            }
                        },
                        outputType,
                        blobOptions
                    );
                };

                // Inizia la compressione con qualità iniziale
                compress(quality);
            };

            img.onerror = () => {
                reject(new Error('Errore nel caricamento dell\'immagine'));
            };

            img.src = e.target.result;
        };

        reader.onerror = () => {
            reject(new Error('Errore nella lettura del file'));
        };

        reader.readAsDataURL(file);
    });
}

