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
    title: 'Motor de Autenticación Centralizada (Kerberos v5 & NTLM)',
    component: 'Key Distribution Center (KDC)',
    summary: 'Valida la identidad del usuario y emite tickets criptográficos TGT (Ticket Granting Ticket) y Service Tickets.',
    protocolOrCore: 'Kerberos RFC 4120, Puerto TCP/UDP 88',
    description: 'Es el corazón de la seguridad en entornos Windows Server. En lugar de transmitir contraseñas por la red, el motor KDC autentica al usuario contra la base de datos de cuentas, genera una clave de sesión y expide tickets firmados criptográficamente para permitir el inicio de sesión único (Single Sign-On SSO) en todos los recursos del dominio.',
    keyResponsibilities: [
      'Emisión de TGT (Ticket-Granting Ticket) tras validar credenciales del usuario.',
      'Emisión de Tickets de Servicio (ST) para recursos como servidores de archivos, SQL, Exchange o IIS.',
      'Autenticación mutua (el cliente verifica al servidor y el servidor al cliente).',
      'Compatibilidad hacia atrás mediante el protocolo NTLMv2 para clientes heredados.'
    ]
  },
  {
    id: 'ldap-directory-service',
    number: '02',
    title: 'Servicio de Directorio y Consultas Jerárquicas (LDAP / LDAPS)',
    component: 'LDAP Protocol Engine',
    summary: 'Proporciona una interfaz estándar para consultar, buscar y modificar objetos (usuarios, grupos, equipos) en el árbol.',
    protocolOrCore: 'LDAP v3 (RFC 4511), Puertos 389 (Clear) / 636 (SSL/TLS)',
    description: 'Active Directory organiza los datos en una estructura jerárquica de árbol orientada a objetos (Distinguished Names: CN, OU, DC). El motor LDAP procesa búsquedas complejas con filtros booleanos (ej. (&(objectCategory=person)(department=Ingeniería))) en microsegundos.',
    keyResponsibilities: [
      'Búsqueda y consulta de atributos de usuarios, ordenadores e impresoras en la red.',
      'Autenticación y enlace (LDAP Bind / StartTLS / LDAPS con certificados X.509).',
      'Paginación de resultados de gran volumen (Simple Paged Results RFC 2696).',
      'Gestión de Unidades Organizativas (OUs) y jerarquía departamental.'
    ]
  },
  {
    id: 'database-engine-ntds',
    number: '03',
    title: 'Motor de Base de Datos Transaccional (ESE / JET Blue NTDS.dit)',
    component: 'Extensible Storage Engine (ESE)',
    summary: 'Almacena físicamente todos los objetos, atributos y esquemas en un archivo transaccional ACID (NTDS.dit).',
    protocolOrCore: 'ESE (JET Blue Engine), ntds.dit + edb.log',
    description: 'Debajo de Active Directory corre un motor de base de datos relacional de alto rendimiento desarrollado por Microsoft llamado Extensible Storage Engine (ESE o JET Blue). Gestiona transacciones ACID con registro por adelantado (Write-Ahead Logging via edb.log) para garantizar consistencia incluso ante fallos abruptos de energía.',
    keyResponsibilities: [
      'Almacenamiento físico de objetos, clases y atributos del esquema de Active Directory.',
      'Control de transacciones ACID (Atomicidad, Consistencia, Aislamiento, Durabilidad).',
      'Desfragmentación en línea e indexación automática de columnas de búsqueda frecuente.',
      'Puntos de control (Checkpoints) y recuperación automática ante caídas de servidor.'
    ]
  },
  {
    id: 'multimaster-replication',
    number: '04',
    title: 'Motor de Replicación Multimaestro (Directory Replication Service - DRS)',
    component: 'Knowledge Consistency Checker (KCC) & DRS',
    summary: 'Sincroniza automáticamente los cambios realizados en cualquier Controlador de Dominio (DC) hacia el resto de la red.',
    protocolOrCore: 'DRS RPC sobre IP (Puerto 135/RPC dinámico) / SMTP en sitios lejanos',
    description: 'A diferencia de bases de datos tradicionales maestro-esclavo, AD utiliza replicación multimaestro: un administrador puede cambiar una contraseña en el Servidor DC1 en Madrid y el cambio se propaga al DC2 en Buenos Aires. El motor KCC calcula la topología de replicación óptima y resuelve colisiones de escritura mediante números de actualización de secuencia (USN) y marcas de tiempo UTC.',
    keyResponsibilities: [
      'Cálculo dinámico de la topología de replicación mediante el KCC (Knowledge Consistency Checker).',
      'Seguimiento de cambios mediante números USN (Update Sequence Numbers) sin necesidad de escaneo completo.',
      'Replicación intrasitio (inmediata con compresión nula) e intersitio (programada con alta compresión).',
      'Resolución de colisiones de atributos usando la regla "el cambio más reciente gana" (Last Write Wins).'
    ]
  },
  {
    id: 'group-policy-engine',
    number: '05',
    title: 'Motor de Políticas de Grupo (GPO Engine & Client-Side Extensions)',
    component: 'Group Policy Client (GPSVC)',
    summary: 'Distribuye y fuerza configuraciones de seguridad, contraseñas, cortafuegos y software en miles de estaciones de trabajo.',
    protocolOrCore: 'SMB (SYSVOL) + LDAP + GPUpdate',
    description: 'Permite la gestión centralizada de configuraciones en toda la flota de computadoras de la empresa. El motor en el servidor almacena las definiciones en el recurso compartido SYSVOL, y el motor del cliente (Group Policy Service) las descarga, procesa en orden de precedencia (LSDOU: Local, Sitio, Dominio, OU) y las aplica al registro de Windows.',
    keyResponsibilities: [
      'Aplicación forzada de directivas de contraseñas, bloqueo de USB y cortafuegos de Windows.',
      'Despliegue automático de certificados digitales y scripts de inicio/cierre de sesión.',
      'Orden de precedencia estricto (LSDOU) con soporte de Herencia y Bloqueo de Herencia (Enforced).',
      'Actualización periódica en segundo plano (cada 90 minutos por defecto con offset aleatorio de 30 min).'
    ]
  },
  {
    id: 'global-catalog-dns',
    number: '06',
    title: 'Catálogo Global y Localización de Servicios (GC & DNS Integrado)',
    component: 'Global Catalog (GC) & SRV Records',
    summary: 'Mantiene una copia parcial de solo lectura de todos los objetos del bosque y permite a los clientes encontrar DCs.',
    protocolOrCore: 'Puertos 3268 (GC) / 3269 (GC SSL), DNS RFC 2782 (SRV Records)',
    description: 'El Catálogo Global permite buscar a un empleado en cualquier dominio de un bosque corporativo multinacional en una sola consulta rápida. Asimismo, el motor se apoya en registros DNS SRV (_ldap._tcp.dc._msdcs.<dominio>) para que cualquier equipo cliente localice al controlador de dominio más cercano con menor latencia de red.',
    keyResponsibilities: [
      'Búsqueda universal de objetos a través de múltiples dominios dentro del mismo bosque.',
      'Resolución de pertenencia a grupos universales durante el proceso de inicio de sesión de usuario.',
      'Registro dinámico de registros DNS SRV para balanceo de carga y localización por afinidad de sitio.',
      'Soporte para zonas DNS integradas en Active Directory con replicación cifrada nativa.'
    ]
  }
];
