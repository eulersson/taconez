import type { Metadata } from "next";
import { Montserrat } from "next/font/google";

import "./globals.css";

const montserrat = Montserrat({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Taconez Journal",
  description: "Manage the annoying sound occurrences.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html suppressHydrationWarning>
      <body className={`
        ${montserrat.className} text-white
        bg-gradient-from-t bg-gradient-to-b from-tz-blue-light to-tz-blue-dark
      `}>
          {children}
      </body>
    </html>
  );
}
