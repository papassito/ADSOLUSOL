import { useEffect, useState } from 'react';

type Mode = 'dark' | 'light' | 'system' | 'oled';
type Palette = 'amber' | 'ocean' | 'emerald' | 'violet' | 'rose';
const modes: Mode[] = ['dark', 'light', 'system', 'oled'];
const palettes: Palette[] = ['amber', 'ocean', 'emerald', 'violet', 'rose'];

function saved<T extends string>(key: string, values: T[], fallback: T): T {
  try {
    const value = localStorage.getItem(key);
    return values.includes(value as T) ? value as T : fallback;
  } catch { return fallback; }
}

export function AppearanceControls() {
  const [mode, setMode] = useState<Mode>(() => saved('adsolusol_theme', modes, 'dark'));
  const [palette, setPalette] = useState<Palette>(() => saved('adsolusol_palette', palettes, 'amber'));

  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    const apply = () => {
      const resolved = mode === 'system' ? (media.matches ? 'dark' : 'light') : mode;
      document.documentElement.dataset.asTheme = resolved;
      document.documentElement.dataset.asPalette = palette;
      document.documentElement.classList.toggle('dark', resolved !== 'light');
      document.documentElement.classList.toggle('light', resolved === 'light');
    };
    apply();
    try {
      localStorage.setItem('adsolusol_theme', mode);
      localStorage.setItem('adsolusol_palette', palette);
    } catch { /* Appearance still works when browser storage is unavailable. */ }
    media.addEventListener('change', apply);
    return () => media.removeEventListener('change', apply);
  }, [mode, palette]);

  return <div className="as-appearance" role="group" aria-label="Apariencia">
    <label>Tema
      <select aria-label="Tema de apariencia" value={mode} onChange={e => setMode(e.target.value as Mode)}>
        <option value="light">Claro</option>
        <option value="dark">Oscuro</option>
        <option value="system">Sistema</option>
        <option value="oled">Negro puro OLED · #000000</option>
      </select>
    </label>
    <label>Color
      <select aria-label="Paleta de color" value={palette} onChange={e => setPalette(e.target.value as Palette)}>
        <option value="amber">Terminal Ámbar</option>
        <option value="ocean">Blueprint Cobalto</option>
        <option value="emerald">Matrix Esmeralda</option>
        <option value="violet">Violeta</option>
        <option value="rose">Táctico Carmesí</option>
      </select>
    </label>
  </div>;
}
