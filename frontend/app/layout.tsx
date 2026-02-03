import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ToastProvider } from "@/components/ui/Toast";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "PROPHETIA - Zero-Knowledge Oracle Network",
  description: "Divine the Future. Reveal Nothing. - Decentralized ZK-ML prediction oracle on Aleo blockchain",
  keywords: ["aleo", "zero-knowledge", "ML", "oracle", "blockchain", "predictions", "ZK-SNARK"],
  authors: [{ name: "PROPHETIA Team" }],
  openGraph: {
    title: "PROPHETIA",
    description: "Zero-Knowledge Machine Learning Oracle Network",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ToastProvider>
          {children}
        </ToastProvider>
      </body>
    </html>
  );
}
