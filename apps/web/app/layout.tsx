import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TripBanBan",
  description: "把行程、地點與每天的節奏整理在一起。"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="zh-Hant">
      <body>{children}</body>
    </html>
  );
}
