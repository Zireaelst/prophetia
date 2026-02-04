import React from 'react';
import { HashRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import AsciiBackground from './components/ui/AsciiBackground';
import Home from './pages/Home';
import Dashboard from './pages/Dashboard';
import Invest from './pages/Invest';
import Data from './pages/Data';
import Models from './pages/Models';
import Predictions from './pages/Predictions';

function App() {
  return (
    <Router>
      <div className="bg-background min-h-screen text-foreground font-sans selection:bg-primary selection:text-white">
        <AsciiBackground />
        
        <Navbar />
        
        <main className="relative z-10">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/invest" element={<Invest />} />
            <Route path="/data" element={<Data />} />
            <Route path="/models" element={<Models />} />
            <Route path="/predictions" element={<Predictions />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;