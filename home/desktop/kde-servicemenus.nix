{ pkgs, lib, machineConfig, ... }:
{
  # video compression service menu — CPU (libx264) and optionally GPU (h264_nvenc) at 3 quality levels
  xdg.dataFile."kio/servicemenus/compress-video.desktop".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=video/mp4;video/x-matroska;video/webm;video/x-msvideo;video/quicktime;video/x-flv;video/ogg;video/mpeg;video/x-ms-wmv;video/3gpp;
    Actions=CpuBest;CpuBal;CpuSmall;${lib.optionalString machineConfig.nvenc "GpuBest;GpuBal;GpuSmall;"}

    [Desktop Action CpuBest]
    Name=Compress — CPU Good Quality
    Icon=video-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v libx264 -preset slow -crf 26 -c:a copy "''${f%.*}_cpu_best.mp4"; done' -- %F

    [Desktop Action CpuBal]
    Name=Compress — CPU Balanced
    Icon=video-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v libx264 -preset medium -crf 32 -c:a copy "''${f%.*}_cpu_bal.mp4"; done' -- %F

    [Desktop Action CpuSmall]
    Name=Compress — CPU Smallest
    Icon=video-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v libx264 -preset fast -crf 38 -c:a copy "''${f%.*}_cpu_small.mp4"; done' -- %F
    ${lib.optionalString machineConfig.nvenc ''

    [Desktop Action GpuBest]
    Name=Compress — GPU (NVENC) Good Quality
    Icon=video-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v h264_nvenc -preset p6 -rc:v vbr -cq 26 -c:a copy "''${f%.*}_gpu_best.mp4"; done' -- %F

    [Desktop Action GpuBal]
    Name=Compress — GPU (NVENC) Balanced
    Icon=video-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v h264_nvenc -preset p4 -rc:v vbr -cq 32 -c:a copy "''${f%.*}_gpu_bal.mp4"; done' -- %F

    [Desktop Action GpuSmall]
    Name=Compress — GPU (NVENC) Smallest
    Icon=video-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$f" -c:v h264_nvenc -preset p2 -rc:v vbr -cq 38 -c:a copy "''${f%.*}_gpu_small.mp4"; done' -- %F
    ''}
  '';

  # OCR service menu — runs tesseract on images and outputs a .txt file
  xdg.dataFile."kio/servicemenus/ocr.desktop".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=image/jpeg;image/png;image/gif;image/webp;image/tiff;image/bmp;image/x-bmp;image/avif;
    Actions=OCRText;

    [Desktop Action OCRText]
    Name=OCR to Text
    Icon=document-new
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.tesseract}/bin/tesseract "$f" "''${f%.*}"; done' -- %F
  '';

  # r-click service menu in dolphin from reimage ported to nix
  xdg.dataFile."kio/servicemenus/reimage.desktop".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=image/jpeg;image/png;image/gif;image/webp;image/tiff;image/bmp;image/x-bmp;image/avif;image/svg+xml;
    Actions=Resize50;Resize75;Resize25;RotateCW;RotateCCW;FlipH;FlipV;ConvertPNG;ConvertJPG;ConvertWEBP;SquareCrop;SquarePad;

    [Desktop Action Resize50]
    Name=Resize to 50%
    Icon=transform-scale
    Exec=${pkgs.imagemagick}/bin/mogrify -resize 50% %F

    [Desktop Action Resize75]
    Name=Resize to 75%
    Icon=transform-scale
    Exec=${pkgs.imagemagick}/bin/mogrify -resize 75% %F

    [Desktop Action Resize25]
    Name=Resize to 25%
    Icon=transform-scale
    Exec=${pkgs.imagemagick}/bin/mogrify -resize 25% %F

    [Desktop Action RotateCW]
    Name=Rotate Clockwise 90°
    Icon=object-rotate-right
    Exec=${pkgs.imagemagick}/bin/mogrify -rotate 90 %F

    [Desktop Action RotateCCW]
    Name=Rotate Counter-Clockwise 90°
    Icon=object-rotate-left
    Exec=${pkgs.imagemagick}/bin/mogrify -rotate -90 %F

    [Desktop Action FlipH]
    Name=Flip Horizontal
    Icon=object-flip-horizontal
    Exec=${pkgs.imagemagick}/bin/mogrify -flop %F

    [Desktop Action FlipV]
    Name=Flip Vertical
    Icon=object-flip-vertical
    Exec=${pkgs.imagemagick}/bin/mogrify -flip %F

    [Desktop Action ConvertPNG]
    Name=Convert to PNG
    Icon=image-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.imagemagick}/bin/convert "$f" "''${f%.*}.png"; done' -- %F

    [Desktop Action ConvertJPG]
    Name=Convert to JPEG
    Icon=image-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.imagemagick}/bin/convert "$f" "''${f%.*}.jpg"; done' -- %F

    [Desktop Action ConvertWEBP]
    Name=Convert to WebP
    Icon=image-x-generic
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do ${pkgs.imagemagick}/bin/convert "$f" "''${f%.*}.webp"; done' -- %F

    [Desktop Action SquareCrop]
    Name=Crop to Square (center)
    Icon=image-crop
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do s=$(${pkgs.imagemagick}/bin/identify -format "%[fx:min(w,h)]" "$f"); ${pkgs.imagemagick}/bin/mogrify -gravity Center -crop "''${s}x''${s}+0+0" +repage "$f"; done' -- %F

    [Desktop Action SquarePad]
    Name=Pad to Square (white)
    Icon=image-resize
    Exec=${pkgs.bash}/bin/bash -c 'for f in "$@"; do s=$(${pkgs.imagemagick}/bin/identify -format "%[fx:max(w,h)]" "$f"); ${pkgs.imagemagick}/bin/mogrify -gravity Center -background white -extent "''${s}x''${s}" "$f"; done' -- %F
  '';
}
