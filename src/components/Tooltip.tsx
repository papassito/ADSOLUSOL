import React, { useState } from 'react';

interface TooltipProps {
  content: string;
  children: React.ReactNode;
}

export const Tooltip: React.FC<TooltipProps> = ({ content, children }) => {
  const [isVisible, setIsVisible] = useState(false);
  return (
    <div className="relative inline-block" onMouseEnter={() => setIsVisible(true)} onMouseLeave={() => setIsVisible(false)}>
      {children}
      {isVisible && (
        <div className="absolute z-50 px-2 py-1 bg-slate-800 text-white text-[10px] rounded shadow-md -top-8 left-0 whitespace-nowrap border border-slate-700">
          {content}
        </div>
      )}
    </div>
  );
};
