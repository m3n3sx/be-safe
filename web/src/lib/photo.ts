export async function preparePhoto(file: File): Promise<File> {
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type))
    throw new Error('Wybierz zdjęcie JPEG, PNG lub WebP.');
  if (file.size > 5 * 1024 * 1024) throw new Error('Zdjęcie może mieć maksymalnie 5 MB.');
  if (typeof createImageBitmap === 'undefined') return file;
  const image = await createImageBitmap(file);
  try {
    const scale = Math.min(1, 1920 / Math.max(image.width, image.height));
    const canvas = document.createElement('canvas');
    canvas.width = Math.round(image.width * scale);
    canvas.height = Math.round(image.height * scale);
    const ctx = canvas.getContext('2d');
    if (!ctx) return file;
    ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob(resolve, 'image/jpeg', 0.85),
    );
    return blob && blob.size < file.size
      ? new File([blob], 'zgloszenie.jpg', { type: 'image/jpeg' })
      : file;
  } finally {
    image.close();
  }
}
