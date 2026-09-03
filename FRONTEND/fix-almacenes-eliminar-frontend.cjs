const fs = require('fs');

const path = 'src/app/pages/almacenes/almacenes.ts';

let ts = fs.readFileSync(path, 'utf8');

/* Cuando cargue almacenes, ocultar estado ELIMINADO */
ts = ts.replace(
  /this\.almacenes\.set\(([^;]+)\);/g,
  (match, contenido) => {
    if (match.includes('ELIMINADO')) return match;

    return `this.almacenes.set((${contenido}).filter((almacen: any) => String(almacen.estado || '').toUpperCase() !== 'ELIMINADO'));`;
  }
);

/* Después de eliminar, quitar también localmente del listado */
ts = ts.replace(
  /if\s*\(accion === 'eliminar'\)\s*\{([\s\S]*?)\}/,
  (match, inner) => {
    if (match.includes('this.almacenes.update')) return match;

    return `if (accion === 'eliminar') {
            this.almacenes.update((lista) =>
              lista.filter((item) => item.idAlmacen !== almacen.idAlmacen),
            );
${inner}
          }`;
  }
);

fs.writeFileSync(path, ts, 'utf8');

console.log('Frontend Almacenes corregido: eliminado desaparece del listado.');
