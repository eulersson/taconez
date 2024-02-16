import { clsx } from "clsx";

export function Button({
  className = "",
  children,
  invertTheme,
  onClick,
}: {
  className?: string;
  children: React.ReactNode;
  invertTheme?: boolean;
  onClick: () => void;
}) {
  const colorClasses = invertTheme ? "text-back bg-fore" : "text-fore bg-back";
  return (
    <button
      className={clsx(
        "border-2 border-fore hover:text-back hover:bg-fore rounded px-1",
        className,
        colorClasses
      )}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
