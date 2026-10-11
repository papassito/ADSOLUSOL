import React from 'react';
import { useTheme } from '../context/ThemeContext';
import { Sun, Moon, Monitor } from 'lucide-react';

export const ThemeToggle: React.FC = () => {
  const { theme, setTheme } = useTheme();

  return (
    <div className="flex bg-slate-900 rounded-lg p-1 border border-slate-800">
      <button onClick={() => setTheme('light')} className={`p-1.5 rounded ${theme === 'light' ? 'bg-slate-700 text-white' : 'text-slate-400'}`}>
        <Sun className="w-4 h-4" />
      </button>
      <button onClick={() => setTheme('dark')} className={`p-1.5 rounded ${theme === 'dark' ? 'bg-slate-700 text-white' : 'text-slate-400'}`}>
        <Moon className="w-4 h-4" />
      </button>
      <button onClick={() => setTheme('system')} className={`p-1.5 rounded ${theme === 'system' ? 'bg-slate-700 text-white' : 'text-slate-400'}`}>
        <Monitor className="w-4 h-4" />
      </button>
    </div>
  );
};
