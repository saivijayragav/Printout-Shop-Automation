'use client';

import { useState } from 'react';
import { BindingType, FileData, PrintColor, Sides } from '@/types';
import { cn } from '@/lib/utils';
import { X } from 'lucide-react';

interface Props {
  file: Omit<FileData, 'binding' | 'color' | 'sides' | 'copies'>;
  onDone: (config: { binding: BindingType; color: PrintColor; sides: Sides }) => void;
  onCancel: () => void;
}

const COLOR_OPTIONS: { value: PrintColor; label: string; badge: string }[] = [
  { value: PrintColor.bw, label: 'Black & White', badge: 'BW' },
  { value: PrintColor.color, label: 'Color +₹5/pg', badge: 'COLOR' },
];

const SIDES_OPTIONS: { value: Sides; label: string }[] = [
  { value: Sides.single, label: 'Single Side' },
  { value: Sides.both, label: 'Double Side' },
  { value: Sides.four, label: 'Four Side' },
];

const BINDING_OPTIONS: { value: BindingType; label: string }[] = [
  { value: BindingType.nobinding, label: 'No Binding' },
  { value: BindingType.soft, label: 'Soft Binding +₹30' },
  { value: BindingType.spiral, label: 'Spiral Binding +₹35' },
];

export default function PrintConfigDialog({ file, onDone, onCancel }: Props) {
  const [color, setColor] = useState<PrintColor>(PrintColor.bw);
  const [sides, setSides] = useState<Sides>(Sides.single);
  const [binding, setBinding] = useState<BindingType>(BindingType.nobinding);

  const showBinding = file.pages > 5;

  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-black/60 backdrop-blur-sm px-0 md:px-4">
      <div className="bg-card border border-border rounded-t-2xl md:rounded-2xl w-full max-w-md p-6 shadow-2xl max-h-[90dvh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-start justify-between mb-5">
          <div>
            <h2 className="text-base font-semibold">Print Settings</h2>
            <p className="text-xs text-muted-foreground mt-0.5 truncate max-w-[220px]">{file.name}</p>
          </div>
          <button onClick={onCancel} className="text-muted-foreground hover:text-foreground ml-2">
            <X size={20} />
          </button>
        </div>

        <div className="flex flex-col gap-5">
          {/* Color */}
          <Section title="Print Color">
            {COLOR_OPTIONS.map((opt) => (
              <RadioRow
                key={opt.value}
                label={opt.label}
                checked={color === opt.value}
                onChange={() => setColor(opt.value)}
              />
            ))}
          </Section>

          {/* Sides */}
          <Section title="Sides">
            {SIDES_OPTIONS.map((opt) => (
              <RadioRow
                key={opt.value}
                label={opt.label}
                checked={sides === opt.value}
                onChange={() => setSides(opt.value)}
              />
            ))}
          </Section>

          {/* Binding (only for >5 page files) */}
          {showBinding && (
            <Section title="Binding">
              {BINDING_OPTIONS.map((opt) => (
                <RadioRow
                  key={opt.value}
                  label={opt.label}
                  checked={binding === opt.value}
                  onChange={() => setBinding(opt.value)}
                />
              ))}
            </Section>
          )}
        </div>

        <button
          onClick={() => onDone({ color, sides, binding })}
          className="mt-6 w-full bg-accent text-accent-foreground font-semibold rounded-xl py-3 text-sm hover:bg-accent/90 active:scale-95 transition"
        >
          Done
        </button>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2">{title}</p>
      <div className="flex flex-col gap-1">{children}</div>
    </div>
  );
}

function RadioRow({ label, checked, onChange }: { label: string; checked: boolean; onChange: () => void }) {
  return (
    <label className={cn(
      'flex items-center gap-3 px-3 py-2.5 rounded-lg cursor-pointer transition-colors',
      checked ? 'bg-accent/15 border border-accent/40' : 'border border-transparent hover:bg-muted'
    )}>
      <input type="radio" checked={checked} onChange={onChange} className="accent-[#6EACDA]" />
      <span className="text-sm">{label}</span>
    </label>
  );
}
