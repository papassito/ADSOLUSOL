export interface ADFunction {
  id: string;
  number: string;
  title: string;
  component: string;
  summary: string;
  protocolOrCore: string;
  description: string;
  keyResponsibilities: string[];
}

export const ACTIVE_DIRECTORY_FUNCTIONS: ADFunction[] = [
  {
    id: 'kerberos-auth',
    number: '01',
    title: 'Motor de Autenticaci n Centralizada (Kerberos v5 & NTLM)',
    component: 'Key Distribution Center (KDC)',
    summary: 'Valida la identidad del usuario y emite tickets criptogr ficos TGT (Ticket Granting Ticket) y Service Tickets.',
    protocolOrCore: 'Kerberos RFC 4120, Puerto TCP/UDP 88',
    description: 'Es el coraz n de la seguridad en entornos Windows Server. En lugar de transmitir contrase as por la red, el motor KDC autentica al usuario contra la base de datos de cuentas, genera una clave de sesi n y expide tickets firmados criptogr ficamente para permitir el inicio de sesi nico (Single Sign-On SSO) en todos los recursos del dominio.',
    keyResponsibilities: [
      'Emisi n de TGT (Ticket-Granting Ticket) tras validar credenciales del usuario.',
      'Emisi n de Tickets de Servicio (ST) para recursos como servidores de archivos, SQL, Exchange o IIS.',
      'Autenticaci n mutua (el cliente verifica al servidor y el servidor al cliente).',
      'Compatibilidad hacia atr s mediante el protocolo NTLMv2 para clientes heredados.'
    ]
  },
  {
    id: 'ldap-directory-service',
    number: '02',
    title: 'Servicio de Directorio y Consultas Jer rquicas (LDAP / LDAPS)',
    component: 'LDAP Protocol Engine',
    summary: 'Proporciona una interfaz est ndar para consultar, buscar y modificar objetos (usuarios, grupos, equipos) en el  rbol.',
    protocolOrCore: 'LDAP v3 (RFC 4511), Puertos 389 (Clear) / 636 (SSL/TLS)',
    description: 'Active Directory organiza los datos en una estructura jer rquica de  rbol orientada a objetos (Distinguished Names: CN, OU, DC). El motor LDAP procesa b squedas complejas con filtros booleanos (ej. (&(objectCategory=person)(department=Ingenieria))) en microsegundos.',
    keyResponsibilities: [
      'B squeda y consulta de atributos de usuarios, ordenadores e impresoras en la red.',
      'Autenticaci n y enlace (LDAP Bind / StartTLS / LDAPS con certificados X.509).',
      'Paginaci n de resultados de gran volumen (Simple Paged Results RFC 2696).',
      'Gesti n de Unidades Organizativas (OUs) y jerarqu a departamental.'
    ]
  },
  {
    id: 'database-engine-ntds',
    number: '03',
    title: 'Motor de Base de Datos Transaccional (ESE / JET Blue NTDS.dit)',
    component: 'Extensible Storage Engine (ESE)',
    summary: 'Almacena f sicamente todos los objetos, atributos y esquemas en un archivo transaccional ACID (NTDS.dit).',
    protocolOrCore: 'ESE (JET Blue Engine), ntds.dit + edb.log',
    description: 'Debajo de Active Directory corre un motor de base de datos relacional de alto rendimiento desarrollado por Microsoft llamado Extensible Storage Engine (ESE o JET Blue). Gestiona transacciones ACID con registro por adelantado (Write-Ahead Logging via edb.log) para garantizar consistencia incluso ante fallos abruptos de energ a.',
    keyResponsibilities: [
      'Almacenamiento f sico de objetos, clases y atributos del esquema de Active Directory.',
      'Control de transacciones ACID (Atomicidad, Consistencia, Aislamiento, Durabilidad).',
      'Desfragmentaci n en l nea e indexaci n autom tica de columnas de b squeda frecuente.',
      'Puntos de control (Checkpoints) y recuperaci n autom tica ante ca das de servidor.'
    ]
  },
  {
    id: 'multimaster-replication',
    number: '04',
    title: 'Motor de Replicaci n Multimaestro (Directory Replication Service - DRS)',
    component: 'Knowledge Consistency Checker (KCC) & DRS',
    summary: 'Sincroniza autom ticamente los cambios realizados en cualquier Controlador de Dominio (DC) hacia el resto de la red.',
    protocolOrCore: 'DRS RPC sobre IP (Puerto 135/RPC din mico) / SMTP en sitios lejanos',
    description: 'A diferencia de bases de datos tradicionales maestro-esclavo, AD utiliza replicaci n multimaestro: un administrador puede cambiar una contrase a en el Servidor DC1 en Madrid y el cambio se propaga al DC2 en Buenos Aires. El motor KCC calcula la topolog a de replicaci ptima y resuelve colisiones de escritura mediante n meros de actualizaci n de secuencia (USN) y marcas de tiempo UTC.',
    keyResponsibilities: [
      'C lculo din mico de la topolog a de replicaci n mediante el KCC (Knowledge Consistency Checker).',
      'Seguimiento de cambios mediante n meros USN (Update Sequence Numbers) sin necesidad de escaneo completo.',
      'Replicaci n intrasitio (inmediata con compresi n nula) e intersitio (programada con alta compresi n).',
      'Resoluci n de colisiones de atributos usando la regla "el cambio m s reciente gana" (Last Write Wins).'
    ]
  },
  {
    id: 'group-policy-engine',
    number: '05',
    title: 'Motor de Pol ticas de Grupo (GPO Engine & Client-Side Extensions)',
    component: 'Group Policy Client (GPSVC)',
    summary: 'Distribuye y fuerza configuraciones de seguridad, contrase as, cortafuegos y software en miles de estaciones de trabajo.',
    protocolOrCore: 'SMB (SYSVOL) + LDAP + GPUpdate',
    description: 'Permite la gesti n centralizada de configuraciones en toda la flota de computadoras de la empresa. El motor en el servidor almacena las definiciones en el recurso compartido SYSVOL, y el motor del cliente (Group Policy Service) las descarga, procesa en orden de precedencia (LSDOU: Local, Sitio, Dominio, OU) y las aplica al registro de Windows.',
    keyResponsibilities: [
      'Aplicaci n forzada de directivas de contrase as, bloqueo de USB y cortafuegos de Windows.',
      'Despliegue autom tico de certificados digitales y scripts de inicio/cierre de sesi n.',
      'Orden de precedencia estricto (LSDOU) con soporte de Herencia y Bloqueo de Herencia (Enforced).',
      'Actualizaci n peri dica en segundo plano (cada 90 minutos por defecto con offset aleatorio de 30 min).'
    ]
  },
  {
    id: 'global-catalog-dns',
    number: '06',
    title: 'Cat logo Global y Localizaci n de Servicios (GC & DNS Integrado)',
    component: 'Global Catalog (GC) & SRV Records',
    summary: 'Mantiene una copia parcial de solo lectura de todos los objetos del bosque y permite a los clientes encontrar DCs.',
    protocolOrCore: 'Puertos 3268 (GC) / 3269 (GC SSL), DNS RFC 2782 (SRV Records)',
    description: 'El Cat logo Global permite buscar a un empleado en cualquier dominio de un bosque corporativo multinacional en una sola consulta r pida. Asimismo, el motor se apoya en registros DNS SRV (_ldap._tcp.dc._msdcs.<dominio>) para que cualquier equipo cliente localice al controlador de dominio m s cercano con menor latencia de red.',
    keyResponsibilities: [
      'B squeda universal de objetos a trav s de m ltiples dominios dentro del mismo bosque.',
      'Resoluci n de pertenencia a grupos universales durante el proceso de inicio de sesi n de usuario.',
      'Registro din mico de registros DNS SRV para balanceo de carga y localizaci n por afinidad de sitio.',
      'Soporte para zonas DNS integradas en Active Directory con replicaci n cifrada nativa.'
    ]
  }
];
