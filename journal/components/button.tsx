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
  return (
    <button
      className={`
        text-black bg-white border-2 border-black border-black rounded px-1 
        hover:text-white hover:bg-black
      `}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
