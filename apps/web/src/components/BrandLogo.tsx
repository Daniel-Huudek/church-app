function isRemoteAsset(src: string) {
  return /^https?:\/\//i.test(src);
}

type BrandLogoProps = {
  src?: string;
  alt?: string;
  width?: number;
  height?: number;
  className?: string;
};

export function BrandLogo({
  src = '/logo.png',
  alt = '',
  width = 38,
  height = 38,
  className,
}: BrandLogoProps) {
  const resolved = src.trim() || '/logo.png';
  const invert = !isRemoteAsset(resolved);

  return (
    <img
      className={className}
      src={resolved}
      alt={alt}
      width={width}
      height={height}
      style={invert ? { filter: 'invert(1)' } : undefined}
    />
  );
}
