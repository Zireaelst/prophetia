/**
 * ═══════════════════════════════════════════════════════════════════════════
 * PROPHETIA - Wallet Button Component
 * Aleo Wallet Connection
 * ═══════════════════════════════════════════════════════════════════════════
 */

'use client';

export function WalletButton() {
  // TODO: Integrate @demox-labs/aleo-wallet-adapter-react in next iteration
  // For now, placeholder button
  
  return (
    <button className="relative inline-flex items-center justify-center px-4 py-2 overflow-hidden font-medium text-white transition-all duration-300 rounded-lg group bg-gradient-to-r from-purple-600 to-pink-600 hover:shadow-[0_0_20px_rgba(168,85,247,0.4)]">
      <span className="absolute inset-0 w-full h-full bg-gradient-to-r from-pink-600 to-purple-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></span>
      <span className="relative flex items-center gap-2">
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
        <span className="text-sm">Connect Wallet</span>
      </span>
    </button>
  );
}
