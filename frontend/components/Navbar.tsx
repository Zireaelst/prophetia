import React, { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { Menu, X, Wallet, Zap } from 'lucide-react';
import Button from './ui/Button';

const Navbar: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);

  const links = [
    { name: 'Home', path: '/' },
    { name: 'Dashboard', path: '/dashboard' },
    { name: 'Invest', path: '/invest' },
    { name: 'Data', path: '/data' },
    { name: 'Models', path: '/models' },
    { name: 'Predictions', path: '/predictions' },
  ];

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 border-b border-glass-border bg-background/60 backdrop-blur-xl">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          
          {/* Logo */}
          <NavLink to="/" className="flex-shrink-0 flex items-center gap-2 cursor-pointer">
            <div className="w-8 h-8 rounded bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
               <Zap className="text-white w-5 h-5 fill-white" />
            </div>
            <span className="text-xl font-bold tracking-wider font-mono bg-clip-text text-transparent bg-gradient-to-r from-white to-white/60">
              PROPHETIA
            </span>
          </NavLink>

          {/* Desktop Nav */}
          <div className="hidden md:block">
            <div className="ml-10 flex items-baseline space-x-8">
              {links.map((link) => (
                <NavLink
                  key={link.name}
                  to={link.path}
                  className={({ isActive }) =>
                    `text-sm font-medium transition-colors font-mono ${
                      isActive
                        ? 'text-primary drop-shadow-[0_0_8px_rgba(147,51,234,0.5)]'
                        : 'text-gray-300 hover:text-white'
                    }`
                  }
                >
                  {link.name}
                </NavLink>
              ))}
            </div>
          </div>

          {/* Wallet Button */}
          <div className="hidden md:block">
            <Button variant="shimmer" leftIcon={<Wallet size={16} />} className="text-xs">
              Connect Wallet
            </Button>
          </div>

          {/* Mobile menu button */}
          <div className="md:hidden">
            <button
              onClick={() => setIsOpen(!isOpen)}
              className="text-gray-300 hover:text-white focus:outline-none"
            >
              {isOpen ? <X size={24} /> : <Menu size={24} />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      {isOpen && (
        <div className="md:hidden bg-background/95 backdrop-blur-xl border-b border-glass-border">
          <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
            {links.map((link) => (
              <NavLink
                key={link.name}
                to={link.path}
                onClick={() => setIsOpen(false)}
                className={({ isActive }) =>
                  `block px-3 py-2 rounded-md text-base font-medium font-mono ${
                    isActive ? 'text-primary bg-white/5' : 'text-gray-300 hover:text-white hover:bg-white/5'
                  }`
                }
              >
                {link.name}
              </NavLink>
            ))}
            <div className="mt-4 px-3">
                 <Button variant="primary" className="w-full justify-center">Connect Wallet</Button>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
};

export default Navbar;