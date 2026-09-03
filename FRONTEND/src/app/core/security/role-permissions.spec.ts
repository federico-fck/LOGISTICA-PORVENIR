import { obtenerPermisosPorRol } from './role-permissions';

describe('Role permissions', () => {
  it('encargado de almacen no puede crear usuarios ni aprobar pedidos', () => {
    const permisos = obtenerPermisosPorRol('ENCARGADO_ALMACEN');

    expect(permisos).toContain('inventario.ajustar');
    expect(permisos).not.toContain('usuarios.crear');
    expect(permisos).not.toContain('pedidos.aprobar');
  });

  it('jefe de area puede aprobar, rechazar y observar pedidos', () => {
    const permisos = obtenerPermisosPorRol('JEFE_AREA');

    expect(permisos).toContain('pedidos.aprobar');
    expect(permisos).toContain('pedidos.rechazar');
    expect(permisos).toContain('pedidos.observar');
  });

  it('supervisor de mina puede leer catalogos operativos sin opciones de compras', () => {
    const permisos = obtenerPermisosPorRol('SUPERVISOR_MINA');

    expect(permisos).toContain('catalogos.ver');
    expect(permisos).toContain('inventario.ver');
    expect(permisos).toContain('despachos.ver');
    expect(permisos).not.toContain('compras.ver');
    expect(permisos).not.toContain('comprobantes.ver');
    expect(permisos).not.toContain('inventario.ver_movimientos');
  });

  it('auditor conserva acceso de lectura sin acciones operativas', () => {
    const permisos = obtenerPermisosPorRol('AUDITOR');

    expect(permisos).toContain('auditoria.ver');
    expect(permisos).toContain('reportes.exportar');
    expect(permisos).not.toContain('inventario.ajustar');
    expect(permisos).not.toContain('despachos.crear');
  });

  it('aliases antiguos normalizan a roles oficiales', () => {
    expect(obtenerPermisosPorRol('Jefe de almacén')).toEqual(
      obtenerPermisosPorRol('ENCARGADO_ALMACEN'),
    );
    expect(obtenerPermisosPorRol('COMPRAS')).toEqual(
      obtenerPermisosPorRol('ENCARGADO_COMPRAS'),
    );
  });
});
