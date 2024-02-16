import { useTheme } from "next-themes";

import { Button } from "@/components/button";

export function ThemeSwitch() {
  const { theme, setTheme } = useTheme();
  const switchTheme = () => {
    setTheme(theme === "light" ? "dark" : "light");
  };
  return (
    <div className="flex space-x-1">
      <Button
        className="w-[30px]"
        invertTheme={theme === "light"}
        onClick={() => switchTheme()}
      >
        ☼
      </Button>
      <Button
        className="w-[30px]"
        invertTheme={theme === "dark"}
        onClick={() => switchTheme()}
      >
        ☾
      </Button>
    </div>
  );
}
