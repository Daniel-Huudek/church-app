type BrandLogoProps = {
  src?: string;
  alt?: string;
  width?: number;
  height?: number;
  className?: string;
};

const DEFAULT_LOGO = '/logo.png';

export function BrandLogo({
  src = DEFAULT_LOGO,
  alt = '',
  width = 168,
  height = 64,
  className,
}: BrandLogoProps) {
  const resolved = src.trim() || DEFAULT_LOGO;

  return (
    <img
      className={className}
      src={resolved}
      alt={alt}
      width={width}
      height={height}
      decoding="async"
    />
  );
}
