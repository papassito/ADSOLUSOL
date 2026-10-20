import React, { useState } from 'react';
import { ACTIVE_DIRECTORY_FUNCTIONS } from '../data/activeDirectoryData';
import { Shield, Database, Network, Key, FileCode, CheckCircle2, Server, ArrowRight } from 'lucide-react';

export const ActiveDirectoryExplorer: React.FC = () => {
  const [kerberosStep, setKerberosStep] = useState<number>(0);

  const nextKerberosStep = () => {
    setKerberosStep((prev) => (prev >= 4 ? 0 : prev + 1));
  };

  const KERBEROS_STEPS = [
    {
      title: '0. Estado Inicial',
      from: 'Usuario (Cliente)',
      to: 'Dominio',
      ticket: 'Ninguno',
      desc: 'El usuario introduce su usuario y contrase a en una estaci n de trabajo unida al dominio.'
    },
    {
      title: '1. Solicitud AS_REQ / AS_REP (TGT)',
      from: 'Cliente',
      to: 'KDC (Authentication Service)',
      ticket: 'TGT (Ticket-Granting Ticket)',
      desc: 'El cliente env a su identidad cifrada con el hash de su clave. El KDC valida el hash y le devuelve un TGT firmado por la cuenta krbtgt del dominio.'
    },
    {
      title: '2. Solicitud TGS_REQ / TGS_REP (ST)',
      from: 'Cliente con TGT',
      to: 'KDC (Ticket-Granting Service)',
      ticket: 'Service Ticket (ST)',
      desc: 'El cliente presenta su TGT solicitando acceso a un recurso espec fico (ej. Servidor de Archivos SMB o Base de Datos SQL). El KDC expide el Service Ticket (ST).'
    },
    {
      title: '3. Presentaci n AP_REQ al Recurso',
      from: 'Cliente con ST',
      to: 'Servidor Destino (SMB/SQL)',
      ticket: 'Acceso Concedido con Token SID',
      desc: 'El cliente entrega el Service Ticket al servidor final. El servidor descifra el ticket usando su propia clave secreta y valida los grupos y permisos del usuario sin consultar de nuevo al KDC.'
    },
    {
      title: '4. Sesi n Autenticada (SSO Exitoso)',
      from: 'Sesi n Activa',
      to: 'Red Corporativa',
      ticket: 'Single Sign-On Activo',
      desc: 'El usuario accede de forma transparente a recursos sin tener que volver a ingresar su contrase a durante las siguientes 10 horas.'
    }
  ];

  return (
    <div className="space-y-8">
      {/* Overview Banner */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 sm:p-8">
        <div className="max-w-3xl">
          <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
            <span>Microsoft Windows Server & Entra ID</span>
            <span aria-hidden="true"> </span>
            <span>Motor de Identidad Empresarial</span>
          </div>
          <h2 className="text-xl sm:text-2xl lg:text-3xl font-bold text-white tracking-tight">
            Motor de Active Directory (AD): Identidad, LDAP y Pol ticas
          </h2>
          <p className="mt-2 text-xs sm:text-sm text-slate-300 leading-relaxed">
            Si tu consulta se refiere a <strong>Active Directory (AD)</strong> en administraci n de sistemas e infraestructura IT, el motor AD es la suite de servicios transaccionales que gestiona la seguridad, autenticaci n, control de acceso y configuraci n de cientos de miles de usuarios y servidores corporativos.
          </p>
        </div>
      </div>

      {/* Interactive Kerberos Flow Simulator */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 sm:p-7">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-5 border-b border-slate-800">
          <div>
            <div className="flex items-center gap-2 text-xs text-amber-400 font-mono font-medium mb-1">
              <span>PROTOCOLO KERBEROS RFC 4120</span>
              <span aria-hidden="true"> </span>
              <span>KDC ENGINE</span>
            </div>
            <h3 className="text-lg sm:text-xl font-bold text-white">
              Simulador del Motor de Autenticaci n Kerberos v5
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Haz clic en el bot n para avanzar paso a paso por la concesi n de tickets criptogr ficos (TGT y ST).
            </p>
          </div>
          <button
            onClick={nextKerberosStep}
            className="px-4 py-2 bg-amber-400 hover:bg-amber-300 active:scale-98 text-slate-950 font-semibold rounded-lg text-xs flex items-center gap-2 transition-all cursor-pointer self-start sm:self-auto shrink-0 shadow-sm"
          >
            <span>{kerberosStep === 4 ? 'Reiniciar Flujo' : 'Siguiente Paso Kerberos'}</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Steps display */}
        <div className="grid grid-cols-1 sm:grid-cols-5 gap-2 pt-5">
          {KERBEROS_STEPS.map((s, idx) => {
            const isCur = kerberosStep === idx;
            const isPast = kerberosStep > idx;
            return (
              <div
                key={idx}
                className={`p-3 rounded-xl border text-xs transition-all ${
                  isCur
                    ? 'border-amber-400 bg-amber-500/10 text-white'
                    : isPast
                    ? 'border-emerald-500/30 bg-emerald-950/20 text-slate-300'
                    : 'border-slate-800 bg-slate-950/50 text-slate-500'
                }`}
              >
                <div className="flex items-center justify-between text-[11px] font-mono mb-1">
                  <span className={isCur ? 'text-amber-400 font-bold' : isPast ? 'text-emerald-400' : ''}>
                    Paso {idx}
                  </span>
                  {isPast && <CheckCircle2 className="w-3 h-3 text-emerald-400" />}
                </div>
                <div className="font-semibold text-xs truncate">{s.title.split('. ')[1]}</div>
              </div>
            );
          })}
        </div>

        {/* Current Active Step Box */}
        <div className="mt-4 p-4 sm:p-5 bg-slate-950 rounded-xl border border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-xs">
          <div className="space-y-1">
            <span className="font-mono text-amber-400 text-xs font-semibold">
              {KERBEROS_STEPS[kerberosStep].title}
            </span>
            <p className="text-slate-200 text-xs sm:text-sm leading-relaxed max-w-2xl">
              {KERBEROS_STEPS[kerberosStep].desc}
            </p>
          </div>
          <div className="bg-slate-900 p-3 rounded-lg border border-slate-800 text-[11px] font-mono shrink-0 space-y-1">
            <div className="text-slate-400">Origen: <span className="text-white">{KERBEROS_STEPS[kerberosStep].from}</span></div>
            <div className="text-slate-400">Destino: <span className="text-white">{KERBEROS_STEPS[kerberosStep].to}</span></div>
            <div className="text-amber-400 font-semibold">Ticket: {KERBEROS_STEPS[kerberosStep].ticket}</div>
          </div>
        </div>
      </div>

      {/* 6 Core Functions of Active Directory */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg sm:text-xl font-bold text-white tracking-tight">
            Las 6 Funciones Arquitect nicas del Motor Active Directory
          </h3>
          <span className="text-xs text-slate-400 font-mono">NTDS.dit Core</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {ACTIVE_DIRECTORY_FUNCTIONS.map((fn) => (
            <div
              key={fn.id}
              className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-slate-700 transition-colors"
            >
              <div className="flex items-baseline gap-3 mb-2">
                <span className="font-mono text-lg font-bold text-amber-400">
                  {fn.number}.
                </span>
                <div>
                  <h4 className="text-base font-bold text-white">{fn.title}</h4>
                  <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                    <span>{fn.component}</span>
                    <span aria-hidden="true"> </span>
                    <span className="font-mono text-[11px] text-amber-400/90">{fn.protocolOrCore}</span>
                  </div>
                </div>
              </div>
              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed mb-4">
                {fn.description}
              </p>
              <div className="bg-slate-950/60 p-3 rounded-lg border border-slate-800/80 text-xs">
                <span className="text-[11px] font-semibold text-slate-400 block mb-1.5">
                  Responsabilidades Operativas:
                </span>
                <ul className="space-y-1 text-slate-300">
                  {fn.keyResponsibilities.map((resp, i) => (
                    <li key={i} className="flex items-start gap-1.5">
                      <span className="text-amber-400"> </span>
                      <span>{resp}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
